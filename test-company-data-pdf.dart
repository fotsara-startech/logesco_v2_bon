import 'dart:io';

/// Test pour vérifier que les données de parametreEntreprise sont utilisées dans le PDF
void main() {
  print('🔧 TEST: Utilisation des données parametreEntreprise dans le PDF du bilan');
  print('=' * 75);
  
  print('\n📋 DONNÉES DE LA TABLE parametreEntreprise:');
  print('   - nomEntreprise: MBOA KATHY B');
  print('   - adresse: kribi');
  print('   - localisation: Mbeka\'a');
  print('   - telephone: 698745120');
  print('   - email: mboa@gmail.com');
  print('   - nuiRccm: P012479935');
  
  print('\n🔧 CORRECTIONS APPORTÉES:');
  print('   ✅ Suppression de l\'en-tête entreprise de l\'interface utilisateur');
  print('   ✅ Utilisation des vraies données dans le PDF uniquement');
  print('   ✅ Filtrage des valeurs par défaut dans l\'affichage PDF');
  print('   ✅ Mapping correct des champs de la base vers le modèle');
  
  print('\n📁 FICHIERS MODIFIÉS:');;
}ans le PDF')ement dnt uniquapparaisseEntreprise  parametres deonnée d'   Lesrint(
  pÉE !');INTERMCTION CORRE\n✅ int(');
  
  prde la base's données s vraieent lele PDF contiérifier que t('   4. V;
  prin en PDF') 3. Exporter  rint('
  prise');e entrep-têtPAS l\'eniche ff\'aterface nue l\'infier q Vériprint('   2.');
  ésactivitmptable d\' un bilan co  1. Générer  print(' TESTER:');
R ('\n🧪 POU
  
  print-tête');'enfo pour l\yInort.companilise rep utPDF 4. ('  
  print);apport'pour le r convertit mProfile().froompanyInfo C3.('   print JSON');
  ampss chlepe mapon() ofile.fromJs CompanyPr  2.t(' e');
  printreprisarametreEnées de pe les donnings récupèrpany-sett 1. API /com  print('  ÉES:');
UX DE DONNFL'\n🔄   
  print(479935');
12I RCCM: P0 NUnt('  riom');
  poa@gmail.cl: mb  Emai print(' 20');
 6987451: rint('   Tel'a');
  p: Mbeka\tionisaal Loc'  t(inpr  ;
i')ibkrAdresse: int('   ;
  prOA KATHY B')('   Nom: MBprint:');
  NDUTTEDF AICHAGE PFF\n📄 A
  print(' uiRccm');
 e.nnyProfilCompam → .nuiRcctreprisearametreEn('   p  printemail');
panyProfile. → Comrise.emailrepeEnt   parametr
  print('phone');ile. CompanyProfelephone →reprise.tEnt   parametrent('n');
  priile.locatiorofompanyPn → Catiocalistreprise.loarametreEn   p  print('s');
ofile.addresnyPrmpase → Coe.adresprisntrerametreEnt('   papri');
  .namempanyProfilereprise → ConomEntise.trepr parametreEn
  print('  MPS:'); CHADESAPPING t('\n🎯 Min  
  pr
  }
ile');: '❌'} $f '✅' ts ?isfileExnt('   ${ri    p;
xistsSync()ile).es = File(fistal fileEx
    finedFiles) { in modifinal file (fi
  
  for];',
  e.dartervict_sor/pdf_expts/servicesures/repor_v2/lib/featogesco   'lart',
 widget.dy_ummarrt_sgets/repoports/widures/rev2/lib/featogesco_ 'l= [
   ifiedFiles l modna
  fi