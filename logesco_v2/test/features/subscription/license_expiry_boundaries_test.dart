import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/models/license_data.dart';

LicenseData _licence(DateTime expire) => LicenseData(
      userId: 'u',
      licenseKey: 'AAAA-BBBB-CCCC-DDDD',
      subscriptionType: SubscriptionType.monthly,
      issuedAt: expire.subtract(const Duration(days: 30)),
      expiresAt: expire,
      deviceFingerprint: 'AAAA-BBBB-CCCC-DDDD',
      signature: 's',
    );

void main() {
  final expire = DateTime(2026, 11, 7); // minuit local, comme les licences émises

  group('limites de validité (convention : valide jusqu\'à l\'instant d\'expiration inclus, puis 3 jours de grâce)', () {
    final l = _licence(expire);

    test('1 seconde avant l\'expiration : active', () {
      final t = expire.subtract(const Duration(seconds: 1));
      expect(l.isExpiredSecure(t), isFalse);
      expect(l.remainingDaysSecure(t), 0);
    });

    test('exactement à l\'expiration : encore active', () {
      expect(l.isExpiredSecure(expire), isFalse);
      expect(l.isInGracePeriodSecure(expire), isFalse);
    });

    test('1 seconde après : expirée mais en période de grâce', () {
      final t = expire.add(const Duration(seconds: 1));
      expect(l.isExpiredSecure(t), isTrue);
      expect(l.isInGracePeriodSecure(t), isTrue);
    });

    test('exactement 3 jours après : la grâce est terminée', () {
      final fin = expire.add(const Duration(days: 3));
      expect(l.isInGracePeriodSecure(fin.subtract(const Duration(seconds: 1))), isTrue);
      expect(l.isInGracePeriodSecure(fin), isFalse);
    });

    test('jours restants : 22 jours pleins avant l\'expiration', () {
      expect(l.remainingDaysSecure(DateTime(2026, 10, 15, 11, 24)), 22);
      expect(l.remainingDaysSecure(expire.add(const Duration(days: 1))), 0);
    });
  });

  group('fuseau horaire et format de la date', () {
    test('la date enregistrée puis relue reste le même instant (heure locale ou UTC)', () {
      for (final d in [expire, expire.toUtc()]) {
        final relu = LicenseData.fromJson(_licence(d).toJson());
        expect(relu.expiresAt.isAtSameMomentAs(d), isTrue, reason: 'instant modifié pour $d');
      }
    });

    test('une date UTC (avec Z) désigne le même instant quel que soit le fuseau du PC', () {
      final utc = DateTime.parse('2026-11-07T00:00:00.000Z');
      final l = _licence(utc);
      expect(l.isExpiredSecure(DateTime.parse('2026-11-06T23:59:59.000Z')), isFalse);
      expect(l.isExpiredSecure(DateTime.parse('2026-11-07T00:00:01.000Z')), isTrue);
      // comparaison d'un instant local et d'un instant UTC : correcte, Dart compare les instants
      expect(l.isExpiredSecure(DateTime.parse('2026-11-07T00:00:01.000Z').toLocal()), isTrue);
    });

    test('une date sans fuseau (format émis par le générateur de clés) est lue à l\'heure locale du PC : même jour calendaire partout', () {
      final lue = DateTime.parse('2026-11-07T00:00:00.000');
      expect(lue.isUtc, isFalse);
      expect([lue.year, lue.month, lue.day, lue.hour], [2026, 11, 7, 0]);
    });
  });
}
