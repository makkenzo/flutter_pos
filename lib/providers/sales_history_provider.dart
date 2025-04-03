import 'package:flutter_pos/models/sale.dart';
import 'package:flutter_pos/models/sale_item.dart';
import 'package:flutter_pos/providers/api_provider.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

@immutable
class SalesHistoryState {
  final List<Sale> sales;
  final bool isLoading;
  final bool hasReachedMax;
  final int currentPage;
  final Object? error;

  const SalesHistoryState({
    this.sales = const [],
    this.isLoading = false,
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.error,
  });

  SalesHistoryState copyWith({
    List<Sale>? sales,
    bool? isLoading,
    bool? hasReachedMax,
    int? currentPage,
    Object? error,
    bool clearError = false,
  }) {
    return SalesHistoryState(
      sales: sales ?? this.sales,
      isLoading: isLoading ?? this.isLoading,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final salesHistoryProvider = StateNotifierProvider<SalesHistoryNotifier, SalesHistoryState>((ref) {
  return SalesHistoryNotifier(ref);
});

class SalesHistoryNotifier extends StateNotifier<SalesHistoryState> {
  final Ref _ref;
  final int _limit = 30;
  bool _isFetching = false;

  SalesHistoryNotifier(this._ref) : super(const SalesHistoryState()) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != AuthStatus.authenticated && next.status == AuthStatus.authenticated) {
        refresh();
      }
    });

    if (_ref.read(authProvider).status == AuthStatus.authenticated) {
      fetchSales();
    }
  }

  Future<void> fetchSales({bool isRefresh = false}) async {
    if (_isFetching || (state.hasReachedMax && !isRefresh)) return;

    final bool isNewSearchOrRefresh = isRefresh;

    if (state.hasReachedMax && !isNewSearchOrRefresh) return;

    _isFetching = true;
    state = state.copyWith(
      isLoading: true,
      error: null,
      clearError: true,
      hasReachedMax: isNewSearchOrRefresh ? false : state.hasReachedMax,
      currentPage: isNewSearchOrRefresh ? 0 : state.currentPage,
    );

    int pageToFetch = state.currentPage;
    int skip = pageToFetch * _limit;

    try {
      final apiService = _ref.read(apiServiceProvider);
      final paginatedResponse = await apiService.getSalesHistory(skip: skip, limit: _limit, sortOrder: 'desc');

      if (!mounted) {
        _isFetching = false;
        return;
      }

      final newSales = paginatedResponse.content;
      final bool reachedMax = paginatedResponse.isLast;

      state = state.copyWith(
        sales: (pageToFetch == 0) ? newSales : [...state.sales, ...newSales],
        isLoading: false,
        hasReachedMax: reachedMax,
        currentPage: reachedMax ? state.currentPage : pageToFetch + 1,
      );
    } on UnauthorizedException catch (e) {
      if (!mounted) {
        _isFetching = false;
        return;
      }

      state = state.copyWith(isLoading: false, error: e, hasReachedMax: true);
      _ref.read(authProvider.notifier).logout();
    } catch (e) {
      if (!mounted) {
        _isFetching = false;
        return;
      }

      state = state.copyWith(isLoading: false, error: e);
    } finally {
      if (mounted) {
        _isFetching = false;
      }
    }
  }

  Future<void> fetchNextPage() async {
    await fetchSales();
  }

  Future<void> refresh() async {
    await fetchSales(isRefresh: true);
  }

  void reset() {
    state = const SalesHistoryState();
  }
}

final saleDetailsProvider = FutureProvider.family<List<SaleItem>, String>((ref, orderId) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    return await apiService.getSaleItems(orderId);
  } on UnauthorizedException {
    ref.read(authProvider.notifier).logout();

    rethrow;
  } catch (e) {
    rethrow;
  }
});
