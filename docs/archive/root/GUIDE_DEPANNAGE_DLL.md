# Guide de Dépannage - DLL Manquantes

## Problème : L'application réclame des DLL

### Symptômes
- Message d'erreur au lancement : "Le programme ne peut pas démarrer car XXX.dll est absent"
- DLL couramment manquantes :
  - `msvcp140.dll`
  - `vcruntime140.dll`
  - `vcruntime140_1.dll`

### Cause
L'application Flutter nécessite les bibliothèques Visual C++ Runtime qui ne sont pas toujours installées sur Windows.

---

## Solutions

### Solution 1 : Installer Visual C++ Redistributable (Recommandé)

1. **Exécuter le fichier inclus** (si disponible) :
   ```
   vcredist\vc_redist.x64.exe
   ```

2. **Ou télécharger depuis Microsoft** :
   - URL : https://aka.ms/vs/17/release/vc_redist.x64.exe
   - Nom complet : Microsoft Visual C++ 2015-2022 Redistributable (x64)

3. **Installation** :
   - Double-cliquer sur `vc_redist.x64.exe`
   - Accepter les conditions
   - Cliquer sur "Installer"
   - Redémarrer si demandé

### Solution 2 : Copier les DLL manuellement

Si vous ne pouvez pas installer le redistributable :

1. **Télécharger les DLL** depuis une machine qui fonctionne :
   - Emplacement : `C:\Windows\System32\`
   - Fichiers nécessaires :
     - `msvcp140.dll`
     - `vcruntime140.dll`
     - `vcruntime140_1.dll`

2. **Copier dans le dossier de l'application** :
   ```
   LOGESCO-Client\app\
   ```

### Solution 3 : Utiliser le script de vérification

Avant de lancer LOGESCO, exécutez :
```
VERIFIER-PREREQUIS.bat
```

Ce script vérifie tous les prérequis et indique ce qui manque.

---

## Prévention pour la Distribution

### Pour les développeurs

Lors de la préparation du package client, le script `preparer-pour-client.bat` :

1. **Copie automatiquement les DLL** depuis System32 (si disponibles)
2. **Télécharge vc_redist.x64.exe** pour inclusion dans le package
3. **Crée un script de vérification** des prérequis

### Inclure dans le package

Assurez-vous que votre package contient :
```
LOGESCO-Client/
├── DEMARRER-LOGESCO.bat
├── VERIFIER-PREREQUIS.bat
├── app/
│   ├── logesco_v2.exe
│   ├── msvcp140.dll          ← DLL copiées
│   ├── vcruntime140.dll      ← DLL copiées
│   └── vcruntime140_1.dll    ← DLL copiées
├── vcredist/
│   └── vc_redist.x64.exe     ← Installeur inclus
└── README.txt
```

---

## Instructions pour les Utilisateurs Finaux

### Avant la première utilisation

1. **Vérifier les prérequis** :
   ```
   Double-cliquer sur : VERIFIER-PREREQUIS.bat
   ```

2. **Si des prérequis manquent** :
   - **Node.js** : Télécharger depuis https://nodejs.org/
   - **Visual C++ Runtime** : Exécuter `vcredist\vc_redist.x64.exe`

3. **Lancer l'application** :
   ```
   Double-cliquer sur : DEMARRER-LOGESCO.bat
   ```

### En cas d'erreur de DLL

1. Installer Visual C++ Redistributable :
   ```
   vcredist\vc_redist.x64.exe
   ```

2. Redémarrer l'ordinateur

3. Relancer LOGESCO

---

## Dépannage Avancé

### Vérifier si Visual C++ Runtime est installé

**Via le Panneau de configuration** :
1. Ouvrir "Programmes et fonctionnalités"
2. Chercher "Microsoft Visual C++ 2015-2022 Redistributable (x64)"
3. Si absent, installer depuis `vcredist\vc_redist.x64.exe`

**Via le Registre** :
```cmd
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
```

### Réinstaller Visual C++ Runtime

Si déjà installé mais problèmes persistent :

1. Désinstaller toutes les versions de "Microsoft Visual C++ Redistributable"
2. Redémarrer
3. Installer la version 2015-2022 (x64)
4. Redémarrer

### Vérifier l'intégrité des DLL

```cmd
cd LOGESCO-Client\app
dir *.dll
```

Devrait afficher au minimum :
- `msvcp140.dll`
- `vcruntime140.dll`
- `vcruntime140_1.dll`
- `flutter_windows.dll`
- Autres DLL Flutter

---

## Checklist de Distribution

Pour éviter les problèmes chez les clients :

- [ ] Exécuter `preparer-pour-client.bat` pour créer le package
- [ ] Vérifier que les DLL sont dans `app\`
- [ ] Vérifier que `vcredist\vc_redist.x64.exe` est inclus
- [ ] Tester sur une machine Windows propre (VM recommandée)
- [ ] Inclure `VERIFIER-PREREQUIS.bat` dans le package
- [ ] Mettre à jour le README avec les instructions d'installation

---

## Support

### Machines de test recommandées

Tester sur :
- Windows 10 (version récente)
- Windows 11
- Machine virtuelle Windows propre (sans Visual Studio)

### Logs de débogage

En cas de problème persistant, vérifier :
- Logs backend : `backend\logs\error.log`
- Event Viewer Windows : Erreurs d'application

---

## Résumé

**Problème principal** : DLL Visual C++ Runtime manquantes

**Solution rapide** : Installer `vcredist\vc_redist.x64.exe`

**Solution automatique** : Le script `preparer-pour-client.bat` copie les DLL et inclut l'installeur

**Prévention** : Toujours tester sur une machine Windows propre avant distribution
