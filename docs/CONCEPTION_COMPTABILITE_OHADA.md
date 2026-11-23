# Conception du module Comptabilité (SYSCOHADA – Cameroun)

> Statut : **phases 1 et 2 réalisées** (socle, puis écritures automatiques — voir les sections « État de la phase » en fin de document). Les phases 3 et 4 restent à faire.
> Les points marqués **[À VALIDER]** doivent être confirmés par un expert-comptable camerounais avant mise en production auprès de clients.

---

## 1. Contexte et objectifs

LOGESCO dispose aujourd'hui d'un module « Comptabilité » qui est en réalité un **tableau de bord de gestion** : il calcule à la volée chiffre d'affaires, coût des marchandises vendues, marge, dépenses et bénéfice à partir des ventes et des `FinancialMovement`. Il n'existe ni plan comptable, ni journaux, ni écritures, ni grand livre, ni exercice comptable.

**Objectif** : ajouter une vraie comptabilité en partie double conforme au **SYSCOHADA révisé (2018)**, applicable au Cameroun, utilisable :

- par des **commerçants sans comptable** (tout est automatique, vocabulaire simple) ;
- par des **cabinets et entreprises** (accès complet aux écritures, journaux, grand livre, balance, clôture).

Deux régimes à supporter : **Système Normal** et **Système Minimal de Trésorerie (SMT)**.

### Hors périmètre (pour l'instant)
- Paie (CNPS, IRPP, bulletins).
- Télédéclaration en ligne (DGI/Téléphone) : on produit les états, pas la transmission.
- Consolidation multi-sociétés (une base = une entité juridique ; les boutiques sont des axes analytiques, pas des sociétés).
- Reprise de l'historique antérieur à la date d'ouverture.

---

## 2. Constat de l'existant (ce sur quoi on s'appuie)

| Source | Modèle Prisma | Utilité comptable |
|---|---|---|
| Ventes | `Vente`, `DetailVente` | CA, TVA collectée, créances clients, remises, ventes annulées (`statut`, `annule`) |
| Règlements / soldes | `TransactionCompte` (clients & fournisseurs) | Mouvements 411 / 401, avances (`avanceUtilisee`) |
| Achats | `CommandeApprovisionnement`, `DetailCommande…` | Achats, dettes fournisseurs, TVA récupérable |
| Caisse | `CashRegister`, `CashSession`, `CashMovement` | Comptes 57x, écarts de caisse |
| Dépenses / recettes diverses | `FinancialMovement`, `MovementCategory` | Charges (classe 6) par catégorie |
| Stock | `Stock`, `MouvementStock`, `StockInventory`, CUMP | Classe 3, variation de stocks |
| Paramètres | `ParametresEntreprise` (`tauxTva`, `nuiRccm`) | Régime fiscal, taux de TVA, identifiants |
| Boutiques | `Boutique` (+ `boutiqueId` partout) | Axe analytique |

### Contraintes techniques à respecter
- **Double moteur de base de données** : SQLite embarqué (local) et PostgreSQL/Neon (cloud), avec un service de synchronisation (`sync-service.js`). Le schéma doit rester compatible avec les deux et chaque ajout nécessite une migration pour les deux.
- **Montants en `Float` dans l'existant.** Pour la comptabilité on utilise des **entiers en FCFA** (le FCFA n'a pas de décimales) afin d'éviter les erreurs d'arrondi et garantir l'équilibre débit = crédit au franc près.
- Application multi-boutiques et multi-postes : la numérotation et l'idempotence doivent tenir compte de la synchronisation.

---

## 3. Principes directeurs

1. **Partie double stricte** : toute écriture est équilibrée (Σ débit = Σ crédit), vérifié en base et dans le service.
2. **Écritures automatiques par défaut** : un événement métier (vente, achat, règlement…) génère ses écritures sans intervention.
3. **Règles d'imputation dans un fichier de configuration**, pas en dur dans le code. Un comptable doit pouvoir relire et corriger la table « opération → comptes » (cf. §6) sans lire du JavaScript.
4. **Inaltérabilité** : une écriture validée ne se modifie ni ne se supprime. Correction = **contre-passation** (écriture inverse) + nouvelle écriture.
5. **Calcul côté backend** (pas dans Flutter), pour être cohérent, auditable et identique quel que soit le poste.
6. **Idempotence** : un même événement source ne peut produire ses écritures qu'une seule fois (clé unique `sourceType + sourceId + rôle`).
7. **Un seul jeu de données, deux interfaces** (mode simple / mode expert) ; le régime fiscal filtre les états, il ne duplique pas les données.
8. **Démarrage à une date d'ouverture** : aucune reprise d'historique ; un assistant saisit le bilan d'ouverture.

---

## 4. Référentiel réglementaire (résumé)

- **SYSCOHADA révisé 2018** (Acte uniforme OHADA relatif au droit comptable) : plan comptable en classes 1 à 9, états financiers annuels (Bilan, Compte de résultat, TAFIRE, Notes annexes), tenue des livres (journal, grand livre, balance, inventaire).
- **Cameroun** : déclaration annuelle **DSF** (Déclaration Statistique et Fiscale) au format OHADA ; **TVA** au taux normal de **19,25 %** (17,5 % + 10 % de centimes additionnels communaux) **[À VALIDER chaque année – Loi de finances]**.
- **Régimes** :
  - *Système Normal* : comptabilité d'engagement complète.
  - *SMT* : comptabilité de trésorerie simplifiée (recettes/dépenses), états allégés. Seuils de CA applicables **[À VALIDER]**.
- **Autres impositions** : en v1, seule la **TVA** a un traitement dédié (comptes 4431/4452 + état mensuel). L'acompte / minimum de perception, l'impôt sur les sociétés ou sur le revenu, la patente, les droits d'accises et la CNPS sont enregistrés **par écriture manuelle (journal OD)** sur des comptes pré-chargés (44x, 64, 431, 891). Des états dédiés viendront en phase 4 **[À VALIDER]**.

---

## 5. Modèle de données

Toutes les nouvelles tables sont préfixées `compta_` pour être isolées du reste. Montants en `Int` (FCFA).

### 5.1 Entités

```prisma
model ComptaExercice {
  id            Int       @id @default(autoincrement())
  libelle       String                       // « Exercice 2027 »
  dateDebut     DateTime  @map("date_debut")
  dateFin       DateTime  @map("date_fin")
  statut        String    @default("ouvert") // ouvert | cloture
  dateCloture   DateTime? @map("date_cloture")
  periodes      ComptaPeriode[]
  ecritures     ComptaEcriture[]
  @@map("compta_exercices")
}

model ComptaPeriode {                          // mois comptable
  id          Int      @id @default(autoincrement())
  exerciceId  Int      @map("exercice_id")
  mois        Int                              // rang du mois dans l'exercice (1..N, N <= 24)
  statut      String   @default("ouverte")    // ouverte | verrouillee
  exercice    ComptaExercice @relation(fields: [exerciceId], references: [id])
  @@unique([exerciceId, mois])
  @@map("compta_periodes")
}

model ComptaCompte {                           // plan comptable
  id              Int     @id @default(autoincrement())
  numero          String  @unique              // « 701 », « 4431 », « 411001 »
  libelle         String
  classe          Int                           // 1..9
  nature          String                        // actif|passif|charge|produit|tresorerie|tiers|hors_bilan
  sens            String?                       // sens normal : debit | credit
  parentNumero    String? @map("parent_numero")
  estCollectif    Boolean @default(false) @map("est_collectif") // 411, 401…
  lettrable       Boolean @default(false)
  systeme         Boolean @default(true)        // fourni par SYSCOHADA (non supprimable)
  actif           Boolean @default(true)
  @@map("compta_comptes")
}

model ComptaJournal {
  id        Int    @id @default(autoincrement())
  code      String @unique                     // VT, AC, CA, BQ, OD, AN
  libelle   String
  type      String                             // ventes|achats|caisse|banque|od|a_nouveaux
  @@map("compta_journaux")
}

model ComptaEcriture {                         // en-tête = une « pièce »
  id            Int       @id @default(autoincrement())
  exerciceId    Int       @map("exercice_id")
  journalId     Int       @map("journal_id")
  numeroPiece   String?   @map("numero_piece")  // attribué à la validation : VT-2027-000123
  dateEcriture  DateTime  @map("date_ecriture")
  libelle       String
  statut        String    @default("brouillon")  // brouillon | validee | contrepassee
  origine       String                            // auto | manuelle | ouverture | cloture
  sourceType    String?   @map("source_type")     // vente | achat | reglement_client | …
  sourceId      Int?      @map("source_id")
  sourceRole    String?   @map("source_role")     // ex. « ca », « cmv » : plusieurs pièces par source
  contrepasseId Int?      @map("contrepasse_id")  // pièce annulée par celle-ci
  boutiqueId    Int?      @map("boutique_id")
  utilisateurId Int?      @map("utilisateur_id")
  dateCreation  DateTime  @default(now()) @map("date_creation")
  lignes        ComptaLigne[]
  exercice      ComptaExercice @relation(fields: [exerciceId], references: [id])
  journal       ComptaJournal  @relation(fields: [journalId], references: [id])
  @@unique([sourceType, sourceId, sourceRole], map: "uq_ecriture_source")
  @@index([exerciceId, dateEcriture])
  @@map("compta_ecritures")
}

model ComptaLigne {
  id          Int     @id @default(autoincrement())
  ecritureId  Int     @map("ecriture_id")
  compteId    Int     @map("compte_id")
  tiersType   String? @map("tiers_type")       // client | fournisseur
  tiersId     Int?    @map("tiers_id")
  libelle     String?
  debit       Int     @default(0)
  credit      Int     @default(0)
  lettrage    String?                            // code de lettrage
  boutiqueId  Int?    @map("boutique_id")       // axe analytique
  ecriture    ComptaEcriture @relation(fields: [ecritureId], references: [id], onDelete: Cascade)
  @@index([compteId])
  @@index([tiersType, tiersId])
  @@map("compta_lignes")
}

model ComptaParametres {                        // 1 ligne
  id                    Int     @id @default(1)
  regime                String  @default("normal")  // normal | smt
  modeAffichage         String  @default("simple")  // simple | expert
  dateOuverture         DateTime? @map("date_ouverture")
  exerciceDefautId      Int?    @map("exercice_defaut_id")
  tauxTvaDefaut         Float   @default(19.25) @map("taux_tva_defaut")
  assujettiTva          Boolean @default(true) @map("assujetti_tva")
  longueurComptesTiers  Int     @default(6)
  @@map("compta_parametres")
}
```

Contraintes SQL complémentaires (migration brute) : `CHECK (debit >= 0 AND credit >= 0 AND NOT (debit > 0 AND credit > 0))` sur `compta_lignes`.

### 5.2 Comptes de tiers
Pour la balance auxiliaire, on **ne crée pas un compte par client/fournisseur** : la ligne porte `compteId = 411 / 401` et `tiersType/tiersId`. Le grand livre auxiliaire est une vue filtrée. Un cabinet qui exige des comptes 411xxxx obtient le numéro affiché `411` + code client formaté (option `longueurComptesTiers`).

### 5.3 Numérotation et synchronisation
- Une écriture **brouillon** n'a pas de numéro. Le numéro de pièce est attribué **à la validation**, séquentiel par journal et exercice.
- Les écritures **automatiques** sont des **données dérivées**, recalculables à partir de leur événement source grâce à la clé unique `(sourceType, sourceId, sourceRole)`. **Décision : génération centralisée** — les écritures automatiques sont produites uniquement par le backend de référence (Neon / serveur central) et jamais par les postes ; les postes les reçoivent par synchronisation. La clé d'idempotence évite les doublons en cas de rejeu. **Constat après analyse de `sync-service.js` (phase 1)** : chaque poste écrit en SQLite local avec sa propre plage d'identifiants (`installation.js`) et pousse vers Neon par file d'opérations ; les postes se resynchronisent par réception. En conséquence : (1) en **phase 1** la saisie manuelle se fait sur n'importe quel poste, les écritures se synchronisent comme les autres tables (tables ajoutées à `PULL_TABLES`, références avant écritures avant lignes) et le numéro de pièce porte le suffixe de poste (`-P2`…) comme les ventes ; (2) en **phase 2** la génération automatique sera confiée au **poste de référence** (poste 1, ou le serveur Postgres en mode cloud), qui lit les ventes et achats déjà synchronisés : elle fonctionne par rattrapage incrémental et idempotent (clé source) et reste correcte même si des postes ont travaillé hors ligne ; (3) le plan comptable et les journaux livrés ont des **identifiants fixes** (bande 8 000 000+, `referentiel.js`) pour être identiques sur tous les postes sans conflit de synchronisation : on ne les complète qu'à la fin du JSON.

---

## 6. Règles d'imputation automatiques

Fichier de configuration prévu : `backend/src/compta/regles-imputation.json` (lisible et modifiable par un comptable). Les comptes ci-dessous sont des **propositions SYSCOHADA [À VALIDER]**.

### 6.1 Ventes (journal VT)

| Événement | Débit | Crédit |
|---|---|---|
| Vente à crédit (montant TTC) | 411 Clients (TTC) | 701 Ventes de marchandises (HT) ; 4431 TVA facturée (TVA) |
| Remise accordée sur facture | — (incluse dans le HT) — option : 709 RRR accordés | — |
| Encaissement comptant espèces | 571 Caisse | 411 Clients |
| Encaissement mobile money / banque | 52x Banque / 578 Mobile money | 411 Clients |
| Utilisation d'une avance client (`avanceUtilisee`) | 4191 Clients – avances reçues | 411 Clients |
| Annulation de vente / article annulé | Contre-passation de la pièce de vente (+ des encaissements éventuels) | |

> Une vente comptant génère **deux lignes logiques** (vente puis encaissement) : le compte 411 est soldé immédiatement, ce qui garde un traitement unique pour comptant et crédit et alimente la balance âgée.

### 6.2 Achats (journal AC)

| Événement | Débit | Crédit |
|---|---|---|
| Réception de commande (HT / TVA / TTC) | 601 Achats de marchandises (HT) ; 4452 TVA récupérable sur achats | 401 Fournisseurs (TTC) |
| Règlement fournisseur | 401 Fournisseurs | 571 / 52x |
| Avance fournisseur | 4091 Fournisseurs – avances versées | 571 / 52x |
| Frais d'approche (transport sur achats) | 6 1x / 6 0x à compléter | 401 ou 571 |

### 6.3 Stocks — **décision de conception**

Deux approches existent :

- **Inventaire intermittent** (usage courant SYSCOHADA) : achats en 601 ; à chaque clôture de période, une écriture de **variation de stocks** (6031 / 31) est calculée à partir de la valorisation CUMP du stock réel.
- **Inventaire permanent** : 31 débité à l'achat, 6031 débité à chaque vente.

**Recommandation : intermittent avec écriture de variation à chaque clôture mensuelle**, car elle garde les écritures de vente simples et colle à la pratique comptable usuelle. Le CMV (coût des marchandises vendues) du tableau de bord actuel est conservé pour la gestion. **[À VALIDER]**

### 6.4 Trésorerie et caisse (journaux CA / BQ)

| Événement | Débit | Crédit |
|---|---|---|
| Entrée d'argent en caisse (apport, recette diverse) | 571 | compte selon catégorie (ex. 758, 101…) |
| Sortie d'argent / dépense | compte de charge selon catégorie (§6.5) | 571 |
| Écart de caisse négatif | 658 Charges diverses | 571 |
| Écart de caisse positif | 571 | 758 Produits divers |
| Virement caisse ↔ banque | 52x ou 571 | 571 ou 52x (via 585 si besoin) |

### 6.5 Dépenses : correspondance catégorie → compte de charge

Chaque `MovementCategory` reçoit un champ `compteComptable` (modifiable). Valeurs proposées par défaut **[À VALIDER]** :

| Catégorie type | Compte |
|---|---|
| Loyer | 622 Locations et charges locatives |
| Électricité / eau | 605 Autres achats (eau, énergie) |
| Transport / carburant | 61 Transports |
| Téléphone / internet | 628 Frais de télécommunications |
| Salaires et main-d'œuvre | 661 Rémunérations directes |
| Entretien / réparations | 624 Entretien, réparations et maintenance |
| Fournitures de bureau | 604 Achats de matières et fournitures consommables |
| Publicité | 627 Publicité, publications |
| Frais bancaires | 631 Frais bancaires |
| Impôts et taxes | 64 Impôts et taxes |
| Autre / non classé | 658 Charges diverses |

La TVA déductible sur dépenses est facultative : la catégorie porte un indicateur « TVA récupérable » (v2).

### 6.6 TVA
- 4431 = TVA facturée sur ventes (collectée) ; 4452 = TVA récupérable sur achats.
- **Déclaration mensuelle** : TVA à décaisser = 4431 − 4452 (− crédit de TVA reporté). Un état dédié sera fourni (§8) ; la comptabilisation du règlement à l'État se fait par écriture OD (44 → 52x).

### 6.7 Clôtures
- **Mensuelle** : verrouillage de la période, écriture de variation de stocks, contrôle d'équilibre.
- **Annuelle** : détermination du résultat (classes 6 et 7 → 13), génération des **à-nouveaux** (journal AN) de l'exercice suivant, affectation du résultat (report à nouveau 12).
- **Hors v1** : amortissements, provisions, charges constatées d'avance, régularisations de fin d'exercice (saisie manuelle en OD en attendant).

---

## 7. Moteur d'écritures (architecture backend)

```
backend/src/compta/
  regles-imputation.json      # table opération → comptes (relue par un comptable)
  plan-comptable-syscohada.json  # comptes pré-chargés
  comptaService.js            # création / validation / contre-passation
  generateurs/                # un fichier par événement : vente, achat, reglement, caisse, depense…
  etats/                      # grand livre, balance, bilan, compte de résultat, TVA…
  routes/compta.js            # /api/v1/compta/*
```

**Déclenchement** : après la transaction métier (vente validée, réception d'achat, paiement…), appel du générateur correspondant **dans la même transaction Prisma** autant que possible. Si la génération échoue, l'événement métier **n'est pas bloqué** : l'événement est mis en file `compta_a_generer` et rejoué (la vente reste prioritaire sur la compta). Un écran « Écritures en attente / en erreur » permet de les traiter.

**Idempotence** : `uq_ecriture_source` ; relancer un générateur sur le même événement renvoie la pièce existante.

**Annulations** : les routes d'annulation de vente appellent `contrepasser(source)`. Elles existent déjà (cf. `routes/sales.js`) et recevront ce hook.

**Périodes verrouillées** : toute tentative d'écrire dans une période ou un exercice clôturé est refusée ; si un événement métier a une date dans une période close (ex. vente antidatée), l'écriture est datée du premier jour de la première période ouverte et un avertissement est consigné.

---

## 8. États produits

| État | Normal | SMT | Mode |
|---|---|---|---|
| Journaux (VT, AC, CA, BQ, OD) | ✔ | ✔ (livre-journal simplifié) | expert |
| Grand livre (général et auxiliaire) | ✔ | — | expert |
| Balance générale / par tiers | ✔ | — | expert |
| Balance âgée clients / fournisseurs | ✔ | ✔ | simple + expert |
| Déclaration de TVA mensuelle (support) | ✔ | selon régime | simple + expert |
| Compte de résultat SYSCOHADA | ✔ | simplifié | simple + expert |
| Bilan SYSCOHADA | ✔ | simplifié | expert (bêta) |
| TAFIRE, notes annexes, DSF | ✔ | — | v4, bêta |
| Livre des recettes / dépenses, état de trésorerie | — | ✔ | simple |
| Exports PDF / Excel / CSV (FEC-like) | ✔ | ✔ | tous |

États **« officiels »** (bilan, compte de résultat réglementaire, DSF) : étiquetés **« Version bêta – à faire valider par votre comptable »** tant que la validation externe n'a pas eu lieu.

---

## 9. Interface (Flutter)

### 9.1 Mode simple (par défaut)
Aucun vocabulaire comptable brut. Écrans :
- **Résumé financier** : résultat du mois, trésorerie, argent dû par les clients, argent dû aux fournisseurs, TVA à payer.
- **Résultat** (compte de résultat en langage clair) et **Trésorerie**.
- **Créances / dettes** (balance âgée).
- **TVA du mois**.
- Bouton « Exporter pour mon comptable » (envoi du journal + grand livre + balance en Excel/PDF).

### 9.2 Mode expert (activé dans Paramètres)
Écrans supplémentaires, regroupés dans le module Comptabilité :
1. **Plan comptable** (ajout de comptes auxiliaires, désactivation).
2. **Journaux et écritures** (liste, filtres, saisie manuelle en partie double avec contrôle d'équilibre, validation, contre-passation).
3. **Grand livre**, **balance**, **lettrage** (rapprochement facture ↔ règlement).
4. **Exercices et périodes** (ouverture, verrouillage, clôture).
5. **Écritures en attente / erreurs** de génération automatique.
6. **Règles d'imputation** (lecture/édition de la table §6).

### 9.3 Assistant d'ouverture (première configuration)
Étapes : choix du régime (Normal/SMT) → date d'ouverture et exercice → assujettissement et taux de TVA → soldes d'ouverture (caisse, banque, mobile money, stock valorisé, créances clients, dettes fournisseurs, capital, report) avec **contrôle d'équilibre automatique** (la différence va en compte d'attente 47 ou 12, à solder) → validation → génération de l'écriture d'à-nouveaux (journal AN).

### 9.4 Internationalisation
Les libellés suivent le système existant (`fr_translations.dart`, `en_translations.dart`, `es_translations.dart`). Le plan comptable est livré en **français** (langue légale OHADA) ; les libellés d'interface sont traduits.

---

## 10. Permissions, audit, sécurité

- Nouvelles permissions granulaires dans le système de rôles existant : module **`accounting`** (déjà utilisé pour le menu Comptabilité) avec les privilèges `READ` (consulter), `CREATE` (saisir des brouillons, créer des comptes), `VALIDATE` (valider et contre-passer), `CLOSE` (verrouiller une période), `MANAGE` (paramètres, exercices, ouverture). Un administrateur a tous les droits. Attention : les rôles qui avaient déjà `accounting:READ` (tableau de bord de gestion) peuvent désormais aussi **consulter** les écritures.
- Journal d'audit (`OperationLog` existant) pour : validation, contre-passation, clôture, modification de règles.
- Aucune suppression physique d'écriture validée (contrainte applicative + trigger SQL).
- Sauvegarde/export avant clôture annuelle (rappel obligatoire).

---

## 11. Plan de réalisation par phases

| Phase | Contenu | Livrable testable |
|---|---|---|
| **1 – Socle** | Schéma + migrations (SQLite & Postgres), plan comptable OHADA pré-chargé, journaux, exercices/périodes, paramètres, assistant d'ouverture, saisie manuelle, validation/contre-passation, grand livre, balance | Un comptable saisit des écritures et obtient grand livre/balance justes |
| **2 – Automatisation** | Générateurs vente, achat, règlements clients/fournisseurs, caisse, dépenses, annulations, TVA ; file d'attente d'erreurs ; correspondance catégories → comptes | Chaque opération métier produit les bonnes écritures, équilibrées et sans doublon |
| **3 – États** | Compte de résultat, bilan, déclaration de TVA, balance âgée, lettrage, mode simple complet, exports, SMT | Un commerçant lit son résultat/TVA ; un cabinet exporte ses états |
| **4 – Avancé** | Variation de stocks automatique, clôture annuelle + à-nouveaux, immobilisations et amortissements, rapprochement bancaire, TAFIRE/DSF, (paie en option) | Clôture d'un exercice complet |

Chaque phase se termine par des **tests automatisés** : équilibre systématique, idempotence, annulation, période verrouillée, parité SQLite/Postgres.

---

## 12. Risques et points ouverts

| # | Risque / question | Mitigation |
|---|---|---|
| 1 | **Aucun expert-comptable pour valider** les imputations et formats d'états | Règles externalisées (§6), états officiels en « bêta », validation externe avant mise en vente aux cabinets |
| 2 | Taux et seuils fiscaux qui changent chaque année (TVA, SMT, minimum de perception) | Paramètres modifiables, jamais codés en dur ; revue annuelle |
| 3 | **Synchronisation** SQLite ↔ Postgres : doublons ou écarts d'écritures | Clé d'idempotence, génération centralisée si possible, analyse de `sync-service.js` avant la phase 2 |
| 4 | Montants `Float` existants → écarts d'arrondi sur TVA | Arrondi au franc par ligne, règle d'arrondi documentée, écart d'arrondi ventilé sur la ligne de produit |
| 5 | Ventes déjà annulées / modifiées après coup | Contre-passation avec hook dans les routes existantes ; test des scénarios d'annulation partielle (`DetailVente.annule`) |
| 6 | Périmètre très large | Découpage en phases, MVP utile dès la phase 2 |
| 7 | Responsabilité si une écriture erronée est utilisée en déclaration | Mentions « document d'aide, à valider par un professionnel », traçabilité complète |

### Décisions prises avant la phase 1
1. **Génération des écritures automatiques : centralisée** (backend de référence uniquement, cf. §5.3).
2. **Comptes de tiers : affichage par tiers (comptes auxiliaires dérivés), pas de table de comptes par client.** Un compte auxiliaire est affiché `411` + code client sur 6 chiffres (ex. `411000042`) dans le grand livre auxiliaire, la balance par tiers et les exports. Il est créé implicitement, ne s'ajoute pas au plan comptable et se règle dans `longueurComptesTiers`. Cela satisfait les cabinets (numéros 411xxxxxx) sans alourdir la base.
3. **Boutiques : états séparés par boutique.** Chaque écriture porte `boutiqueId` ; tous les états (journaux, grand livre, balance, compte de résultat, bilan, TVA) acceptent un filtre « Boutique X » ou « Toutes (consolidé) ». Numérotation des pièces unique pour l'entreprise. Les virements entre boutiques passent par le compte 585 (virements internes).
4. **Taxes en v1 : TVA uniquement** (état mensuel). Les autres impôts sont saisis en OD (cf. §4).
5. **Mobile money : un seul compte dédié**, `578 Mobile money` (libellé et numéro modifiables) **[À VALIDER]**. Le détail MTN/Orange pourra se faire plus tard par sous-comptes sans changer le moteur.

---

## Annexe A – Plan comptable de départ (extrait pré-chargé)

| Classe | Comptes principaux |
|---|---|
| 1 Capitaux | 101 Capital, 11 Réserves, 12 Report à nouveau, 13 Résultat de l'exercice, 16 Emprunts |
| 2 Immobilisations | 21 Incorporelles, 22 Terrains, 23 Bâtiments, 24 Matériel et mobilier, 245 Matériel de transport, 28 Amortissements |
| 3 Stocks | 31 Marchandises |
| 4 Tiers | 401 Fournisseurs, 4091 Avances fournisseurs, 411 Clients, 4191 Avances clients, 421 Personnel, 431 CNPS, 4431 TVA facturée, 4452 TVA récupérable, 4441 État – impôts sur les bénéfices, 47 Comptes d'attente |
| 5 Trésorerie | 521 Banques, 571 Caisse, 578 Mobile money, 585 Virements internes |
| 6 Charges | 601 Achats de marchandises, 6031 Variation de stocks de marchandises, 604/605 Fournitures, 61 Transports, 62/63 Services extérieurs, 64 Impôts et taxes, 658 Charges diverses, 66 Charges de personnel, 67 Frais financiers, 681 Dotations |
| 7 Produits | 701 Ventes de marchandises, 706 Services vendus, 709 RRR accordés, 758 Produits divers |
| 8 Autres | 81/82 HAO, 891 Impôts sur les résultats |

Liste complète et libellés officiels à charger depuis le plan SYSCOHADA révisé **[À VALIDER : relecture de la liste finale]**.

## Annexe B – Journaux

| Code | Libellé | Alimenté par |
|---|---|---|
| VT | Ventes | Ventes, annulations de ventes |
| AC | Achats | Réceptions de commandes fournisseurs |
| CA | Caisse | Mouvements de caisse, dépenses espèces, écarts |
| BQ | Banque / Mobile money | Règlements non espèces |
| OD | Opérations diverses | Saisie manuelle, TVA, régularisations, variation de stocks |
| AN | À-nouveaux | Ouverture et clôture |

---

## État de la phase 1 (réalisé)

**Backend** (`backend/src/compta/`, `backend/src/routes/compta.js`)
- Schéma Prisma SQLite et PostgreSQL (`compta_*`), migration SQLite `add_compta_socle`, migration Neon idempotente (`cloud-migration-runner`, `migrations_pg/20261123090000_add_compta_socle`).
- Plan comptable SYSCOHADA de départ (139 comptes) et 6 journaux, chargés au démarrage de façon idempotente.
- Service : exercices et périodes, plan comptable (comptes utilisateur), écritures en partie double (brouillon, validation avec numérotation, contre-passation), idempotence par source, verrouillage des périodes, assistant d'ouverture (écart vers 4711/4712), grand livre (solde reporté, solde progressif, compte auxiliaire 411 + code tiers), balance (filtre boutique).
- API `/api/v1/compta` avec contrôle de droits par privilège.
- Tests : `npm run test:compta` (20 tests, base construite avec le vrai `migration.sql`) ; la suite `npm run test:sync` (218 tests) reste verte.

**Flutter** (`features/accounting/`)
- Page « Comptabilité (écritures) » (menu ⋮ du tableau de bord comptable) : écritures, plan comptable, grand livre, balance, exercices et paramètres ; formulaire de saisie avec contrôle d'équilibre ; assistant d'ouverture ; traductions fr/en/es ; privilèges ajoutés à l'écran des rôles.

**Non vérifié / limites connues**
- Le SQL Postgres (Neon) n'a pas été exécuté sur une vraie base Postgres dans cet environnement.
- Les écrans Flutter passent l'analyse statique (aucune erreur) mais n'ont pas été essayés à la main.
- Numérotation continue par poste seulement (suffixe `-Pn`) ; à revoir si un cabinet exige une numérotation continue sur l'ensemble des postes.
- Mode simple / expert : le réglage existe, mais tous les onglets restent visibles dans les deux modes (le mode simple viendra avec la phase 3).
- Les droits ne masquent pas encore les boutons : le serveur refuse l'action (403) avec un message.

---

## État de la phase 2 (réalisé)

**Principe retenu** (`backend/src/compta/moteur-auto.js`) : plutôt que de rejouer l'historique des opérations, le moteur calcule pour chaque document source (vente, commande, dépense, session de caisse...) la situation comptable qu'il doit produire aujourd'hui (un solde net par compte et par tiers), la compare à ce qui est déjà comptabilisé et n'écrit que la **différence**. Une annulation, une annulation partielle d'articles ou un règlement tardif produisent ainsi leur écriture de régularisation sans logique propre à chaque cas ; relancer ne change rien (idempotent) ; l'ordre de synchronisation des postes n'a pas d'importance. Les écritures sont validées, numérotées, datées du document (première écriture) ou de sa dernière modification (régularisation), ignorent tout ce qui précède la date d'ouverture, et ne se contre-passent pas à la main (on corrige l'opération d'origine).

**Sources traduites** (règles dans `regles-imputation.json`, modifiables sans toucher au code) :
- ventes terminées : 701, 4431, créance 411 (par client), avance consommée 4191, encaissement 571 ; ventes annulées : tout est repris ;
- commandes fournisseurs : achats reçus 601, dette 401 (par fournisseur) ou avance 4091, règlements 571 ;
- dépenses : compte de charge selon la catégorie (mots-clés, surcharge possible), contre 571 ; dépenses annulées reprises ;
- écarts de caisse à la fermeture des sessions (658 / 758) ;
- dépôts d'avance des clients (571 / 4191), paiements directs d'un client hors vente (571 / 411), règlements fournisseurs hors commande (401 / 571).

**Exécution** : sur le poste de référence uniquement (poste 1, serveur cloud ou poste sans identité), toutes les 5 minutes (désactivable avec `COMPTA_AUTO=off`), ou à la demande (bouton « Générer maintenant », `POST /compta/generer`). Les opérations qui échouent (période verrouillée, aucun exercice...) sont listées dans le rapport sans bloquer les autres (`GET /compta/generation`).

**Contrôles de cohérence** (`GET /compta/controles`, bouton « Contrôles de cohérence ») : compare les soldes tenus en comptabilité aux soldes de gestion (comptes clients, comptes fournisseurs, somme des caisses). Un écart signale une opération que le moteur ne sait pas traduire ; c'est le filet de sécurité qui évite une comptabilité fausse sans qu'on le voie.

**Tests** : `npm run test:compta` (38 tests dont 18 pour le moteur, sur une base créée avec le schéma complet).

**Limites connues** :
- TVA récupérable sur achats non comptabilisée : les commandes fournisseurs ne portent pas de TVA en base ;
- tout encaissement va en 571 : le mode de paiement réel (espèces, mobile money, banque) n'est pas enregistré sur la vente ;
- variation de stocks, immobilisations, clôture : phase 4 ;
- un paiement client direct enregistré sans session de caisse ouverte n'a pas de mouvement de caisse et n'est donc pas vu ; il apparaît dans les contrôles ;
- chaque passage relit tous les documents depuis l'ouverture (pas de curseur) : à optimiser pour de très gros volumes ;
- le comportement n'a été vérifié que sur des données de test, pas sur une base réelle de production : lancer d'abord sur une copie et examiner les contrôles.
