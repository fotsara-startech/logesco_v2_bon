import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/sales/models/sale.dart';

void main() {
  group('Date Serialization Tests', () {
    test('dateVente should preserve local time when serialized', () {
      // Créer une date locale: 2 juillet 2026 à 00:00
      final selectedDate = DateTime(2026, 7, 2, 0, 0, 0);

      print('📅 Date sélectionnée: $selectedDate');
      print('   - Jour: ${selectedDate.day}');
      print('   - Mois: ${selectedDate.month}');
      print('   - Année: ${selectedDate.year}');
      print('   - Heure: ${selectedDate.hour}');

      // Créer une requête de vente
      final request = CreateSaleRequest(
        modePaiement: 'comptant',
        montantRemise: 0,
        montantPaye: 25000,
        details: [
          const CreateSaleDetailRequest(
            produitId: 1,
            quantite: 1,
            prixUnitaire: 25000,
            prixAffiche: 25000,
          ),
        ],
        dateVente: selectedDate,
      );

      // Sérialiser en JSON
      final json = request.toJson();
      print('\n📤 JSON sérialisé:');
      print('   - dateVente: ${json['dateVente']}');

      // Vérifier que la date ne contient pas de "Z" (pas en UTC)
      expect(json['dateVente'], isNotNull);
      expect(json['dateVente'], isNot(contains('Z')));

      // Vérifier que la date sérialisée commence par "2026-07-02"
      expect(json['dateVente'], startsWith('2026-07-02'));

      // Simuler un cycle complet JSON (comme si on envoyait/recevait du backend)
      // D'abord sérialiser les détails correctement
      final jsonForBackend = {
        ...json,
        'details': (json['details'] as List).map((d) {
          if (d is Map) return d;
          return (d as CreateSaleDetailRequest).toJson();
        }).toList(),
      };

      // Désérialiser
      final deserializedRequest = CreateSaleRequest.fromJson(jsonForBackend);
      print('\n📥 Date désérialisée: ${deserializedRequest.dateVente}');
      print('   - Jour: ${deserializedRequest.dateVente?.day}');
      print('   - Mois: ${deserializedRequest.dateVente?.month}');
      print('   - Année: ${deserializedRequest.dateVente?.year}');
      print('   - Heure: ${deserializedRequest.dateVente?.hour}');

      // Vérifier que la date est préservée
      expect(deserializedRequest.dateVente?.day, equals(2));
      expect(deserializedRequest.dateVente?.month, equals(7));
      expect(deserializedRequest.dateVente?.year, equals(2026));
      expect(deserializedRequest.dateVente?.hour, equals(0));
    });

    test('dateVente with custom time should be preserved', () {
      // Créer une date avec une heure spécifique: 2 juillet 2026 à 14:30
      final selectedDate = DateTime(2026, 7, 2, 14, 30, 0);

      final request = CreateSaleRequest(
        modePaiement: 'comptant',
        montantRemise: 0,
        montantPaye: 25000,
        details: [
          const CreateSaleDetailRequest(
            produitId: 1,
            quantite: 1,
            prixUnitaire: 25000,
            prixAffiche: 25000,
          ),
        ],
        dateVente: selectedDate,
      );

      final json = request.toJson();

      // Simuler un cycle complet JSON
      final jsonForBackend = {
        ...json,
        'details': (json['details'] as List).map((d) {
          if (d is Map) return d;
          return (d as CreateSaleDetailRequest).toJson();
        }).toList(),
      };

      final deserializedRequest = CreateSaleRequest.fromJson(jsonForBackend);

      // Vérifier que l'heure est préservée
      expect(deserializedRequest.dateVente?.day, equals(2));
      expect(deserializedRequest.dateVente?.month, equals(7));
      expect(deserializedRequest.dateVente?.year, equals(2026));
      expect(deserializedRequest.dateVente?.hour, equals(14));
      expect(deserializedRequest.dateVente?.minute, equals(30));
    });
  });
}
