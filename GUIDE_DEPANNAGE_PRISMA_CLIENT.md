# Guide de Dépannage - Erreur Prisma Client

## Problème
```
❌ Erreur fatale au démarrage: Cannot find module '.prisma/client/default'
```

## Solution Rapide

### Étape 1: Régénérer le client Prisma
```bash
cd backend
npx prisma generate
```

### Étape 2: Redémarrer le backend
```bash
node src/server-standalone.js
```

## Script Automatique
Exécutez le fichier `SOLUTION_RAPIDE_PRISMA.bat` qui fait tout automatiquement.

## Pourquoi cette erreur ?

Cette erreur survient quand :
- Le client Prisma n'a pas été généré après l'installation
- Les fichiers `.prisma/client` sont manquants ou corrompus
- La version de Prisma a changé

## Prévention

Pour éviter ce problème lors des futurs déploiements :
1. Toujours exécuter `npx prisma generate` après `npm install`
2. Inclure le dossier `node_modules/@prisma/client` dans le package
3. Vérifier que le schéma Prisma est présent

## Commandes de Vérification

```bash
# Vérifier si Prisma est installé
npx prisma --version

# Vérifier le schéma
npx prisma validate

# Régénérer si nécessaire
npx prisma generate
```