// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// /// Script pour réinitialiser toutes les données de licence
// /// À exécuter depuis logesco_v2
// void main() async {
//   print('🔄 Réinitialisation de la licence...\n');

//   const storage = FlutterSecureStorage(
//     aOptions: AndroidOptions(
//       encryptedSharedPreferences: true,
//     ),
//   );

//   try {
//     // Clés à supprimer
//     final keysToDelete = [
//       // Licence
//       'license_data',
//       'license_key',
//       'stored_license',

//       // Période d'essai
//       'trial_start_date',
//       'trial_active',
//       'trial_ever_used',

//       // Validation
//       'last_validation',
//       'grace_period_start',

//       // Cache
//       'degradation_mode',
//       'seen_notifications',

//       // Empreinte d'appareil (optionnel - décommenter si besoin)
//       // 'device_fingerprint',
//       // 'last_device_fingerprint',
//       // 'device_fingerprint_checksum',
//       // 'device_fingerprint_archive',
//     ];

//     print('📋 Suppression des clés de stockage sécurisé:');
//     for (final key in keysToDelete) {
//       await storage.delete(key: key);
//       print('  ✓ $key');
//     }

//     print('\n✅ Réinitialisation terminée avec succès!');
//     print('\n📝 Prochaines étapes:');
//     print('  1. Redémarrer l\'application logesco_v2');
//     print('  2. Une nouvelle période d\'essai de 7 jours démarrera automatiquement');
//     print('  3. Récupérer la nouvelle clé d\'appareil dans l\'interface');
//     print('  4. Générer une nouvelle clé de licence dans logesco_license_admin');
//   } catch (e) {
//     print('\n❌ Erreur lors de la réinitialisation: $e');
//   }
// }
