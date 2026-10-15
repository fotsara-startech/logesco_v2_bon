import 'license_data.dart';
import 'subscription_status.dart';

/// Pourquoi l'écran de blocage s'affiche : un message précis évite de prendre une licence perdue pour une licence expirée
enum BlockingReason { suspectDate, graceEnded, licenseExpired, noValidLicense }

/// Détermine le motif du blocage à partir du statut calculé
BlockingReason blockingReasonOf(SubscriptionStatus? status) {
  if (status == null) return BlockingReason.noValidLicense;
  if (status.warnings.any((w) => w.toLowerCase().contains('manipulation'))) return BlockingReason.suspectDate;
  if (status.isInGracePeriod) return BlockingReason.graceEnded;
  // Une vraie licence (mensuelle, annuelle...) dont la date est dépassée
  final exp = status.expirationDate;
  if (status.type != SubscriptionType.trial && exp != null && (status.remainingDays ?? 0) == 0) {
    return BlockingReason.licenseExpired;
  }
  // Sinon : aucune licence lisible sur ce poste (jamais activée, ou licence introuvable)
  return BlockingReason.noValidLicense;
}

String blockingMessage(BlockingReason r) {
  switch (r) {
    case BlockingReason.suspectDate:
      return "La date de l'ordinateur semble incorrecte. Vérifiez la date, l'heure et le fuseau horaire de Windows, puis relancez LOGESCO.";
    case BlockingReason.graceEnded:
      return 'Votre licence est expirée et la période de grâce est terminée.';
    case BlockingReason.licenseExpired:
      return 'Votre licence est arrivée à expiration.';
    case BlockingReason.noValidLicense:
      return "Aucune licence valide n'a été trouvée sur ce poste. Si vous l'avez déjà activée, ressaisissez votre clé d'activation : elle sera désormais conservée.";
  }
}
