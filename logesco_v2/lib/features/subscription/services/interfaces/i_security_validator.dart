/// Interface pour le service de validation de sécurité
/// Responsable de la détection des tentatives de contournement
abstract class ISecurityValidator {
  /// Vérifie si l'environnement d'exécution est sécurisé
  Future<bool> validateEnvironment();

  /// Détecte si un débogueur est attaché à l'application
  Future<bool> isDebuggerAttached();

  /// Vérifie si l'application s'exécute sur un émulateur
  Future<bool> isEmulator();

  /// Détecte si l'appareil est rooté/jailbreaké
  Future<bool> isRooted();

  /// Vérifie l'intégrité du code de l'application
  Future<bool> verifyCodeIntegrity();

  /// Détecte les tentatives de manipulation des fichiers critiques
  Future<bool> detectTampering();

  /// Vérifie la signature de l'application
  Future<bool> verifyAppSignature();

  /// Effectue une validation complète de sécurité
  Future<SecurityValidationResult> performFullSecurityCheck();
}

/// Résultat de la validation de sécurité
class SecurityValidationResult {
  final bool isSecure;
  final List<SecurityThreat> threats;
  final String? details;

  const SecurityValidationResult({
    required this.isSecure,
    required this.threats,
    this.details,
  });

  /// Retourne true si aucune menace critique n'est détectée
  bool get isSafe => threats.where((t) => t.isCritical).isEmpty;
}

/// Types de menaces de sécurité détectées
enum SecurityThreat {
  debuggerAttached(true),
  emulatorDetected(true),
  rootDetected(true),
  codeIntegrityFailure(true),
  tamperingDetected(true),
  invalidSignature(true),
  suspiciousEnvironment(false);

  const SecurityThreat(this.isCritical);

  final bool isCritical;
}
