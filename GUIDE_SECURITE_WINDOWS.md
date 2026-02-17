# Guide - Problème de Sécurité Windows

## Erreur Observée
```
npx : File C:\Program Files\nodejs\npx.ps1 cannot be loaded because running scripts is disabled on this system.
SecurityError: (:) [], PSSecurityException
UnauthorizedAccess
```

## Cause
Windows bloque l'exécution des scripts PowerShell par sécurité par défaut.

## Solutions

### Solution 1 - Autoriser les scripts (Recommandée)
**En tant qu'administrateur :**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Solution 2 - Utiliser directement Prisma
```cmd
cd backend
node_modules\.bin\prisma generate
```

### Solution 3 - Bypass temporaire
```cmd
powershell -ExecutionPolicy Bypass -Command "npx prisma generate"
```

## Prévention Future

Pour éviter ce problème lors des déploiements :
1. Inclure une note dans la documentation client
2. Utiliser des scripts .bat au lieu de PowerShell
3. Tester sur des machines "propres" avant livraison

## Scripts Créés
- `SOLUTION_POWERSHELL_ADMIN.bat` - Solution complète avec admin
- `SOLUTION_ALTERNATIVE_CMD.bat` - Solution sans PowerShell