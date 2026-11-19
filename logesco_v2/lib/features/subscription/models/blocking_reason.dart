import 'package:get/get.dart';
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
      return 'subscription_date_ordinateur_semble_incorrecte_verifiez_date'.tr;
    case BlockingReason.graceEnded:
      return 'subscription_votre_licence_est_expiree_periode_grace'.tr;
    case BlockingReason.licenseExpired:
      return 'subscription_votre_licence_est_arrivee_expiration'.tr;
    case BlockingReason.noValidLicense:
      return 'subscription_aucune_licence_valide_n_ete_trouvee'.tr;
  }
}
