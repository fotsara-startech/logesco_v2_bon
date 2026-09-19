# Jeu de données de démonstration — Quincaillerie

Script : `seed-demo-quincaillerie.js`
Destiné aux captures d'écran du site web et aux démos commerciales.

---

## Ce que contient la base

**Entreprise** — QUINCAILLERIE LE BÂTISSEUR SARL, Yaoundé.
100 % fictive : nom, NUI, RCCM, adresses, téléphones, clients et fournisseurs
sont inventés. Aucune donnée réelle, les images peuvent être publiées.

| | |
|---|---|
| Secteur | Quincaillerie / matériaux de construction, gamme cohérente |
| Boutiques | Magasin Central — Nkoldongo (principale) · Agence Mvan |
| Produits | 241 références dans 13 rayons, dont 5 prestations facturées |
| Clients | 43, dont 14 professionnels avec NUI et RCCM |
| Fournisseurs | 8 |
| Historique | 1er mars → 6 août 2026 (6 mois) |
| Ventes | 974, réparties sur ~135 jours d'ouverture (fermé le dimanche) |
| Approvisionnement | 58 commandes fournisseurs, réceptions au fil des jours |
| TVA | 19,25 %, facturée aux professionnels uniquement |

**Chiffres de référence — juillet 2026 (dernier mois complet)**

| | |
|---|---|
| Ventes | 209 |
| Chiffre d'affaires | 16 096 781 FCFA |
| Marge brute | 4 012 926 FCFA |
| Dépenses d'exploitation | 1 432 000 FCFA |
| Bénéfice net | 2 580 926 FCFA (16 %) |

**Août 2026 au 6 (mois en cours)** — 45 ventes, 3 340 751 FCFA.
C'est ce que le tableau de bord affiche dans la tuile « ce mois » : le mois
n'a que cinq jours d'ouverture écoulés, c'est normal et cohérent.

---

## Comptes

| Utilisateur | Rôle | Usage |
|---|---|---|
| `Thierry Nkoulou` | Gérant (accès complet) | **compte à utiliser pour les captures** |
| `Alice Mballa` | Caissier | session de caisse ouverte aujourd'hui |
| `Patrick Essomba` | Caissier | |
| `Sandrine Ngo Bell` | Caissier | Agence Mvan |
| `Rodrigue Ekani` | Magasinier | inventaires |

Mot de passe pour tous : `Demo2026!`

Le compte `admin` existe mais est **désactivé**. Il ne doit pas être supprimé :
l'application le recrée automatiquement au démarrage s'il est absent
(`AdminService.ensureAdminExists`), et il réapparaîtrait sur les captures.

---

## Les 6 captures — où trouver la donnée

### 1. Facture
Ventes → aujourd'hui → **VTE-20260806-0830095**
ENTREPRISE SOGEBAT SARL · 6 lignes cohérentes (fer à béton, treillis, hourdis,
livraison) · sous-total 634 400 · TVA 19,25 % 122 122 · **total 756 522 FCFA**.
Le client a un NUI et un RCCM, ils apparaîtront sur la facture.

Pour un **devis** plutôt qu'une facture : Proformas → `PRF-202608-0001`,
ETS BATIR PLUS SARL, 6 lignes, 2 107 386 FCFA.

> Pensez à charger le logo de l'entreprise dans Paramètres avant la capture :
> le champ existe et il est vide. C'est un argument fort sur la facture.

### 2. Caisse en session
Se connecter en **Alice Mballa**. Sa session sur la Caisse Principale est
ouverte depuis ce matin 7 h 5x, fond de caisse 100 000 FCFA, 7 ventes déjà
encaissées. Le panier en cours est un état d'écran, pas une donnée : ajoutez
4-5 articles au panier juste avant de déclencher la capture.

⚠️ LOGESCO ne gère que **comptant** et **crédit**. Il n'y a ni Mobile Money ni
carte dans le flux de vente. Cette capture ne peut donc pas montrer le mobile
money — c'est un développement, pas un problème de données.

### 3. Stock avec alertes
Stock / Inventaire, boutique Magasin Central. 10 références sous le seuil,
dont **2 en rupture totale** :

| Référence | Produit | Qté | Seuil |
|---|---|---|---|
| CIM-002 | Ciment CPJ 42.5R — sac de 50 kg | **0** | 60 |
| FER-012 | Fer à béton HA 12 mm — barre de 12 m | **0** | 40 |
| ELE-002 | Câble souple 2 × 2.5 mm² — rouleau 100 m | 3 | 10 |
| ELP-004 | Meuleuse d'angle 125 mm — 900 W | 3 | 8 |
| PVC-110 | Tube PVC évacuation Ø 110 — 3 m | 4 | 10 |
| PEI-001 | Peinture à eau blanche — seau de 20 L | 5 | 12 |
| SAN-010 | Mitigeur lavabo chromé | 6 | 12 |
| TOI-001 | Tôle bac aluzinc 30/100 — 3 m | 7 | 25 |
| QUI-002 | Pointe 60 mm — au kilo | 24 | 40 |
| CIM-001 | Ciment CPJ 35 — sac de 50 kg | 33 | 60 |

Les deux ruptures sont les best-sellers du rayon : c'est exactement l'objection
que la capture doit lever.

### 4. Tableau de bord
Voir les deux réserves plus bas — la carte Rentabilité a un défaut d'affichage
à corriger avant de capturer.

### 5. Fiche client avec solde
Clients → **CONSTRUCTIONS MEKONGO & FILS** → Compte.
15 achats, 36 écritures, **dette de 263 086 FCFA** affichée en rouge.

Autres bons candidats : PLOMBERIE SERVICE PLUS (230 089 FCFA, 12 achats),
COMPLEXE SCOLAIRE LA SEMENCE (225 717 FCFA, 14 achats).
Total des créances en cours : 1 266 097 FCFA sur 14 comptes.

### 6. Rapport de ventes
Sélectionner **juillet 2026** : mois complet, 209 ventes, courbe sur 27 jours
d'ouverture. L'historique remonte à mars, une période « 6 derniers mois » donne
une courbe croissante (coefficient mensuel 0,90 → 1,18).

---

## Deux points à régler avant de capturer le tableau de bord

Ce sont des correctifs de code, pas de données.

1. **`BOTTOM OVERFLOWED BY 38 PIXELS`** sur la carte Rentabilité
   (`lib/features/dashboard/widgets/profitability_stat_card.dart`). La `Column`
   empile en-tête + titre + montant + marge + pastille de statut pour environ
   198 px de contenu dans une cellule de grille plus courte.

2. **Montant non formaté.** La carte affiche
   `netProfit.toStringAsFixed(0)`, soit `2580926 FCFA` au lieu de
   `2 580 926 FCFA`. Même chose dans `accounting_summary_widget.dart`.
   Sur une capture destinée à vendre de la gestion, ça se voit.

---

## Relancer la génération

Le générateur est **déterministe** (graine fixe) : deux exécutions produisent
exactement les mêmes chiffres, donc les mêmes captures.

```bash
cd "C:/Users/DIGITAL MARKET/AppData/Local/LOGESCO/backend"
DATABASE_URL="file:C:/Users/DIGITAL MARKET/AppData/Local/LOGESCO/backend/database/logesco.db" ./node.exe scripts/seed-demo-quincaillerie.js
```

⚠️ Le script **efface toutes les données métier** de la base ciblée avant de
régénérer. À n'exécuter que sur une base de démonstration.

La date de référence est figée au 6 août 2026 (`AUJOURDHUI` en tête de script).
Si vous capturez un autre jour, la session de caisse « ouverte » et les ventes
du jour ne tomberont plus sur la date du système : ajustez `AUJOURDHUI` et
relancez.

**Synchronisation cloud** — `CLOUD_DB_URL` est commenté dans le `.env` et le
champ `dateModification` est laissé à `null` sur les enregistrements générés.
Ce jeu de démonstration ne remontera pas vers Neon.
