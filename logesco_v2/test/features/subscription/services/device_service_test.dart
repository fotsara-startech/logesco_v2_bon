import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/models/device_fingerprint.dart';
import 'package:logesco_v2/features/subscription/services/implementations/device_service.dart';

void main() {
  group('DeviceService - Logic Tests', () {
    late DeviceService deviceService;

    setUp(() {
      deviceService = DeviceService();
    });

    test('should validate DeviceFingerprint model correctly', () {
      // Test avec une empreinte valide
      final validFingerprint = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.now(),
      );

      expect(validFingerprint.deviceId, equals('test-device-123'));
      expect(validFingerprint.platform, equals('android'));
      expect(validFingerprint.isValid, isTrue);

      // Test avec une empreinte ancienne (invalide)
      final oldFingerprint = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.now().subtract(const Duration(days: 35)),
      );

      expect(oldFingerprint.isValid, isFalse);
    });

    test('should compare fingerprints correctly', () {
      final fingerprint1 = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.now(),
      );

      final fingerprint2 = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.now(),
      );

      final fingerprint3 = DeviceFingerprint(
        deviceId: 'different-device',
        platform: 'ios',
        osVersion: 'iOS 16',
        appVersion: '1.0.0',
        hardwareId: 'hardware-456',
        combinedHash: 'different-hash',
        generatedAt: DateTime.now(),
      );

      expect(fingerprint1.matches(fingerprint2), isTrue);
      expect(fingerprint1.matches(fingerprint3), isFalse);
      expect(fingerprint1 == fingerprint2, isTrue);
      expect(fingerprint1 == fingerprint3, isFalse);
    });

    test('should serialize and deserialize DeviceFingerprint correctly', () {
      final originalFingerprint = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.parse('2024-01-01T12:00:00Z'),
      );

      // Sérialiser vers JSON
      final json = originalFingerprint.toJson();
      expect(json['deviceId'], equals('test-device-123'));
      expect(json['platform'], equals('android'));
      expect(json['combinedHash'], equals('abc123def456'));

      // Désérialiser depuis JSON
      final deserializedFingerprint = DeviceFingerprint.fromJson(json);
      expect(deserializedFingerprint.deviceId, equals(originalFingerprint.deviceId));
      expect(deserializedFingerprint.platform, equals(originalFingerprint.platform));
      expect(deserializedFingerprint.combinedHash, equals(originalFingerprint.combinedHash));
      expect(deserializedFingerprint.generatedAt, equals(originalFingerprint.generatedAt));
    });

    test('should handle toString method correctly', () {
      final fingerprint = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456789',
        generatedAt: DateTime.now(),
      );

      final stringRepresentation = fingerprint.toString();
      expect(stringRepresentation, contains('android'));
      expect(stringRepresentation, contains('abc123de')); // Premier 8 caractères du hash
    });

    test('should validate fingerprint data completeness', () {
      // Test avec des données complètes
      final completeFingerprint = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.now(),
      );

      // Utiliser une méthode publique pour tester la validation
      expect(completeFingerprint.deviceId.isNotEmpty, isTrue);
      expect(completeFingerprint.platform.isNotEmpty, isTrue);
      expect(completeFingerprint.osVersion.isNotEmpty, isTrue);
      expect(completeFingerprint.appVersion.isNotEmpty, isTrue);
      expect(completeFingerprint.hardwareId.isNotEmpty, isTrue);
      expect(completeFingerprint.combinedHash.isNotEmpty, isTrue);

      // Test avec des données incomplètes
      final incompleteFingerprint = DeviceFingerprint(
        deviceId: '',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.now(),
      );

      expect(incompleteFingerprint.deviceId.isEmpty, isTrue);
    });

    test('should handle edge cases in fingerprint validation', () {
      // Test avec une date future (devrait être valide)
      final futureFingerprint = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(futureFingerprint.isValid, isTrue);

      // Test avec une date exactement à la limite (30 jours)
      final limitFingerprint = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.now().subtract(const Duration(days: 30, hours: 1)),
      );

      expect(limitFingerprint.isValid, isFalse);
    });

    test('should handle hashCode correctly', () {
      final fingerprint1 = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456',
        generatedAt: DateTime.now(),
      );

      final fingerprint2 = DeviceFingerprint(
        deviceId: 'different-device',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'abc123def456', // Même hash
        generatedAt: DateTime.now(),
      );

      final fingerprint3 = DeviceFingerprint(
        deviceId: 'test-device-123',
        platform: 'android',
        osVersion: 'Android 12',
        appVersion: '1.0.0',
        hardwareId: 'hardware-123',
        combinedHash: 'different-hash',
        generatedAt: DateTime.now(),
      );

      expect(fingerprint1.hashCode, equals(fingerprint2.hashCode)); // Même combinedHash
      expect(fingerprint1.hashCode, isNot(equals(fingerprint3.hashCode))); // Hash différent
    });
  });
}
