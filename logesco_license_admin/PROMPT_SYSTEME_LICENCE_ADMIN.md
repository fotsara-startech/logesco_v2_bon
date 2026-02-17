# Système de Gestion des Licences LOGESCO - Guide pour Interface Admin

## Vue d'ensemble

Ce document décrit le système de licences d'activation pour l'application LOGESCO V2. Utilisez ces spécifications pour générer des clés de licence valides dans votre interface d'administration.

---

## 1. STRUCTURE D'UNE CLÉ DE LICENCE

### Format de la clé
```
LOGESCO_V1_<payload_base64>
```

**Composants :**
- **Préfixe** : `LOGESCO_` (identifiant de l'application)
- **Version** : `V1` (version du format de clé)
- **Séparateur** : `_` (underscore)
- **Payload** : Données JSON encodées en Base64

### Structure du Payload JSON

Le payload contient les informations suivantes (avant encodage Base64) :

```json
{
  "userId": "CLIENT001",
  "type": "annual",
  "issued": "2024-11-07T10:30:00.000Z",
  "expires": "2025-11-07T10:30:00.000Z",
  "device": "ABC123DEF456",
  "features": ["full_inventory", "sales", "reports", "advanced_analytics", "cash_register", "expense_management", "user_management", "role_management", "backup_restore", "multi_device_sync"],
  "signature": "base64_encoded_rsa_signature"
}
```

**Champs obligatoires :**

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `userId` | String | Identifiant unique du client | `"CLIENT001"` |
| `type` | String | Type d'abonnement (voir types ci-dessous) | `"annual"` |
| `issued` | String | Date d'émission ISO 8601 | `"2024-11-07T10:30:00.000Z"` |
| `expires` | String | Date d'expiration ISO 8601 | `"2025-11-07T10:30:00.000Z"` |
| `device` | String | Hash de l'empreinte de l'appareil | `"ABC123DEF456"` |
| `features` | Array | Liste complète des fonctionnalités (identique pour tous les types) | `["full_inventory", "sales", ...]` |
| `signature` | String | Signature RSA-SHA256 en Base64 | `"dGVzdHNpZ25hdHVyZQ=="` |

---

## 2. TYPES D'ABONNEMENT

### Types disponibles

| Type | Valeur JSON | Durée | Description |
|------|-------------|-------|-------------|
| **Essai** | `"trial"` | 7 jours | Période d'essai gratuite - **Accès complet** |
| **Mensuel** | `"monthly"` | 30 jours | Abonnement mensuel - **Accès complet** |
| **Annuel** | `"annual"` | 365 jours | Abonnement annuel - **Accès complet** |
| **À vie** | `"lifetime"` | Jusqu'au 31/12/2099 | Licence permanente - **Accès complet** |

**Important** : Tous les types de licence donnent accès à l'intégralité des fonctionnalités de LOGESCO. La seule différence est la durée de validité.

### Calcul des dates d'expiration

```javascript
// Exemple en JavaScript
const now = new Date();
let expirationDate;

switch (subscriptionType) {
  case 'trial':
    expirationDate = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    break;
  case 'monthly':
    expirationDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    break;
  case 'annual':
    expirationDate = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);
    break;
  case 'lifetime':
    expirationDate = new Date('2099-12-31T23:59:59.999Z');
    break;
}
```

---

## 3. FONCTIONNALITÉS PAR TYPE D'ABONNEMENT

### Principe important

**TOUTES les licences actives donnent accès à TOUTES les fonctionnalités de l'application.**

La seule différence entre les types d'abonnement est la **durée de validité** :
- **Trial** : 7 jours d'accès complet
- **Monthly** : 30 jours d'accès complet
- **Annual** : 365 jours d'accès complet
- **Lifetime** : Accès complet permanent

### Fonctionnalités complètes (pour tous les types)

```javascript
const allFeatures = [
  'full_inventory',
  'sales',
  'reports',
  'advanced_analytics',
  'cash_register',
  'expense_management',
  'user_management',
  'role_management',
  'backup_restore',
  'multi_device_sync'
];
```

### Liste des fonctionnalités disponibles

- `full_inventory` : Gestion complète de l'inventaire
- `sales` : Module de ventes complet
- `reports` : Rapports et statistiques
- `advanced_analytics` : Analyses avancées et tableaux de bord
- `cash_register` : Gestion de caisse
- `expense_management` : Gestion des dépenses
- `user_management` : Gestion des utilisateurs
- `role_management` : Gestion des rôles et permissions
- `backup_restore` : Sauvegarde et restauration
- `multi_device_sync` : Synchronisation multi-appareils

**Note** : Peu importe le type de licence (essai, mensuel, annuel ou à vie), tant que la licence est active, l'utilisateur a accès à toutes ces fonctionnalités.

---

## 4. EMPREINTE D'APPAREIL (Device Fingerprint)

### Structure de l'empreinte

L'empreinte d'appareil est un hash unique généré à partir des caractéristiques de l'appareil du client :

```json
{
  "deviceId": "unique-device-id",
  "platform": "Windows",
  "osVersion": "10.0.19045",
  "appVersion": "2.0.0",
  "hardwareId": "hardware-specific-id",
  "combinedHash": "SHA256_HASH_OF_ALL_ABOVE",
  "generatedAt": "2024-11-07T10:30:00.000Z"
}
```

### Génération du hash d'appareil

Le client génère son propre hash d'appareil lors de la première activation. Dans votre interface admin, vous devez :

1. **Demander au client de fournir son hash d'appareil** (généré par l'application LOGESCO)
2. **Ou utiliser un hash temporaire** pour une activation ultérieure

**Exemple de hash temporaire :**
```javascript
// Hash temporaire pour activation initiale
const deviceHash = "TEMP_" + generateRandomString(32);
```

**Important :** Une licence est liée à un appareil spécifique. Le hash doit correspondre à l'appareil du client.

---

## 5. SIGNATURE CRYPTOGRAPHIQUE RSA

### Principe de la signature

La signature garantit l'authenticité et l'intégrité de la licence. Elle est générée avec une **clé privée RSA 2048 bits** et vérifiée avec la **clé publique** intégrée dans l'application.

### Données à signer

Créez une chaîne de données à partir des informations de la licence :

```javascript
const dataToSign = `${userId}-${type}-${issued}-${expires}-${device}`;
// Exemple : "CLIENT001-annual-2024-11-07T10:30:00.000Z-2025-11-07T10:30:00.000Z-ABC123DEF456"
```

### Génération de la signature (avec clé privée)

**IMPORTANT :** Vous devez générer une paire de clés RSA 2048 bits et garder la clé privée **SECRÈTE** sur votre serveur admin.

#### Exemple avec Node.js (crypto)

```javascript
const crypto = require('crypto');
const fs = require('fs');

// Charger votre clé privée RSA
const privateKey = fs.readFileSync('private_key.pem', 'utf8');

// Données à signer
const dataToSign = `${userId}-${type}-${issued}-${expires}-${device}`;

// Générer la signature
const sign = crypto.createSign('RSA-SHA256');
sign.update(dataToSign);
sign.end();

const signature = sign.sign(privateKey, 'base64');
```

#### Exemple avec Python (cryptography)

```python
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
import base64

# Charger votre clé privée
with open('private_key.pem', 'rb') as f:
    private_key = serialization.load_pem_private_key(
        f.read(),
        password=None
    )

# Données à signer
data_to_sign = f"{user_id}-{type}-{issued}-{expires}-{device}"

# Générer la signature
signature = private_key.sign(
    data_to_sign.encode('utf-8'),
    padding.PKCS1v15(),
    hashes.SHA256()
)

# Encoder en Base64
signature_base64 = base64.b64encode(signature).decode('utf-8')
```

### Génération de la paire de clés RSA

#### Avec OpenSSL (ligne de commande)

```bash
# Générer la clé privée (2048 bits)
openssl genrsa -out private_key.pem 2048

# Extraire la clé publique
openssl rsa -in private_key.pem -pubout -out public_key.pem
```

#### Avec Node.js

```javascript
const crypto = require('crypto');
const fs = require('fs');

const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: {
    type: 'spki',
    format: 'pem'
  },
  privateKeyEncoding: {
    type: 'pkcs8',
    format: 'pem'
  }
});

fs.writeFileSync('private_key.pem', privateKey);
fs.writeFileSync('public_key.pem', publicKey);
```

**CRITIQUE :** La clé publique doit être intégrée dans l'application LOGESCO (voir section 7).

---

## 6. PROCESSUS COMPLET DE GÉNÉRATION

### Étapes pour générer une licence

```javascript
function generateLicense(clientData) {
  // 1. Récupérer les informations du client
  const userId = clientData.clientId;
  const subscriptionType = clientData.subscriptionType; // 'trial', 'monthly', 'annual', 'lifetime'
  const deviceHash = clientData.deviceFingerprint;
  
  // 2. Calculer les dates
  const issuedAt = new Date();
  const expiresAt = calculateExpirationDate(subscriptionType, issuedAt);
  
  // 3. Déterminer les fonctionnalités (toutes les fonctionnalités pour tous les types)
  const features = getAllFeatures();
  
  // 4. Créer les données à signer
  const dataToSign = `${userId}-${subscriptionType}-${issuedAt.toISOString()}-${expiresAt.toISOString()}-${deviceHash}`;
  
  // 5. Générer la signature RSA
  const signature = signData(dataToSign, privateKey);
  
  // 6. Créer le payload
  const payload = {
    userId: userId,
    type: subscriptionType,
    issued: issuedAt.toISOString(),
    expires: expiresAt.toISOString(),
    device: deviceHash,
    features: features,
    signature: signature
  };
  
  // 7. Encoder en Base64
  const payloadJson = JSON.stringify(payload);
  const payloadBase64 = Buffer.from(payloadJson).toString('base64');
  
  // 8. Construire la clé de licence
  const licenseKey = `LOGESCO_V1_${payloadBase64}`;
  
  return licenseKey;
}
```

### Exemple complet (Node.js)

```javascript
const crypto = require('crypto');
const fs = require('fs');

// Charger la clé privée
const privateKey = fs.readFileSync('private_key.pem', 'utf8');

function generateLicense(clientId, subscriptionType, deviceHash) {
  // Dates
  const now = new Date();
  const issued = now.toISOString();
  
  let expires;
  switch (subscriptionType) {
    case 'trial':
      expires = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString();
      break;
    case 'monthly':
      expires = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000).toISOString();
      break;
    case 'annual':
      expires = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000).toISOString();
      break;
    case 'lifetime':
      expires = new Date('2099-12-31T23:59:59.999Z').toISOString();
      break;
  }
  
  // Fonctionnalités (toutes les fonctionnalités pour tous les types de licence)
  const features = [
    'full_inventory',
    'sales',
    'reports',
    'advanced_analytics',
    'cash_register',
    'expense_management',
    'user_management',
    'role_management',
    'backup_restore',
    'multi_device_sync'
  ];
  
  // Signature
  const dataToSign = `${clientId}-${subscriptionType}-${issued}-${expires}-${deviceHash}`;
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(dataToSign);
  sign.end();
  const signature = sign.sign(privateKey, 'base64');
  
  // Payload
  const payload = {
    userId: clientId,
    type: subscriptionType,
    issued: issued,
    expires: expires,
    device: deviceHash,
    features: features,
    signature: signature
  };
  
  // Encodage
  const payloadJson = JSON.stringify(payload);
  const payloadBase64 = Buffer.from(payloadJson).toString('base64');
  
  // Clé finale
  return `LOGESCO_V1_${payloadBase64}`;
}

// Utilisation
const licenseKey = generateLicense(
  'CLIENT001',
  'annual',
  'ABC123DEF456789'
);

console.log('Clé de licence générée :');
console.log(licenseKey);
```

---

## 7. INTÉGRATION DE LA CLÉ PUBLIQUE DANS L'APPLICATION

### Emplacement dans le code

La clé publique doit être intégrée dans le fichier :
```
logesco_v2/lib/features/subscription/services/implementations/key_manager.dart
```

### Format de la clé publique

```dart
static const Map<String, String> _embeddedPublicKeys = {
  'key_v1': '''-----BEGIN PUBLIC KEY-----
VOTRE_CLE_PUBLIQUE_ICI_EN_FORMAT_PEM
-----END PUBLIC KEY-----''',
};
```

### Calcul du checksum d'intégrité

Pour chaque clé publique, calculez son hash SHA-256 :

```javascript
const crypto = require('crypto');

function calculateKeyIntegrity(publicKeyPem) {
  const hash = crypto.createHash('sha256');
  hash.update(publicKeyPem.trim());
  return hash.digest('hex');
}
```

Ajoutez le hash dans :

```dart
static const Map<String, String> _keyIntegrityHashes = {
  'key_v1': 'HASH_SHA256_DE_VOTRE_CLE_PUBLIQUE',
};
```

---

## 8. VALIDATION D'UNE LICENCE (Côté Application)

### Processus de validation

L'application LOGESCO valide une licence en plusieurs étapes :

1. **Vérification du format** : `LOGESCO_V1_<base64>`
2. **Décodage Base64** : Extraction du payload JSON
3. **Validation de la structure** : Tous les champs obligatoires présents
4. **Vérification de la signature RSA** : Avec la clé publique intégrée
5. **Vérification de l'expiration** : Date actuelle < date d'expiration
6. **Vérification de l'appareil** : Hash d'appareil correspond
7. **Validation des fonctionnalités** : Présence de toutes les fonctionnalités requises

### États possibles

- ✅ **Valide** : Licence active et valide - **Accès complet à toutes les fonctionnalités**
- ❌ **Invalide** : Format incorrect ou signature invalide - **Aucun accès**
- ⏰ **Expirée** : Date d'expiration dépassée - **Accès bloqué**
- 🔒 **Appareil non correspondant** : Hash d'appareil différent - **Accès bloqué**
- ⚠️ **Période de grâce** : 3 jours après expiration - **Accès complet avec notifications**

---

## 9. PÉRIODE DE GRÂCE

### Fonctionnement

Après l'expiration d'une licence, l'application accorde une **période de grâce de 3 jours** :

- L'utilisateur peut continuer à utiliser l'application **avec toutes les fonctionnalités**
- Des notifications d'expiration sont affichées régulièrement
- Après les 3 jours de grâce, l'accès est complètement bloqué

### Calcul de la période de grâce

```javascript
const gracePeriodDays = 3;
const gracePeriodEnd = new Date(expirationDate.getTime() + gracePeriodDays * 24 * 60 * 60 * 1000);

const isInGracePeriod = now > expirationDate && now < gracePeriodEnd;
```

---

## 10. STOCKAGE ET SÉCURITÉ

### Stockage côté application

Les licences sont stockées de manière sécurisée dans l'application :

- **Flutter Secure Storage** : Chiffrement natif de la plateforme
- **Validation périodique** : Vérification régulière de l'intégrité
- **Protection contre la manipulation** : Détection de modifications

### Bonnes pratiques pour l'admin

1. **Clé privée** : Ne JAMAIS partager ou exposer la clé privée
2. **Stockage sécurisé** : Garder la clé privée sur un serveur sécurisé
3. **Logs** : Enregistrer toutes les générations de licences
4. **Révocation** : Prévoir un mécanisme de révocation si nécessaire
5. **Rotation des clés** : Changer périodiquement les clés RSA

---

## 11. EXEMPLE DE BASE DE DONNÉES ADMIN

### Structure recommandée

```sql
CREATE TABLE clients (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  company VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE licenses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id VARCHAR(50) NOT NULL,
  license_key TEXT NOT NULL,
  subscription_type ENUM('trial', 'monthly', 'annual', 'lifetime') NOT NULL,
  issued_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  device_fingerprint VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  revoked_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (client_id) REFERENCES clients(id)
);

CREATE TABLE license_activations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  license_id INT NOT NULL,
  activated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  device_info JSON,
  ip_address VARCHAR(45),
  FOREIGN KEY (license_id) REFERENCES licenses(id)
);
```

---

## 12. API RECOMMANDÉE POUR L'INTERFACE ADMIN

### Endpoints suggérés

```
POST   /api/admin/clients              - Créer un client
GET    /api/admin/clients              - Lister les clients
GET    /api/admin/clients/:id          - Détails d'un client

POST   /api/admin/licenses             - Générer une licence
GET    /api/admin/licenses             - Lister les licences
GET    /api/admin/licenses/:id         - Détails d'une licence
PUT    /api/admin/licenses/:id/revoke  - Révoquer une licence
GET    /api/admin/licenses/:id/validate - Valider une licence

GET    /api/admin/stats                - Statistiques globales
```

### Exemple de requête pour générer une licence

```json
POST /api/admin/licenses
Content-Type: application/json

{
  "clientId": "CLIENT001",
  "subscriptionType": "annual",
  "deviceFingerprint": "ABC123DEF456789"
}
```

### Exemple de réponse

```json
{
  "success": true,
  "data": {
    "licenseId": 123,
    "licenseKey": "LOGESCO_V1_eyJ1c2VySWQiOiJDTElFTlQwMDEiLCJ0eXBlIjoiYW5udWFsIiwiaXNzdWVkIjoiMjAyNC0xMS0wN1QxMDozMDowMC4wMDBaIiwiZXhwaXJlcyI6IjIwMjUtMTEtMDdUMTA6MzA6MDAuMDAwWiIsImRldmljZSI6IkFCQzEyM0RFRjQ1Njc4OSIsImZlYXR1cmVzIjpbImZ1bGxfaW52ZW50b3J5Iiwic2FsZXMiLCJyZXBvcnRzIiwiYWR2YW5jZWRfYW5hbHl0aWNzIl0sInNpZ25hdHVyZSI6ImRHVnpkSE5wWjI1aGRIVnlaUT09In0=",
    "clientId": "CLIENT001",
    "subscriptionType": "annual",
    "issuedAt": "2024-11-07T10:30:00.000Z",
    "expiresAt": "2025-11-07T10:30:00.000Z",
    "features": ["full_inventory", "sales", "reports", "advanced_analytics", "cash_register", "expense_management", "user_management", "role_management", "backup_restore", "multi_device_sync"]
  }
}
```

---

## 13. CHECKLIST DE GÉNÉRATION

Avant de générer une licence, vérifiez :

- [ ] Client enregistré dans la base de données
- [ ] Type d'abonnement valide (`trial`, `monthly`, `annual`, `lifetime`)
- [ ] Hash d'appareil fourni par le client
- [ ] Clé privée RSA disponible et sécurisée
- [ ] Dates calculées correctement (émission et expiration)
- [ ] Fonctionnalités assignées selon le type d'abonnement
- [ ] Signature RSA générée avec SHA-256
- [ ] Payload encodé en Base64 valide
- [ ] Format final : `LOGESCO_V1_<base64>`
- [ ] Licence sauvegardée dans la base de données
- [ ] Email de confirmation envoyé au client

---

## 14. DÉPANNAGE

### Problèmes courants

#### Licence invalide après génération

- Vérifier que la clé publique dans l'application correspond à la clé privée utilisée
- Vérifier le format de la signature (doit être en Base64)
- Vérifier que les données signées sont exactement : `userId-type-issued-expires-device`

#### Signature ne correspond pas

- S'assurer d'utiliser RSA-SHA256 (pas SHA1 ou autre)
- Vérifier que la clé privée est au format PEM correct
- Vérifier que les dates sont au format ISO 8601

#### Licence expirée immédiatement

- Vérifier le calcul des dates d'expiration
- S'assurer que les dates sont en UTC
- Vérifier le format ISO 8601 : `YYYY-MM-DDTHH:mm:ss.sssZ`

---

## 15. EXEMPLE COMPLET D'UTILISATION

### Scénario : Nouveau client avec abonnement annuel

```javascript
// 1. Créer le client
const client = {
  id: 'CLIENT001',
  name: 'Jean Dupont',
  email: 'jean.dupont@example.com',
  company: 'Entreprise XYZ'
};

// 2. Le client installe LOGESCO et génère son hash d'appareil
// (fourni par le client via l'application)
const deviceHash = 'A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6';

// 3. Générer la licence
const license = generateLicense(
  client.id,
  'annual',
  deviceHash
);

// 4. Sauvegarder dans la base de données
saveLicenseToDatabase({
  clientId: client.id,
  licenseKey: license,
  subscriptionType: 'annual',
  issuedAt: new Date(),
  expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
  deviceFingerprint: deviceHash
});

// 5. Envoyer la licence au client par email
sendLicenseEmail(client.email, license);

console.log('Licence générée et envoyée avec succès !');
console.log('Clé de licence :', license);
```

---

## RÉSUMÉ DES POINTS CRITIQUES

1. **Format strict** : `LOGESCO_V1_<base64_payload>`
2. **Signature RSA-SHA256** : Obligatoire avec clé privée 2048 bits
3. **Dates ISO 8601** : Format UTC avec millisecondes
4. **Hash d'appareil** : Fourni par le client, unique par installation
5. **Fonctionnalités** : Selon le type d'abonnement
6. **Sécurité** : Clé privée JAMAIS exposée
7. **Validation** : L'application vérifie signature, dates, et appareil

---

## CONTACT ET SUPPORT

Pour toute question sur l'implémentation du système de licences, référez-vous à :

- Documentation technique : `logesco_v2/lib/features/subscription/README.md`
- Exemple de générateur : `logesco_v2/tools/license_generator_example.dart`
- Modèles de données : `logesco_v2/lib/features/subscription/models/`

---

**Version du document** : 1.0  
**Date** : 7 novembre 2024  
**Application** : LOGESCO V2
