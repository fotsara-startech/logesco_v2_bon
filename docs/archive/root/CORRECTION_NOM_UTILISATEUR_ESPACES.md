# Correction : Backend ne démarre pas avec noms d'utilisateurs contenant espaces/caractères spéciaux

## Problème identifié

Le backend embarqué ne démarre pas automatiquement chez certains clients dont le nom d'utilisateur Windows contient des espaces ou caractères spéciaux (ex: `André jean d'arc`).

### Cause racine

Dans `backend_service.dart`, lors de la génération des scripts de démarrage (`.cmd` et `.vbs`), les chemins n'étaient pas correctement échappés pour gérer :
- Les espaces dans les chemins (ex: `C:\Users\André jean d'arc\AppData\Local\LOGESCO\backend`)
- Les caractères spéciaux (apostrophes, accents, etc.)

Le problème se manifestait dans deux endroits :

1. **Fichier CMD** : Les variables `$backendDir`, `$nodeExe`, `$serverJs`, et `$dbPath` étaient directement insérées sans échappement des guillemets qu'elles pouvaient contenir
2. **Fichier VBS** : Tentative d'échappement avec `.replaceAll('"', '""')` mais appliquée uniquement au chemin du CMD, pas aux chemins contenus dans le CMD

## Solution appliquée

### 1. Échappement correct dans le fichier CMD

Tous les chemins sont maintenant correctement échappés avant insertion :

```dart
// Échapper les guillemets doubles déjà présents dans les chemins (remplacer " par "")
// et entourer chaque chemin de guillemets pour gérer les espaces
final backendDirEscaped = backendDir.replaceAll('"', '""');
final nodeExeEscaped = nodeExe.replaceAll('"', '""');
final serverJsEscaped = serverJs.replaceAll('"', '""');
final dbPathEscaped = dbPath.replaceAll('"', '""');

final cmdContent = [
  '@echo off',
  'cd /d "$backendDirEscaped"',
  'SET "LOGESCO_DATA_DIR=$backendDirEscaped"',
  'SET "PORT=$_port"',
  'SET "NODE_ENV=production"',
  'SET "DATABASE_URL=file:$dbPathEscaped"',
  '"$nodeExeEscaped" "$serverJsEscaped"',
].join('\r\n');
```

### 2. Simplification du fichier VBS

Le VBS utilise maintenant `Chr(34)` pour insérer des guillemets littéraux, ce qui évite tous les problèmes d'échappement :

```dart
final vbsContent = [
  'Set WshShell = CreateObject("WScript.Shell")',
  'Dim cmd',
  // Chr(34) génère un guillemet double littéral en VBS
  'cmd = "cmd.exe /C " & Chr(34) & "$cmdPath" & Chr(34)',
  'WshShell.Run cmd, 0, False',
].join('\r\n');
```

## Pourquoi ça fonctionne

1. **CMD Windows** : Les guillemets doubles `"` sont le mécanisme standard pour encadrer des chemins avec espaces. Si un chemin contient déjà des guillemets, on les double (`""`) pour les échapper.

2. **VBScript** : `Chr(34)` génère le caractère guillemet double (code ASCII 34) de manière programmatique, évitant ainsi tous les problèmes d'échappement de chaînes.

3. **Ordre d'exécution** :
   - Flutter lance `wscript.exe _logesco_start.vbs`
   - VBS lance `cmd.exe /C "_logesco_start.cmd"`
   - CMD exécute `node.exe server.js` avec les bonnes variables d'environnement

## Test requis

Tester avec des noms d'utilisateurs problématiques :
- ✅ `André jean d'arc` (espaces + apostrophe + accent)
- ✅ `Jean-Marie O'Connor` (tiret + apostrophe)
- ✅ `User (Admin)` (parenthèses)
- ✅ `Test & Dev` (esperluette)

## Date de correction

2 septembre 2026
