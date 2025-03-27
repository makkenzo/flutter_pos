enum PaymentMethod {
  cash('Наличные'),
  card('Карта'),
  other('Другое');

  const PaymentMethod(this.displayTitle);
  final String displayTitle;
}
