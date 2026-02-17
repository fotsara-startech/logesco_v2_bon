# Guide de Génération de Clés RSA pour LOGESCO

## ⚠️ IMPORTANT - Signature RSA en Production

L'implémentation actuelle utilise une **signature simplifiée pour le développement**. Pour la production, vous devez générer et utiliser une vraie paire de clés RSA 2048 bits.

## Étape 1 : Générer la Paire de Clés RSA

### Avec OpenSSL (Recommandé)

```bash
# Générer la clé privée (2048 bits)
openssl genrsa -out private_key.pem 2048

# Extraire la clé publique
openssl rsa -in private_key.pem -pubout -out public_key.pem
```

### Avec Node.js

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

## Étape 2 : Intégrer la Clé Privée dans l'Admin

### Option A : Variable d'environnement (Recommandé)

1. Créez un fichier `.env` à la racine du projet :
```
RSA_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
VOTRE_CLE_PRIVEE_ICI
-----END RSA PRIVATE KEY-----"
```

2. Ajoutez `.env` au `.gitignore`

3. Utilisez `flutter_dotenv` pour charger la clé

### Option B : Fichier sécurisé

Stockez `private_key.pem` dans un dossier sécurisé hors du contrôle de version.

## Étape 3 : Implémenter la Signature RSA Réelle

Remplacez la méthode `_generateRsaSignature` dans `lib/core/services/license_generator_service.dart` :

```dart
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

static String _generateRsaSignature(String data) {
  // Charger votre clé privée
  final privateKey = _loadPrivateKey();
  
  // Créer le signer RSA avec SHA-256
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
  
  // Initialiser avec la clé privée
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  
  // Signer les données
  final dataBytes = utf8.encode(data);
  final signature = signer.generateSignature(Uint8List.fromList(dataBytes));
  
  // Retourner en Base64
  return base64Encode(signature.bytes);
}

static RSAPrivateKey _loadPrivateKey() {
  // Charger depuis l'environnement ou un fichier sécurisé
  final pemString = Platform.environment['RSA_PRIVATE_KEY'] ?? '';
  return _parsePrivateKeyFromPem(pemString);
}

static RSAPrivateKey _parsePrivateKeyFromPem(String pem) {
  // Nettoyer le PEM
  final rows = pem.split('\n').where((row) {
    return row.isNotEmpty &&
        !row.startsWith('-----BEGIN') &&
        !row.startsWith('-----END');
  }).join('');

  // Décoder le Base64
  final keyBytes = base64Decode(rows);

  // Parser l'ASN.1
  final asn1Parser = ASN1Parser(keyBytes);
  final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

  // Extraire les composants de la clé RSA
  final modulus = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
  final privateExponent = (topLevelSeq.elements[3] as ASN1Integer).valueAsBigInteger;
  final p = (topLevelSeq.elements[4] as ASN1Integer).valueAsBigInteger;
  final q = (topLevelSeq.elements[5] as ASN1Integer).valueAsBigInteger;

  return RSAPrivateKey(modulus!, privateExponent!, p, q);
}
```

## Étape 4 : Intégrer la Clé Publique dans LOGESCO

La clé publique doit être intégrée dans l'application LOGESCO pour vérifier les signatures.

Fichier : `logesco_v2/lib/features/subscription/services/implementations/key_manager.dart`

```dart
static const Map<String, String> _embeddedPublicKeys = {
  'key_v1': '''-----BEGIN PUBLIC KEY-----
VOTRE_CLE_PUBLIQUE_ICI_EN_FORMAT_PEM
-----END PUBLIC KEY-----''',
};
```

## Étape 5 : Calculer le Checksum d'Intégrité

```dart
import 'package:crypto/crypto.dart';

String calculateKeyIntegrity(String publicKeyPem) {
  final hash = sha256.convert(utf8.encode(publicKeyPem.trim()));
  return hash.toString();
}
```

Ajoutez le hash dans LOGESCO :

```dart
static const Map<String, String> _keyIntegrityHashes = {
  'key_v1': 'HASH_SHA256_DE_VOTRE_CLE_PUBLIQUE',
};
```

## Dépendances Nécessaires

Ajoutez au `pubspec.yaml` si nécessaire :

```yaml
dependencies:
  pointycastle: ^3.7.3
  asn1lib: ^1.5.0
  flutter_dotenv: ^5.1.0  # Pour les variables d'environnement
```

## Sécurité

### ✅ À FAIRE :
- Générer une nouvelle paire de clés unique pour votre application
- Stocker la clé privée de manière sécurisée (variables d'environnement, coffre-fort)
- Ne JAMAIS commiter la clé privée dans Git
- Utiliser des permissions restrictives sur les fichiers de clés
- Changer les clés périodiquement (rotation)

### ❌ À NE PAS FAIRE :
- Utiliser la clé d'exemple fournie
- Commiter la clé privée dans le contrôle de version
- Partager la clé privée par email ou chat
- Stocker la clé privée en clair dans le code
- Utiliser la même clé pour plusieurs applications

## Test de la Signature

Pour tester que votre signature fonctionne :

```dart
void testSignature() {
  final testData = 'CLIENT001-annual-2024-11-07T10:00:00.000Z-2025-11-07T10:00:00.000Z-ABC123';
  final signature = LicenseGeneratorService._generateRsaSignature(testData);
  
  print('Signature générée : $signature');
  print('Longueur : ${base64Decode(signature).length} bytes');
  // Devrait être 256 bytes pour RSA 2048
}
```

## Support

Pour toute question sur l'implémentation RSA, consultez :
- Documentation PointyCastle : https://pub.dev/packages/pointycastle
- Spécifications LOGESCO : `PROMPT_SYSTEME_LICENCE_ADMIN.md`
