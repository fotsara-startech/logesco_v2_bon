import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/services/implementations/secure_time_service.dart';
import 'package:logesco_v2/features/subscription/services/license_log.dart';

import 'license_stability_test.dart' show FauxCoffre;

/// Horloge système simulée : on peut la faire sauter (resynchronisation Windows, pile CMOS usée...)
class Horloge {
  Duration decalage = Duration.zero;
  DateTime now() => DateTime.now().add(decalage);
}

/// Heure réseau (NTP) simulée : toujours la VRAIE heure, indépendante de l'horloge système du PC
Future<DateTime> _heureReelle(String s, Duration t) async => DateTime.now();
Future<DateTime> _reseauAbsent(String s, Duration t) async => throw const SocketException('pas de réseau');

void main() {
  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('secure_time');
    LicenseLog.overrideDirectory = tmp.path;
    LicenseLog.reset();
  });
  tearDown(() async {
    await LicenseLog.flush();
    LicenseLog.overrideDirectory = null;
    LicenseLog.reset();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// Poste activé depuis 30 jours (donc HORS de la fenêtre de grâce NTP de 7 jours : contrôles complets)
  Future<SecureTimeService> demarrer(FauxCoffre coffre, Horloge h, Future<DateTime> Function(String, Duration) ntp) async {
    final s = SecureTimeService(secureStorage: coffre, clock: h.now, ntpLookup: ntp);
    await s.recordFirstActivation(DateTime.now().subtract(const Duration(days: 30)));
    await s.initialize();
    return s;
  }

  test('référence : réseau disponible, horloge stable -> heure fiable et exacte', () async {
    final h = Horloge();
    final s = await demarrer(FauxCoffre(), h, _heureReelle);
    final r = await s.getSecureTime();
    expect(r.isSystemTimeReliable, isTrue, reason: r.warnings.join(' | '));
    expect(r.trustedTime.difference(DateTime.now()).abs(), lessThan(const Duration(seconds: 5)));
  });

  test('DÉFAUT : Windows recale l\'horloge en arrière de quelques minutes après le démarrage -> ne doit pas être pris pour une fraude', () async {
    final h = Horloge();
    final s = await demarrer(FauxCoffre(), h, _heureReelle);
    h.decalage = const Duration(minutes: -3); // resynchronisation automatique de Windows
    final r = await s.getSecureTime();
    expect(r.isSystemTimeReliable, isTrue, reason: 'faux positif de "manipulation de date" : ${r.warnings.join(' | ')}');
  });

  test('DÉFAUT : horloge du PC très en retard au démarrage (pile CMOS), puis recalée par Windows -> l\'heure de référence reste exacte', () async {
    final h = Horloge()..decalage = const Duration(days: -700); // PC qui redémarre en 2024
    final s = await demarrer(FauxCoffre(), h, _heureReelle);
    h.decalage = Duration.zero; // Windows resynchronise l'horloge
    final r = await s.getSecureTime();
    expect(r.trustedTime.difference(DateTime.now()).abs(), lessThan(const Duration(days: 1)),
        reason: 'l\'heure de référence a sauté de ${r.trustedTime.difference(DateTime.now()).inDays} jours : une licence valide paraîtrait expirée');
    expect(r.isSystemTimeReliable, isTrue, reason: r.warnings.join(' | '));
  });

  test('DÉFAUT : horloge du PC en avance au démarrage puis corrigée -> pas de faux positif', () async {
    final h = Horloge()..decalage = const Duration(hours: 5);
    final s = await demarrer(FauxCoffre(), h, _heureReelle);
    h.decalage = Duration.zero;
    final r = await s.getSecureTime();
    expect(r.isSystemTimeReliable, isTrue, reason: r.warnings.join(' | '));
  });

  test('réseau absent au démarrage, aucun historique -> heure système, jamais "manipulation"', () async {
    final s = await demarrer(FauxCoffre(), Horloge(), _reseauAbsent);
    final r = await s.getSecureTime();
    expect(r.isSystemTimeReliable, isTrue);
    expect(r.trustedTime.difference(DateTime.now()).abs(), lessThan(const Duration(seconds: 5)));
  });

  test('réseau absent au démarrage, avec une heure réseau mémorisée d\'une session précédente -> jamais "manipulation"', () async {
    final coffre = FauxCoffre();
    final h = Horloge();
    await demarrer(coffre, h, _heureReelle); // session 1 : réseau OK, l'heure est mémorisée
    final s2 = SecureTimeService(secureStorage: coffre, clock: h.now, ntpLookup: _reseauAbsent);
    await s2.initialize(); // session 2 : réseau absent
    final r = await s2.getSecureTime();
    expect(r.isSystemTimeReliable, isTrue, reason: r.warnings.join(' | '));
  });

  test('réseau absent, session 2, horloge du PC reculée de 2 minutes par Windows -> pas de fraude', () async {
    final coffre = FauxCoffre();
    final h = Horloge();
    await demarrer(coffre, h, _heureReelle);
    final s2 = SecureTimeService(secureStorage: coffre, clock: h.now, ntpLookup: _reseauAbsent);
    await s2.initialize();
    h.decalage = const Duration(minutes: -2);
    final r = await s2.getSecureTime();
    expect(r.isSystemTimeReliable, isTrue, reason: r.warnings.join(' | '));
  });

  test('coffre illisible : l\'heure reste utilisable et jamais "manipulation"', () async {
    final coffre = FauxCoffre()..toutEnPanne = true;
    final s = SecureTimeService(secureStorage: coffre, clock: Horloge().now, ntpLookup: _heureReelle);
    await s.initialize();
    final r = await s.getSecureTime();
    expect(r.isSystemTimeReliable, isTrue, reason: r.warnings.join(' | '));
  });

  test('première semaine après activation : aucun contrôle de manipulation (fenêtre de grâce)', () async {
    final h = Horloge();
    final s = SecureTimeService(secureStorage: FauxCoffre(), clock: h.now, ntpLookup: _heureReelle);
    await s.recordFirstActivation(DateTime.now().subtract(const Duration(days: 2)));
    await s.initialize();
    h.decalage = const Duration(minutes: -30);
    expect((await s.getSecureTime()).isSystemTimeReliable, isTrue);
  });

  test('DÉFAUT : une erreur INTERNE du service de temps ne doit pas être prise pour une manipulation de date', () async {
    var panne = false;
    final s = SecureTimeService(
      secureStorage: FauxCoffre(),
      clock: () => panne ? throw StateError('horloge illisible') : DateTime.now(),
      ntpLookup: _heureReelle,
    );
    await s.recordFirstActivation(DateTime.now().subtract(const Duration(days: 30)));
    await s.initialize();
    panne = true;
    final r = await s.getSecureTime();
    expect(r.isSystemTimeReliable, isTrue, reason: 'une erreur interne a été traitée comme une fraude');
    expect(r.isManipulationDetected, isFalse);
    expect(r.trustedTime.difference(DateTime.now()).abs(), lessThan(const Duration(seconds: 5)));
  });

  group('fraude volontaire sur l horloge : ce que le service de temps fait réellement', () {
    test('horloge reculée d un mois pendant l utilisation (réseau OK au démarrage) : sans effet sur l heure de référence', () async {
      final h = Horloge();
      final s = await demarrer(FauxCoffre(), h, _heureReelle);
      h.decalage = const Duration(days: -30);
      final r = await s.getSecureTime();
      expect(r.trustedTime.difference(DateTime.now()).abs(), lessThan(const Duration(seconds: 5)));
    });

    test('horloge reculée d un mois puis redémarrage AVEC réseau : l heure réseau reprend le dessus', () async {
      final coffre = FauxCoffre();
      final h = Horloge();
      await demarrer(coffre, h, _heureReelle);
      h.decalage = const Duration(days: -30);
      final s2 = SecureTimeService(secureStorage: coffre, clock: h.now, ntpLookup: _heureReelle);
      await s2.initialize();
      final r = await s2.getSecureTime();
      expect(r.trustedTime.difference(DateTime.now()).abs(), lessThan(const Duration(seconds: 5)));
    });

    test('horloge reculée d un mois puis redémarrage SANS réseau : l heure de référence ne suit pas l horloge truquée', () async {
      final coffre = FauxCoffre();
      final h = Horloge();
      await demarrer(coffre, h, _heureReelle);
      h.decalage = const Duration(days: -30);
      final s2 = SecureTimeService(secureStorage: coffre, clock: h.now, ntpLookup: _reseauAbsent);
      await s2.initialize();
      final r = await s2.getSecureTime();
      expect(r.trustedTime.difference(DateTime.now()).abs(), lessThan(const Duration(seconds: 5)), reason: 'la référence suit l horloge truquée');
      expect(r.isSystemTimeReliable, isTrue, reason: 'aucun blocage : la fraude est simplement sans effet');
    });

    test('PC sans réseau pendant 60 jours : l heure de référence suit le temps qui passe, la licence vieillit', () async {
      final coffre = FauxCoffre();
      final h = Horloge();
      await demarrer(coffre, h, _heureReelle);
      h.decalage = const Duration(days: 60); // 60 jours plus tard, toujours sans réseau
      final s2 = SecureTimeService(secureStorage: coffre, clock: h.now, ntpLookup: _reseauAbsent);
      await s2.initialize();
      final r = await s2.getSecureTime();
      expect(h.now().difference(r.trustedTime).abs(), lessThan(const Duration(seconds: 5)), reason: 'la licence ne vieillit pas hors ligne');
      expect(r.isSystemTimeReliable, isTrue);
    });

    test('hors ligne : horloge du PC reculée de 30 jours -> la dernière heure réseau est retenue (reculer ne sert à rien)', () async {
      final coffre = FauxCoffre();
      final h = Horloge();
      await demarrer(coffre, h, _heureReelle);
      h.decalage = const Duration(days: -30);
      final s2 = SecureTimeService(secureStorage: coffre, clock: h.now, ntpLookup: _reseauAbsent);
      await s2.initialize();
      final r = await s2.getSecureTime();
      expect(r.trustedTime.difference(DateTime.now()).abs(), lessThan(const Duration(seconds: 5)));
    });

    test('hors ligne et sans aucun historique : horloge du PC', () async {
      final h = Horloge()..decalage = const Duration(days: 3);
      final s = await demarrer(FauxCoffre(), h, _reseauAbsent);
      final r = await s.getSecureTime();
      expect(r.trustedTime.difference(h.now()).abs(), lessThan(const Duration(seconds: 5)));
    });

    test('avec réseau au démarrage, les sauts d horloge pendant la session restent sans effet (heure réseau + chronomètre)', () async {
      final h = Horloge();
      final s = await demarrer(FauxCoffre(), h, _heureReelle);
      h.decalage = const Duration(days: 400);
      final r = await s.getSecureTime();
      expect(r.trustedTime.difference(DateTime.now()).abs(), lessThan(const Duration(seconds: 5)));
    });
  });
}
