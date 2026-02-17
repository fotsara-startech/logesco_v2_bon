/// Service d'obfuscation pour protéger le code critique
/// Applique diverses techniques de protection contre le reverse engineering
abstract class ICodeObfuscator {
  /// Obfusque une chaîne de caractères sensible
  String obfuscateString(String input);
  
  /// Désobfusque une chaîne de caractères
  String deobfuscateString(String obfuscated);
  
  /// Obfusque une clé cryptographique
  String obfuscateKey(String key);
  
  /// Désobfusque une clé cryptographique
  String deobfuscateKey(String obfuscatedKey);
  
  /// Génère un identifiant obfusqué pour une méthode
  String obfuscateMethodName(String methodName);
  
  /// Applique une transformation anti-debug
  T applyAntiDebugTransform<T>(T Function() operation);
  
  /// Vérifie l'intégrité du code obfusqué
  bool verifyObfuscationIntegrity();
}

/// Techniques d'obfuscation disponibles
enum ObfuscationTechnique {
  stringEncryption,
  keyScrambling,
  controlFlowObfuscation,
  deadCodeInsertion,
  nameMangling,
}
