import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/sync/services/cloud_config_service.dart';

const _lienOk =
    'postgresql://neondb_owner:MotDePasseSecret123@ep-exemple-pooler.c-3.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require';

void main() {
  group('vérification du lien avant d\'appeler le serveur', () {
    test('un lien Neon correct est accepté', () {
      expect(verifierLienNeon(_lienOk), isNull);
      expect(verifierLienNeon('  $_lienOk  '), isNull, reason: 'espaces autour : retirés');
      expect(verifierLienNeon(_lienOk.replaceFirst('postgresql', 'postgres')), isNull);
    });

    test('vide : on demande de coller le lien', () {
      expect(verifierLienNeon(''), contains('Collez le lien'));
      expect(verifierLienNeon('   '), contains('Collez le lien'));
    });

    test('INJECTION : espace, retour à la ligne, guillemet, apostrophe, accent grave ou antislash sont refusés', () {
      final pieges = [
        '$_lienOk\nJWT_SECRET=pirate',
        '$_lienOk\r\nPORT=1',
        '$_lienOk AUTRE=1',
        '$_lienOk"',
        "$_lienOk'",
        '$_lienOk`',
        '$_lienOk\\',
        'postgresql://u:p@hote/ba se',
      ];
      for (final p in pieges) {
        expect(verifierLienNeon(p), isNotNull, reason: 'refusé : ${p.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}');
      }
    });

    test('ce qui n\'est pas un lien PostgreSQL est refusé avec une explication', () {
      expect(verifierLienNeon('https://console.neon.tech/projet'), contains('postgresql://'));
      expect(verifierLienNeon('neondb_owner:mdp@hote/base'), contains('postgresql://'));
    });

    test('lien incomplet : on dit ce qui manque', () {
      expect(verifierLienNeon('postgresql://hote/base'), contains('mot de passe'));
      expect(verifierLienNeon('postgresql://utilisateur@hote/base'), contains('mot de passe'));
      expect(verifierLienNeon('postgresql://utilisateur:@hote/base'), contains('mot de passe'));
      expect(verifierLienNeon('postgresql://u:p@hote'), contains('nom de la base'));
      expect(verifierLienNeon('postgresql://u:p@hote/'), contains('nom de la base'));
    });
  });

  group('lecture des réponses du serveur', () {
    test('état de la connexion : active, enregistrée, redémarrage nécessaire ; jamais de mot de passe', () {
      final c = CloudConfig.fromJson({
        'active': false,
        'infoActive': null,
        'enregistree': true,
        'infoEnregistree': {'hote': 'ep-x.neon.tech', 'base': 'neondb', 'utilisateur': 'neondb_owner'},
        'redemarrageNecessaire': true,
      });
      expect(c.active, isFalse);
      expect(c.infoActive, isNull);
      expect(c.enregistree, isTrue);
      expect(c.infoEnregistree!.hote, 'ep-x.neon.tech');
      expect(c.redemarrageNecessaire, isTrue);
    });

    test('mode 100 % local : rien d\'actif ni d\'enregistré', () {
      final c = CloudConfig.fromJson({'active': false, 'enregistree': false, 'redemarrageNecessaire': false});
      expect([c.active, c.enregistree, c.redemarrageNecessaire], [false, false, false]);
    });

    test('test réussi sur une base prête et vide : le poste enverra ses données', () {
      final t = CloudTestResult.fromJson({
        'ok': true,
        'message': 'Connexion réussie.',
        'info': {'hote': 'h', 'base': 'b', 'utilisateur': 'u'},
        'schemaPret': true,
        'tablesManquantes': [],
        'donnees': {'produits': 0, 'clients': 0, 'ventes': 0},
      });
      expect(t.ok, isTrue);
      expect(t.schemaPret, isTrue);
      expect(t.cloudDejaRempli, isFalse);
    });

    test('test réussi sur une base déjà remplie : on le sait', () {
      final t = CloudTestResult.fromJson({
        'ok': true,
        'message': 'Connexion réussie.',
        'schemaPret': true,
        'donnees': {'produits': 120, 'clients': 14, 'ventes': 800},
      });
      expect(t.cloudDejaRempli, isTrue);
      expect(t.donnees!['produits'], 120);
    });

    test('connexion réussie mais schéma absent : tables manquantes listées, pas d\'enregistrement possible', () {
      final t = CloudTestResult.fromJson({
        'ok': true,
        'message': 'Connexion réussie, mais...',
        'schemaPret': false,
        'tablesManquantes': ['ventes', 'clients'],
      });
      expect(t.ok, isTrue);
      expect(t.schemaPret, isFalse);
      expect(t.tablesManquantes, ['ventes', 'clients']);
      expect(t.donnees, isNull);
      expect(t.cloudDejaRempli, isFalse);
    });

    test('échec de connexion : le message du serveur est conservé tel quel', () {
      final t = CloudTestResult.fromJson({'ok': false, 'message': 'Le mot de passe ou le nom d\'utilisateur est refusé : recopiez le lien.'});
      expect(t.ok, isFalse);
      expect(t.message, contains('refusé'));
    });
  });
}
