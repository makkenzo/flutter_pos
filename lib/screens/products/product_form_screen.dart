import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pos/database/database.dart';
import 'package:flutter_pos/providers/product_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product; // Принимаем существующий товар для редактирования

  // Если product == null, это режим добавления
  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>(); // Ключ для валидации формы

  // Контроллеры для полей ввода
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _descriptionController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _quantityController;

  bool get _isEditing => widget.product != null; // Проверяем, режим редактирования или добавления

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры значениями существующего товара или пустыми строками
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _purchasePriceController = TextEditingController(text: widget.product?.purchasePrice?.toString() ?? '');
    _sellingPriceController = TextEditingController(text: widget.product?.sellingPrice.toString() ?? '');
    _quantityController = TextEditingController(text: widget.product?.quantity.toString() ?? '');
  }

  @override
  void dispose() {
    // Освобождаем ресурсы контроллеров
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Функция сохранения (вызывается при нажатии кнопки)
  Future<void> _saveForm() async {
    // Проверяем валидность формы
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Сохраняем значения полей

      final name = _nameController.text;
      final sku = _skuController.text;
      final description = _descriptionController.text.isEmpty ? null : _descriptionController.text;
      final purchasePrice = double.tryParse(_purchasePriceController.text); // Безопасное преобразование в double
      final sellingPrice = double.parse(_sellingPriceController.text); // Здесь уверены, т.к. валидатор прошел
      final quantity = int.parse(_quantityController.text); // Здесь уверены

      bool success;
      if (_isEditing) {
        // Режим редактирования - вызываем updateProduct
        success = await ref
            .read(productFormNotifierProvider.notifier)
            .updateProduct(
              widget.product!, // Передаем существующий товар
              name: name,
              sku: sku,
              description: description,
              purchasePrice: purchasePrice,
              sellingPrice: sellingPrice,
              quantity: quantity,
            );
      } else {
        // Режим добавления - вызываем addProduct
        success = await ref
            .read(productFormNotifierProvider.notifier)
            .addProduct(
              name: name,
              sku: sku,
              description: description,
              purchasePrice: purchasePrice,
              sellingPrice: sellingPrice,
              quantity: quantity,
            );
      }

      // Показываем сообщение и закрываем экран при успехе
      if (success && mounted) {
        // Проверка mounted важна после async вызова
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Товар обновлен' : 'Товар добавлен'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Возвращаемся на предыдущий экран
      }
      // Ошибки обрабатываются внутри Notifier и могут быть показаны через ref.watch(productFormNotifierProvider)
    } else {
      // Форма невалидна, показываем сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, исправьте ошибки в форме'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем состояние Notifier для отображения индикатора загрузки или ошибок
    ref.listen<AsyncValue<void>>(productFormNotifierProvider, (_, state) {
      if (state is AsyncError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: ${state.error}'), backgroundColor: Colors.red));
      }
    });
    final formState = ref.watch(productFormNotifierProvider); // Получаем текущее состояние (для индикатора загрузки)

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать товар' : 'Добавить товар'),
        actions: [
          // Кнопка сохранения
          IconButton(
            icon:
                formState.isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            onPressed: formState.isLoading ? null : _saveForm, // Блокируем кнопку во время загрузки
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Используем ListView для прокрутки на маленьких экранах
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название товара *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Название не может быть пустым';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'Артикул (SKU) / Штрих-код *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Артикул не может быть пустым';
                  }
                  // TODO: Добавить проверку уникальности SKU при добавлении/редактировании (требует запроса к БД)
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(labelText: 'Цена продажи *', prefixText: '₸ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ), // Разрешает цифры и точку (макс 2 знака после)
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Цена продажи обязательна';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Введите корректную положительную цену';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Количество на складе *'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Только целые числа
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Количество обязательно';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Введите корректное неотрицательное количество';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание (необязательно)'),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(labelText: 'Цена закупки (необязательно)', prefixText: '₸ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (value) {
                  // Необязательно, но если введено, должно быть корректным числом >= 0
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'Введите корректную неотрицательную цену или оставьте поле пустым';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: formState.isLoading ? null : _saveForm,
                child: Text(formState.isLoading ? 'Сохранение...' : 'Сохранить товар'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
