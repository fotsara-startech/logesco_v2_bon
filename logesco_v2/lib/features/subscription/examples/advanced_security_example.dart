import '../services/implementations/advanced_security_service.dart';
import '../services/implementations/security_validator.dart';
import '../services/implementations/code_obfuscator.dart';

/// Exemple d'utilisation des mesures de sécurité avancées
/// Démontre l'intégration de la détection anti-contournement et de l'obfuscation
class AdvancedSecurityExample {
  late final AdvancedSecurityService _securityService;
  late final SecurityValidator _validator;
  late final CodeObfuscator _obfuscator;
  
  AdvancedSecurityExample() {
    _validator = SecurityValidator();
    _obfuscator = CodeObfuscator();
    _securityService = AdvancedSecurityService(
      securityValidator: _validator,
      codeObfuscator: _obfuscator,
    );
  }
  
  /// Démontre l'initialisation de la protection avancée
  Future<void> demonstrateSecurityInitialization() async {
    print('=== Initialisation de la Protection Avancée ===');
    
    // Initialisation du système de sécurité
    final isSecure = await _securityService.initializeAdvancedProtection();
    
    if (isSecure) {
      print(' Système de sécurité initialisé avec succès');
      print(' Environnement validé comme sécurisé');
    } else {
      print(' Échec de l\'initialisation - Environnement non sécurisé');
      return;
    }
    
    // Vérification détaillée de sécurité
    final securityResult = await _validator.performFullSecurityCheck();
    print('Résultat de sécurité: ');
    
    if (securityResult.threats.isNotEmpty) {
      print('Menaces détectées:');
      for (final threat in securityResult.threats) {
        final criticality = threat.isCritical ? "CRITIQUE" : "MINEURE";
        print('  -  []');
      }
    }
    
    print('Détails: ');
  }
  
  /// Démontre l'obfuscation de données sensibles
  Future<void> demonstrateDataObfuscation() async {
    print('\n=== Démonstration de l\'Obfuscation ===');
    
    // Données sensibles à protéger
    const sensitiveData = 'LICENSE_KEY_ABC123XYZ789';
    const cryptoKey = 'CRYPTO_SECRET_KEY_2024';
    
    print('Données originales: ');
    
    // Obfuscation des données
    final obfuscatedData = _obfuscator.obfuscateString(sensitiveData);
    print('Données obfusquées: ');
    
    // Désobfuscation pour vérification
    final deobfuscatedData = _obfuscator.deobfuscateString(obfuscatedData);
    print('Données désobfusquées: ');
    print('Intégrité: ');
    
    // Obfuscation de clé cryptographique
    print('\nClé crypto originale: ');
    final obfuscatedKey = _obfuscator.obfuscateKey(cryptoKey);
    print('Clé obfusquée: ');
    
    // Génération de nom de méthode obfusqué
    const methodName = 'validateLicense';
    final obfuscatedMethod = _obfuscator.obfuscateMethodName(methodName);
    print('Nom de méthode obfusqué:  -> ');
  }
  
  /// Démontre la validation sécurisée de licence
  Future<void> demonstrateSecureLicenseValidation() async {
    print('\n=== Validation Sécurisée de Licence ===');
    
    // Simulation d'une licence valide
    const validLicense = 'VALID_LICENSE_DATA_WITH_CHECKSUM_123456789ABC';
    final obfuscatedLicense = _obfuscator.obfuscateString(validLicense);
    
    print('Validation de licence en cours...');
    
    // Validation avec protection anti-debug
    final isValid = await _securityService.validateLicenseSecurely(obfuscatedLicense);
    
    if (isValid) {
      print(' Licence validée avec succès');
      
      // Génération d'une clé de session sécurisée
      final sessionKey = _securityService.generateSecureSessionKey();
      print('Clé de session générée: ...');
      
    } else {
      print(' Échec de la validation de licence');
    }
  }
  
  /// Démontre le chiffrement de données sensibles
  Future<void> demonstrateSensitiveDataEncryption() async {
    print('\n=== Chiffrement de Données Sensibles ===');
    
    const sensitiveInfo = 'User credentials and payment information';
    print('Données à chiffrer: ');
    
    // Chiffrement avec protection multicouche
    final encryptedData = _securityService.encryptSensitiveData(sensitiveInfo);
    print('Données chiffrées: ...');
    
    // Déchiffrement sécurisé
    final decryptedData = await _securityService.decryptSensitiveData(encryptedData);
    
    if (decryptedData != null) {
      print('Données déchiffrées: ');
      print('Intégrité: ');
    } else {
      print(' Échec du déchiffrement - Environnement non sécurisé');
    }
  }
  
  /// Démontre la détection anti-contournement
  Future<void> demonstrateAntiTamperingDetection() async {
    print('\n=== Détection Anti-Contournement ===');
    
    // Vérification de débogueur
    final debuggerDetected = await _validator.isDebuggerAttached();
    print('Débogueur détecté: ');
    
    // Vérification d'émulateur
    final emulatorDetected = await _validator.isEmulator();
    print('Émulateur détecté: ');
    
    // Vérification de root/jailbreak
    final rootDetected = await _validator.isRooted();
    print('Root/Jailbreak détecté: ');
    
    // Vérification d'intégrité du code
    final integrityValid = await _validator.verifyCodeIntegrity();
    print('Intégrité du code: ');
    
    // Vérification de manipulation
    final tamperingDetected = await _validator.detectTampering();
    print('Manipulation détectée: ');
    
    // Vérification de l'intégrité de l'obfuscation
    final obfuscationIntegrity = _obfuscator.verifyObfuscationIntegrity();
    print('Intégrité obfuscation: ');
  }
  
  /// Exécute tous les exemples de sécurité avancée
  Future<void> runAllSecurityExamples() async {
    print(' DÉMONSTRATION DES MESURES DE SÉCURITÉ AVANCÉES \n');
    
    try {
      await demonstrateSecurityInitialization();
      await demonstrateDataObfuscation();
      await demonstrateSecureLicenseValidation();
      await demonstrateSensitiveDataEncryption();
      await demonstrateAntiTamperingDetection();
      
      print('\n Démonstration terminée avec succès!');
      
    } catch (e) {
      print('\n Erreur lors de la démonstration: ');
    }
  }
}

/// Point d'entrée pour tester les mesures de sécurité avancées
Future<void> main() async {
  final example = AdvancedSecurityExample();
  await example.runAllSecurityExamples();
}
