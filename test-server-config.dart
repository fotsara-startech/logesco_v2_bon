import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Script de test pour vérifier la configuration du serveur
void main() async {
  print('🔍 Test de configuration du serveur LOGESCO');
  print('=' * 50);

  // Obtenir le répertoire Documents
  final directory = await getApplicationDocumentsDirectory();
  final configFile = File('${directory.path}/server_config.txt');

  print('\n📁 Répertoire de configuration: ${directory.path}');
  print('📄 Fichier de configuration: ${configFile.path}');

  if (await configFile.exists()) {
    print('\n✅ Fichier de configuration trouvé!');
    final content = await configFile.readAsString();
    print('📝 Contenu: $content');
  } else {
    print('\n⚠️ Fichier de configuration NON trouvé');
    print('   Création du fichier avec l\'URL par défaut...');

    try {
      await configFile.writeAsString('http://192.168.100.101:8080/api/v1');
      print('✅ Fichier créé avec succès');
      final content = await configFile.readAsString();
      print('📝 Contenu: $content');
    } catch (e) {
      print('❌ Erreur lors de la création: $e');
    }
  }

  print('\n' + '=' * 50);
  print('Test terminé');
}
