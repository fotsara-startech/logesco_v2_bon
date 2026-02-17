import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class AuthService extends GetxService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final Rx<String?> _token = Rx<String?>(null);

  String? get token => _token.value;
  bool get isAuthenticated => _token.value != null;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadToken();
  }

  Future<void> _loadToken() async {
    _token.value = await _secureStorage.read(key: AppConstants.authTokenKey);
  }

  Future<String?> getToken() async {
    if (_token.value == null) {
      await _loadToken();
    }

    // Si aucun token n'est disponible, retourner null pour forcer l'authentification
    return _token.value;
  }

  Future<void> setToken(String token) async {
    _token.value = token;
    await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
  }

  Future<void> setRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> clearTokens() async {
    _token.value = null;
    await _secureStorage.delete(key: AppConstants.authTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<void> logout() async {
    await clearTokens();
    Get.offAllNamed('/login');
  }

  /// Teste la connexion à l'API
  Future<bool> testConnection() async {
    try {
      // Importer ApiClient ici pour éviter les dépendances circulaires
      final apiClient = Get.find<dynamic>(); // On utilisera l'ApiClient via Get.find

      // Pour l'instant, on considère que la connexion est OK si on arrive ici
      // Dans une vraie implémentation, on ferait un appel API simple comme /health
      return true;
    } catch (e) {
      print('❌ [AuthService] Erreur test connexion: $e');
      return false;
    }
  }
}
