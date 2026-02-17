import 'dart:io';

/// Script pour corriger le parsing de l'ID dans CompanySettingsService
void main() async {
  final file = File('logesco_v2/lib/features/company_settings/services/company_settings_service.dart');
  
  if (!file.existsSync()) {
    print('❌ Fichier non trouvé: ${file.path}');
    return;
  }

  print('🔧 Correction du parsing de l\'ID dans CompanySettingsService...');
  
  String content = await file.readAsString();
  
  // Remplacer toutes les occurrences de id: companyData['id'] par une version sécurisée
  content = content.replaceAll(
    "id: companyData['id'],",
    "id: companyData['id'] is String ? int.tryParse(companyData['id']) : companyData['id'],"
  );
  
  // Aussi corriger les occurrences avec ?? 1
  content = content.replaceAll(
    "id: companyData['id'] ?? 1,",
    "id: companyData['id'] is String ? int.tryParse(companyData['id']) ?? 1 : (companyData['id'] ?? 1),"
  );
  
  await file.writeAsString(content);
  
  print('✅ CompanySettingsService corrigé !');
  print('   - Parsing sécurisé de l\'ID implémenté');
  print('   - Protection contre les erreurs de type String/int');
}