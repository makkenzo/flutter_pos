import 'package:flutter_pos/utils/constants/storage_keys.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: StorageKeys.authToken, value: token);
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: StorageKeys.authToken);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: StorageKeys.authToken);
  }
}
