import 'package:flutter/material.dart';
import 'package:flutter_pos/models/analytics/sales_analytics.dart';
import 'package:flutter_pos/providers/api_provider.dart';
import 'package:flutter_pos/providers/auth_provider.dart';
import 'package:flutter_pos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AnalyticsState {
  /// Данные аналитики (или начальное пустое состояние)
  final AsyncValue<SalesAnalytics> analyticsData;

  /// Выбранный диапазон дат (может быть null)
  final DateTimeRange? selectedDateRange;

  const AnalyticsState({required this.analyticsData, this.selectedDateRange});

  // Начальное состояние
  AnalyticsState.initial() : this(analyticsData: AsyncValue.data(SalesAnalytics.empty()));

  AnalyticsState copyWith({
    AsyncValue<SalesAnalytics>? analyticsData,
    DateTimeRange? selectedDateRange,
    bool clearDateRange = false, // Флаг для сброса диапазона
  }) {
    return AnalyticsState(
      analyticsData: analyticsData ?? this.analyticsData,
      selectedDateRange: clearDateRange ? null : selectedDateRange ?? this.selectedDateRange,
    );
  }
}

// Провайдер для AnalyticsNotifier
final analyticsProvider = StateNotifierProvider.autoDispose<AnalyticsNotifier, AnalyticsState>((ref) {
  // Используем .autoDispose, т.к. данные обычно нужны только пока экран открыт
  // Если хотите кэшировать дольше, уберите .autoDispose
  return AnalyticsNotifier(ref);
});

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;

  AnalyticsNotifier(this._ref) : super(AnalyticsState.initial()) {
    // Загружаем данные за весь период при инициализации
    _fetchAnalytics();
  }

  /// Загружает данные аналитики для текущего выбранного периода дат
  Future<void> _fetchAnalytics() async {
    // Устанавливаем состояние загрузки, сохраняя старые данные, если они есть
    state = state.copyWith(analyticsData: AsyncValue.loading());

    try {
      final apiService = _ref.read(apiServiceProvider);
      final data = await apiService.getSalesAnalytics(
        startDate: state.selectedDateRange?.start,
        endDate: state.selectedDateRange?.end,
      );
      // Успех: обновляем данные
      state = state.copyWith(analyticsData: AsyncValue.data(data));
    } on UnauthorizedException catch (e, st) {
      state = state.copyWith(analyticsData: AsyncValue.error(e, st));
      _ref.read(authProvider.notifier).logout(); // Выход
    } catch (e, st) {
      state = state.copyWith(analyticsData: AsyncValue.error(e, st));
    }
  }

  /// Устанавливает новый диапазон дат и перезагружает данные
  Future<void> setDateRange(DateTimeRange? newRange) async {
    // Обновляем состояние с новым диапазоном (или сбрасываем его)
    state = state.copyWith(selectedDateRange: newRange, clearDateRange: newRange == null);
    // Перезагружаем данные для нового диапазона
    await _fetchAnalytics();
  }

  /// Перезагружает данные для текущего диапазона (pull-to-refresh)
  Future<void> refresh() async {
    await _fetchAnalytics();
  }
}
