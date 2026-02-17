import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../models/device_fingerprint.dart';
import '../interfaces/i_device_service.dart';

/// Implémentation du service d'empreinte d'appareil
class DeviceService implements IDeviceService {
  static const String _fingerprintKey = 'device_fingerprint';
  static const String _lastFingerprintKey = 'last_device_fingerprint';

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String> generateDeviceFingerprint() async {
    final deviceInfo = await getDeviceInfo();

    // Créer une chaîne unique basée sur les caractéristiques de l'appareil
    final fingerprintData = [
      deviceInfo['deviceId'] ?? '',
      deviceInfo['platform'] ?? '',
      deviceInfo['osVersion'] ?? '',
      deviceInfo['model'] ?? '',
      deviceInfo['brand'] ?? '',
      deviceInfo['hardware'] ?? '',
    ].join('|');

    // Générer un hash SHA-256 de l'empreinte
    final bytes = utf8.encode(fingerprintData);
    final digest = sha256.convert(bytes);
    final fullHash = digest.toString();

    // Convertir en format court XXXX-XXXX-XXXX-XXXX (16 caractères)
    return _convertToShortFormat(fullHash);
  }

  /// Convertit un hash long en format court XXXX-XXXX-XXXX-XXXX
  String _convertToShortFormat(String hash) {
    // Alphabet sans caractères ambigus
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    // Prendre les 16 premiers octets du hash (32 caractères hex)
    final hashSubstring = hash.substring(0, 32);

    // Convertir en entier et générer 4 segments de 4 caractères
    final segments = <String>[];
    for (int i = 0; i < 4; i++) {
      // Prendre 8 caractères hex (4 octets) pour chaque segment
      final hexPart = hashSubstring.substring(i * 8, (i + 1) * 8);
      final value = int.parse(hexPart, radix: 16);

      // Générer un segment de 4 caractères
      String segment = '';
      int remaining = value;
      for (int j = 0; j < 4; j++) {
        segment = alphabet[remaining % alphabet.length] + segment;
        remaining = remaining ~/ alphabet.length;
      }

      segments.add(segment);
    }

    // Assembler au format XXXX-XXXX-XXXX-XXXX
    return segments.join('-');
  }

  @override
  Future<bool> verifyDeviceFingerprint(String storedFingerprint) async {
    try {
      final currentFingerprint = await generateDeviceFingerprint();
      return currentFingerprint == storedFingerprint;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'empreinte: $e');
      return false;
    }
  }

  @override
  Future<Map<String, String>> getDeviceInfo() async {
    final Map<String, String> deviceData = {};

    try {
      // Obtenir les informations du package
      final packageInfo = await PackageInfo.fromPlatform();
      deviceData['appVersion'] = packageInfo.version;
      deviceData['buildNumber'] = packageInfo.buildNumber;

      if (kIsWeb) {
        // Informations pour le web
        final webBrowserInfo = await _deviceInfo.webBrowserInfo;
        deviceData['platform'] = 'web';
        deviceData['deviceId'] = webBrowserInfo.vendor ?? 'unknown';
        deviceData['osVersion'] = webBrowserInfo.platform ?? 'unknown';
        deviceData['model'] = webBrowserInfo.userAgent ?? 'unknown';
        deviceData['brand'] = webBrowserInfo.vendor ?? 'unknown';
        deviceData['hardware'] = webBrowserInfo.hardwareConcurrency?.toString() ?? 'unknown';
      } else if (Platform.isAndroid) {
        // Informations Android
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData['platform'] = 'android';
        deviceData['deviceId'] = androidInfo.id;
        deviceData['osVersion'] = 'Android ${androidInfo.version.release}';
        deviceData['model'] = androidInfo.model;
        deviceData['brand'] = androidInfo.brand;
        deviceData['hardware'] = androidInfo.hardware;
        deviceData['manufacturer'] = androidInfo.manufacturer;
        deviceData['product'] = androidInfo.product;
        deviceData['fingerprint'] = androidInfo.fingerprint;
      } else if (Platform.isIOS) {
        // Informations iOS
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData['platform'] = 'ios';
        deviceData['deviceId'] = iosInfo.identifierForVendor ?? 'unknown';
        deviceData['osVersion'] = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        deviceData['model'] = iosInfo.model;
        deviceData['brand'] = 'Apple';
        deviceData['hardware'] = iosInfo.utsname.machine;
        deviceData['name'] = iosInfo.name;
      } else if (Platform.isWindows) {
        // Informations Windows
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceData['platform'] = 'windows';
        deviceData['deviceId'] = windowsInfo.deviceId;
        deviceData['osVersion'] = windowsInfo.displayVersion;
        deviceData['model'] = windowsInfo.productName;
        deviceData['brand'] = 'Microsoft';
        deviceData['hardware'] = windowsInfo.computerName;
      } else if (Platform.isLinux) {
        // Informations Linux
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceData['platform'] = 'linux';
        deviceData['deviceId'] = linuxInfo.machineId ?? 'unknown';
        deviceData['osVersion'] = linuxInfo.prettyName;
        deviceData['model'] = linuxInfo.name;
        deviceData['brand'] = 'Linux';
        deviceData['hardware'] = linuxInfo.variant ?? 'unknown';
      } else if (Platform.isMacOS) {
        // Informations macOS
        final macInfo = await _deviceInfo.macOsInfo;
        deviceData['platform'] = 'macos';
        deviceData['deviceId'] = macInfo.systemGUID ?? 'unknown';
        deviceData['osVersion'] = macInfo.osRelease;
        deviceData['model'] = macInfo.model;
        deviceData['brand'] = 'Apple';
        deviceData['hardware'] = macInfo.arch;
      }
    } catch (e) {
      debugPrint('Erreur lors de la collecte des informations de l\'appareil: $e');
      // Valeurs par défaut en cas d'erreur
      deviceData['platform'] = Platform.operatingSystem;
      deviceData['deviceId'] = 'unknown';
      deviceData['osVersion'] = 'unknown';
      deviceData['model'] = 'unknown';
      deviceData['brand'] = 'unknown';
      deviceData['hardware'] = 'unknown';
      deviceData['appVersion'] = '1.0.0';
    }

    return deviceData;
  }

  @override
  Future<DeviceFingerprint> createDeviceFingerprint() async {
    final deviceInfo = await getDeviceInfo();
    final combinedHash = await generateDeviceFingerprint();

    return DeviceFingerprint(
      deviceId: deviceInfo['deviceId'] ?? 'unknown',
      platform: deviceInfo['platform'] ?? 'unknown',
      osVersion: deviceInfo['osVersion'] ?? 'unknown',
      appVersion: deviceInfo['appVersion'] ?? '1.0.0',
      hardwareId: deviceInfo['hardware'] ?? 'unknown',
      combinedHash: combinedHash,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> storeDeviceFingerprint(DeviceFingerprint fingerprint) async {
    try {
      // Valider l'empreinte avant stockage
      if (!_isValidFingerprint(fingerprint)) {
        throw Exception('Empreinte d\'appareil invalide - données manquantes ou corrompues');
      }

      final jsonString = jsonEncode(fingerprint.toJson());

      // Stocker l'empreinte principale
      await _secureStorage.write(key: _fingerprintKey, value: jsonString);

      // Stocker également comme dernière empreinte connue pour la détection de changements
      await _secureStorage.write(key: _lastFingerprintKey, value: jsonString);

      // Stocker un checksum pour vérifier l'intégrité
      final checksum = _calculateChecksum(jsonString);
      await _secureStorage.write(key: '${_fingerprintKey}_checksum', value: checksum);

      debugPrint('Empreinte d\'appareil stockée avec succès');
    } catch (e) {
      debugPrint('Erreur lors du stockage de l\'empreinte: $e');
      rethrow;
    }
  }

  @override
  Future<DeviceFingerprint?> getStoredFingerprint() async {
    try {
      final jsonString = await _secureStorage.read(key: _fingerprintKey);
      if (jsonString == null) return null;

      // Vérifier l'intégrité des données stockées
      final storedChecksum = await _secureStorage.read(key: '${_fingerprintKey}_checksum');
      if (storedChecksum != null) {
        final calculatedChecksum = _calculateChecksum(jsonString);
        if (storedChecksum != calculatedChecksum) {
          debugPrint('Intégrité de l\'empreinte compromise - checksum invalide');
          // Nettoyer les données corrompues
          await clearStoredFingerprint();
          return null;
        }
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final fingerprint = DeviceFingerprint.fromJson(json);

      // Validation supplémentaire de cohérence
      if (!_isValidFingerprint(fingerprint)) {
        debugPrint('Empreinte stockée invalide - nettoyage nécessaire');
        await clearStoredFingerprint();
        return null;
      }

      return fingerprint;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'empreinte: $e');
      // En cas d'erreur de parsing, nettoyer les données corrompues
      await clearStoredFingerprint();
      return null;
    }
  }

  @override
  Future<bool> hasDeviceChanged() async {
    try {
      final storedFingerprint = await getStoredFingerprint();
      if (storedFingerprint == null) {
        // Pas d'empreinte stockée, considérer comme un nouvel appareil
        debugPrint('Aucune empreinte stockée - nouvel appareil détecté');
        return true;
      }

      // Vérifier si l'empreinte stockée est encore valide (pas trop ancienne)
      if (!storedFingerprint.isValid) {
        debugPrint('Empreinte stockée expirée - mise à jour nécessaire');
        return true;
      }

      final currentFingerprint = await createDeviceFingerprint();

      // Comparer les caractéristiques critiques avec tolérance
      final criticalMatch = _compareCriticalCharacteristics(storedFingerprint, currentFingerprint);

      // Si les caractéristiques critiques ne correspondent pas, l'appareil a changé
      if (!criticalMatch) {
        debugPrint('Changement d\'appareil détecté - caractéristiques critiques différentes');
        debugPrint('Stocké: ${storedFingerprint.deviceId} vs Actuel: ${currentFingerprint.deviceId}');
        return true;
      }

      // Vérifier le hash combiné pour une validation plus fine
      final hashMatch = await verifyDeviceFingerprint(storedFingerprint.combinedHash);
      if (!hashMatch) {
        debugPrint('Changement d\'appareil détecté - hash différent');
        return true;
      }

      debugPrint('Aucun changement d\'appareil détecté');
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la détection de changement d\'appareil: $e');
      // En cas d'erreur, considérer comme un changement par sécurité
      return true;
    }
  }

  @override
  Future<void> updateFingerprintIfNeeded() async {
    try {
      final hasChanged = await hasDeviceChanged();
      if (hasChanged) {
        debugPrint('Mise à jour de l\'empreinte d\'appareil nécessaire');

        // Sauvegarder l'ancienne empreinte pour audit si elle existe
        final oldFingerprint = await getStoredFingerprint();
        if (oldFingerprint != null) {
          await _archiveOldFingerprint(oldFingerprint);
        }

        final newFingerprint = await createDeviceFingerprint();
        await storeDeviceFingerprint(newFingerprint);

        debugPrint('Empreinte d\'appareil mise à jour avec succès');
        debugPrint('Nouvelle empreinte: ${newFingerprint.combinedHash.substring(0, 8)}...');
      } else {
        debugPrint('Aucune mise à jour d\'empreinte nécessaire');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'empreinte: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearStoredFingerprint() async {
    try {
      await _secureStorage.delete(key: _fingerprintKey);
      await _secureStorage.delete(key: _lastFingerprintKey);
      await _secureStorage.delete(key: '${_fingerprintKey}_checksum');
      await _secureStorage.delete(key: '${_fingerprintKey}_archive');
      debugPrint('Empreinte d\'appareil et données associées supprimées');
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'empreinte: $e');
      rethrow;
    }
  }

  /// Méthode utilitaire pour obtenir un résumé de l'appareil actuel
  Future<String> getDeviceSummary() async {
    final deviceInfo = await getDeviceInfo();
    return '${deviceInfo['brand']} ${deviceInfo['model']} (${deviceInfo['platform']}) - ${deviceInfo['osVersion']}';
  }

  /// Méthode pour valider l'intégrité de l'empreinte stockée
  Future<bool> validateStoredFingerprintIntegrity() async {
    try {
      final stored = await getStoredFingerprint();
      if (stored == null) return false;

      // Vérifier que l'empreinte n'est pas trop ancienne
      if (!stored.isValid) {
        debugPrint('Empreinte stockée expirée');
        return false;
      }

      // Vérifier la cohérence des données
      if (!_isValidFingerprint(stored)) {
        debugPrint('Empreinte stockée incomplète ou invalide');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la validation de l\'intégrité: $e');
      return false;
    }
  }

  /// Valide qu'une empreinte contient toutes les données requises
  bool _isValidFingerprint(DeviceFingerprint fingerprint) {
    return fingerprint.combinedHash.isNotEmpty &&
        fingerprint.deviceId.isNotEmpty &&
        fingerprint.platform.isNotEmpty &&
        fingerprint.osVersion.isNotEmpty &&
        fingerprint.hardwareId.isNotEmpty &&
        fingerprint.appVersion.isNotEmpty;
  }

  /// Calcule un checksum pour vérifier l'intégrité des données
  String _calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Compare les caractéristiques critiques avec tolérance pour les changements mineurs
  bool _compareCriticalCharacteristics(DeviceFingerprint stored, DeviceFingerprint current) {
    // Les caractéristiques qui ne doivent jamais changer
    final immutableMatch = stored.deviceId == current.deviceId && stored.platform == current.platform && stored.hardwareId == current.hardwareId;

    if (!immutableMatch) {
      return false;
    }

    // Tolérance pour les mises à jour d'OS et d'application
    // Ces changements sont normaux et ne doivent pas invalider l'empreinte
    return true;
  }

  /// Archive l'ancienne empreinte pour audit
  Future<void> _archiveOldFingerprint(DeviceFingerprint oldFingerprint) async {
    try {
      final archiveData = {'fingerprint': oldFingerprint.toJson(), 'archivedAt': DateTime.now().toIso8601String(), 'reason': 'device_change_detected'};

      final jsonString = jsonEncode(archiveData);
      await _secureStorage.write(key: '${_fingerprintKey}_archive', value: jsonString);

      debugPrint('Ancienne empreinte archivée pour audit');
    } catch (e) {
      debugPrint('Erreur lors de l\'archivage de l\'ancienne empreinte: $e');
      // Ne pas faire échouer le processus principal si l'archivage échoue
    }
  }

  /// Récupère l'empreinte archivée pour audit
  Future<Map<String, dynamic>?> getArchivedFingerprint() async {
    try {
      final jsonString = await _secureStorage.read(key: '${_fingerprintKey}_archive');
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'empreinte archivée: $e');
      return null;
    }
  }

  /// Effectue une vérification complète de cohérence
  Future<Map<String, dynamic>> performConsistencyCheck() async {
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'checks': <String, dynamic>{},
    };

    try {
      // Vérifier l'existence de l'empreinte stockée
      final stored = await getStoredFingerprint();
      result['checks']['fingerprint_exists'] = stored != null;

      if (stored != null) {
        // Vérifier la validité de l'empreinte
        result['checks']['fingerprint_valid'] = stored.isValid;
        result['checks']['fingerprint_complete'] = _isValidFingerprint(stored);

        // Vérifier la cohérence avec l'appareil actuel
        final hasChanged = await hasDeviceChanged();
        result['checks']['device_unchanged'] = !hasChanged;

        // Vérifier l'intégrité des données
        final integrityValid = await validateStoredFingerprintIntegrity();
        result['checks']['integrity_valid'] = integrityValid;

        // Informations sur l'empreinte
        result['fingerprint_info'] = {
          'platform': stored.platform,
          'generated_at': stored.generatedAt.toIso8601String(),
          'hash_preview': stored.combinedHash.substring(0, 8),
        };
      }

      // Vérifier l'existence d'une archive
      final archived = await getArchivedFingerprint();
      result['checks']['has_archive'] = archived != null;

      result['overall_status'] = _calculateOverallStatus(result['checks']);
    } catch (e) {
      result['error'] = e.toString();
      result['overall_status'] = 'error';
    }

    return result;
  }

  /// Calcule le statut global basé sur les vérifications
  String _calculateOverallStatus(Map<String, dynamic> checks) {
    if (checks['fingerprint_exists'] != true) {
      return 'no_fingerprint';
    }

    if (checks['fingerprint_valid'] != true || checks['fingerprint_complete'] != true || checks['integrity_valid'] != true) {
      return 'invalid_fingerprint';
    }

    if (checks['device_unchanged'] != true) {
      return 'device_changed';
    }

    return 'valid';
  }
}
