# 🚀 Setup Rapide pour Nouveau Client LOGESCO

## Configuration Neon en 3 étapes

### 1️⃣ Configurer l'URL Neon

Ajoutez dans `.env`:
```env
CLOUD_DB_URL="postgresql://user:password@host/database?sslmode=require"
```

### 2️⃣ Créer les tables

```bash
cd backend
npx prisma migrate deploy
```

### 3️⃣ Configurer les triggers

```bash
node setup-neon.js
```

## ✅ C'est tout !

Votre base de données Neon est maintenant configurée avec:
- ✅ Toutes les tables créées
- ✅ Colonne `date_modification` sur toutes les tables
- ✅ Triggers automatiques pour la synchronisation
- ✅ Synchronisation incrémentale activée

## 📖 Documentation Complète

Pour plus de détails, consultez: `GUIDE_SETUP_NEON_COMPLET.md`

## 🔍 Vérification

Redémarrez le serveur et vérifiez qu'il n'y a plus de messages:
```
⚠️  pas de date_modification sur Neon, pull complet...
```

## 🐛 Problème ?

1. Vérifiez que `CLOUD_DB_URL` est correct dans `.env`
2. Vérifiez que la migration Prisma a réussi
3. Consultez `GUIDE_SETUP_NEON_COMPLET.md` pour le dépannage
