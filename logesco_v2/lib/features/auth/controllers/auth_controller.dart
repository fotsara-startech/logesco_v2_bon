import 'dart:developer';

import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logesco_v2/core/config/environment_config.dart';
import 'package:logesco_v2/core/routes/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/exceptions.dart';
import '../../../core/config/app_config.dart';
import '../models/user.dart';
import '../../users/models/role_model.dart' as role_model;

/// Contrôleur d'authentification avec GetX
class AuthController extends GetxController {
  final ApiClient _apiClient = Get.put(ApiClient());
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // État observable
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isAuthenticated = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  @override
  void onReady() {
    super.onReady();
    // En mode développement avec bypass auth, créer un utilisateur fictif
    if (AppConfig.isDevelopmentMode && AppConfig.bypassAuth) {
      _createMockUser();
    }
  }

  /// Vérifie le statut d'authentification au démarrage
  Future<void> _checkAuthStatus() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.authTokenKey);
      if (token != null) {
        _apiClient.setAuthToken(token);

        // Configurer aussi l'ApiService pour les autres modules
        try {
          final apiService = Get.find<ApiService>();
          apiService.setAuthToken(token);
        } catch (e) {
          print('⚠️ ApiService non trouvé lors de la vérification: $e');
        }

        await _loadUserProfile();
      }
    } catch (e) {
      // Erreur lors de la vérification, nettoyer les données
      await _clearAuthData();
    }
  }

  /// Vérifie si l'utilisateur est authentifié (avec vérification du token)
  Future<bool> checkAuthentication() async {
    try {
      print('🔐 Vérification de l\'authentification...');
      final token = await _secureStorage.read(key: AppConstants.authTokenKey);
      if (token == null) {
        print('❌ Aucun token trouvé');

        // En mode développement, essayer de se connecter automatiquement
        if (AppConfig.isDevelopmentMode) {
          print('🔧 Mode développement - tentative de connexion automatique...');
          final autoLoginSuccess = await _attemptAutoLogin();
          if (autoLoginSuccess) {
            return true;
          }
        }

        return false;
      }

      print('✅ Token trouvé: ${token.substring(0, 20)}...');

      // Configurer le token dans l'API client
      _apiClient.setAuthToken(token);

      // Configurer aussi l'ApiService pour les autres modules
      try {
        final apiService = Get.find<ApiService>();
        apiService.setAuthToken(token);
      } catch (e) {
        print('⚠️ ApiService non trouvé lors de la vérification: $e');
      }

      // Tenter de charger le profil utilisateur pour vérifier la validité du token
      await _loadUserProfile();

      final isValid = isAuthenticated.value && currentUser.value != null;
      print('🎯 Résultat de l\'authentification: $isValid');
      return isValid;
    } catch (e) {
      print('❌ Erreur lors de la vérification de l\'authentification: $e');
      // Token invalide ou erreur réseau, nettoyer les données
      await _clearAuthData();

      // En mode développement, essayer de se connecter automatiquement
      if (AppConfig.isDevelopmentMode) {
        print('🔧 Mode développement - tentative de connexion automatique après erreur...');
        final autoLoginSuccess = await _attemptAutoLogin();
        if (autoLoginSuccess) {
          return true;
        }
      }

      return false;
    }
  }

  /// Connexion utilisateur
  Future<bool> login(String username, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('=== TENTATIVE DE CONNEXION ===');
      print('Nom d\'utilisateur: "$username"');
      print('Mot de passe: "${password.replaceAll(RegExp(r'.'), '*')}"');
      print('URL: ${EnvironmentConfig.apiBaseUrl}/auth/login');
      print('==============================');

      final response = await _apiClient.post('/auth/login', {
        'nomUtilisateur': username,
        'motDePasse': password,
      });

      print('=== RÉPONSE CONNEXION ===');
      print("Success: ${response.isSuccess}");
      print("Data: ${response.data}");
      print('========================');

      if (response.isSuccess) {
        final data = response.data['data'] as Map<String, dynamic>;
        final token = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String?;
        final userData = data['utilisateur'] as Map<String, dynamic>;

        // Sauvegarder les tokens
        await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
        if (refreshToken != null) {
          await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
        }

        // Configurer le client API
        _apiClient.setAuthToken(token);

        // Configurer aussi l'ApiService pour les autres modules
        try {
          final apiService = Get.find<ApiService>();
          apiService.setAuthToken(token);
        } catch (e) {
          print('⚠️ ApiService non trouvé: $e');
        }

        log("token: $token");
        log("refreshToken: $refreshToken");
        log("userData: $userData");

        // Mettre à jour l'état
        try {
          currentUser.value = User.fromJson(userData);
          isAuthenticated.value = true;
          log("✅ Utilisateur créé: ${currentUser.value}");

          // Note: AuthorizationService délègue maintenant au PermissionService
          // La synchronisation se fait automatiquement via les observables
        } catch (e) {
          log("❌ Erreur création utilisateur: $e");
          throw Exception("Erreur lors de la création de l'utilisateur: $e");
        }

        try {
          await Get.offAllNamed(AppRoutes.dashboard);
          print('✅ Navigation réussie');
          Get.snackbar('Succès', 'Connexion réussie');
        } catch (e) {
          print('❌ Erreur de navigation: $e');
          Get.snackbar('Erreur', 'Impossible de charger le tableau de bord');
        }

        return true;
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      Get.snackbar('Erreur de connexion', e.message);
    } catch (e) {
      errorMessage.value = 'Erreur inattendue lors de la connexion';
      Get.snackbar('Erreur', 'Erreur inattendue lors de la connexion');
    } finally {
      isLoading.value = false;
    }

    return false;
  }

  /// Déconnexion utilisateur
  Future<void> logout() async {
    try {
      print('🚪 [AuthController] Début de la déconnexion...');

      // Appeler l'API de déconnexion
      await _apiClient.post('/auth/logout', {});
      print('✅ [AuthController] API de déconnexion appelée');
    } catch (e) {
      // Erreur silencieuse lors de la déconnexion API
      print('⚠️ [AuthController] Erreur API déconnexion (ignorée): $e');
    } finally {
      // Nettoyer l'état local dans tous les cas
      print('🧹 [AuthController] Nettoyage des données d\'authentification...');
      await _clearAuthData();

      // Rediriger vers la page de connexion
      print('🔄 [AuthController] Redirection vers la page de connexion...');
      Get.offAllNamed(AppRoutes.login);
      print('✅ [AuthController] Déconnexion terminée');
    }
  }

  /// Rafraîchir le token d'authentification
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _apiClient.post('/auth/refresh', {
        'refreshToken': refreshToken,
      });

      if (response.isSuccess) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['token'] as String;

        await _secureStorage.write(key: AppConstants.authTokenKey, value: newToken);
        _apiClient.setAuthToken(newToken);

        return true;
      }
    } catch (e) {
      // Erreur silencieuse lors du rafraîchissement du token
    }

    return false;
  }

  /// Charger le profil utilisateur
  Future<void> _loadUserProfile() async {
    try {
      print('🔍 Chargement du profil utilisateur...');
      final response = await _apiClient.get('/auth/me');
      print('📡 Réponse /auth/me: success=${response.isSuccess}');

      if (response.isSuccess) {
        final userData = response.data['data'] as Map<String, dynamic>;
        print('👤 Données utilisateur reçues: ${userData.keys.toList()}');

        try {
          currentUser.value = User.fromJson(userData);
          isAuthenticated.value = true;
          print('✅ Profil utilisateur chargé avec succès: ${currentUser.value?.nomUtilisateur}');

          // Note: AuthorizationService délègue maintenant au PermissionService
          // La synchronisation se fait automatiquement via les observables
          print('🔄 Profil utilisateur synchronisé automatiquement');
        } catch (e) {
          print('❌ Erreur lors de la création du modèle User: $e');
          print('📋 Données reçues: $userData');
          throw e;
        }
      } else {
        print('❌ Échec de la récupération du profil: ${response.data}');
        throw Exception('Échec de la récupération du profil utilisateur');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du profil: $e');
      // Erreur lors du chargement du profil, nettoyer les données
      await _clearAuthData();
      throw e; // Relancer l'erreur pour que checkAuthentication puisse la gérer
    }
  }

  /// Nettoyer les données d'authentification
  Future<void> _clearAuthData() async {
    await _secureStorage.delete(key: AppConstants.authTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    _apiClient.clearAuthToken();

    currentUser.value = null;
    isAuthenticated.value = false;
    errorMessage.value = '';
    isLoading.value = false; // ✅ Arrêter le loading
  }

  /// Créer un utilisateur fictif pour le mode développement
  void _createMockUser() {
    currentUser.value = User(
      id: 1,
      nomUtilisateur: 'admin',
      email: 'admin@logesco.com',
      dateCreation: DateTime.now(),
      dateModification: DateTime.now(),
      role: const role_model.UserRole(
        nom: 'ADMIN',
        displayName: 'Administrateur',
        isAdmin: true,
        privileges: {},
      ),
    );
    isAuthenticated.value = true;
  }

  /// Vérifier si l'utilisateur est connecté
  bool get isLoggedIn => isAuthenticated.value && currentUser.value != null;

  /// Tentative de connexion automatique en mode développement
  Future<bool> _attemptAutoLogin() async {
    try {
      print('🔧 Tentative de connexion automatique avec admin/admin123...');

      final response = await _apiClient.post('/auth/login', {
        'nomUtilisateur': 'admin',
        'motDePasse': 'admin123',
      });

      if (response.isSuccess) {
        final data = response.data['data'] as Map<String, dynamic>;
        final token = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String?;
        final userData = data['utilisateur'] as Map<String, dynamic>;

        // Sauvegarder les tokens
        await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
        if (refreshToken != null) {
          await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
        }

        // Configurer le client API
        _apiClient.setAuthToken(token);

        // Configurer aussi l'ApiService pour les autres modules
        try {
          final apiService = Get.find<ApiService>();
          apiService.setAuthToken(token);
        } catch (e) {
          print('⚠️ ApiService non trouvé: $e');
        }

        // Mettre à jour l'état
        currentUser.value = User.fromJson(userData);
        isAuthenticated.value = true;

        print('✅ Connexion automatique réussie');
        return true;
      } else {
        print('❌ Échec de la connexion automatique');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de la connexion automatique: $e');
      return false;
    }
  }
}
