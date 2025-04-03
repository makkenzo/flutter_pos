import 'dart:io';

import 'package:flutter_pos/services/api_service.dart';

String formatErrorMessage(Object? error) {
  if (error == null) return 'Произошла неизвестная ошибка.';

  if (error is UnauthorizedException) {
    return 'Сессия истекла или недействительна. Пожалуйста, войдите снова.';
  }
  if (error is HttpException) {
    String message = error.message;

    return message;
  }

  if (error is SocketException) {
    return 'Ошибка сети. Проверьте подключение к интернету.';
  }

  String defaultMessage = error.toString();
  if (defaultMessage.startsWith("Exception:")) {
    defaultMessage = defaultMessage.substring(10).trim();
  }

  if (defaultMessage.length > 150) {
    defaultMessage = '${defaultMessage.substring(0, 147)}...';
  }
  return defaultMessage;
}
