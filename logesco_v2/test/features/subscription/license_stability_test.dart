import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/models/license_data.dart';
import 'package:logesco_v2/features/subscription/models/subscription_status.dart';
import 'package:logesco_v2/features/subscription/services/implementations/crypto_service.dart';
import 'package:logesco_v2/features/subscription/services/implementations/license_service.dart';
import 'package:logesco_v2/features/subscription/services/implementations/secure_license_storage.dart';
import 'package:logesco_v2/features/subscription/services/implementations/secure_time_service.dart';
import 'package:logesco_v2/features/subscription/services/implementations/subscription_manager.dart';
import 'package:logesco_v2/features/subscription/services/interfaces/i_device_service.dart';
import 'package:logesco_v2/features/subscription/services/license_key_backup.dart';
import 'package:logesco_v2/features/subscription/services/license_log.dart';

/// Coffre de stockage en mémoire, avec des pannes que l'on commande, pour reproduire ce qui arrive sur un vrai poste :
/// le stockage sécurisé de Windows répond parfois mal (accès simultanés au fichier, lenteur, verrou antivirus...).
class FauxCoffre extends FlutterSecureStorage {
  final Map<String, String> donnees = {};

  /// Clé -> nombre de lectures de cette clé qui échoueront encore (panne passagère)
  final Map<String, int> pannesDeLecture = {};

  /// Toutes les lectures échouent (coffre injoignable)
  bool toutEnPanne = false;

  FauxCoffre() : super();

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (toutEnPanne) throw PlatformException(code: 'panne', message: 'coffre injoignable');
    final restantes = pannesDeLecture[key] ?? 0;
    if (restantes > 0) {
      pannesDeLecture[key] = restantes - 1;
      throw PlatformException(code: 'panne', message: 'lecture échouée (passagère)');
    }
    return donnees[key];
  }

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) {
      donnees.remove(key);
    } else {
      donnees[key] = value;
    }
  }

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    donnees.remove(key);
  }

  @override
  Future<bool> containsKey({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => donnees.containsKey(key);

  @override
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => Map.of(donnees);

  @override
  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => donnees.clear();
}

/// Appareil dont l'empreinte peut changer (renommage du PC, mise à jour de Windows...)
class FauxAppareil implements IDeviceService {
  String empreinte;
  FauxAppareil(this.empreinte);

  @override
  Future<String> generateDeviceFingerprint() async => empreinte;

  @override
  Future<bool> verifyDeviceFingerprint(String storedFingerprint) async => storedFingerprint == empreinte;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

LicenseData _licence() => LicenseData(
      userId: 'client-test',
      licenseKey: 'ABCD-EFGH-JKLM-NPQR',
      subscriptionType: SubscriptionType.monthly,
      issuedAt: DateTime.now().subtract(const Duration(days: 3)),
      expiresAt: DateTime.now().add(const Duration(days: 27)),
      deviceFingerprint: 'AAAA-BBBB-CCCC-DDDD',
      signature: 'signature-de-test',
    );

class _Poste {
  final FauxCoffre coffre = FauxCoffre();
  final FauxAppareil appareil = FauxAppareil('AAAA-BBBB-CCCC-DDDD');
  late final CryptoService crypto = CryptoService();
  late final SecureLicenseStorage stockage = SecureLicenseStorage(cryptoService: crypto, deviceService: appareil, secureStorage: coffre);
  late final LicenseService licences = LicenseService(cryptoService: crypto, deviceService: appareil, secureStorage: stockage);
  late final SubscriptionManager gestionnaire = SubscriptionManager(
    licenseService: licences,
    deviceService: appareil,
    cryptoService: crypto,
    secureStorage: coffre,
    secureTimeService: SecureTimeService(secureStorage: coffre),
  );

  Future<void> activer() async {
    await stockage.initialize();
    await licences.storeLicense(_licence());
  }

  /// La licence est-elle toujours lisible ?
  Future<bool> licencePresente() async => (await licences.getStoredLicense()) != null;
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('license_stability');
    LicenseLog.overrideDirectory = tmp.path;
    LicenseKeyBackup.overrideDirectory = '${tmp.path}${Platform.pathSeparator}cle'; // jamais le vrai dossier de l'utilisateur
    LicenseLog.reset();
  });

  tearDown(() async {
    await LicenseLog.flush();
    LicenseLog.overrideDirectory = null;
    LicenseKeyBackup.overrideDirectory = null;
    LicenseLog.reset();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('point de départ : une licence activée est lisible et la validation périodique ne la touche pas', () async {
    final p = _Poste();
    await p.activer();
    expect(await p.licencePresente(), isTrue);
    await p.gestionnaire.performPeriodicValidation();
    expect(await p.licencePresente(), isTrue, reason: 'sans panne, rien ne change');
  });

  test('DÉFAUT : une lecture du coffre qui échoue UNE seule fois pendant la validation périodique ne doit pas effacer la licence', () async {
    final p = _Poste();
    await p.activer();
    expect(await p.licencePresente(), isTrue);

    // Le coffre de Windows répond mal une fois (accès simultané au fichier, lenteur, verrou antivirus...)
    p.coffre.pannesDeLecture['logesco_license_primary'] = 1;
    await p.gestionnaire.performPeriodicValidation();

    // Le coffre répond de nouveau : la licence doit toujours être là. Avant le correctif, elle avait été EFFACÉE.
    expect(await p.licencePresente(), isTrue, reason: 'une panne passagère du coffre a effacé la licence');
  });

  test('DÉFAUT : un coffre injoignable pendant la validation périodique ne doit pas effacer la licence', () async {
    final p = _Poste();
    await p.activer();

    p.coffre.toutEnPanne = true;
    await p.gestionnaire.performPeriodicValidation();
    p.coffre.toutEnPanne = false;

    expect(await p.licencePresente(), isTrue, reason: 'le coffre était momentanément injoignable : la licence ne doit pas disparaître');
  });

  test('DÉFAUT : un changement d\'empreinte de l\'appareil (PC renommé, Windows mis à jour) ne doit pas effacer la licence', () async {
    final p = _Poste();
    await p.activer();

    p.appareil.empreinte = 'ZZZZ-YYYY-XXXX-WWWW'; // le PC a changé de nom ou Windows s'est mis à jour
    await p.gestionnaire.performPeriodicValidation();

    expect(await p.licencePresente(), isTrue, reason: 'un changement d\'empreinte a effacé la licence en silence');
  });

  for (final cle in ['logesco_license_backup', 'logesco_license_integrity', 'logesco_tamper_detection', 'logesco_license_primary', 'logesco_license_metadata']) {
    test('DÉFAUT : une lecture ratée de $cle ne doit pas effacer la licence', () async {
      final p = _Poste();
      await p.activer();
      p.coffre.pannesDeLecture[cle] = 1;
      await p.gestionnaire.performPeriodicValidation();
      expect(await p.licencePresente(), isTrue, reason: 'la panne passagère sur $cle a effacé la licence');
    });
  }

  group('copie durable de la clé', () {
    late Directory dossierCle;
    setUp(() {
      dossierCle = Directory.systemTemp.createTempSync('license_key');
      LicenseKeyBackup.overrideDirectory = dossierCle.path;
    });
    tearDown(() {
      LicenseKeyBackup.overrideDirectory = null;
      if (dossierCle.existsSync()) dossierCle.deleteSync(recursive: true);
    });

    test('enregistrer puis relire, effacer', () async {
      final b = LicenseKeyBackup();
      expect(await b.load(), isNull);
      expect(await b.save('  ABCD-EFGH  '), isTrue);
      expect(await b.load(), 'ABCD-EFGH');
      expect(await b.save('   '), isFalse);
      await b.clear();
      expect(await b.load(), isNull);
    });

    test('fichier illisible : null, sans erreur', () async {
      File('${dossierCle.path}${Platform.pathSeparator}license.key').writeAsStringSync('pas du json');
      expect(await LicenseKeyBackup().load(), isNull);
    });

    test('une copie de clé invalide ne restaure rien (mêmes contrôles que l activation)', () async {
      final p = _Poste();
      await p.stockage.initialize();
      await LicenseKeyBackup().save('CLE-INVALIDE');
      await p.gestionnaire.performPeriodicValidation();
      expect(await p.licencePresente(), isFalse, reason: 'une clé invalide ne doit jamais redonner une licence');
    });

    test('la réinitialisation explicite supprime aussi la copie', () async {
      final p = _Poste();
      await p.activer();
      await LicenseKeyBackup().save('ABCD-EFGH-JKLM-NPQR');
      await p.gestionnaire.resetLicenseData();
      expect(await LicenseKeyBackup().load(), isNull);
    });
  });
}
