import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pos/models/product.dart';
import 'package:flutter_pos/providers/product_providers.dart';
import 'package:flutter_pos/utils/constants/sizes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _skuNameController;
  late TextEditingController _skuCodeController;
  late TextEditingController _barcodeController;
  late TextEditingController _unitController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  late TextEditingController _costPriceController;
  late TextEditingController _status1cController;
  late TextEditingController _departmentController;
  late TextEditingController _groupNameController;
  late TextEditingController _subgroupController;
  late TextEditingController _supplierController;

  bool get _isEditing => widget.product != null;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    final p = widget.product;

    _skuNameController = TextEditingController(text: p?.skuName ?? '');
    _skuCodeController = TextEditingController(text: p?.skuCode ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _unitController = TextEditingController(text: p?.unit ?? 'шт');
    _priceController = TextEditingController(text: p?.price.toString() ?? '');
    _quantityController = TextEditingController(text: p?.quantity.toString() ?? '0');

    _costPriceController = TextEditingController(text: p?.costPrice.toString() ?? '');
    _status1cController = TextEditingController(text: p?.status1c ?? '');
    _departmentController = TextEditingController(text: p?.department ?? '');
    _groupNameController = TextEditingController(text: p?.groupName ?? '');
    _subgroupController = TextEditingController(text: p?.subgroup ?? '');
    _supplierController = TextEditingController(text: p?.supplier ?? '');
  }

  @override
  void dispose() {
    _skuNameController.dispose();
    _skuCodeController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _status1cController.dispose();
    _departmentController.dispose();
    _groupNameController.dispose();
    _subgroupController.dispose();
    _supplierController.dispose();

    super.dispose();
  }

  Future<void> _saveForm() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, исправьте ошибки в форме'), backgroundColor: Colors.orange),
      );
      return;
    }

    final skuName = _skuNameController.text.trim();
    final skuCode = _skuCodeController.text.trim();
    final barcode = _barcodeController.text.trim();
    final unit = _unitController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final quantity = int.parse(_quantityController.text.trim());

    final costPrice = double.tryParse(_costPriceController.text.trim());
    final status1c = _status1cController.text.trim();
    final department = _departmentController.text.trim();
    final groupName = _groupNameController.text.trim();
    final subgroup = _subgroupController.text.trim();
    final supplier = _supplierController.text.trim();

    final now = DateTime.now();
    final productData = Product(
      id: widget.product?.id ?? 0,
      skuName: skuName,
      skuCode: skuCode,
      barcode: barcode,
      unit: unit,
      price: price,
      quantity: quantity,
      costPrice: costPrice ?? 0.0,
      status1c: status1c,
      department: department,
      groupName: groupName,
      subgroup: subgroup,
      supplier: supplier,
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: widget.product?.updatedAt ?? now,
    );

    Product? resultProduct;

    if (_isEditing) {
      resultProduct = await ref
          .read(productFormNotifierProvider.notifier)
          .updateProduct(widget.product!.id, productData);
    } else {
      resultProduct = await ref.read(productFormNotifierProvider.notifier).addProduct(productData);
    }

    if (context.mounted) {
      if (resultProduct != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Товар успешно обновлен' : 'Товар успешно добавлен'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(resultProduct);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(productFormNotifierProvider, (previous, next) {
      if (!next.isLoading && next.hasError) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${next.error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    final theme = Theme.of(context);

    final formAsyncState = ref.watch(productFormNotifierProvider);
    final isLoading = formAsyncState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать товар' : 'Добавить товар'),
        actions: [
          if (_isEditing)
            IconButton(
              icon:
                  _isDeleting
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                      : const Icon(Icons.delete_outline),
              tooltip: 'Удалить товар',
              onPressed: isLoading ? null : _confirmAndDelete,
            ),
          IconButton(
            icon:
                isLoading && !_isDeleting
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                    : const Icon(Icons.save),
            tooltip: 'Сохранить',
            onPressed: isLoading ? null : _saveForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              Text('Основные данные', style: theme.textTheme.titleLarge),

              const SizedBox(height: TSizes.spaceBtwItems / 2),

              _buildTextField(
                controller: _skuNameController,
                labelText: 'Название товара *',
                icon: Icons.label_outline,
                validator: _validateNotEmpty,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),

              _buildTextField(
                controller: _barcodeController,
                labelText: 'Штрих-код *',
                icon: Icons.barcode_reader,
                validator: _validateNotEmpty,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),
              _buildTextField(
                controller: _unitController,
                labelText: 'Ед. изм. *',
                icon: Icons.square_foot_outlined,
                validator: _validateNotEmpty,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              Text('Цена и Количество', style: theme.textTheme.titleLarge),

              const SizedBox(height: TSizes.spaceBtwItems / 2),

              _buildTextField(
                controller: _priceController,
                labelText: 'Цена продажи *',
                icon: Icons.sell_outlined,
                prefixText: '₸ ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: _validatePositiveNumber,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),
              _buildTextField(
                controller: _costPriceController,
                labelText: 'Себестоимость *',
                icon: Icons.price_change_outlined,
                prefixText: '₸ ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: _validatePositiveNumber,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),
              _buildTextField(
                controller: _quantityController,
                labelText: 'Количество на складе *',
                icon: Icons.numbers_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateNonNegativeInteger,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),
              Padding(
                padding: const EdgeInsets.only(top: TSizes.xs, left: TSizes.sm, right: TSizes.sm),
                child: Text(
                  'Изменение этого значения обновит текущий остаток товара на складе.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              Text('Дополнительная информация (необязательно)', style: Theme.of(context).textTheme.titleLarge),

              const SizedBox(height: TSizes.spaceBtwItems / 2),

              _buildTextField(
                controller: _skuCodeController,
                labelText: 'SKU',
                icon: Icons.inventory_2_outlined,
                validator: _validateNotEmpty,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
              ),

              _buildTextField(
                controller: _supplierController,
                labelText: 'Поставщик',
                icon: Icons.local_shipping_outlined,
                enabled: !isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => isLoading ? null : _saveForm(),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.disabled)) {
                      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);
                    }
                    return null;
                  }),
                ),
                icon:
                    isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                        : const Icon(Icons.save, size: 22),
                label: Text(isLoading ? 'СОХРАНЕНИЕ...' : 'СОХРАНИТЬ'),
                onPressed: isLoading ? null : _saveForm,
              ),
              const SizedBox(height: TSizes.defaultSpace),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final productToDelete = widget.product;
    if (productToDelete == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Подтвердить удаление'),
          content: Text(
            'Вы уверены, что хотите удалить товар "${productToDelete.skuName}"?\nЭто действие нельзя будет отменить.',
          ),
          actions: <Widget>[
            TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(ctx).pop(false)),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Удалить'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isDeleting = true;
      });

      bool success = false;

      try {
        success = await ref.read(productFormNotifierProvider.notifier).deleteProduct(productToDelete.id);
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }

      if (success && mounted) {
        Navigator.of(context).pop(); // Закрываем при успехе
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLines = 1,
    bool enabled = true,
    // --- НОВЫЕ ПАРАМЕТРЫ ---
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted, // Функция для вызова при нажатии "Готово"/"Enter"
    // ----------------------
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.sm / 2), // Уменьшим вертикальный отступ
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: icon != null ? Icon(icon, size: TSizes.iconSm) : null, // Используем константу
          prefixText: prefixText,
          // border: const OutlineInputBorder(), // Убрали, т.к. тема задает Underline
          // isDense: true, // Тема уже задает isDense и contentPadding
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        enabled: enabled,
        style: TextStyle(color: enabled ? null : Theme.of(context).disabledColor), // Используем цвет из темы
        // --- ИСПОЛЬЗОВАНИЕ НОВЫХ ПАРАМЕТРОВ ---
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        // -------------------------------------
      ),
    );
  }

  String? _validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Это поле не может быть пустым';
    }
    return null;
  }

  String? _validatePositiveNumber(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Поле не может быть пустым';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Введите корректное число';
    }
    if (number <= 0) {
      return 'Число должно быть положительным';
    }
    return null;
  }

  String? _validateNonNegativeInteger(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Поле не может быть пустым';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Введите целое число';
    }
    if (number < 0) {
      return 'Число не может быть отрицательным';
    }
    return null;
  }
}
