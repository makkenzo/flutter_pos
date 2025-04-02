import 'dart:convert';
import 'dart:io';

import 'package:flutter_pos/models/cart_item.dart';
import 'package:flutter_pos/models/payment_method.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/models/sale.dart';
import 'package:flutter_pos/models/sale_item.dart';
import 'package:flutter_pos/services/storage_service.dart';
import 'package:http/http.dart' as http;

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

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final contentList = json['content'] as List? ?? [];
    final items =
        contentList
            .map((itemJson) => fromJsonT(itemJson as Map<String, dynamic>))
            .toList();

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
      print("!!! Error parsing PaginatedResponse from JSON: $e");
      print("Problematic JSON keys: ${json.keys}");
      rethrow;
    }
  }
}

class ApiService {
  final String _baseUrl = "https://pos-api.makkenzo.com";
  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _getAuthHeaders({
    bool includeContentType = true,
  }) async {
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
    String errorMessage =
        '$operation failed with status code ${response.statusCode}.';
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
    final Uri loginUri = Uri.parse('$_baseUrl/auth/token');
    print('Attempting login to: $loginUri');

    try {
      final response = await http
          .post(
            loginUri,
            headers: await _getAuthHeaders(),
            body: jsonEncode(<String, String>{
              'username': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('Login response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final body = jsonDecode(response.body);
          final token = body['access_token'] as String?;

          if (token != null && token.isNotEmpty) {
            await _storageService.saveToken(token);
            print('Login successful, token saved.');
            return token;
          } else {
            print('Login error: Token not found in response body.');
            throw Exception('Не удалось получить токен из ответа сервера.');
          }
        } catch (e) {
          print('Login error parsing response: $e');
          throw Exception('Ошибка обработки ответа сервера при входе.');
        }
      } else {
        throw _handleHttpError(response, 'Login');
      }
    } on SocketException catch (e) {
      print('Login network error: $e');
      throw Exception('Ошибка сети. Проверьте подключение к интернету.');
    } on http.ClientException catch (e) {
      print('Login client error: $e');
      throw Exception('Ошибка клиента при подключении к серверу.');
    } catch (e) {
      print('Login unexpected error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Неизвестная ошибка при входе: ${e.runtimeType}');
    }
  }

  Future<void> logout() async {
    try {
      await _storageService.deleteToken();
      print('Logged out, token deleted.');
    } catch (e) {
      print("Error during logout (token deletion): $e");
    }
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

    final Uri productsUri = Uri.parse(
      '$_baseUrl/products/local/',
    ).replace(queryParameters: queryParams);

    print('Fetching products from: $productsUri');

    try {
      final response = await http
          .get(
            productsUri,
            headers: await _getAuthHeaders(includeContentType: false),
          )
          .timeout(const Duration(seconds: 20));

      print('Get products response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));

          return PaginatedResponse.fromJson(body, Product.fromJson);
        } catch (e) {
          print('Get products error parsing response: $e');
          throw Exception(
            'Ошибка обработки ответа сервера при получении продуктов.',
          );
        }
      } else {
        throw _handleHttpError(response, 'Get products');
      }
    } on SocketException catch (e) {
      print('Get products network error: $e');
      throw Exception('Ошибка сети при получении продуктов.');
    } on http.ClientException catch (e) {
      print('Get products client error: $e');
      throw Exception('Ошибка клиента при получении продуктов.');
    } catch (e) {
      print('Get products unexpected error: $e');
      if (e is Exception) rethrow;
      throw Exception(
        'Неизвестная ошибка при получении продуктов: ${e.runtimeType}',
      );
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    if (barcode.isEmpty) return null;
    final Uri productUri = Uri.parse(
      '$_baseUrl/products/global/by-barcode/$barcode',
    );
    print('Fetching product by barcode: $productUri');

    try {
      final response = await http
          .get(
            productUri,
            headers: await _getAuthHeaders(includeContentType: false),
          )
          .timeout(const Duration(seconds: 10));

      print('Get product by barcode status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          return Product.fromJson(body);
        } catch (e) {
          print('Get product by barcode error parsing response: $e');
          throw Exception('Ошибка обработки ответа сервера.');
        }
      } else if (response.statusCode == 404) {
        print('Product with barcode $barcode not found.');
        return null;
      } else {
        throw _handleHttpError(response, 'Get product by barcode $barcode');
      }
    } on SocketException catch (e) {
      print('Get product by barcode network error: $e');
      throw Exception('Ошибка сети.');
    } on http.ClientException catch (e) {
      print('Get product by barcode client error: $e');
      throw Exception('Ошибка клиента.');
    } catch (e) {
      print('Get product by barcode unexpected error: $e');
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка: ${e.runtimeType}');
    }
  }

  Future<Product> addProduct(Product product) async {
    final Uri productsUri = Uri.parse('$_baseUrl/products/local/');
    print('Adding product to: $productsUri');

    try {
      final response = await http
          .post(
            productsUri,
            headers: await _getAuthHeaders(),
            body: jsonEncode(product.toJsonForCreate()),
          )
          .timeout(const Duration(seconds: 15));

      print('Add product response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          return Product.fromJson(body);
        } catch (e) {
          print('Add product error parsing response: $e');
          throw Exception(
            'Ошибка обработки ответа сервера после добавления продукта.',
          );
        }
      } else {
        throw _handleHttpError(response, 'Add product');
      }
    } on SocketException catch (e) {
      print('Add product network error: $e');
      throw Exception('Ошибка сети при добавлении продукта.');
    } on http.ClientException catch (e) {
      print('Add product client error: $e');
      throw Exception('Ошибка клиента при добавлении продукта.');
    } catch (e) {
      print('Add product unexpected error: $e');
      if (e is Exception) rethrow;
      throw Exception(
        'Неизвестная ошибка при добавлении продукта: ${e.runtimeType}',
      );
    }
  }

  Future<Product> updateProduct(int productId, Product product) async {
    final Uri productUri = Uri.parse('$_baseUrl/products/local/$productId');
    print('Updating product at: $productUri');

    try {
      final response = await http
          .put(
            productUri,
            headers: await _getAuthHeaders(),
            body: jsonEncode(product.toJsonForUpdate()),
          )
          .timeout(const Duration(seconds: 15));

      print('Update product response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          return Product.fromJson(body);
        } catch (e) {
          print('Update product error parsing response: $e');
          throw Exception(
            'Ошибка обработки ответа сервера после обновления продукта.',
          );
        }
      } else {
        throw _handleHttpError(response, 'Update product $productId');
      }
    } on SocketException catch (e) {
      print('Update product network error: $e');
      throw Exception('Ошибка сети при обновлении продукта.');
    } on http.ClientException catch (e) {
      print('Update product client error: $e');
      throw Exception('Ошибка клиента при обновлении продукта.');
    } catch (e) {
      print('Update product unexpected error: $e');
      if (e is Exception) rethrow;
      throw Exception(
        'Неизвестная ошибка при обновлении продукта: ${e.runtimeType}',
      );
    }
  }

  Future<void> deleteProduct(int productId) async {
    final Uri productUri = Uri.parse('$_baseUrl/products/local/$productId');
    print('Deleting product at: $productUri');

    try {
      final response = await http
          .delete(
            productUri,
            headers: await _getAuthHeaders(includeContentType: false),
          )
          .timeout(const Duration(seconds: 15));

      print('Delete product response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleHttpError(response, 'Delete product $productId');
      }
    } on SocketException catch (e) {
      print('Delete product network error: $e');
      throw Exception('Ошибка сети при удалении продукта.');
    } on http.ClientException catch (e) {
      print('Delete product client error: $e');
      throw Exception('Ошибка клиента при удалении продукта.');
    } catch (e) {
      print('Delete product unexpected error: $e');
      if (e is Exception) rethrow;
      throw Exception(
        'Неизвестная ошибка при удалении продукта: ${e.runtimeType}',
      );
    }
  }

  Future<String> createSale(
    List<CartItem> cartItems,
    double totalAmount,
    PaymentMethod paymentMethod,
  ) async {
    if (cartItems.isEmpty) {
      throw ArgumentError("Корзина не может быть пустой для создания продажи.");
    }

    final queryParams = <String, String>{
      'currency': 'KZT',
      'payment_method': paymentMethod.name,
      'sale_status': 'paid',
    };

    final Uri salesUri = Uri.parse(
      '$_baseUrl/sales/create',
    ).replace(queryParameters: queryParams);

    final List<Map<String, dynamic>> itemsBody =
        cartItems.map((item) {
          final double itemCostPrice = 0.0;
          return {
            'product_id': item.productId,
            'quantity': item.quantity,
            'price': item.priceAtSale,
            'cost_price': itemCostPrice, // <--- ДОБАВЛЕНО ПОЛЕ cost_price
            // 'total': item.itemTotal, // Если нужно
          };
        }).toList();
    print('Sale request body (items): ${jsonEncode(itemsBody)}');

    try {
      final response = await http
          .post(
            salesUri,
            headers: await _getAuthHeaders(),
            body: jsonEncode(itemsBody),
          )
          .timeout(const Duration(seconds: 25));

      print('Create sale response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          final orderId = body['order_id'] as String?;
          if (orderId != null && orderId.isNotEmpty) {
            print('Sale created successfully. Order ID: $orderId');
            return orderId;
          } else {
            print('Create sale error: order_id not found in response body.');
            throw Exception('Не удалось получить ID заказа из ответа сервера.');
          }
        } catch (e) {
          print('Create sale error parsing response: $e');
          throw Exception(
            'Ошибка обработки ответа сервера после создания продажи.',
          );
        }
      } else if (response.statusCode == 422) {
        print('Create sale failed with 422: ${response.body}');
        String detailMessage = 'Ошибка валидации данных при создании продажи.';
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));

          if (body['detail'] is List && body['detail'].isNotEmpty) {
            detailMessage = (body['detail'] as List)
                .map(
                  (err) =>
                      "Поле: ${err['loc']?.join('.') ?? 'N/A'}, Сообщение: ${err['msg'] ?? 'N/A'}",
                )
                .join('; ');
          } else if (body['detail'] != null) {
            detailMessage = body['detail'].toString();
          }
        } catch (_) {}
        throw Exception(detailMessage);
      } else {
        throw _handleHttpError(response, 'Create sale');
      }
    } on SocketException catch (e) {
      print('Create sale network error: $e');
      throw Exception('Ошибка сети при создании продажи.');
    } on http.ClientException catch (e) {
      print('Create sale client error: $e');
      throw Exception('Ошибка клиента при создании продажи.');
    } catch (e) {
      print('Create sale unexpected error: $e');
      if (e is Exception) rethrow;
      throw Exception(
        'Неизвестная ошибка при создании продажи: ${e.runtimeType}',
      );
    }
  }

  Future<PaginatedResponse<Sale>> getSalesHistory({
    int skip = 0,
    int limit = 20,
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      'sort_order': sortOrder,
    };

    final Uri salesUri = Uri.parse(
      '$_baseUrl/sales/',
    ).replace(queryParameters: queryParams);

    print('Fetching sales history from: $salesUri');

    try {
      final response = await http
          .get(
            salesUri,
            headers: await _getAuthHeaders(includeContentType: false),
          )
          .timeout(const Duration(seconds: 20));

      print('Get sales history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));

          return PaginatedResponse.fromJson(body, Sale.fromJson);
        } catch (e) {
          print('Get sales history error parsing response: $e');
          throw Exception(
            'Ошибка обработки ответа сервера при получении истории продаж.',
          );
        }
      } else {
        throw _handleHttpError(response, 'Get sales history');
      }
    } on SocketException catch (e) {
      print('Get sales history network error: $e');
      throw Exception('Ошибка сети при получении истории продаж.');
    } on http.ClientException catch (e) {
      print('Get sales history client error: $e');
      throw Exception('Ошибка клиента при получении истории продаж.');
    } catch (e) {
      print('Get sales history unexpected error: $e');
      if (e is Exception) rethrow;
      throw Exception(
        'Неизвестная ошибка при получении истории продаж: ${e.runtimeType}',
      );
    }
  }

  Future<List<SaleItem>> getSaleItems(String orderId) async {
    final Uri saleItemsUri = Uri.parse('$_baseUrl/sales/$orderId');
    print('Fetching sale items for order: $saleItemsUri');

    try {
      final response = await http
          .get(
            saleItemsUri,
            headers: await _getAuthHeaders(includeContentType: false),
          )
          .timeout(const Duration(seconds: 15));

      print('Get sale items response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body is Map &&
              body.containsKey('items') &&
              body['items'] is List) {
            List<dynamic> itemsList = body['items'];
            return itemsList
                .map((dynamic item) => SaleItem.fromJson(item))
                .toList();
          } else if (body is List) {
            return body.map((dynamic item) => SaleItem.fromJson(item)).toList();
          } else {
            throw Exception('Неожиданный формат ответа для деталей продажи.');
          }
        } catch (e) {
          print('Get sale items error parsing response: $e');
          throw Exception(
            'Ошибка обработки ответа сервера при получении деталей продажи.',
          );
        }
      } else {
        throw _handleHttpError(response, 'Get sale items for order $orderId');
      }
    } on SocketException catch (e) {
      print('Get sale items network error: $e');
      throw Exception('Ошибка сети при получении деталей продажи.');
    } on http.ClientException catch (e) {
      print('Get sale items client error: $e');
      throw Exception('Ошибка клиента при получении деталей продажи.');
    } catch (e) {
      print('Get sale items unexpected error: $e');
      if (e is Exception) rethrow;
      throw Exception(
        'Неизвестная ошибка при получении деталей продажи: ${e.runtimeType}',
      );
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
