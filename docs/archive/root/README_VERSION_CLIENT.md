# LOGESCO v2 - Version CLIENT

## 🎯 Qu'est-ce que c'est?

La **Version CLIENT** de LOGESCO est conçue pour fonctionner sur un réseau local. Elle se connecte à un serveur LOGESCO centralisé et ne démarre pas son propre backend.

## ✨ Caractéristiques

- ✅ Démarrage rapide (pas d'initialisation du serveur)
- ✅ Connexion à un serveur réseau
- ✅ Interface utilisateur complète
- ✅ Pas de messages techniques
- ✅ Configuration simple

## 🚀 Installation Rapide

### Étape 1: Télécharger et installer

1. Téléchargez `logesco-client.exe`
2. Exécutez l'installateur
3. Suivez les instructions

### Étape 2: Configurer le serveur

**Avant le premier démarrage**, exécutez:

```bash
setup-client-reseau.bat
```

Le script vous demandera:
- L'adresse IP du serveur (ex: `192.168.100.101`)
- Le port (par défaut: `8080`)

### Étape 3: Lancer l'application

```bash
logesco-client.exe
```

## ✅ Vérification

Si tout fonctionne:
- ✅ L'écran de connexion s'affiche rapidement
- ✅ Pas de message "Démarrage du backend"
- ✅ Vous pouvez vous connecter avec `admin` / `admin123`
- ✅ Le dashboard se charge

## ❌ Problèmes?

### L'app ne se connecte pas

1. Vérifiez l'adresse IP du serveur
2. Vérifiez que le serveur est en cours d'exécution
3. Vérifiez que le firewall n'est pas bloquant
4. Relancez `setup-client-reseau.bat`

### Le serveur n'est pas accessible

1. Vérifiez l'adresse IP: `ping 192.168.100.101`
2. Vérifiez que le serveur est en cours d'exécution
3. Vérifiez le port: `http://192.168.100.101:8080/api/v1/auth/test`

## 📞 Support

Consultez `DEPLOIEMENT_CLIENT_RESEAU.md` pour plus de détails.
