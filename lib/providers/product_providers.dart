import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/providers/api_provider.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/services/api_service.dart';
import 'package:meta/meta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ProductListState {
  final List<Product> products;
  final bool isLoading;
  final bool hasReachedMax;
  final int currentPage;
  final String? currentQuery;
  final Object? error;

  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.currentQuery,
    this.error,
  });

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasReachedMax,
    int? currentPage,
    String? currentQuery,
    Object? error,
    bool clearError = false,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      currentQuery: currentQuery ?? this.currentQuery,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final productListProvider = StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  return ProductListNotifier(ref);
});

class ProductListNotifier extends StateNotifier<ProductListState> {
  final Ref _ref;
  final int _limit = 20;

  ProductListNotifier(this._ref) : super(const ProductListState()) {
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.status != AuthStatus.authenticated && next.status == AuthStatus.authenticated) {
        refresh();
      }
    });
    if (_ref.read(authProvider).status == AuthState.authenticated) {
      fetchProducts();
    }
  }

  Future<void> fetchProducts({bool isRefresh = false, String? query}) async {
    if (state.isLoading || (state.hasReachedMax && !isRefresh && query == state.currentQuery)) return;

    state = state.copyWith(isLoading: true, error: null, clearError: true);

    int pageToFetch = isRefresh || query != state.currentQuery ? 0 : state.currentPage;
    int skip = pageToFetch * _limit;
    String? fetchQuery = query ?? state.currentQuery;

    try {
      final apiService = _ref.read(apiServiceProvider);
      final paginatedResponse = await apiService.getProducts(skip: skip, limit: _limit, searchQuery: fetchQuery);

      final newProducts = paginatedResponse.content;
      final bool isLastPage = paginatedResponse.isLast;

      state = state.copyWith(
        products: (pageToFetch == 0) ? newProducts : [...state.products, ...newProducts],
        isLoading: false,
        hasReachedMax: isLastPage,
        currentPage: pageToFetch + 1,
        currentQuery: fetchQuery,
      );
    } catch (e, st) {
      print('Error fetching products page $pageToFetch: $e');

      if (e is UnauthorizedException) {
        _ref.read(authProvider.notifier).logout();
      }

      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> fetchNextPage() async {
    await fetchProducts();
  }

  Future<void> search(String query) async {
    await fetchProducts(isRefresh: true, query: query.isNotEmpty ? query : null);
  }

  Future<void> refresh() async {
    await fetchProducts(isRefresh: true, query: state.currentQuery);
  }

  void invalidateList() {
    refresh();
  }

  void reset() {
    state = const ProductListState();
  }
}

final productFormNotifierProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, AsyncValue<void>>((ref) {
  return ProductFormNotifier(ref);
});

class ProductFormNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ProductFormNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> addProduct(Product product) async {
    state = const AsyncValue.loading();
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.addProduct(product);

      await _ref.read(productListProvider.notifier).refresh();

      state = const AsyncValue.data(null);
      return true;
    } on UnauthorizedException catch (e, st) {
      print('Error adding product: Unauthorized $e');
      state = AsyncValue.error(e, st);
      _ref.read(authProvider.notifier).logout();
      return false;
    } catch (e, st) {
      print('Error adding product via API: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct(int productId, Product product) async {
    state = const AsyncValue.loading();
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateProduct(productId, product);

      await _ref.read(productListProvider.notifier).refresh();

      state = const AsyncValue.data(null);
      return true;
    } on UnauthorizedException catch (e, st) {
      print('Error updating product: Unauthorized $e');
      state = AsyncValue.error(e, st);
      _ref.read(authProvider.notifier).logout();
      return false;
    } catch (e, st) {
      print('Error updating product via API: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    state = const AsyncValue.loading();
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.deleteProduct(productId);

      await _ref.read(productListProvider.notifier).refresh();

      state = const AsyncValue.data(null);
      return true;
    } on UnauthorizedException catch (e, st) {
      print('Error deleting product: Unauthorized $e');
      state = AsyncValue.error(e, st);
      _ref.read(authProvider.notifier).logout();
      return false;
    } catch (e, st) {
      print('Error deleting product via API: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final productByBarcodeProvider = FutureProvider.autoDispose.family<Product?, String>((ref, barcode) async {
  if (barcode.isEmpty) {
    return null;
  }

  final apiService = ref.watch(apiServiceProvider);
  try {
    final product = await apiService.getProductByBarcode(barcode);
    return product;
  } on UnauthorizedException {
    ref.read(authProvider.notifier).logout();

    return null;
  } catch (e) {
    print("Error fetching product by barcode $barcode: $e");
    return null;
  }
});
