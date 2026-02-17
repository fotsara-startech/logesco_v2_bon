import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/services/implementations/crypto_service.dart';

void main() {
  group('CryptoService Tests', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoService();
    });

    test('should generate SHA-256 hash correctly', () {
      const testData = 'Hello, World!';
      final hash = cryptoService.generateHash(testData);

      expect(hash, isNotEmpty);
      expect(hash.length, equals(64)); // SHA-256 produces 64 character hex string
    });

    test('should generate random keys of correct length', () {
      final key1 = cryptoService.generateRandomKey();
      final key2 = cryptoService.generateRandomKey(16);

      expect(key1, isNotEmpty);
      expect(key2, isNotEmpty);
      expect(key1, isNot(equals(key2))); // Should be different
    });

    test('should encrypt and decrypt data correctly', () {
      const testData = 'This is a test message for encryption';
      const testKey = 'my-secret-key-for-testing-purposes';

      final encrypted = cryptoService.encryptData(testData, testKey);
      final decrypted = cryptoService.decryptData(encrypted, testKey);

      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(testData))); // Should be different from original
      expect(decrypted, equals(testData)); // Should match original after decryption
    });

    test('should verify data integrity correctly', () {
      const testData = 'Test data for integrity check';
      final checksum = cryptoService.generateHash(testData);

      expect(cryptoService.verifyIntegrity(testData, checksum), isTrue);
      expect(cryptoService.verifyIntegrity('Modified data', checksum), isFalse);
    });

    test('should generate and verify HMAC correctly', () {
      const testData = 'Test data for HMAC';
      const testKey = 'hmac-secret-key';

      final hmac = cryptoService.generateHmac(testData, testKey);

      expect(cryptoService.verifyHmac(testData, testKey, hmac), isTrue);
      expect(cryptoService.verifyHmac('Modified data', testKey, hmac), isFalse);
    });

    test('should encode and decode Base64 correctly', () {
      final testBytes = [72, 101, 108, 108, 111]; // "Hello" in ASCII
      final encoded = cryptoService.encodeBase64(testBytes);
      final decoded = cryptoService.decodeBase64(encoded);

      expect(encoded, equals('SGVsbG8='));
      expect(decoded, equals(testBytes));
    });
  });
}
