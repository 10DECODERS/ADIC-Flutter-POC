import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyService {
  static const String _apiKeyKey = 'openai_api_key';
  final _secureStorage = const FlutterSecureStorage();

  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }

  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }

  Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
} 