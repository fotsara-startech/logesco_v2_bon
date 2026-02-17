import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/models/models.dart';

void main() {
  group('LicenseKeyPayload', () {
    test('should create valid payload from JSON', () {
      final json = {
        'userId': 'user123',
        'type': 'monthly',
        'issued': '2024-01-01T00:00:00.000Z',
        'expires': '2024-02-01T00:00:00.000Z',
        'device': 'device_hash_123',
        'features': ['feature1', 'feature2'],
        'signature': 'rsa_signature_123',
      };

      final payload = LicenseKeyPayload.fromJson(json);

      expect(payload.userId, equals('user123'));
      expect(payload.subscriptionType, equals('monthly'));
      expect(payload.issued, equals('2024-01-01T00:00:00.000Z'));
      expect(payload.expires, equals('2024-02-01T00:00:00.000Z'));
      expect(payload.device, equals('device_hash_123'));
      expect(payload.features, equals(['feature1', 'feature2']));
      expect(payload.signature, equals('rsa_signature_123'));
    });

    test('should validate payload correctly', () {
      final validPayload = LicenseKeyPayload(
        userId: 'user123',
        subscriptionType: 'monthly',
        issued: '2024-01-01T00:00:00.000Z',
        expires: '2024-02-01T00:00:00.000Z',
        device: 'device_hash',
        features: ['feature1'],
        signature: 'signature',
      );

      expect(validPayload.isValid(), isTrue);

      final invalidPayload = LicenseKeyPayload(
        userId: '',
        subscriptionType: 'invalid_type',
        issued: 'invalid_date',
        expires: '2024-02-01T00:00:00.000Z',
        device: 'device_hash',
        features: [],
        signature: '',
      );

      expect(invalidPayload.isValid(), isFalse);
    });

    test('should convert to and from LicenseData', () {
      final licenseData = LicenseData(
        userId: 'user123',
        licenseKey: 'test_key',
        subscriptionType: SubscriptionType.monthly,
        issuedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        expiresAt: DateTime.parse('2024-02-01T00:00:00.000Z'),
        deviceFingerprint: 'device_hash',
        signature: 'signature',
        metadata: {
          'features': ['feature1', 'feature2']
        },
      );

      final payload = LicenseKeyPayload.fromLicenseData(licenseData);
      final convertedBack = payload.toLicenseData('test_key');

      expect(convertedBack.userId, equals(licenseData.userId));
      expect(convertedBack.subscriptionType, equals(licenseData.subscriptionType));
      expect(convertedBack.issuedAt, equals(licenseData.issuedAt));
      expect(convertedBack.expiresAt, equals(licenseData.expiresAt));
      expect(convertedBack.deviceFingerprint, equals(licenseData.deviceFingerprint));
      expect(convertedBack.signature, equals(licenseData.signature));
    });
  });

  group('LicenseKeyUtils', () {
    test('should validate key format correctly', () {
      const validKey = 'LOGESCO_V1_eyJ0ZXN0IjoidmFsdWUifQ==';
      const invalidKey1 = 'INVALID_KEY';
      const invalidKey2 = 'LOGESCO_V2_invalid';
      const invalidKey3 = '';

      expect(LicenseKeyUtils.isValidKeyFormat(validKey), isTrue);
      expect(LicenseKeyUtils.isValidKeyFormat(invalidKey1), isFalse);
      expect(LicenseKeyUtils.isValidKeyFormat(invalidKey2), isFalse);
      expect(LicenseKeyUtils.isValidKeyFormat(invalidKey3), isFalse);
    });

    test('should encode and decode payload correctly', () {
      final payload = LicenseKeyPayload(
        userId: 'user123',
        subscriptionType: 'monthly',
        issued: '2024-01-01T00:00:00.000Z',
        expires: '2024-02-01T00:00:00.000Z',
        device: 'device_hash',
        features: ['feature1'],
        signature: 'signature',
      );

      final encodedKey = LicenseKeyUtils.encodePayload(payload);
      expect(encodedKey.startsWith('LOGESCO_V1_'), isTrue);

      final decodedPayload = LicenseKeyUtils.decodePayload(encodedKey);
      expect(decodedPayload, isNotNull);
      expect(decodedPayload!.userId, equals(payload.userId));
      expect(decodedPayload.subscriptionType, equals(payload.subscriptionType));
      expect(decodedPayload.device, equals(payload.device));
    });

    test('should generate complete license key', () {
      final licenseKey = LicenseKeyUtils.generateLicenseKey(
        userId: 'user123',
        subscriptionType: SubscriptionType.monthly,
        issuedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        expiresAt: DateTime.parse('2024-02-01T00:00:00.000Z'),
        deviceFingerprint: 'device_hash',
        signature: 'signature',
        features: ['feature1', 'feature2'],
      );

      expect(licenseKey.startsWith('LOGESCO_V1_'), isTrue);
      expect(LicenseKeyUtils.isValidKeyFormat(licenseKey), isTrue);

      final metadata = LicenseKeyUtils.extractKeyMetadata(licenseKey);
      expect(metadata, isNotNull);
      expect(metadata!['userId'], equals('user123'));
      expect(metadata['type'], equals('monthly'));
    });

    test('should validate license key with expiration', () {
      // Test with expired key
      final expiredKey = LicenseKeyUtils.generateLicenseKey(
        userId: 'user123',
        subscriptionType: SubscriptionType.monthly,
        issuedAt: DateTime.now().subtract(const Duration(days: 60)),
        expiresAt: DateTime.now().subtract(const Duration(days: 30)),
        deviceFingerprint: 'device_hash',
        signature: 'signature',
      );

      final expiredResult = LicenseKeyUtils.validateLicenseKey(expiredKey);
      expect(expiredResult.isValid, isFalse);
      expect(expiredResult.isExpired, isTrue);

      // Test with valid key
      final validKey = LicenseKeyUtils.generateLicenseKey(
        userId: 'user123',
        subscriptionType: SubscriptionType.monthly,
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        deviceFingerprint: 'device_hash',
        signature: 'signature',
      );

      final validResult = LicenseKeyUtils.validateLicenseKey(validKey);
      expect(validResult.isValid, isTrue);
      expect(validResult.payload, isNotNull);
    });
  });

  group('LicenseKeyValidationResult', () {
    test('should create valid result', () {
      final payload = LicenseKeyPayload(
        userId: 'user123',
        subscriptionType: 'monthly',
        issued: '2024-01-01T00:00:00.000Z',
        expires: '2024-02-01T00:00:00.000Z',
        device: 'device_hash',
        features: [],
        signature: 'signature',
      );

      final result = LicenseKeyValidationResult.valid(payload);
      expect(result.isValid, isTrue);
      expect(result.payload, equals(payload));
      expect(result.errorMessage, isNull);
      expect(result.isExpired, isFalse);
    });

    test('should create invalid result', () {
      final result = LicenseKeyValidationResult.invalid('Test error');
      expect(result.isValid, isFalse);
      expect(result.payload, isNull);
      expect(result.errorMessage, equals('Test error'));
      expect(result.isExpired, isFalse);
    });

    test('should create expired result', () {
      final result = LicenseKeyValidationResult.expired('Key expired');
      expect(result.isValid, isFalse);
      expect(result.payload, isNull);
      expect(result.errorMessage, equals('Key expired'));
      expect(result.isExpired, isTrue);
    });
  });
}
