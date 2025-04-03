class ApiConstants {
  ApiConstants._();

  // ЗАМЕНИТЕ НА ВАШ РЕАЛЬНЫЙ URL
  static const String baseUrl = "https://pos-api.metalogic.kz";

  // Эндпоинты (примеры)
  static const String loginEndpoint = "/auth/token";
  static const String productsEndpoint = "/products/local/"; // С пагинацией
  static const String productByBarcodeEndpoint = "/products/global/by-barcode/"; // Добавить {barcode}
  static const String productByIdEndpoint = "/products/local/{id}"; // Добавить {id}
  static const String salesEndpoint = "/sales/";
  static const String salesCreateEndpoint = "/sales/create"; // Как в вашем примере curl
  static const String saleItemsEndpoint = "/sales/{orderId}"; // Уточнить эндпоинт деталей
}
