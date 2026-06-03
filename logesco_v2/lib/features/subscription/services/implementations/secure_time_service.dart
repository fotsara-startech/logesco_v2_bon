import 'dart:async';
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

  /// Indique si le résultat vient d'une vérification fraîche ou du cache
  final bool isFresh;

  const TimeValidationResult({
    required this.trustedTime,
    required this.isSystemTimeReliable,
    required this.ntpAvailable,
    this.systemTimeOffset,
    this.warnings = const [],
    this.isFresh = false,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get isManipulationDetected => !isSystemTimeReliable;
}

/// Service de validation sécurisée du temps avec support offline
///
/// Protège contre la manipulation de l'horloge système en utilisant:
/// 1. Vérification NTP async (ne bloque jamais l'UI)
/// 2. Détection de retour en arrière de l'horloge
/// 3. Horodatage persistant multi-niveaux
/// 4. Compteur de sessions pour détecter les réinstallations
/// 5. Mode offline gracieux avec cache intelligent
class SecureTimeService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences? _prefs;

  // Clés de stockage
  static const String _keyLastCheckTime = 'secure_time_last_check';
  static const String _keyLastNtpTime = 'secure_time_last_ntp';
  static const String _keySessionCounter = 'secure_time_session_counter';
  static const String _keyFirstActivation = 'secure_time_first_activation';
  static const String _keySystemTimeOffset = 'secure_time_system_offset';
  static const String _keyNtpFailureCount = 'secure_time_ntp_failures';

  // Configuration
  static const Duration _ntpCacheDuration = Duration(days: 30); // Cache très long (30 jours)
  static const Duration _maxAcceptableOffset = Duration(minutes: 5);
  static const int _maxNtpRetries = 2; // Réduit de 3 à 2
  static const Duration _ntpTimeout = Duration(seconds: 2); // Réduit de 5 à 2
  static const int _maxNtpFailuresBeforeOffline = 5;

  // Flags pour contrôler les validations
  bool _manipulationCheckEnabled = true; // Désactivé après démarrage

  // Serveurs NTP publics (fallback en cascade)
  static const List<String> _ntpServers = [
    'time.google.com',
    'pool.ntp.org',
    'time.cloudflare.com', // Reordonné pour rapidité
  ];

  // Cache
  DateTime? _cachedNtpTime;
  DateTime? _cachedNtpTimestamp;
  DateTime? _lastCheckTime;
  int? _sessionCounter;
  int _ntpFailureCount = 0;
  bool _isOfflineMode = false;

  SecureTimeService({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _prefs = prefs;

  /// Initialise le service
  Future<void> initialize() async {
    await _loadStoredData();
    await _incrementSessionCounter();

    // NTP check UNIQUEMENT à l'initialisation
    await _performInitialNtpCheck();

    // Après démarrage: désactiver les checks de manipulation horloge
    _manipulationCheckEnabled = false;
  }

  /// Effectue UNE SEULE vérification NTP au démarrage
  Future<void> _performInitialNtpCheck() async {
    try {
      final ntpTime = await _getNetworkTimeWithTimeout(
        forceRefresh: true,
        timeout: _ntpTimeout,
      );

      if (ntpTime != null) {
        _cachedNtpTime = ntpTime;
        _cachedNtpTimestamp = DateTime.now();
        await _storeNtpTime(ntpTime);
        _ntpFailureCount = 0;
        _isOfflineMode = false;
      } else {
        _ntpFailureCount++;
        if (_ntpFailureCount >= _maxNtpFailuresBeforeOffline) {
          _isOfflineMode = true;
        }
      }
    } catch (e) {
      _ntpFailureCount++;
      if (_ntpFailureCount >= _maxNtpFailuresBeforeOffline) {
        _isOfflineMode = true;
      }
    }
  }

  /// Obtient l'heure sécurisée et fiable SANS JAMAIS bloquer l'UI
  ///
  /// Stratégie:
  /// 1. Retourner immédiatement le cache si disponible
  /// 2. NTP check UNIQUEMENT au démarrage (initialize())
  /// 3. Pendant session: utiliser cache + temps écoulé
  /// 4. Jamais d'attente > 2 secondes
  Future<TimeValidationResult> getSecureTime({
    bool forceNtpCheck = false,
    bool throwOnManipulation = false, // IMPORTANT: Jamais vrai pendant session
  }) async {
    final warnings = <String>[];
    DateTime trustedTime;
    bool isSystemTimeReliable = true;
    bool ntpAvailable = false;
    Duration? systemTimeOffset;
    bool isFresh = false;

    try {
      // 1. Vérifier le retour en arrière de l'horloge système
      // UNIQUEMENT si manipulation check est activé (démarrage uniquement)
      final clockRollback = _manipulationCheckEnabled ? await _detectTimeManipulation() : false;
      if (clockRollback) {
        isSystemTimeReliable = false;
        warnings.add('Retour en arrière de l\'horloge système détecté');
      }

      // 2. NTP check UNIQUEMENT si forceNtpCheck ET manipulation enabled
      // (i.e., uniquement au démarrage ou si explicitement forcé)
      DateTime? ntpTime;
      if (forceNtpCheck && _manipulationCheckEnabled) {
        ntpTime = await _getNetworkTimeWithTimeout(
          forceRefresh: true,
          timeout: _ntpTimeout,
        );
      } else {
        // Pendant session: utiliser cache uniquement
        ntpTime = null;
      }

      if (ntpTime != null) {
        ntpAvailable = true;
        trustedTime = ntpTime;
        isFresh = true;

        // Calculer l'offset avec l'heure système
        final systemTime = DateTime.now();
        systemTimeOffset = ntpTime.difference(systemTime);

        // Offset > 5 minutes = manipulation de date système confirmée
        // Mais UNIQUEMENT si check activé
        if (_manipulationCheckEnabled && systemTimeOffset.abs() > _maxAcceptableOffset) {
          isSystemTimeReliable = false;
          warnings.add(
            'Manipulation de date détectée: décalage de ${systemTimeOffset.inMinutes} minutes',
          );
        }

        // Mettre à jour le cache
        if (isSystemTimeReliable) {
          await _updateLastCheckTime(trustedTime);
          _ntpFailureCount = 0;
          _isOfflineMode = false;
        }
      } else {
        // NTP indisponible → Mode offline gracieux
        warnings.add('Serveur NTP indisponible (cache utilisé)');

        // Utiliser le cache NTP s'il existe
        if (_cachedNtpTime != null && _cachedNtpTimestamp != null) {
          final elapsedSinceNtp = DateTime.now().difference(_cachedNtpTimestamp!);

          if (elapsedSinceNtp.isNegative) {
            // Date système reculée
            isSystemTimeReliable = false;
            trustedTime = _cachedNtpTime!;
            warnings.add('Temps restauré depuis cache NTP');
          } else {
            trustedTime = _cachedNtpTime!.add(elapsedSinceNtp);
            warnings.add('Temps calculé depuis cache');
          }
        } else if (_lastCheckTime != null && !clockRollback) {
          // Pas de cache NTP → utiliser lastCheckTime avec élapsed
          final elapsedSinceCheck = DateTime.now().difference(_lastCheckTime!);
          trustedTime = _lastCheckTime!.add(elapsedSinceCheck);
          warnings.add('Temps calculé depuis dernière vérification');
        } else {
          // Aucun cache disponible → système time seulement
          trustedTime = DateTime.now();
          isSystemTimeReliable = false;
          warnings.add('Attention: Utilisation de l\'horloge système (cache indisponible)');
        }
      }

      return TimeValidationResult(
        trustedTime: trustedTime,
        isSystemTimeReliable: isSystemTimeReliable,
        ntpAvailable: ntpAvailable,
        systemTimeOffset: systemTimeOffset,
        warnings: warnings,
        isFresh: isFresh,
      );
    } catch (e) {
      // Les erreurs en getSecureTime ne bloquent jamais
      return TimeValidationResult(
        trustedTime: DateTime.now(),
        isSystemTimeReliable: false,
        ntpAvailable: false,
        warnings: ['Erreur validation temps: ${e.toString()}'],
        isFresh: false,
      );
    }
  }

  /// Obtient l'heure NTP avec timeout strict
  Future<DateTime?> _getNetworkTimeWithTimeout({
    bool forceRefresh = false,
    required Duration timeout,
  }) async {
    // Utiliser le cache si disponible et récent
    if (!forceRefresh && _cachedNtpTime != null && _cachedNtpTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cachedNtpTimestamp!);
      if (cacheAge < _ntpCacheDuration) {
        return _cachedNtpTime;
      }
    }

    // Lancer la requête NTP avec timeout strict
    try {
      return await _getNetworkTimeSequential(timeout).timeout(
        timeout,
        onTimeout: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Essaie les serveurs NTP en cascade avec timeouts
  Future<DateTime?> _getNetworkTimeSequential(Duration timeout) async {
    for (final server in _ntpServers) {
      for (int retry = 0; retry < _maxNtpRetries; retry++) {
        try {
          final ntpTime = await NTP
              .now(
                lookUpAddress: server,
                timeout: timeout,
              )
              .timeout(timeout);

          // Succès
          _cachedNtpTime = ntpTime;
          _cachedNtpTimestamp = DateTime.now();
          await _storeNtpTime(ntpTime);
          return ntpTime;
        } catch (e) {
          // Continuer au serveur suivant
          if (retry < _maxNtpRetries - 1) {
            await Future.delayed(Duration(milliseconds: 100 * (retry + 1)));
          }
        }
      }
    }

    return null;
  }

  /// Détecte si l'horloge système a été manipulée
  Future<bool> _detectTimeManipulation() async {
    if (_lastCheckTime == null) {
      return false; // Première exécution
    }

    final currentTime = DateTime.now();

    // Vérifier si l'heure actuelle est antérieure à la dernière vérification
    if (currentTime.isBefore(_lastCheckTime!)) {
      return true;
    }

    return false;
  }

  /// Stocke l'heure NTP de manière sécurisée
  Future<void> _storeNtpTime(DateTime ntpTime) async {
    try {
      await _secureStorage.write(
        key: _keyLastNtpTime,
        value: ntpTime.toIso8601String(),
      );
    } catch (e) {
      // Silencieux
    }
  }

  /// Met à jour l'heure de la dernière vérification
  Future<void> _updateLastCheckTime(DateTime time) async {
    _lastCheckTime = time;

    try {
      await _secureStorage.write(
        key: _keyLastCheckTime,
        value: time.toIso8601String(),
      );

      if (_prefs != null) {
        await _prefs!.setString(_keyLastCheckTime, time.toIso8601String());
      }
    } catch (e) {
      // Silencieux
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
    } catch (e) {
      // Silencieux
    }
  }

  /// Charge les données stockées
  Future<void> _loadStoredData() async {
    try {
      final lastCheckStr = await _secureStorage.read(key: _keyLastCheckTime);
      if (lastCheckStr != null) {
        _lastCheckTime = DateTime.parse(lastCheckStr);
      }

      final lastNtpStr = await _secureStorage.read(key: _keyLastNtpTime);
      if (lastNtpStr != null) {
        _cachedNtpTime = DateTime.parse(lastNtpStr);
        _cachedNtpTimestamp = _lastCheckTime;
      }

      final sessionCounterStr = await _secureStorage.read(key: _keySessionCounter);
      if (sessionCounterStr != null) {
        _sessionCounter = int.tryParse(sessionCounterStr);
      }

      final failureCountStr = await _secureStorage.read(key: _keyNtpFailureCount);
      if (failureCountStr != null) {
        _ntpFailureCount = int.tryParse(failureCountStr) ?? 0;
      }
    } catch (e) {
      // Silencieux
    }
  }

  /// Enregistre la première activation
  Future<void> recordFirstActivation(DateTime activationTime) async {
    try {
      await _secureStorage.write(
        key: _keyFirstActivation,
        value: activationTime.toIso8601String(),
      );

      if (_prefs != null) {
        await _prefs!.setString(_keyFirstActivation, activationTime.toIso8601String());
      }
    } catch (e) {
      // Silencieux
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
      // Silencieux
    }
    return null;
  }

  /// Vérifie si l'application a été réinstallée
  Future<bool> detectReinstallation() async {
    try {
      final secureData = await _secureStorage.read(key: _keySessionCounter);
      final prefsData = _prefs?.getInt(_keySessionCounter);

      if (secureData != null && prefsData == null) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si l'app est en mode offline
  bool get isOfflineMode => _isOfflineMode;

  /// Force une vérification NTP immédiate (en arrière-plan)
  Future<DateTime?> forceNtpCheck() async {
    return await _getNetworkTimeWithTimeout(
      forceRefresh: true,
      timeout: _ntpTimeout,
    );
  }

  /// Nettoie toutes les données stockées (tests uniquement)
  Future<void> clearAllData() async {
    try {
      await _secureStorage.delete(key: _keyLastCheckTime);
      await _secureStorage.delete(key: _keyLastNtpTime);
      await _secureStorage.delete(key: _keySessionCounter);
      await _secureStorage.delete(key: _keyFirstActivation);
      await _secureStorage.delete(key: _keySystemTimeOffset);
      await _secureStorage.delete(key: _keyNtpFailureCount);

      if (_prefs != null) {
        await _prefs!.remove(_keyLastCheckTime);
        await _prefs!.remove(_keySessionCounter);
        await _prefs!.remove(_keyFirstActivation);
      }

      _cachedNtpTime = null;
      _cachedNtpTimestamp = null;
      _lastCheckTime = null;
      _sessionCounter = null;
      _ntpFailureCount = 0;
      _isOfflineMode = false;
    } catch (e) {
      // Silencieux
    }
  }

  /// Obtient des statistiques de diagnostic
  Future<Map<String, dynamic>> getDiagnostics() async {
    final systemTime = DateTime.now();
    final ntpTime = await _getNetworkTimeWithTimeout(
      forceRefresh: false,
      timeout: _ntpTimeout,
    );

    return {
      'systemTime': systemTime.toIso8601String(),
      'lastCheckTime': _lastCheckTime?.toIso8601String(),
      'cachedNtpTime': _cachedNtpTime?.toIso8601String(),
      'sessionCounter': _sessionCounter,
      'ntpAvailable': ntpTime != null,
      'systemTimeOffset': ntpTime?.difference(systemTime).inSeconds,
      'manipulationDetected': await _detectTimeManipulation(),
      'reinstallationDetected': await detectReinstallation(),
      'offlineMode': _isOfflineMode,
      'ntpFailureCount': _ntpFailureCount,
    };
  }

  /// Dispose le service
  void dispose() {
    // Plus de timer à annuler (validations périodiques désactivées)
  }
}
