import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  AuthService._internal();

  static const String _passwordKey = 'admin_password_hash';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _lastLoginKey = 'last_login';

  // Mot de passe par défaut (hash de "admin123")
  static const String _defaultPasswordHash = '0192023a7bbd73250516f069df18b500';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Définir le mot de passe par défaut si c'est la première utilisation
    if (!_prefs!.containsKey(_passwordKey)) {
      await _prefs!.setString(_passwordKey, _defaultPasswordHash);
    }
  }

  /// Vérifie si l'utilisateur est connecté
  bool get isLoggedIn {
    return _prefs?.getBool(_isLoggedInKey) ?? false;
  }

  /// Obtient la date de dernière connexion
  DateTime? get lastLogin {
    final timestamp = _prefs?.getInt(_lastLoginKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Connexion avec mot de passe
  Future<bool> login(String password) async {
    final hashedPassword = _hashPassword(password);
    final storedHash = _prefs?.getString(_passwordKey) ?? _defaultPasswordHash;

    if (hashedPassword == storedHash) {
      await _prefs?.setBool(_isLoggedInKey, true);
      await _prefs?.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    }

    return false;
  }

  /// Déconnexion
  Future<void> logout() async {
    await _prefs?.setBool(_isLoggedInKey, false);
  }

  /// Changer le mot de passe
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    // Vérifier l'ancien mot de passe
    if (!await login(currentPassword)) {
      return false;
    }

    // Définir le nouveau mot de passe
    final newHash = _hashPassword(newPassword);
    await _prefs?.setString(_passwordKey, newHash);

    return true;
  }

  /// Réinitialiser le mot de passe (pour les cas d'urgence)
  Future<void> resetPassword() async {
    await _prefs?.setString(_passwordKey, _defaultPasswordHash);
    await logout();
  }

  /// Vérifier si c'est la première utilisation
  bool get isFirstTime {
    final storedHash = _prefs?.getString(_passwordKey);
    return storedHash == null || storedHash == _defaultPasswordHash;
  }

  /// Hash du mot de passe avec MD5 (simple pour cette application)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Obtenir des statistiques de sécurité
  Map<String, dynamic> getSecurityStats() {
    return {
      'isLoggedIn': isLoggedIn,
      'lastLogin': lastLogin?.toIso8601String(),
      'isFirstTime': isFirstTime,
      'passwordChanged': !isFirstTime,
    };
  }
}
