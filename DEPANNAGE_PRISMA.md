# Dépannage - Erreur Téléchargement Prisma

## Problème

Lors de l'exécution de `preparer-pour-client.bat`, vous voyez:

```
Error: request to https://binaries.prisma.sh/all_commits/.../query_engine.dll.node.sha256 failed
```

## Cause

Prisma essaie de télécharger les binaires natifs depuis Internet, mais:
- Problème de connexion réseau
- Pare-feu bloque la connexion
- Proxy d'entreprise
- Serveur Prisma temporairement indisponible

## Solutions

### Solution 1: Vérifier la Connexion Internet ⭐ RECOMMANDÉ

1. **Vérifier la connexion**:
   ```powershell
   ping binaries.prisma.sh
   ```

2. **Réessayer le build**:
   ```batch
   preparer-pour-client.bat
   ```

### Solution 2: Générer Prisma Manuellement

1. **Aller dans le dossier backend**:
   ```batch
   cd backend
   ```

2. **Générer le client Prisma**:
   ```batch
   npx prisma generate
   ```

3. **Vérifier que ça fonctionne**:
   ```batch
   dir node_modules\.prisma\client
   ```

4. **Relancer le build**:
   ```batch
   cd ..
   preparer-pour-client.bat
   ```

Le script copiera automatiquement le client Prisma déjà généré.

### Solution 3: Configurer un Proxy (Si Nécessaire)

Si vous êtes derrière un proxy d'entreprise:

1. **Configurer les variables d'environnement**:
   ```batch
   set HTTP_PROXY=http://proxy.entreprise.com:8080
   set HTTPS_PROXY=http://proxy.entreprise.com:8080
   ```

2. **Relancer le build**:
   ```batch
   preparer-pour-client.bat
   ```

### Solution 4: Utiliser un Build Existant

Si vous avez déjà un build qui fonctionne:

1. **Copier le client Prisma**:
   ```batch
   xcopy /E /I /Y "backend\node_modules\.prisma" "dist-portable\node_modules\.prisma"
   ```

2. **Continuer le build**:
   Le script détectera que Prisma est déjà présent.

---

## Vérification

### Vérifier que Prisma est Bien Généré

```batch
cd backend
dir node_modules\.prisma\client
```

Vous devriez voir:
```
query_engine-windows.dll.node
index.js
index.d.ts
...
```

### Tester le Client Prisma

```batch
cd backend
node -e "const { PrismaClient } = require('@prisma/client'); console.log('OK')"
```

Si vous voyez "OK", Prisma fonctionne!

---

## Problème Persistant?

### Télécharger Manuellement les Binaires

1. **Identifier la version Prisma**:
   ```batch
   cd backend
   npx prisma --version
   ```

2. **Télécharger depuis**:
   https://github.com/prisma/prisma-engines/releases

3. **Placer dans**:
   ```
   backend\node_modules\.prisma\client\
   ```

---

## Prévention

### Avant de Builder

1. **Tester la connexion**:
   ```powershell
   Test-NetConnection binaries.prisma.sh -Port 443
   ```

2. **Générer Prisma d'abord**:
   ```batch
   cd backend
   npm install
   npx prisma generate
   cd ..
   ```

3. **Puis builder**:
   ```batch
   preparer-pour-client.bat
   ```

---

## Script de Build Alternatif

Si le problème persiste, utilisez ce script:

```batch
@echo off
echo Preparation LOGESCO avec Prisma pre-genere...

REM 1. Générer Prisma dans le backend source
cd backend
call npm install
call npx prisma generate
cd ..

REM 2. Builder le package
call preparer-pour-client.bat

echo.
echo Build termine!
pause
```

Sauvegardez-le comme `build-avec-prisma.bat` et exécutez-le.

---

## Résumé Rapide

```batch
# Si erreur de téléchargement Prisma:

# 1. Générer manuellement
cd backend
npx prisma generate

# 2. Vérifier
dir node_modules\.prisma\client

# 3. Relancer le build
cd ..
preparer-pour-client.bat
```

Le script copiera automatiquement le client Prisma déjà généré! ✅
