import 'exceptions.dart';

/// Traduit les erreurs techniques en messages compréhensibles par l'utilisateur.
///
/// Avant : « Impossible de charger les alertes: Exception: Erreur de connexion: FormatException: SyntaxError:
/// Unexpected token 'T', "Trop de re"... is not valid JSON ». L'utilisateur n'y apprend ni ce qui s'est passé, ni quoi
/// faire. Chaque message dit maintenant la situation en une phrase et l'action à mener.
class FriendlyError {
  static const String surcharge = 'Le serveur reçoit trop de demandes en ce moment. Patientez quelques secondes, puis réessayez.';
  static const String reseau = 'Impossible de joindre le serveur. Vérifiez votre connexion internet, puis réessayez.';
  static const String delai = 'Le serveur met trop de temps à répondre. Vérifiez votre connexion, puis réessayez.';
  static const String reponse = 'Le serveur a renvoyé une réponse inattendue. Réessayez dans un instant ; si cela continue, contactez le support.';
  static const String serveur = 'Le serveur rencontre un problème momentané. Réessayez dans un instant ; si cela continue, contactez le support.';
  static const String session = 'Votre session a expiré. Reconnectez-vous.';
  static const String droits = "Vous n'avez pas le droit d'effectuer cette action.";

  /// Explication claire pour un code HTTP (null s'il n'y a rien de plus utile que le message du serveur)
  static String? pourStatut(int statut) {
    if (statut == 429) return surcharge;
    if (statut == 401) return session;
    if (statut == 403) return droits;
    if (statut == 408 || statut == 504) return delai;
    if (statut >= 500 && statut < 600) return serveur;
    return null;
  }

  // Les motifs sont testés dans cet ordre : le plus précis d'abord
  static final List<MapEntry<RegExp, String>> _motifs = [
    // « trop de re » : le texte est souvent tronqué (« Unexpected token 'T', "Trop de re"... is not valid JSON »)
    MapEntry(RegExp(r'\b429\b|trop de re|too many requests|rate.?limit|rate_limited'), surcharge),
    MapEntry(RegExp(r'timeoutexception|timed out|deadline exceeded|délai d.attente'), delai),
    MapEntry(
      RegExp(r'failed to fetch|socketexception|clientexception|failed host lookup|connection (refused|closed|reset|failed|error)|network is unreachable|no route to host|xmlhttprequest|handshakeexception|pas de connexion internet|no_internet'),
      reseau,
    ),
    MapEntry(RegExp(r'formatexception|unexpected token|is not valid json|syntaxerror|unexpected character|unexpected end of input|parse_error|erreur de format de réponse'), reponse),
    MapEntry(RegExp(r'status[: ]+401|\(401\)'), session),
    MapEntry(RegExp(r'status[: ]+403|\(403\)'), droits),
    MapEntry(RegExp(r'status[: ]+5\d\d|\(5\d\d\)|internal server error|bad gateway|service unavailable|gateway time-?out'), serveur),
  ];

  /// Explication claire si le texte contient une cause technique reconnue, sinon null
  static String? explication(String texte) {
    final t = texte.toLowerCase();
    for (final m in _motifs) {
      if (m.key.hasMatch(t)) return m.value;
    }
    return null;
  }

  /// Message lisible pour n'importe quelle erreur (ApiException, Exception, texte).
  /// [contexte] : ce que l'on essayait de faire (« Impossible de charger les alertes »).
  static String message(Object? erreur, {String? contexte}) {
    String propre;
    if (erreur is ApiException) {
      // Le statut HTTP est plus fiable que le texte : « Erreur de communication avec le serveur (502) »
      propre = pourStatut(erreur.statusCode) ?? nettoyer(erreur.message);
    } else {
      propre = nettoyer(erreur?.toString() ?? '');
    }
    if (propre.isEmpty) propre = 'Une erreur est survenue. Réessayez dans un instant.';
    return contexte == null || contexte.isEmpty ? propre : '$contexte. $propre';
  }

  /// Nettoie un message déjà composé, comme « Impossible de charger les stocks: Exception: Erreur de connexion:
  /// ClientException: Failed to fetch, uri=... » : la cause technique est remplacée par une explication, et le début
  /// du message (ce que l'on faisait) est conservé.
  static String nettoyer(String texte) {
    final sansPrefixe = texte.replaceAll('Exception: ', '').replaceAll('ApiException: ', '').trim();
    final cause = explication(sansPrefixe);
    // Le suffixe « (Code: X, Status: 404) » d'une ApiException est du jargon : il sert à détecter la cause, pas à l'affichage
    final affichable = sansPrefixe.replaceAll(RegExp(r'\s*\(Code: [^)]*\)'), '').trim();
    if (cause == null) return affichable;
    if (affichable.contains(cause)) return affichable; // déjà clair

    // « Impossible de charger les alertes: <technique> » → on garde « Impossible de charger les alertes »
    final i = affichable.indexOf(': ');
    if (i > 0 && i <= 80) {
      final debut = affichable.substring(0, i).trim();
      if (debut.isNotEmpty &&
          !debut.contains('(') &&
          explication(debut) == null &&
          !debut.toLowerCase().startsWith('erreur de connexion') &&
          !debut.toLowerCase().startsWith('erreur inattendue')) {
        return '$debut. $cause';
      }
    }
    return cause;
  }
}
