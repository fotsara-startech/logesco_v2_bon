import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../interfaces/i_code_obfuscator.dart';

/// Implémentation du service d'obfuscation de code
/// Protège les éléments critiques contre le reverse engineering
class CodeObfuscator implements ICodeObfuscator {
  static const String _obfuscationKey = 'ObF_K3y_2024_S3cur3';
  static const List<String> _dummyStrings = [
    'dummy_operation_1',
    'fake_validation_check',
    'decoy_security_method',
    'phantom_license_verify',
  ];
  
  final Random _random = Random.secure();
  
  @override
  String obfuscateString(String input) {
    if (input.isEmpty) return input;
    
    try {
      // Conversion en bytes
      final inputBytes = utf8.encode(input);
      final keyBytes = utf8.encode(_obfuscationKey);
      
      // XOR avec la clé
      final obfuscatedBytes = <int>[];
      for (int i = 0; i < inputBytes.length; i++) {
        obfuscatedBytes.add(inputBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      // Encodage en base64 avec padding aléatoire
      final randomPrefix = _generateRandomBytes(4);
      final randomSuffix = _generateRandomBytes(4);
      
      final finalBytes = [...randomPrefix, ...obfuscatedBytes, ...randomSuffix];
      return base64.encode(finalBytes);
    } catch (e) {
      // Fallback: simple rotation
      return _simpleRotationObfuscation(input);
    }
  }
  
  @override
  String deobfuscateString(String obfuscated) {
    if (obfuscated.isEmpty) return obfuscated;
    
    try {
      // Décodage base64
      final decodedBytes = base64.decode(obfuscated);
      
      // Suppression du padding (4 bytes au début et à la fin)
      if (decodedBytes.length < 8) {
        return _simpleRotationDeobfuscation(obfuscated);
      }
      
      final actualBytes = decodedBytes.sublist(4, decodedBytes.length - 4);
      final keyBytes = utf8.encode(_obfuscationKey);
      
      // XOR inverse
      final originalBytes = <int>[];
      for (int i = 0; i < actualBytes.length; i++) {
        originalBytes.add(actualBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(originalBytes);
    } catch (e) {
      // Fallback: simple rotation inverse
      return _simpleRotationDeobfuscation(obfuscated);
    }
  }
  
  @override
  String obfuscateKey(String key) {
    // Obfuscation spéciale pour les clés cryptographiques
    final hash = sha256.convert(utf8.encode(key + _obfuscationKey));
    final hashString = hash.toString();
    
    // Mélange des caractères avec un pattern spécifique
    final chars = hashString.split('');
    final obfuscatedChars = <String>[];
    
    for (int i = 0; i < chars.length; i += 2) {
      if (i + 1 < chars.length) {
        obfuscatedChars.add(chars[i + 1]);
        obfuscatedChars.add(chars[i]);
      } else {
        obfuscatedChars.add(chars[i]);
      }
    }
    
    return base64.encode(utf8.encode(obfuscatedChars.join()));
  }
  
  @override
  String deobfuscateKey(String obfuscatedKey) {
    try {
      final decoded = utf8.decode(base64.decode(obfuscatedKey));
      final chars = decoded.split('');
      final originalChars = <String>[];
      
      // Inverse du mélange
      for (int i = 0; i < chars.length; i += 2) {
        if (i + 1 < chars.length) {
          originalChars.add(chars[i + 1]);
          originalChars.add(chars[i]);
        } else {
          originalChars.add(chars[i]);
        }
      }
      
      return originalChars.join();
    } catch (e) {
      return obfuscatedKey;
    }
  }
  
  @override
  String obfuscateMethodName(String methodName) {
    // Génération d'un nom de méthode obfusqué mais valide
    final hash = sha256.convert(utf8.encode(methodName));
    final hashHex = hash.toString().substring(0, 8);
    
    return 'm__';
  }
  
  @override
  T applyAntiDebugTransform<T>(T Function() operation) {
    // Insertion de code anti-debug
    _performDummyOperations();
    
    // Vérification de timing pour détecter le débogage
    final startTime = DateTime.now().millisecondsSinceEpoch;
    
    final result = operation();
    
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final executionTime = endTime - startTime;
    
    // Si l'exécution prend trop de temps, c'est suspect
    if (executionTime > 1000) {
      _performDummyOperations();
    }
    
    return result;
  }
  
  @override
  bool verifyObfuscationIntegrity() {
    try {
      // Test de l'obfuscation/désobfuscation
      const testString = 'integrity_test_string';
      final obfuscated = obfuscateString(testString);
      final deobfuscated = deobfuscateString(obfuscated);
      
      if (deobfuscated != testString) {
        return false;
      }
      
      // Test de l'obfuscation des clés
      const testKey = 'test_key_123';
      final obfuscatedKey = obfuscateKey(testKey);
      
      // Vérification que la clé est bien obfusquée
      if (obfuscatedKey == testKey || obfuscatedKey.isEmpty) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Génère des bytes aléatoires pour le padding
  List<int> _generateRandomBytes(int length) {
    final bytes = <int>[];
    for (int i = 0; i < length; i++) {
      bytes.add(_random.nextInt(256));
    }
    return bytes;
  }
  
  /// Obfuscation simple par rotation (fallback)
  String _simpleRotationObfuscation(String input) {
    final chars = input.split('');
    final rotated = chars.map((char) {
      final code = char.codeUnitAt(0);
      return String.fromCharCode((code + 13) % 256);
    }).join();
    
    return base64.encode(utf8.encode(rotated));
  }
  
  /// Désobfuscation simple par rotation (fallback)
  String _simpleRotationDeobfuscation(String obfuscated) {
    try {
      final decoded = utf8.decode(base64.decode(obfuscated));
      final chars = decoded.split('');
      
      return chars.map((char) {
        final code = char.codeUnitAt(0);
        return String.fromCharCode((code - 13) % 256);
      }).join();
    } catch (e) {
      return obfuscated;
    }
  }
  
  /// Effectue des opérations factices pour confondre l'analyse
  void _performDummyOperations() {
    // Opérations factices pour augmenter la complexité
    var dummy = 0;
    for (int i = 0; i < 10; i++) {
      dummy += _random.nextInt(100);
      dummy = dummy.hashCode;
    }
    
    // Utilisation des chaînes factices
    for (final dummyString in _dummyStrings) {
      final hash = sha256.convert(utf8.encode(dummyString + dummy.toString()));
      dummy ^= hash.hashCode;
    }
  }
}

/// Mixin pour ajouter des capacités d'obfuscation aux classes critiques
mixin ObfuscationMixin {
  static final CodeObfuscator _obfuscator = CodeObfuscator();
  
  /// Protège une chaîne sensible
  String protectString(String sensitive) {
    return _obfuscator.obfuscateString(sensitive);
  }
  
  /// Récupère une chaîne protégée
  String retrieveString(String protected) {
    return _obfuscator.deobfuscateString(protected);
  }
  
  /// Protège une clé cryptographique
  String protectKey(String key) {
    return _obfuscator.obfuscateKey(key);
  }
  
  /// Exécute une opération critique avec protection anti-debug
  T executeProtected<T>(T Function() operation) {
    return _obfuscator.applyAntiDebugTransform(operation);
  }
}
