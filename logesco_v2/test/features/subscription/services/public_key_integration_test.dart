import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/services/implementations/crypto_service.dart';

void main() {
  group('CryptoService Public Key Integration', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoService();
    });

    test('should create crypto service instance', () {
      expect(cryptoService, isNotNull);
    });

    test('should verify signature with valid PEM format', () {
      const testData = 'test data';
      const testSignature = 'dGVzdCBzaWduYXR1cmU='; // base64 encoded "test signature"
      const validPemKey = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyKwQmX7OqiXQoGbwODjN
vEHlcjHt8RtJ9mK5pL3nF2wQ8xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9
oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6m
P4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ
3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9
oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6m
P4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ3xR7yN6mP4sT1vK9oL2nF8wQ
QIDAQAB
-----END PUBLIC KEY-----''';

      // This should not throw an exception and should return false for invalid signature
      final result = cryptoService.verifySignature(testData, testSignature, validPemKey);
      expect(result, isFalse); // Expected to be false since signature is invalid
    });

    test('should handle invalid PEM format gracefully', () {
      const testData = 'test data';
      const testSignature = 'dGVzdCBzaWduYXR1cmU=';
      const invalidPemKey = 'invalid key format';

      // Should not throw exception and return false
      final result = cryptoService.verifySignature(testData, testSignature, invalidPemKey);
      expect(result, isFalse);
    });

    test('should generate secure hash', () {
      const testInput = 'test input for hashing';

      final hash1 = cryptoService.generateHash(testInput);
      final hash2 = cryptoService.generateHash(testInput);

      expect(hash1, equals(hash2)); // Same input should produce same hash
      expect(hash1.length, equals(64)); // SHA-256 produces 64 character hex string
    });

    test('should verify data integrity', () {
      const testData = 'test data for integrity check';

      final checksum = cryptoService.generateHash(testData);
      final isValid = cryptoService.verifyIntegrity(testData, checksum);

      expect(isValid, isTrue);

      // Test with wrong checksum
      const wrongChecksum = 'wrong_checksum';
      final isInvalid = cryptoService.verifyIntegrity(testData, wrongChecksum);

      expect(isInvalid, isFalse);
    });

    test('should generate random keys', () {
      final key1 = cryptoService.generateRandomKey();
      final key2 = cryptoService.generateRandomKey();

      expect(key1, isNot(equals(key2))); // Should be different
      expect(key1.isNotEmpty, isTrue);
      expect(key2.isNotEmpty, isTrue);
    });

    test('should encrypt and decrypt data', () {
      const testData = 'sensitive data to encrypt';
      const encryptionKey = 'test_encryption_key_32_bytes_long';

      final encrypted = cryptoService.encryptData(testData, encryptionKey);
      expect(encrypted, isNot(equals(testData)));

      final decrypted = cryptoService.decryptData(encrypted, encryptionKey);
      expect(decrypted, equals(testData));
    });

    test('should generate and verify HMAC', () {
      const testData = 'data to authenticate';
      const hmacKey = 'hmac_secret_key';

      final hmac = cryptoService.generateHmac(testData, hmacKey);
      expect(hmac.isNotEmpty, isTrue);

      final isValid = cryptoService.verifyHmac(testData, hmacKey, hmac);
      expect(isValid, isTrue);

      // Test with wrong HMAC
      const wrongHmac = 'wrong_hmac_value';
      final isInvalid = cryptoService.verifyHmac(testData, hmacKey, wrongHmac);
      expect(isInvalid, isFalse);
    });
  });
}
