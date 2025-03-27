class CartItem {
  final int productId; // ID товара из базы данных
  final String sku; // Артикул для быстрой идентификации
  final String name; // Название товара (для отображения)
  final double priceAtSale; // Цена *на момент добавления* в корзину
  int quantity; // Количество этого товара в корзине (изменяемое)

  CartItem({
    required this.productId,
    required this.sku,
    required this.name,
    required this.priceAtSale,
    required this.quantity,
  });

  // Метод для удобного увеличения количества
  void increment() {
    quantity++;
  }

  // Метод для уменьшения количества
  // Возвращает true, если количество стало 0 или меньше
  bool decrement() {
    quantity--;
    return quantity <= 0;
  }

  // Вычисляемое свойство для общей стоимости этой позиции
  double get itemTotal => priceAtSale * quantity;

  // (Опционально) Можно добавить методы для сравнения, копирования и т.д., если потребуется
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CartItem && runtimeType == other.runtimeType && sku == other.sku; // Считаем элементы одинаковыми, если у них один SKU

  @override
  int get hashCode => sku.hashCode;

  // Метод для создания копии с возможностью изменения количества
  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      sku: sku,
      name: name,
      priceAtSale: priceAtSale,
      quantity: quantity ?? this.quantity,
    );
  }
}
