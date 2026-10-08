import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:logesco_v2/features/subscription/services/license_log.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('license_log_test');
    LicenseLog.overrideDirectory = tmp.path;
    LicenseLog.reset();
  });

  tearDown(() {
    LicenseLog.overrideDirectory = null;
    LicenseLog.reset();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('écrit les lignes dans l\'ordre, avec horodatage et source', () async {
    LicenseLog.log('statut', 'premier');
    LicenseLog.log('lecture', 'second');
    LicenseLog.error('stockage', 'échec', StateError('boom'));
    await LicenseLog.flush();

    final lines = File('${tmp.path}${Platform.pathSeparator}license.log').readAsLinesSync();
    expect(lines.length, 3);
    expect(lines[0], matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} \[statut\] premier$')));
    expect(lines[1], contains('[lecture] second'));
    expect(lines[2], contains('StateError'));
    expect(lines[2], contains('boom'));
  });

  test('rotation : le fichier ne grossit pas indéfiniment', () async {
    final big = 'x' * 1000;
    for (var i = 0; i < 700; i++) {
      LicenseLog.log('test', big);
    }
    await LicenseLog.flush();
    final f = File('${tmp.path}${Platform.pathSeparator}license.log');
    expect(f.lengthSync(), lessThan(520 * 1024));
    expect(File('${f.path}.1').existsSync(), true);
  });

  test('un dossier inutilisable ne lève jamais d\'erreur', () async {
    // un FICHIER à la place du dossier : la création du journal échoue
    final blocker = File('${tmp.path}${Platform.pathSeparator}bloque')..writeAsStringSync('x');
    LicenseLog.overrideDirectory = '${blocker.path}${Platform.pathSeparator}sous';
    LicenseLog.reset();
    LicenseLog.log('statut', 'ne doit pas planter');
    await LicenseLog.flush();
  });
}
