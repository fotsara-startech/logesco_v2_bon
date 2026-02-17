/// Interface pour les services cryptographiques
abstract class ICryptoService {
  /// Vérifie une signature RSA
  bool verifySignature(String data, String signature, String publicKey);

  /// Génère un hash sécurisé (SHA-256)
  String generateHash(String input);

  /// Chiffre des données avec AES
  String encryptData(String data, String key);

  /// Déchiffre des données AES
  String decryptData(String encryptedData, String key);

  /// Vérifie l'intégrité des données avec un checksum
  bool verifyIntegrity(String data, String checksum);

  /// Génère une clé de chiffrement aléatoire
  String generateRandomKey([int length = 32]);

  /// Encode en Base64
  String encodeBase64(List<int> bytes);

  /// Décode depuis Base64
  List<int> decodeBase64(String encoded);

  /// Génère un hash HMAC
  String generateHmac(String data, String key);

  /// Vérifie un hash HMAC
  bool verifyHmac(String data, String key, String expectedHmac);
}
