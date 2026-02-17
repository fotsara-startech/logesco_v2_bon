import 'dart:io';

/// Script pour corriger toutes les occurrences de CompanyProfile.fromJson dans CompanySettingsService
void main() async {
  final file = File('logesco_v2/lib/features/company_settings/services/company_settings_service.dart');

  if (!file.existsSync()) {
    print('❌ Fichier non trouvé');
    return;
  }

  print('🔧 Correction du CompanySettingsService...');

  String content = await file.readAsString();

  // Remplacer toutes les occurrences de CompanyProfile.fromJson(jsonData['message'])
  final oldPattern = RegExp(r"// Le backend retourne les données dans 'message' au lieu de 'data'\s*\n\s*final profile = CompanyProfile\.fromJson\(jsonData\['message'\]\);", multiLine: true);

  final newCode = '''// Le backend retourne maintenant les données dans 'data'
        final companyData = jsonData['data'];
        
        // Créer manuellement le CompanyProfile pour éviter les problèmes de parsing
        final profile = CompanyProfile(
          id: companyData['id'],
          name: companyData['nomEntreprise'] ?? 'Entreprise',
          address: companyData['adresse'] ?? '',
          location: companyData['localisation'],
          phone: companyData['telephone'],
          email: companyData['email'],
          nuiRccm: companyData['nuiRccm'],
          createdAt: companyData['dateCreation'] != null ? DateTime.parse(companyData['dateCreation']) : DateTime.now(),
          updatedAt: companyData['dateModification'] != null ? DateTime.parse(companyData['dateModification']) : DateTime.now(),
        );''';

  content = content.replaceAll(oldPattern, newCode);

  // Aussi corriger l'occurrence dans le cache
  content = content.replaceAll('return CompanyProfile.fromJson(jsonData);', '''// Créer manuellement le CompanyProfile depuis le cache
          return CompanyProfile(
            id: jsonData['id'],
            name: jsonData['nomEntreprise'] ?? 'Entreprise',
            address: jsonData['adresse'] ?? '',
            location: jsonData['localisation'],
            phone: jsonData['telephone'],
            email: jsonData['email'],
            nuiRccm: jsonData['nuiRccm'],
            createdAt: jsonData['dateCreation'] != null ? DateTime.parse(jsonData['dateCreation']) : DateTime.now(),
            updatedAt: jsonData['dateModification'] != null ? DateTime.parse(jsonData['dateModification']) : DateTime.now(),
          );''');

  await file.writeAsString(content);

  print('✅ CompanySettingsService corrigé !');
  print('   - Toutes les occurrences de CompanyProfile.fromJson() remplacées');
  print('   - Parsing manuel implémenté');
  print('   - Utilisation de jsonData[\'data\'] au lieu de jsonData[\'message\']');
}
