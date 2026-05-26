import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntp/ntp.dart';

/// Erreurs liées à la validation du temps
enum TimeValidationError {
  timeManipulation,
  ntpUnavailable,
  systemClockSuspicious,
  reinstallationDetected,
}

/// Exception pour les erreurs de validation du temps
class TimeValidationException implements Exception {
  final TimeValidationError error;
  final String message;

  TimeValidationException(this.error, this.message);

  @override
  String toString() => 'TimeValidationException: $message';
}

/// Résultat de la validation du temps
class TimeValidationResult {
  final DateTime trustedTime;
  final bool isSystemTimeReliable;
  final bool ntpAvailable;
  final Duration? systemTimeOffset;
  final List<String> warnings;

  const TimeValidationResult({
    required this.trustedTime,
    required this.isSystemTimeReliable,
    required this.ntpAvailable,
    this.systemTimeOffset,
    this.warnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get isManipulationDetected => !isSystemTimeReliable;
}

/// Service de validation sécurisée du temps
///
/// Protège contre la manipulation de l'horloge système en utilisant:
/// 1. Vérification NTP (Network Time Protocol)
/// 2. Détection de retour en arrière de l'horloge
/// 3. Horodatage persistant multi-niveaux
/// 4. Compteur de sessions pour détecter les réinstallations
class SecureTimeService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _prefs;

  // Clés de stockage
  static const String _keyLastCheckTime = 'secure_time_last_check';
  static const String _keyLastNtpTime = 'secure_time_last_ntp';
  static const String _keySessionCounter = 'secure_time_session_counter';
  static const String _keyFirstActivation = 'secure_time_first_activation';
  static const String _keySystemTimeOffset = 'secure_time_system_offset';

  // Configuration
  static const Duration _ntpCacheDuration = Duration(hours: 24);
  static const Duration _maxAcceptableOffset = Duration(minutes: 5);
  static const int _maxNtpRetries = 3;

  // Serveurs NTP publics (fallback en cascade)
  static const List<String> _ntpServers = [
    'time.google.com',
    'pool.ntp.org',
    'time.windows.com',
    'time.cloudflare.com',
  ];

  // Cache
  DateTime? _cachedNtpTime;
  DateTime? _cachedNtpTimestamp;
  DateTime? _lastCheckTime;
  int? _sessionCounter;

  SecureTimeService({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _prefs = prefs;

  /// Initialise le service
  Future<void> initialize() async {
    await _loadStoredData();
    await _incrementSessionCounter();
  }

  /// Obtient l'heure sécurisée et fiable
  ///
  /// Retourne l'heure la plus fiable disponible en utilisant:
  /// 1. NTP si disponible et récent
  /// 2. Temps calculé depuis la dernière vérification NTP
  /// 3. Temps système si aucune manipulation détectée
  ///
  /// Lance une exception si manipulation détectée
  Future<TimeValidationResult> getSecureTime({
    bool forceNtpCheck = false,
    bool throwOnManipulation = true,
  }) async {
    final warnings = <String>[];
    DateTime trustedTime;
    bool isSystemTimeReliable = true;
    bool ntpAvailable = false;
    Duration? systemTimeOffset;

    try {
      // 1. Vérifier le retour en arrière de l'horloge système
      final clockRollback = await _detectTimeManipulation();
      if (clockRollback) {
        isSystemTimeReliable = false;
        warnings.add('Retour en arrière de l\'horloge système détecté');
      }

      // 2. Essayer d'obtenir l'heure NTP
      final ntpTime = await _getNetworkTime(forceRefresh: forceNtpCheck);

      if (ntpTime != null) {
        ntpAvailable = true;
        trustedTime = ntpTime;

        // Calculer l'offset avec l'heure système
        final systemTime = DateTime.now();
        systemTimeOffset = ntpTime.difference(systemTime);

        // Offset > 5 minutes = manipulation de date système confirmée
        if (systemTimeOffset.abs() > _maxAcceptableOffset) {
          isSystemTimeReliable = false;
          warnings.add(
            'Manipulation de date détectée: décalage de ${systemTimeOffset.inMinutes} minutes avec NTP',
          );
        }

        // Mettre à jour le cache seulement si l'heure système est fiable
        if (isSystemTimeReliable) {
          await _updateLastCheckTime(trustedTime);
        }
      } else {
        // Pas de NTP disponible
        warnings.add('Serveur NTP non disponible, utilisation du temps calculé');

        if (_cachedNtpTime != null && _cachedNtpTimestamp != null) {
          final elapsedSinceNtp = DateTime.now().difference(_cachedNtpTimestamp!);

          // Si elapsed est négatif → date système reculée par rapport au moment du cache NTP
          if (elapsedSinceNtp.isNegative) {
            isSystemTimeReliable = false;
            // Utiliser le cache NTP directement comme référence minimale
            trustedTime = _cachedNtpTime!;
            warnings.add('Manipulation de date détectée: date système antérieure au cache NTP');
          } else {
            trustedTime = _cachedNtpTime!.add(elapsedSinceNtp);
            warnings.add('Temps calculé depuis la dernière vérification NTP');
          }
        } else if (_lastCheckTime != null && !clockRollback) {
          trustedTime = DateTime.now();
          await _updateLastCheckTime(trustedTime);
        } else {
          if (throwOnManipulation) {
            throw TimeValidationException(
              TimeValidationError.ntpUnavailable,
              'Impossible de valider l\'heure. Veuillez vous connecter à Internet.',
            );
          }
          trustedTime = DateTime.now();
          warnings.add('ATTENTION: Utilisation de l\'heure système non vérifiée');
        }
      }

      // 3. Si manipulation confirmée et throwOnManipulation, lancer l'exception
      if (!isSystemTimeReliable && throwOnManipulation) {
        throw TimeValidationException(
          TimeValidationError.timeManipulation,
          'L\'horloge système a été manipulée. Veuillez restaurer la date et l\'heure correctes.',
        );
      }

      return TimeValidationResult(
        trustedTime: trustedTime,
        isSystemTimeReliable: isSystemTimeReliable,
        ntpAvailable: ntpAvailable,
        systemTimeOffset: systemTimeOffset,
        warnings: warnings,
      );
    } catch (e) {
      if (e is TimeValidationException) {
        rethrow;
      }
      throw TimeValidationException(
        TimeValidationError.systemClockSuspicious,
        'Erreur lors de la validation du temps: $e',
      );
    }
  }

  /// Détecte si l'horloge système a été manipulée
  Future<bool> _detectTimeManipulation() async {
    if (_lastCheckTime == null) {
      return false; // Première exécution
    }

    final currentTime = DateTime.now();

    // Vérifier si l'heure actuelle est antérieure à la dernière vérification
    if (currentTime.isBefore(_lastCheckTime!)) {
      print('⚠️  [SecureTimeService] Retour en arrière détecté:');
      print('   Dernière vérification: $_lastCheckTime');
      print('   Heure actuelle: $currentTime');
      return true;
    }

    // Vérifier si le saut temporel est anormalement grand (> 7 jours)
    final timeDifference = currentTime.difference(_lastCheckTime!);
    if (timeDifference > const Duration(days: 7)) {
      print('⚠️  [SecureTimeService] Saut temporel suspect: ${timeDifference.inDays} jours');
      // Note: Ceci pourrait être légitime (appareil éteint longtemps)
      // On ne bloque pas mais on force une vérification NTP
      return false;
    }

    return false;
  }

  /// Obtient l'heure depuis un serveur NTP
  Future<DateTime?> _getNetworkTime({bool forceRefresh = false}) async {
    // Utiliser le cache si disponible et récent
    if (!forceRefresh && _cachedNtpTime != null && _cachedNtpTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cachedNtpTimestamp!);
      if (cacheAge < _ntpCacheDuration) {
        print(' [SecureTimeService] Utilisation du cache NTP (âge: ${cacheAge.inHours}h)');
        return _cachedNtpTime;
      }
    }

    // Essayer chaque serveur NTP en cascade
    for (final server in _ntpServers) {
      for (int retry = 0; retry < _maxNtpRetries; retry++) {
        try {
          print(' [SecureTimeService] Requête NTP vers $server (tentative ${retry + 1})');

          final ntpTime = await NTP.now(
            lookUpAddress: server,
            timeout: const Duration(seconds: 5),
          );

          print(' [SecureTimeService] Heure NTP obtenue: $ntpTime');

          // Mettre en cache
          _cachedNtpTime = ntpTime;
          _cachedNtpTimestamp = DateTime.now();
          await _storeNtpTime(ntpTime);

          return ntpTime;
        } catch (e) {
          print(' [SecureTimeService] Échec NTP $server (tentative ${retry + 1}): $e');

          if (retry < _maxNtpRetries - 1) {
            await Future.delayed(Duration(seconds: retry + 1));
          }
        }
      }
    }

    print('⚠️  [SecureTimeService] Tous les serveurs NTP ont échoué');
    return null;
  }

  /// Stocke l'heure NTP de manière sécurisée
  Future<void> _storeNtpTime(DateTime ntpTime) async {
    try {
      await _secureStorage.write(
        key: _keyLastNtpTime,
        value: ntpTime.toIso8601String(),
      );
    } catch (e) {
      print('⚠️  [SecureTimeService] Erreur stockage NTP: $e');
    }
  }

  /// Met à jour l'heure de la dernière vérification
  Future<void> _updateLastCheckTime(DateTime time) async {
    _lastCheckTime = time;

    try {
      // Stockage multi-niveaux pour résistance à la suppression
      await _secureStorage.write(
        key: _keyLastCheckTime,
        value: time.toIso8601String(),
      );

      if (_prefs != null) {
        await _prefs!.setString(_keyLastCheckTime, time.toIso8601String());
      }
    } catch (e) {
      print('⚠️  [SecureTimeService] Erreur mise à jour lastCheckTime: $e');
    }
  }

  /// Incrémente le compteur de sessions
  Future<void> _incrementSessionCounter() async {
    _sessionCounter = (_sessionCounter ?? 0) + 1;

    try {
      await _secureStorage.write(
        key: _keySessionCounter,
        value: _sessionCounter.toString(),
      );

      if (_prefs != null) {
        await _prefs!.setInt(_keySessionCounter, _sessionCounter!);
      }

      print('');
    } catch (e) {
      print('⚠️  [SecureTimeService] Erreur compteur sessions: $e');
    }
  }

  /// Charge les données stockées
  Future<void> _loadStoredData() async {
    try {
      // Charger lastCheckTime
      final lastCheckStr = await _secureStorage.read(key: _keyLastCheckTime);
      if (lastCheckStr != null) {
        _lastCheckTime = DateTime.parse(lastCheckStr);
        print('');
      }

      // Charger lastNtpTime
      final lastNtpStr = await _secureStorage.read(key: _keyLastNtpTime);
      if (lastNtpStr != null) {
        _cachedNtpTime = DateTime.parse(lastNtpStr);
        _cachedNtpTimestamp = _lastCheckTime; // Approximation
        print(' [SecureTimeService] Dernier NTP: $_cachedNtpTime');
      }

      // Charger sessionCounter
      final sessionCounterStr = await _secureStorage.read(key: _keySessionCounter);
      if (sessionCounterStr != null) {
        _sessionCounter = int.tryParse(sessionCounterStr);
        print('');
      }

      // Vérifier la cohérence avec SharedPreferences
      if (_prefs != null) {
        final prefsLastCheck = _prefs!.getString(_keyLastCheckTime);
        final prefsSessionCounter = _prefs!.getInt(_keySessionCounter);

        // Détecter une réinstallation suspecte
        if (_lastCheckTime != null && prefsLastCheck == null) {
          print('⚠️  [SecureTimeService] Réinstallation potentielle détectée');
        }

        if (_sessionCounter != null && prefsSessionCounter == null) {
          print('⚠️  [SecureTimeService] Compteur de sessions réinitialisé');
        }
      }
    } catch (e) {
      print('⚠️  [SecureTimeService] Erreur chargement données: $e');
    }
  }

  /// Enregistre la première activation (appelé lors de l'activation de licence)
  Future<void> recordFirstActivation(DateTime activationTime) async {
    try {
      await _secureStorage.write(
        key: _keyFirstActivation,
        value: activationTime.toIso8601String(),
      );

      if (_prefs != null) {
        await _prefs!.setString(_keyFirstActivation, activationTime.toIso8601String());
      }

      print(' [SecureTimeService] Première activation enregistrée: $activationTime');
    } catch (e) {
      print('⚠️  [SecureTimeService] Erreur enregistrement activation: $e');
    }
  }

  /// Obtient la date de première activation
  Future<DateTime?> getFirstActivation() async {
    try {
      final firstActivationStr = await _secureStorage.read(key: _keyFirstActivation);
      if (firstActivationStr != null) {
        return DateTime.parse(firstActivationStr);
      }
    } catch (e) {
      print('⚠️  [SecureTimeService] Erreur lecture première activation: $e');
    }
    return null;
  }

  /// Vérifie si l'application a été réinstallée
  Future<bool> detectReinstallation() async {
    try {
      final secureData = await _secureStorage.read(key: _keySessionCounter);
      final prefsData = _prefs?.getInt(_keySessionCounter);

      // Si les données existent dans secure storage mais pas dans prefs
      if (secureData != null && prefsData == null) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Force une vérification NTP immédiate
  Future<DateTime?> forceNtpCheck() async {
    return await _getNetworkTime(forceRefresh: true);
  }

  /// Nettoie toutes les données stockées (pour tests uniquement)
  Future<void> clearAllData() async {
    try {
      await _secureStorage.delete(key: _keyLastCheckTime);
      await _secureStorage.delete(key: _keyLastNtpTime);
      await _secureStorage.delete(key: _keySessionCounter);
      await _secureStorage.delete(key: _keyFirstActivation);
      await _secureStorage.delete(key: _keySystemTimeOffset);

      if (_prefs != null) {
        await _prefs!.remove(_keyLastCheckTime);
        await _prefs!.remove(_keySessionCounter);
        await _prefs!.remove(_keyFirstActivation);
      }

      _cachedNtpTime = null;
      _cachedNtpTimestamp = null;
      _lastCheckTime = null;
      _sessionCounter = null;

      print('Y [SecureTimeService] Toutes les données nettoyées');
    } catch (e) {
      print('⚠️  [SecureTimeService] Erreur nettoyage: $e');
    }
  }

  /// Obtient des statistiques de diagnostic
  Future<Map<String, dynamic>> getDiagnostics() async {
    final systemTime = DateTime.now();
    final ntpTime = await _getNetworkTime();

    return {
      'systemTime': systemTime.toIso8601String(),
      'lastCheckTime': _lastCheckTime?.toIso8601String(),
      'cachedNtpTime': _cachedNtpTime?.toIso8601String(),
      'sessionCounter': _sessionCounter,
      'ntpAvailable': ntpTime != null,
      'systemTimeOffset': ntpTime != null ? ntpTime.difference(systemTime).inSeconds : null,
      'manipulationDetected': await _detectTimeManipulation(),
      'reinstallationDetected': await detectReinstallation(),
    };
  }
}
