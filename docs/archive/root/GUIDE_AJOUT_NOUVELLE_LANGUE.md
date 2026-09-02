# Guide: Ajouter une Nouvelle Langue à l'Application

## Vue d'ensemble

Ce guide explique comment ajouter une 3e langue (ou plus) à l'application Logesco. Nous utiliserons l'espagnol comme exemple, mais la procédure est identique pour toute autre langue.

## Étapes à Suivre

### Étape 1: Créer le Fichier de Traduction

Créez un nouveau fichier dans `logesco_v2/lib/core/translations/` pour votre nouvelle langue.

**Exemple: `es_translations.dart` (Espagnol)**

```dart
/// Traductions espagnoles de l'application
final Map<String, String> esTranslations = {
  // ==================================