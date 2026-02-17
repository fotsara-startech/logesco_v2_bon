# Guide de Génération de Licences LOGESCO

Ce guide vous explique comment générer des clés de licence pour vos clients en tant que propriétaire du projet LOGESCO.

## 🎯 Vue d'ensemble

Le système de licence LOGESCO utilise :
- **Clés cryptographiques RSA** pour signer les licences
- **Format de clé standardisé** : `LOGESCO_V1_<payload_base64>`
- **Validation côté client** avec vérification de signature
- **Gestion des types d'abonnement** : trial, monthly, annual, lifetime

## 🚀 Démarrage rapide

### 1. Utiliser le générateur d'exemple

```bash
cd logesco_v2
dart tools/license_generator_example.dart generate CLIENT001 annual 12 ABC123DEF456
```

### 2. Résultat obtenu

```
✅ Clé de licence générée avec succès!

📋 Informations de la licence:
   Client ID: CLIENT001
   Type: annual
   Émise le: 06/11/2024
   Expire le: 06/11/2025
   Appareil: ABC123DEF456

🔑 Clé de licence:
   LOGESCO_V1_eyJ1c2VySWQiOiJDTElFTlQwMDEiLCJ0eXBlIjoiYW5udWFsIi...
```

## 📋 Types d'abonnement disponibles

| Type | Durée | Fonctionnalités |
|------|-------|-----------------|
| `trial` | 7 jours | Inventaire de base, ventes de base |
| `monthly` | 1 mois | Inventaire complet, ventes, rapports |
| `annual` | 12 mois | Inventaire complet, ventes, rapports, analytics |
| `lifetime` | Illimitée | Toutes les fonctionnalités + support premium |

## 🔧 Commandes disponibles

### Générer une licence
```bash
dart tools/license_generator_example.dart generate <client-id> <type> <months> <device-hash>
```

**Exemples :**
```bash
# Licence annuelle pour CLIENT001
dart tools/license_generator_example.dart generate CLIENT001 annual 12 ABC123DEF456

# Licence mensuelle pour CLIENT002  
dart tools/license_generator_example.dart generate CLIENT002 monthly 1 XYZ789GHI012

# Licence à vie pour CLIENT003
dart tools/license_generator_example.dart generate CLIENT003 lifetime 999 DEF456JKL789
```

### Valider une licence
```bash
dart tools/license_generator_example.dart validate LOGESCO_V1_eyJ1c2VySWQi...
```

### Afficher les informations d'une licence
```bash
dart tools/license_generator_example.dart info LOGESCO_V1_eyJ1c2VySWQi...
```

## 🔐 Sécurité et signatures

### ⚠️ IMPORTANT - Signatures factices

Le générateur d'exemple utilise des **signatures factices** pour la démonstration. Pour un environnement de production, vous devez :

1. **Générer une paire de clés RSA réelle**
2. **Signer les licences avec votre clé privée**
3. **Intégrer la clé publique dans l'application**

### Génération de vraies clés RSA

```bash
# Générer une clé privée RSA 2048 bits
openssl genrsa -out private_key.pem 2048

# Extraire la clé publique
openssl rsa -in private_key.pem -pubout -out public_key.pem
```

### Intégration de la clé publique

Modifiez le fichier `logesco_v2/lib/features/subscription/services/implementations/crypto_service.dart` pour utiliser votre vraie clé publique :

```dart
RSAPublicKey _getDefaultPublicKey() {
  // Remplacez par votre vraie clé publique
  final modulus = BigInt.parse('VOTRE_MODULUS_ICI');
  final exponent = BigInt.from(65537);
  return RSAPublicKey(modulus, exponent);
}
```

## 📁 Organisation des fichiers

```
logesco_v2/
├── tools/
│   └── license_generator_example.dart    # Générateur d'exemple
├── generated_licenses/                   # Licences générées (créé automatiquement)
│   ├── license_CLIENT001_1699123456.json
│   └── license_CLIENT002_1699123789.json
└── GUIDE_GENERATION_LICENCES.md         # Ce guide
```

## 🎯 Workflow de génération pour vos clients

### 1. Collecte des informations client
- **ID Client** : Identifiant unique (ex: CLIENT001, COMPANY_ABC)
- **Type d'abonnement** : trial, monthly, annual, lifetime
- **Durée** : Nombre de mois (ignoré pour lifetime)
- **Hash d'appareil** : Empreinte de l'appareil du client

### 2. Génération de la licence
```bash
dart tools/license_generator_example.dart generate [CLIENT_ID] [TYPE] [MONTHS] [DEVICE_HASH]
```

### 3. Envoi au client
- Copiez la clé générée
- Envoyez-la au client avec les instructions d'activation
- Conservez une copie dans vos archives

### 4. Instructions pour le client
1. Ouvrir LOGESCO
2. Aller dans **Paramètres > Abonnement**
3. Cliquer sur **"Activer une licence"**
4. Coller la clé de licence
5. Valider l'activation

## 🔍 Obtenir l'empreinte d'appareil du client

Le client peut obtenir son empreinte d'appareil dans LOGESCO :
1. Ouvrir l'application
2. Aller dans **Paramètres > Abonnement**
3. L'empreinte d'appareil est affichée en bas de la page

Ou vous pouvez leur demander d'exécuter cette commande dans leur terminal :
```bash
# Sur Windows
wmic csproduct get uuid

# Sur macOS  
system_profiler SPHardwareDataType | grep "Hardware UUID"

# Sur Linux
sudo dmidecode -s system-uuid
```

## 📊 Suivi des licences

Les licences générées sont automatiquement sauvegardées dans `generated_licenses/` avec :
- Métadonnées complètes
- Date de génération
- Informations client
- Clé de licence

Exemple de fichier généré :
```json
{
  "generatedAt": "2024-11-06T10:30:00.000Z",
  "licenseKey": "LOGESCO_V1_eyJ1c2VySWQi...",
  "metadata": {
    "clientId": "CLIENT001",
    "type": "annual",
    "issuedAt": "2024-11-06T10:30:00.000Z",
    "expiresAt": "2025-11-06T10:30:00.000Z",
    "deviceFingerprint": "ABC123DEF456"
  }
}
```

## 🚨 Bonnes pratiques de sécurité

1. **Gardez vos clés privées secrètes** - Ne les partagez jamais
2. **Sauvegardez vos clés** - Stockez-les dans un endroit sûr
3. **Utilisez des ID clients uniques** - Évitez les doublons
4. **Documentez vos licences** - Tenez un registre des licences émises
5. **Vérifiez les empreintes d'appareil** - Assurez-vous qu'elles sont correctes
6. **Testez les licences** - Validez-les avant de les envoyer

## 🆘 Dépannage

### Erreur "Format de clé invalide"
- Vérifiez que la clé commence par `LOGESCO_V1_`
- Assurez-vous qu'elle n'est pas tronquée

### Erreur "Signature cryptographique invalide"
- Vérifiez que vous utilisez la bonne clé publique
- Assurez-vous que la signature a été générée avec la clé privée correspondante

### Erreur "Cette licence est liée à un autre appareil"
- Vérifiez l'empreinte d'appareil du client
- Générez une nouvelle licence avec la bonne empreinte

## 📞 Support

Pour toute question sur la génération de licences :
1. Consultez ce guide
2. Testez avec le générateur d'exemple
3. Vérifiez les logs de l'application client
4. Contactez l'équipe de développement si nécessaire