LOGESCO v2 - Dossier Assets
============================

Ce dossier contient les fichiers necessaires pour la distribution de l'application.

CONTENU
-------

1. VC_redist.x64.exe (ou vc_redist.x64.exe)
   - Microsoft Visual C++ 2015-2022 Redistributable (x64)
   - Taille: ~25 MB
   - Utilise pour: Resoudre les problemes de DLL manquantes sur les machines clientes
   - Source: https://aka.ms/vs/17/release/vc_redist.x64.exe
   
   Ce fichier est automatiquement copie dans le package client lors de l'execution
   de preparer-pour-client.bat
   
   Note: Le script accepte les deux noms (VC_redist.x64.exe ou vc_redist.x64.exe)

UTILISATION
-----------

Le script preparer-pour-client.bat copie automatiquement vc_redist.x64.exe
dans le package client final:

  release\LOGESCO-Client\vcredist\vc_redist.x64.exe

Les utilisateurs finaux peuvent executer ce fichier pour installer les DLL
necessaires si l'application reclame des DLL manquantes.

MISE A JOUR
-----------

Pour mettre a jour VC_redist.x64.exe:
1. Telecharger la derniere version depuis:
   https://aka.ms/vs/17/release/vc_redist.x64.exe
2. Remplacer le fichier dans ce dossier
3. Reconstruire le package client avec preparer-pour-client.bat

TEST
----

Pour tester que le fichier sera correctement copie:
  test-copie-vcredist.bat

NOTES
-----

- Ce fichier n'est PAS inclus dans le controle de version Git (.gitignore)
- Taille approximative: 25 MB
- Version actuelle: Microsoft Visual C++ 2015-2022 Redistributable
