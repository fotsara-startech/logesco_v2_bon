import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/models/blocking_reason.dart';
import 'package:logesco_v2/features/subscription/models/license_data.dart';
import 'package:logesco_v2/features/subscription/models/subscription_status.dart';

SubscriptionStatus _s({SubscriptionType type = SubscriptionType.monthly, DateTime? exp, int? jours, bool grace = false, List<String> warnings = const []}) =>
    SubscriptionStatus(isActive: false, type: type, expirationDate: exp, remainingDays: jours, isInGracePeriod: grace, warnings: warnings);

void main() {
  test('statut inconnu ou licence introuvable : "aucune licence valide", pas "expirée"', () {
    expect(blockingReasonOf(null), BlockingReason.noValidLicense);
    expect(blockingReasonOf(_s(type: SubscriptionType.trial, jours: 0, warnings: ['Aucun abonnement actif'])), BlockingReason.noValidLicense);
  });

  test('date de Windows suspecte', () {
    expect(blockingReasonOf(_s(exp: DateTime(2026, 11, 7), jours: 0, warnings: ['Manipulation de la date système détectée. Restaurez la date correcte.'])), BlockingReason.suspectDate);
  });

  test('licence réellement expirée', () {
    expect(blockingReasonOf(_s(exp: DateTime(2026, 9, 1), jours: 0)), BlockingReason.licenseExpired);
  });

  test('période de grâce terminée', () {
    expect(blockingReasonOf(_s(exp: DateTime(2026, 9, 1), jours: 0, grace: true)), BlockingReason.graceEnded);
  });

  test('chaque motif a un message distinct et le message "licence perdue" invite à ressaisir la clé', () {
    final messages = BlockingReason.values.map(blockingMessage).toSet();
    expect(messages.length, BlockingReason.values.length);
    expect(blockingMessage(BlockingReason.noValidLicense), contains('ressaisissez'));
  });
}
