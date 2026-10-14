import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:logesco_v2/features/sync/views/cloud_config_page.dart';

void main() {
  setUp(Get.reset);

  test("sans droits d'administrateur (aucun service de permissions), l'écran n'est pas disponible", () {
    expect(CloudConfigPage.disponible, isFalse);
  });

  testWidgets("accès refusé : message de réserve, aucune saisie de lien, aucun bouton d'enregistrement", (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: CloudConfigPage()));
    await tester.pump();
    expect(find.textContaining("réservé à l'administrateur"), findsOneWidget);
    expect(find.byType(TextField), findsNothing, reason: 'le lien (avec son mot de passe) ne peut pas être saisi');
    expect(find.text('Enregistrer et redémarrer'), findsNothing);
    expect(find.text('Tester la connexion'), findsNothing);
  });
}
