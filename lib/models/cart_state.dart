import 'package:flutter_pos/models/cart_item.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class CartState {
  final List<CartItem> items;

  // Приватный конструктор
  const CartState._(this.items);

  // Начальное состояние - пустая корзина
  factory CartState.initial() => const CartState._([]);

  // Геттер для получения общей суммы корзины
  double get totalPrice {
    // Используем fold для суммирования itemTotal каждого элемента
    return items.fold(0.0, (sum, item) => sum + item.itemTotal);
    // Или так: items.map((item) => item.itemTotal).sum; (нужен import 'package:collection/collection.dart';)
  }

  // Геттер для общего количества товаров в корзине (не уникальных позиций)
  int get totalItemsCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Метод для получения элемента по SKU (или null, если не найден)
  CartItem? findItemBySku(String sku) {
    // Используем firstWhereOrNull из пакета collection
    return items.firstWhereOrNull((item) => item.sku == sku);
  }

  // Метод для создания нового состояния с добавленным/обновленным товаром
  CartState updateItem(CartItem itemToUpdate) {
    final index = items.indexWhere((item) => item.sku == itemToUpdate.sku);
    final newItems = List<CartItem>.from(items); // Создаем копию списка
    if (index != -1) {
      // Товар уже есть, обновляем его (создаем новый экземпляр CartItem)
      newItems[index] = itemToUpdate.copyWith(); // Используем copyWith
    } else {
      // Новый товар, добавляем
      newItems.add(itemToUpdate.copyWith()); // Добавляем копию
    }
    return CartState._(newItems);
  }

  // Метод для создания нового состояния с удаленным товаром
  CartState removeItem(String sku) {
    final newItems = items.where((item) => item.sku != sku).toList();
    return CartState._(newItems);
  }

  // Метод для создания нового состояния (пустая корзина)
  CartState clear() {
    return CartState.initial();
  }
}
