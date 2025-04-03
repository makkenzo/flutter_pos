import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_pos/models/analytics/sales_analytics.dart';
import 'package:flutter_pos/models/cart_item.dart';
import 'package:flutter_pos/models/cart_state.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/models/sale.dart';
import 'package:flutter_pos/models/sale_item.dart';
import 'package:flutter_pos/services/storage_service.dart';
import 'package:flutter_pos/utils/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PaginatedResponse<T> {
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final int limit;
  final int skip;
  final bool isLast;
  final List<T> content;

  PaginatedResponse({
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.limit,
    required this.skip,
    required this.isLast,
    required this.content,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final contentList = json['content'] as List? ?? [];
    final items = contentList.map((itemJson) => fromJsonT(itemJson as Map<String, dynamic>)).toList();

    try {
      return PaginatedResponse<T>(
        totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
        currentPage: (json['current_page'] as num?)?.toInt() ?? 0,
        totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
        limit: (json['limit'] as num?)?.toInt() ?? 0,
        skip: (json['skip'] as num?)?.toInt() ?? 0,

        isLast: json['is_last'] as bool? ?? true,
        content: items,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class ApiService {
  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _getAuthHeaders({bool includeContentType = true}) async {
    String? token = await _storageService.getToken();
    final headers = <String, String>{};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    if (token != null && token.isNotEmpty) {
      headers['X-API-Key'] = token;
    }
    return headers;
  }

  Exception _handleHttpError(http.Response response, String operation) {
    String errorMessage = '$operation failed with status code ${response.statusCode}.';
    try {
      final body = jsonDecode(response.body);
      if (body['message'] != null) {
        errorMessage += ' Message: ${body['message']}';
      } else if (body['detail'] != null) {
        errorMessage += ' Detail: ${body['detail']}';
      }
    } catch (_) {
      errorMessage += ' Response body: ${response.body}';
    }

    if (response.statusCode == 401) {
      return UnauthorizedException(errorMessage);
    }
    return HttpException(errorMessage);
  }

  Future<String> login(String username, String password) async {
    final Uri loginUri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');

    try {
      final response = await http
          .post(
            loginUri,
            headers: await _getAuthHeaders(),
            body: jsonEncode(<String, String>{'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final body = jsonDecode(response.body);
          final token = body['access_token'] as String?;

          if (token != null && token.isNotEmpty) {
            await _storageService.saveToken(token);

            return token;
          } else {
            throw Exception('Не удалось получить токен из ответа сервера.');
          }
        } catch (e) {
          throw Exception('Ошибка обработки ответа сервера при входе.');
        }
      } else {
        throw _handleHttpError(response, 'Login');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети. Проверьте подключение к интернету.');
    } on http.ClientException catch (_) {
      throw Exception('Ошибка клиента при подключении к серверу.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Неизвестная ошибка при входе: ${e.runtimeType}');
    }
  }

  Future<void> logout() async {
    try {
      await _storageService.deleteToken();
    } catch (_) {}
  }

  Future<PaginatedResponse<Product>> getProducts({
    int skip = 0,
    int limit = 20,
    String? searchQuery,
    String sortBy = 'name',
    String sortOrder = 'asc',
    int? minPrice,
    int? maxPrice,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'sort_order': sortOrder,
      'sort_by': sortBy,
    };
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }
    if (minPrice != null) {
      queryParams['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['max_price'] = maxPrice.toString();
    }

    final Uri productsUri = Uri.parse('${ApiConstants.baseUrl}/products/local/').replace(queryParameters: queryParams);

    try {
      final response = await http
          .get(productsUri, headers: await _getAuthHeaders(includeContentType: false))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));

          return PaginatedResponse.fromJson(body, Product.fromJson);
        } catch (e) {
          throw Exception('Ошибка обработки ответа сервера при получении продуктов.');
        }
      } else {
        throw _handleHttpError(response, 'Get products');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети при получении продуктов.');
    } on http.ClientException catch (_) {
      throw Exception('Ошибка клиента при получении продуктов.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка при получении продуктов: ${e.runtimeType}');
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;
    final Uri productUri = Uri.parse('${ApiConstants.baseUrl}/products/global/by-barcode/$barcode');

    try {
      final response = await http
          .get(productUri, headers: await _getAuthHeaders(includeContentType: false))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          return Product.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        } catch (e) {
          throw Exception('Ошибка обработки ответа сервера.');
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw _handleHttpError(response, 'Get product by barcode $barcode');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети.');
    } on http.ClientException catch (_) {
      throw Exception('Ошибка клиента.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка: ${e.runtimeType}');
    }
  }

  Future<Product> addProduct(Product product) async {
    final Uri productsUri = Uri.parse('${ApiConstants.baseUrl}/products/local/');

    try {
      final response = await http
          .post(productsUri, headers: await _getAuthHeaders(), body: jsonEncode(product.toJsonForCreate()))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          return Product.fromJson(body);
        } catch (e) {
          throw Exception('Ошибка обработки ответа сервера после добавления продукта.');
        }
      } else {
        throw _handleHttpError(response, 'Add product');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети при добавлении продукта.');
    } on http.ClientException catch (_) {
      throw Exception('Ошибка клиента при добавлении продукта.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка при добавлении продукта: ${e.runtimeType}');
    }
  }

  Future<Product> updateProduct(int productId, Product product) async {
    final Uri productUri = Uri.parse('${ApiConstants.baseUrl}/products/local/$productId');

    try {
      final response = await http
          .put(productUri, headers: await _getAuthHeaders(), body: jsonEncode(product.toJsonForUpdate()))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          return Product.fromJson(body);
        } catch (e) {
          throw Exception('Ошибка обработки ответа сервера после обновления продукта.');
        }
      } else {
        throw _handleHttpError(response, 'Update product $productId');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети при обновлении продукта.');
    } on http.ClientException catch (_) {
      throw Exception('Ошибка клиента при обновлении продукта.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка при обновлении продукта: ${e.runtimeType}');
    }
  }

  Future<void> deleteProduct(int productId) async {
    final Uri productUri = Uri.parse('${ApiConstants.baseUrl}/products/local/$productId');

    try {
      final response = await http
          .delete(productUri, headers: await _getAuthHeaders(includeContentType: false))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleHttpError(response, 'Delete product $productId');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети при удалении продукта.');
    } on http.ClientException catch (_) {
      throw Exception('Ошибка клиента при удалении продукта.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка при удалении продукта: ${e.runtimeType}');
    }
  }

  Future<String> createSale(
    List<CartItem> cartItems,
    double totalAmount,
    PaymentMethod paymentMethod,
    CartDiscountType discountType,
    double discountValue,
    double subtotal,
  ) async {
    if (cartItems.isEmpty) {
      throw ArgumentError("Корзина не может быть пустой для создания продажи.");
    }

    final queryParams = <String, String>{
      'currency': 'KZT',
      'payment_method': paymentMethod.name,
      'sale_status': 'paid',
      'discount_type': discountType.name,
      'discount_value': discountValue.toString(),
    };

    final Uri salesUri = Uri.parse('${ApiConstants.baseUrl}/sales/create').replace(queryParameters: queryParams);

    final List<Map<String, dynamic>> itemsBody =
        cartItems.map((item) {
          final double itemCostPrice = item.costPrice;
          return {
            'product_id': item.productId,
            'product_name': item.name,
            'barcode': item.barcode,
            'quantity': item.quantity,
            'price': item.priceAtSale,
            'cost_price': itemCostPrice,
          };
        }).toList();

    try {
      final response = await http
          .post(salesUri, headers: await _getAuthHeaders(), body: jsonEncode(itemsBody))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          final orderId = body['order_id'] as String?;
          if (orderId != null && orderId.isNotEmpty) {
            return orderId;
          } else {
            throw Exception('Не удалось получить ID заказа из ответа сервера.');
          }
        } catch (e) {
          throw Exception('Ошибка обработки ответа сервера после создания продажи.');
        }
      } else if (response.statusCode == 422) {
        String detailMessage = 'Ошибка валидации данных при создании продажи.';
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));

          if (body['detail'] is List && body['detail'].isNotEmpty) {
            detailMessage = (body['detail'] as List)
                .map((err) => "Поле: ${err['loc']?.join('.') ?? 'N/A'}, Сообщение: ${err['msg'] ?? 'N/A'}")
                .join('; ');
          } else if (body['detail'] != null) {
            detailMessage = body['detail'].toString();
          }
        } catch (_) {}
        throw Exception(detailMessage);
      } else {
        throw _handleHttpError(response, 'Create sale');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети при создании продажи.');
    } on http.ClientException catch (_) {
      throw Exception('Ошибка клиента при создании продажи.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка при создании продажи: ${e.runtimeType}');
    }
  }

  Future<PaginatedResponse<Sale>> getSalesHistory({int skip = 0, int limit = 20, String sortOrder = 'desc'}) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'sort_order': sortOrder,
      'sort_by': 'order_id',
    };

    final Uri salesUri = Uri.parse('${ApiConstants.baseUrl}/sales/').replace(queryParameters: queryParams);

    try {
      final response = await http
          .get(salesUri, headers: await _getAuthHeaders(includeContentType: false))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));

          return PaginatedResponse.fromJson(body, Sale.fromJson);
        } catch (e) {
          throw Exception('Ошибка обработки ответа сервера при получении истории продаж.');
        }
      } else {
        throw _handleHttpError(response, 'Get sales history');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети при получении истории продаж.');
    } on http.ClientException catch (_) {
      throw Exception('Ошибка клиента при получении истории продаж.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка при получении истории продаж: ${e.runtimeType}');
    }
  }

  Future<List<SaleItem>> getSaleItems(String orderId) async {
    final Uri saleItemsUri = Uri.parse('${ApiConstants.baseUrl}/sales/$orderId');

    try {
      final response = await http
          .get(saleItemsUri, headers: await _getAuthHeaders(includeContentType: false))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body is Map && body.containsKey('items') && body['items'] is List) {
            List<dynamic> itemsList = body['items'];
            return itemsList.map((dynamic item) => SaleItem.fromJson(item)).toList();
          } else if (body is List) {
            return body.map((dynamic item) => SaleItem.fromJson(item)).toList();
          } else {
            throw Exception('Неожиданный формат ответа для деталей продажи.');
          }
        } catch (e) {
          throw Exception('Ошибка обработки ответа сервера при получении деталей продажи.');
        }
      } else {
        throw _handleHttpError(response, 'Get sale items for order $orderId');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети при получении деталей продажи.');
    } on http.ClientException catch (_) {
      throw Exception('Ошибка клиента при получении деталей продажи.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка при получении деталей продажи: ${e.runtimeType}');
    }
  }

  Future<SalesAnalytics> getSalesAnalytics({DateTime? startDate, DateTime? endDate}) async {
    final queryParams = <String, String>{};
    // Форматируем даты в ISO 8601 (YYYY-MM-DD), если они переданы
    // Уточните у API, какой формат даты он ожидает!
    if (startDate != null) {
      queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
    }
    if (endDate != null) {
      // Включаем весь день для endDate
      queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
    }

    // ЗАМЕНИТЕ на ваш эндпоинт
    final Uri analyticsUri = Uri.parse('${ApiConstants.baseUrl}/analytics/sales').replace(queryParameters: queryParams);

    try {
      final response = await http
          .get(analyticsUri, headers: await _getAuthHeaders(includeContentType: false))
          .timeout(const Duration(seconds: 30)); // Таймаут побольше для аналитики

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          return SalesAnalytics.fromJson(body);
        } catch (e) {
          throw Exception('Ошибка обработки ответа сервера при получении аналитики.');
        }
      } else {
        throw _handleHttpError(response, 'Get sales analytics');
      }
    } on SocketException catch (_) {
      throw Exception('Ошибка сети при получении аналитики.');
    } on TimeoutException catch (_) {
      throw Exception('Превышено время ожидания ответа от сервера.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка при получении аналитики: ${e.runtimeType}');
    }
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends HttpException {
  UnauthorizedException(String message) : super(message);
}
