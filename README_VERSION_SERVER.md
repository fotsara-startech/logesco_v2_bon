# LOGESCO v2 - Version SERVER

## 🎯 Qu'est-ce que c'est?

La **Version SERVER** de LOGESCO est conçue pour fonctionner en standalone. Elle démarre son propre backend embarqué et peut servir de serveur centralisé pour les clients réseau.

## ✨ Caractéristiques

- ✅ Backend embarqué intégré
- ✅ Peut fonctionner en standalone
- ✅ Crée automatiquement l'utilisateur admin
- ✅ Initialisation complète du système
- ✅ Peut servir de serveur pour les clients réseau

## 🚀 Installation

### Étape 1: Télécharger et installer

1. Téléchargez `logesco-server.exe`
2. Exécutez l'installateur
3. Suivez les instructions

### Étape 2: Lancer l'application

```bash
logesco-server.exe
```

L'application:
1. Démarre le backend embarqué
2. Initialise la base de données
3. Crée l'utilisateur admin
4. Affiche l'écran de connexion

### Étape 3: Se connecter

Utilisez les identifiants par défaut:
- **Utilisateur:** `admin`
- **Mot de passe:** `admin123`

## ✅ Vérification

Si tout fonctionne:
- ✅ Vous voyez "Mode SERVER - Démarrage du backend embarqué"
- ✅ Vous voyez "Backend service started successfully"
- ✅ Vous voyez "Utilisateur admin: Disponible"
- ✅ L'écran de connexion s'affiche
- ✅ Vous pouvez vous connecter

## 🌐 Utilisation comme Serveur Réseau

Pour utiliser cette version comme serveur pour les clients réseau:

1. **Lancez la version SERVER**
2. **Notez l'adresse IP du serveur:**
   ```bash
   ipconfig
   ```
   Cherchez l'adresse IPv4 (ex: `192.168.100.101`)

3. **Distribuez cette adresse aux clients**
4. **Les clients exécutent:**
   ```bash
   setup-client-reseau.bat
   ```
   Et entrent l'adresse IP du serveur

## ❌ Problèmes?

### L'app ne démarre pas

1. Vérifiez que le backend est disponible
2. Vérifiez les logs
3. Essayez de redémarrer

### Le backend ne démarre pas

1. Vérifiez que le port 8080 est disponible
2. Vérifiez que le firewall n'est pas bloquant
3. Vérifiez les logs

## 📞 Support

Consultez la documentation pour plus de détails.
