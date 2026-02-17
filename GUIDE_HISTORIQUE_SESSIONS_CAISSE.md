# Guide - Historique des Sessions de Caisse (Admin)

## Accès à l'Historique

En tant qu'**administrateur**, vous avez accès à l'historique complet de toutes les sessions de caisse.

### Méthode 1: Depuis la Page de Session de Caisse

1. **Ouvrir l'application**
2. **Aller dans le menu** → **Session de Caisse**
3. **Cliquer sur l'icône d'historique** (⏱️) dans la barre d'application (en haut à droite)

> ⚠️ **Note**: L'icône d'historique n'est visible que pour les administrateurs

### Méthode 2: Navigation Directe

Vous pouvez aussi accéder directement via la route:
```
/cash-session/history
```

## Fonctionnalités de l'Historique

### 1. Filtres de Période

L'historique propose plusieurs filtres prédéfinis:

- **Aujourd'hui**: Sessions du jour en cours
- **Hier**: Sessions de la veille
- **Cette semaine**: Sessions de la semaine en cours
- **Semaine dernière**: Sessions de la semaine précédente
- **Ce mois**: Sessions du mois en cours
- **Mois dernier**: Sessions du mois précédent
- **Période personnalisée**: Choisir une plage de dates spécifique
- **Toutes les sessions**: Afficher tout l'historique

### 2. Informations Affichées

Pour chaque session, vous verrez:

#### Informations Principales
- **Nom de la caisse**
- **Nom de l'utilisateur** (caissier/caissière)
- **Statut**: Active ou Fermée
- **Date et heure d'ouverture**
- **Durée de la session**

#### Informations Financières (Sessions Fermées)
- **Solde d'ouverture**: Montant initial déclaré
- **Solde de fermeture**: Montant final déclaré
- **Écart**: Différence entre attendu et déclaré
  - ✅ **Vert avec +**: Excédent (plus d'argent que prévu)
  - ❌ **Rouge avec -**: Manque (moins d'argent que prévu)

### 3. Détails d'une Session

**Cliquer sur une session** pour voir tous les détails:

- Caisse utilisée
- Utilisateur
- Dates et heures exactes (ouverture/fermeture)
- Durée totale
- Solde d'ouverture
- Solde attendu (calculé automatiquement)
- Solde déclaré à la fermeture
- **Écart** (mis en évidence avec couleur)

## Utilisation Pratique

### Vérifier les Écarts

1. **Filtrer par période** (ex: "Aujourd'hui")
2. **Regarder les sessions fermées**
3. **Identifier les écarts** (rouge = manque, vert = excédent)
4. **Cliquer sur la session** pour voir les détails complets

### Suivre les Performances

1. **Filtrer par "Cette semaine"**
2. **Comparer les durées** des sessions
3. **Vérifier les écarts** pour chaque caissier
4. **Identifier les tendances** (écarts récurrents)

### Audit Mensuel

1. **Sélectionner "Ce mois"** ou **"Mois dernier"**
2. **Exporter mentalement** les données importantes
3. **Analyser les écarts** par caissier
4. **Prendre des décisions** de gestion

## Codes Couleur

| Couleur | Signification |
|---------|---------------|
| 🟢 Vert | Session active OU Écart positif (excédent) |
| 🔴 Rouge | Écart négatif (manque) |
| ⚫ Gris | Session fermée (sans écart ou neutre) |

## Calcul Automatique des Écarts

Le système calcule automatiquement:

```
Solde Attendu = Solde Ouverture + Ventes - Dépenses
Écart = Solde Déclaré - Solde Attendu
```

**Exemple**:
- Ouverture: 10 000 FCFA
- Ventes: 50 000 FCFA
- Dépenses: 5 000 FCFA
- **Solde Attendu**: 10 000 + 50 000 - 5 000 = **55 000 FCFA**
- Solde Déclaré: 54 500 FCFA
- **Écart**: 54 500 - 55 000 = **-500 FCFA** (manque)

## Permissions

### Administrateur (Vous)
✅ Voir l'historique complet
✅ Voir tous les détails financiers
✅ Voir les écarts
✅ Filtrer par période
✅ Voir les sessions de tous les utilisateurs

### Caissier/Caissière
❌ Pas d'accès à l'historique
❌ Ne voit pas le solde attendu lors de la clôture
✅ Peut seulement gérer sa session active

## Actualisation

- **Bouton Actualiser** (🔄) en haut à droite
- Recharge automatiquement les données
- Utile après une nouvelle clôture de session

## Astuces

1. **Vérification quotidienne**: Consultez "Aujourd'hui" chaque soir
2. **Suivi hebdomadaire**: Analysez "Cette semaine" le lundi
3. **Bilan mensuel**: Exportez "Ce mois" en fin de mois
4. **Période personnalisée**: Utile pour des audits spécifiques

## Prochaines Fonctionnalités (À venir)

- 📊 Export Excel de l'historique
- 📈 Graphiques d'analyse des écarts
- 🔔 Alertes sur écarts importants
- 📧 Rapports automatiques par email
- 🖨️ Impression de l'historique

## Support

En cas de problème:
1. Vérifiez votre connexion internet
2. Actualisez la page (bouton 🔄)
3. Vérifiez que vous êtes bien administrateur
4. Contactez le support technique si le problème persiste
