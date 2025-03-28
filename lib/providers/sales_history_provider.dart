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

  SalesHistoryNotifier(this._ref) : super(const SalesHistoryState()) {
    fetchSales();
  }

  Future<void> fetchSales({bool isRefresh = false}) async {
    if (state.isLoading || (state.hasReachedMax && !isRefresh)) return;

    state = state.copyWith(isLoading: true, error: null, clearError: true);

    int pageToFetch = isRefresh ? 0 : state.currentPage;
    int skip = pageToFetch * _limit;

    try {
      final apiService = _ref.read(apiServiceProvider);

      final paginatedResponse = await apiService.getSalesHistory(skip: skip, limit: _limit, sortOrder: 'desc');

      final newSales = paginatedResponse.content;

      final bool reachedMax = paginatedResponse.isLast;

      state = state.copyWith(
        sales: (pageToFetch == 0) ? newSales : [...state.sales, ...newSales],
        isLoading: false,
        hasReachedMax: reachedMax,

        currentPage: reachedMax ? state.currentPage : pageToFetch + 1,
      );
    } on UnauthorizedException catch (e, st) {
      print('Error fetching sales history: Unauthorized $e');
      state = state.copyWith(isLoading: false, error: e);
      _ref.read(authProvider.notifier).logout();
    } catch (e, st) {
      print('Error fetching sales history page $pageToFetch: $e');
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> fetchNextPage() async {
    await fetchSales();
  }

  Future<void> refresh() async {
    await fetchSales(isRefresh: true);
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
