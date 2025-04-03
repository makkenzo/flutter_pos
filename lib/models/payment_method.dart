enum PaymentMethod {
  cash('Наличные'),
  card('Карта'),
  other('Другое');

  const PaymentMethod(this.displayTitle);
  final String displayTitle;
}

extension PaymentMethodExtension on PaymentMethod {
  String get currencySymbol {
    // Пример - замените на вашу логику получения символа валюты
    // return NumberFormat.simpleCurrency(locale: 'ru_RU').currencySymbol;
    return '₸';
  }
}
