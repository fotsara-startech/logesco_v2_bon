import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/api_response.dart';
import '../models/company_profile.dart';

class CompanySettingsService {
  final AuthService _authService;
  static const String _cacheKey = 'company_profile_cache';
  static const String _cacheTimestampKey = 'company_profile_cache_cache_timestamp';
  static const Duration _cacheExpiration = Duration(hours: 1);

  // Mode test pour simuler les réponses quand le backend n'est pas disponible
  static const bool _useTestMode = false;

  CompanySettingsService(this._authService);

  /// Récupère le profil de l'entreprise
  Future<ApiResponse<CompanyProfile>> getCompanyProfile({bool forceRefresh = false}) async {
    try {
      // Vérifier le cache d'abord si pas de refresh forcé
      if (!forceRefresh) {
        final cachedProfile = await _getCachedProfile();
        if (cachedProfile != null) {
          return ApiResponse.success(cachedProfile, message: 'Données récupérées du cache');
        }
      }

      // Mode test : retourner un profil de test
      if (_useTestMode) {
        return _simulateGetTestProfile();
      }

      // Si on n'est plus en mode test, vider le cache de test
      await _clearCache();

      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/company-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      print('📊 Company Profile API Response Status: ${response.statusCode}');
      print('📊 Company Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📊 Parsing company profile from API response...');

        // Le backend retourne maintenant les données dans 'data'
        final companyData = jsonData['data'];

        // Créer manuellement le CompanyProfile pour éviter les problèmes de parsing
        final profile = CompanyProfile(
          id: companyData['id'] is String ? int.tryParse(companyData['id']) : companyData['id'],
          name: companyData['nomEntreprise'] ?? 'Entreprise',
          address: companyData['adresse'] ?? '',
          location: companyData['localisation'],
          phone: companyData['telephone'],
          email: companyData['email'],
          nuiRccm: companyData['nuiRccm'],
          createdAt: companyData['dateCreation'] != null ? DateTime.parse(companyData['dateCreation']) : DateTime.now(),
          updatedAt: companyData['dateModification'] != null ? DateTime.parse(companyData['dateModification']) : DateTime.now(),
        );

        print('✅ === PROFIL D\'ENTREPRISE RÉCUPÉRÉ DEPUIS L\'API ===');
        print('✅ Nom: ${profile.name}');
        print('✅ Adresse: ${profile.address}');
        print('✅ Localisation: ${profile.location ?? 'Non définie'}');
        print('✅ Téléphone: ${profile.phone ?? 'Non défini'}');
        print('✅ Email: ${profile.email ?? 'Non défini'}');
        print('✅ NUI/RCCM: ${profile.nuiRccm ?? 'Non défini'}');
        print('✅ ================================================');

        // Mettre en cache le profil
        await _cacheProfile(profile);

        return ApiResponse.success(profile, message: jsonData['message'] ?? 'Profil récupéré avec succès');
      } else if (response.statusCode == 401) {
        // Erreur d'authentification, essayer l'endpoint public
        print('🔄 [INFO] Erreur d\'authentification, utilisation de l\'endpoint public...');
        return await _getCompanyProfileFromPublicEndpoint();
      } else if (response.statusCode == 404) {
        return ApiResponse.error(message: 'Profil d\'entreprise non trouvé');
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la récupération du profil');
      }
    } catch (e) {
      print('❌ Error getting company profile: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez votre connexion.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Récupère le profil depuis l'endpoint public (sans authentification)
  Future<ApiResponse<CompanyProfile>> _getCompanyProfileFromPublicEndpoint() async {
    try {
      print('🌐 [DEBUG] Récupération depuis l\'endpoint public...');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/company-settings/public'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      print('🌐 [DEBUG] Réponse endpoint public: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final companyData = jsonData['data'];

        // Créer manuellement le CompanyProfile
        final profile = CompanyProfile(
          id: companyData['id'] is String ? int.tryParse(companyData['id']) ?? 1 : (companyData['id'] ?? 1),
          name: companyData['nomEntreprise'] ?? 'Entreprise',
          address: companyData['adresse'] ?? '',
          location: companyData['localisation'],
          phone: companyData['telephone'],
          email: companyData['email'],
          nuiRccm: companyData['nuiRccm'],
          createdAt: companyData['dateCreation'] != null ? DateTime.parse(companyData['dateCreation']) : DateTime.now(),
          updatedAt: companyData['dateModification'] != null ? DateTime.parse(companyData['dateModification']) : DateTime.now(),
        );

        print('✅ [DEBUG] CompanyProfile créé depuis endpoint public: ${profile.name}');

        // Mettre en cache le profil
        await _cacheProfile(profile);

        return ApiResponse.success(profile, message: 'Profil récupéré depuis endpoint public');
      } else if (response.statusCode == 404) {
        return ApiResponse.error(message: 'Profil d\'entreprise non configuré');
      } else {
        return ApiResponse.error(message: 'Erreur lors de la récupération du profil depuis l\'endpoint public');
      }
    } catch (e) {
      print('❌ [ERROR] Erreur endpoint public: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez votre connexion.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Simule la récupération d'un profil de test
  Future<ApiResponse<CompanyProfile>> _simulateGetTestProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Vérifier d'abord s'il y a un profil en cache
    final cachedProfile = await _getCachedProfile();
    if (cachedProfile != null) {
      return ApiResponse.success(cachedProfile, message: 'Profil récupéré du cache (mode test)');
    }

    // Créer un profil de test par défaut
    final testProfile = CompanyProfile(
      id: 1,
      name: 'Mon Entreprise',
      address: 'Adresse de l\'entreprise',
      location: 'Ville, Pays',
      phone: '+237 682471185 / +237 6 58 96 2546',
      email: 'contact@monentreprise.com',
      nuiRccm: 'NUI/RCCM',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Mettre en cache le profil de test
    await _cacheProfile(testProfile);

    return ApiResponse.success(testProfile, message: 'Profil de test créé');
  }

  /// Simule une réponse de test
  Future<ApiResponse<CompanyProfile>> _simulateTestResponse(CompanyProfileRequest request) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));

    final profile = CompanyProfile(
      id: DateTime.now().millisecondsSinceEpoch,
      name: request.name,
      address: request.address,
      location: request.location,
      phone: request.phone,
      email: request.email,
      nuiRccm: request.nuiRccm,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Mettre en cache le profil simulé
    await _cacheProfile(profile);

    return ApiResponse.success(
      profile,
      message: 'Profil créé avec succès (mode test)',
    );
  }

  /// Crée un nouveau profil d'entreprise
  Future<ApiResponse<CompanyProfile>> createCompanyProfile(CompanyProfileRequest request) async {
    // Mode test : simuler la réponse
    if (_useTestMode) {
      return _simulateTestResponse(request);
    }

    try {
      // Valider les données avant l'envoi
      final tempProfile = CompanyProfile(
        name: request.name,
        address: request.address,
        location: request.location,
        phone: request.phone,
        email: request.email,
        nuiRccm: request.nuiRccm,
      );

      final validationErrors = tempProfile.validate();
      if (validationErrors.isNotEmpty) {
        return ApiResponse.error(
          message: 'Données invalides',
          errors: validationErrors.entries.map((e) => ApiError(field: e.key, message: e.value)).toList(),
        );
      }

      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      print('Creating company profile with data: ${json.encode(request.toJson())}');
      print('API URL: ${ApiConfig.baseUrl}/company-settings');

      final response = await http
          .put(
        Uri.parse('${ApiConfig.baseUrl}/company-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      )
          .timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Le backend retourne maintenant les données dans 'data'
        final companyData = jsonData['data'];

        // Créer manuellement le CompanyProfile pour éviter les problèmes de parsing
        final profile = CompanyProfile(
          id: companyData['id'] is String ? int.tryParse(companyData['id']) : companyData['id'],
          name: companyData['nomEntreprise'] ?? 'Entreprise',
          address: companyData['adresse'] ?? '',
          location: companyData['localisation'],
          phone: companyData['telephone'],
          email: companyData['email'],
          nuiRccm: companyData['nuiRccm'],
          createdAt: companyData['dateCreation'] != null ? DateTime.parse(companyData['dateCreation']) : DateTime.now(),
          updatedAt: companyData['dateModification'] != null ? DateTime.parse(companyData['dateModification']) : DateTime.now(),
        );

        // Mettre en cache le nouveau profil
        await _cacheProfile(profile);

        return ApiResponse.success(profile, message: jsonData['message'] ?? 'Profil créé avec succès');
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la création du profil');
      }
    } catch (e) {
      print('❌ Error creating company profile: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez votre connexion.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Met à jour le profil d'entreprise
  Future<ApiResponse<CompanyProfile>> updateCompanyProfile(CompanyProfileRequest request) async {
    // Mode test : simuler la mise à jour
    if (_useTestMode) {
      return _simulateTestResponse(request);
    }

    try {
      // Valider les données avant l'envoi
      final tempProfile = CompanyProfile(
        name: request.name,
        address: request.address,
        location: request.location,
        phone: request.phone,
        email: request.email,
        nuiRccm: request.nuiRccm,
      );

      final validationErrors = tempProfile.validate();
      if (validationErrors.isNotEmpty) {
        return ApiResponse.error(
          message: 'Données invalides',
          errors: validationErrors.entries.map((e) => ApiError(field: e.key, message: e.value)).toList(),
        );
      }

      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      print('Updating company profile with data: ${json.encode(request.toJson())}');

      final response = await http
          .put(
        Uri.parse('${ApiConfig.baseUrl}/company-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      )
          .timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Le backend retourne maintenant les données dans 'data'
        final companyData = jsonData['data'];

        // Créer manuellement le CompanyProfile pour éviter les problèmes de parsing
        final profile = CompanyProfile(
          id: companyData['id'] is String ? int.tryParse(companyData['id']) : companyData['id'],
          name: companyData['nomEntreprise'] ?? 'Entreprise',
          address: companyData['adresse'] ?? '',
          location: companyData['localisation'],
          phone: companyData['telephone'],
          email: companyData['email'],
          nuiRccm: companyData['nuiRccm'],
          createdAt: companyData['dateCreation'] != null ? DateTime.parse(companyData['dateCreation']) : DateTime.now(),
          updatedAt: companyData['dateModification'] != null ? DateTime.parse(companyData['dateModification']) : DateTime.now(),
        );

        // Mettre à jour le cache
        await _cacheProfile(profile);

        return ApiResponse.success(profile, message: jsonData['message'] ?? 'Profil mis à jour avec succès');
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la mise à jour du profil');
      }
    } catch (e) {
      print('❌ Error updating company profile: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez votre connexion.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Supprime le profil d'entreprise
  Future<ApiResponse<void>> deleteCompanyProfile() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return ApiResponse.error(message: 'Token d\'authentification manquant');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/company-settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Supprimer du cache
        await _clearCache();

        return ApiResponse.success(null, message: jsonData['message']);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(message: errorData['message'] ?? 'Erreur lors de la suppression du profil');
      }
    } catch (e) {
      print('❌ Error deleting company profile: $e');
      if (e.toString().contains('Timeout')) {
        return ApiResponse.error(message: 'Le serveur ne répond pas. Vérifiez votre connexion.');
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(message: 'Impossible de se connecter au serveur.');
      }
      return ApiResponse.error(message: 'Erreur de connexion: $e');
    }
  }

  /// Récupère le profil depuis le cache
  Future<CompanyProfile?> _getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedData != null && cacheTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
        final now = DateTime.now();

        // Vérifier si le cache n'a pas expiré
        if (now.difference(cacheTime) < _cacheExpiration) {
          final jsonData = json.decode(cachedData);
          // Créer manuellement le CompanyProfile depuis le cache
          return CompanyProfile(
            id: jsonData['id'] is String ? int.tryParse(jsonData['id']) : jsonData['id'],
            name: jsonData['nomEntreprise'] ?? 'Entreprise',
            address: jsonData['adresse'] ?? '',
            location: jsonData['localisation'],
            phone: jsonData['telephone'],
            email: jsonData['email'],
            nuiRccm: jsonData['nuiRccm'],
            createdAt: jsonData['dateCreation'] != null ? DateTime.parse(jsonData['dateCreation']) : DateTime.now(),
            updatedAt: jsonData['dateModification'] != null ? DateTime.parse(jsonData['dateModification']) : DateTime.now(),
          );
        } else {
          // Cache expiré, le supprimer
          await _clearCache();
        }
      }
    } catch (e) {
      print('❌ Error reading cached profile: $e');
      await _clearCache(); // Supprimer le cache corrompu
    }
    return null;
  }

  /// Met en cache le profil
  Future<void> _cacheProfile(CompanyProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(profile.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(_cacheKey, jsonData);
      await prefs.setInt(_cacheTimestampKey, timestamp);

      print('✅ Company profile cached successfully');
    } catch (e) {
      print('❌ Error caching profile: $e');
    }
  }

  /// Supprime le cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      print('✅ Company profile cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Vérifie si des données sont en cache
  Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_cacheKey);
  }

  /// Récupère l'âge du cache en minutes
  Future<int?> getCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);

      if (cacheTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
        final now = DateTime.now();
        return now.difference(cacheTime).inMinutes;
      }
    } catch (e) {
      print('❌ Error getting cache age: $e');
    }
    return null;
  }
}
