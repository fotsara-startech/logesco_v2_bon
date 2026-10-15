import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/services/implementations/crypto_service.dart';
import 'package:logesco_v2/features/subscription/services/implementations/license_service.dart';
import 'package:logesco_v2/features/subscription/services/implementations/secure_license_storage.dart';
import 'package:logesco_v2/features/subscription/services/implementations/secure_time_service.dart';
import 'package:logesco_v2/features/subscription/services/implementations/subscription_manager.dart';
import 'package:logesco_v2/features/subscription/services/license_key_backup.dart';
import 'package:logesco_v2/features/subscription/services/license_log.dart';

import 'license_stability_test.dart' show FauxCoffre, FauxAppareil;

/// Test avec une VRAIE clé, lue dans l'environnement (jamais écrite dans un fichier) :
///   LICENSE_TEST_KEY=XXXX-XXXX-XXXX-XXXX LICENSE_TEST_FINGERPRINT=XXXX-XXXX-XXXX-XXXX flutter test <ce fichier>
void main() {
  final cle = Platform.environment['LICENSE_TEST_KEY'];
  final empreinte = Platform.environment['LICENSE_TEST_FINGERPRINT'];
  final skip = (cle == null || empreinte == null) ? 'LICENSE_TEST_KEY / LICENSE_TEST_FINGERPRINT absentes' : false;

  late Directory tmp, dossierCle;
  late FauxCoffre coffre;
  late SubscriptionManager gestionnaire;
  late LicenseService licences;

  void construire() {
    final appareil = FauxAppareil(empreinte ?? 'x');
    final crypto = CryptoService();
    final stockage = SecureLicenseStorage(cryptoService: crypto, deviceService: appareil, secureStorage: coffre);
    licences = LicenseService(cryptoService: crypto, deviceService: appareil, secureStorage: stockage);
    gestionnaire = SubscriptionManager(
      licenseService: licences,
      deviceService: appareil,
      cryptoService: crypto,
      secureStorage: coffre,
      secureTimeService: SecureTimeService(secureStorage: coffre),
    );
  }

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lic_real');
    dossierCle = Directory.systemTemp.createTempSync('lic_real_key');
    LicenseLog.overrideDirectory = tmp.path;
    LicenseLog.reset();
    LicenseKeyBackup.overrideDirectory = dossierCle.path;
    coffre = FauxCoffre();
    construire();
  });

  tearDown(() async {
    await LicenseLog.flush();
    LicenseLog.overrideDirectory = null;
    LicenseKeyBackup.overrideDirectory = null;
    LicenseLog.reset();
    for (final d in [tmp, dossierCle]) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
  });

  test('activation réelle, puis coffre vidé : la licence revient seule', () async {
    expect(await gestionnaire.activateLicense(cle!), isTrue, reason: 'la clé doit être acceptée pour cette empreinte');
    expect(await licences.getStoredLicense(), isNotNull);
    expect(await LicenseKeyBackup().load(), cle, reason: 'copie durable enregistrée');

    coffre.donnees.clear(); // le coffre Windows a été vidé
    construire(); // l'application redémarre : plus aucun cache en mémoire
    expect(await licences.getStoredLicense(), isNull);

    final statut = await gestionnaire.getCurrentStatus();
    expect(await licences.getStoredLicense(), isNotNull, reason: 'licence restaurée depuis la copie');
    expect(statut.isActive, isTrue);
  }, skip: skip);

  test('activation réelle, puis panne passagère du coffre pendant la validation périodique', () async {
    expect(await gestionnaire.activateLicense(cle!), isTrue);
    coffre.pannesDeLecture['logesco_license_backup'] = 1;
    await gestionnaire.performPeriodicValidation();
    coffre.toutEnPanne = true;
    await gestionnaire.performPeriodicValidation();
    coffre.toutEnPanne = false;
    expect(await licences.getStoredLicense(), isNotNull);
  }, skip: skip);

  test('mauvaise empreinte : la clé est refusée et aucune copie n\'est utilisée pour restaurer', () async {
    final autre = FauxAppareil('AAAA-BBBB-CCCC-DDDD');
    final crypto = CryptoService();
    final stockage = SecureLicenseStorage(cryptoService: crypto, deviceService: autre, secureStorage: coffre);
    final l2 = LicenseService(cryptoService: crypto, deviceService: autre, secureStorage: stockage);
    final g2 = SubscriptionManager(licenseService: l2, deviceService: autre, cryptoService: crypto, secureStorage: coffre, secureTimeService: SecureTimeService(secureStorage: coffre));
    expect(await g2.activateLicense(cle!), isFalse);
    await LicenseKeyBackup().save(cle);
    await g2.getCurrentStatus();
    expect(await l2.getStoredLicense(), isNull);
  }, skip: skip);
}
