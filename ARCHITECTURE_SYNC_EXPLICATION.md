# Architecture de Synchronisation LOGESCO — Guide Équipe

## À lire avant d'expliquer à un client

Ce document explique comment fonctionne la synchronisation des données dans LOGESCO.
Il est destiné à l'équipe commerciale et technique pour qu'elle puisse expliquer
clairement le fonctionnement aux clients.

---

## Les 3 types de clients LOGESCO

### Type 1 — 100% Hors ligne (Offline)

**Pour qui ?**
Client qui n'a pas besoin de partager ses données entre plusieurs sites ou utilisateurs distants.
Tout se passe sur une seule machine.

**Comment ça marche ?**
```
[Application Flutter] ──> [Backend local] ──> [Base de données locale SQLite]
```

- Tout est installé sur une seule machine
- Aucune connexion internet requise
- Les données ne quittent jamais la machine du client
- Idéal pour une petite boutique avec un seul poste

**Ce qu'on dit au client :**
> "Votre logiciel fonctionne entièrement sur votre machine. Pas besoin d'internet.
> Vos données sont chez vous, personne d'autre n'y a accès."

---

### Type 2 — Réseau Local (Intranet)

**Pour qui ?**
Client qui a plusieurs vendeurs dans la même boutique, tous connectés au même réseau WiFi.

**Comment ça marche ?**
```
[Vendeur 1 - Flutter] ──┐
[Vendeur 2 - Flutter] ──┼──> [Serveur local boutique] ──> [Base de données locale]
[Caissier  - Flutter] ──┘
         (WiFi de la boutique)
```

- Un seul serveur installé sur une machine dédiée dans la boutique
- Tous les vendeurs s'y connectent via le WiFi local
- Pas besoin d'internet pour les opérations quotidiennes
- Les données restent dans la boutique

**Ce qu'on dit au client :**
> "On installe un serveur dans votre boutique. Tous vos vendeurs s'y connectent
> avec leur téléphone ou ordinateur via votre WiFi. Tout fonctionne même sans internet."

---

### Type 3 — Hybride Local + Cloud (Recommandé pour multi-sites)

**Pour qui ?**
Client qui a plusieurs boutiques dans des villes différentes, ou qui veut
contrôler son activité à distance (patron à l'étranger, comptable dans une autre ville).

**Comment ça marche ?**

```
[Gérant Douala]    ──> [Backend local Douala]   ──┐
[Patron étranger]  ──> [Backend local Paris]    ──┼──> [Neon.tech - BD Cloud]
[Comptable Yaoundé]──> [Backend local Yaoundé]  ──┘
                                                    (Source de vérité partagée)
```

- Chaque site a son propre backend installé localement
- Tous les backends sont connectés à la même base de données en ligne (Neon.tech)
- Quand internet est disponible → tout le monde voit les mêmes données en temps réel
- Quand internet coupe → chaque site continue de travailler normalement en local,
  les données se synchronisent automatiquement dès que la connexion revient

**Ce qu'on dit au client :**
> "Chaque site a son propre logiciel qui fonctionne même sans internet.
> Dès qu'internet est disponible, toutes vos boutiques se synchronisent automatiquement.
> Vous pouvez voir les ventes de Douala depuis Paris en temps réel."

---

## Comment fonctionne la synchronisation (Type 3)

### Quand internet est disponible

1. Le gérant de Douala fait une vente → elle est enregistrée localement
2. En moins de 30 secondes, cette vente est envoyée vers Neon (cloud)
3. Le patron à l'étranger rafraîchit son app → il voit la vente de Douala
4. La synchronisation est **bidirectionnelle** : chaque site envoie ET reçoit

### Quand internet est coupé

1. Le gérant continue de travailler normalement → les ventes sont sauvegardées en local
2. Une file d'attente (queue) enregistre toutes les opérations faites hors ligne
3. Dès qu'internet revient → la queue est envoyée automatiquement vers Neon
4. Les autres sites reçoivent les données manquantes lors de leur prochaine sync

### Délai de synchronisation

- Quand internet est disponible : **moins de 30 secondes**
- Après une coupure internet : **dès que la connexion revient**

---

## Règle importante à expliquer aux clients

### Ce qui peut se faire hors ligne sans risque ✅
- Enregistrer des ventes
- Encaisser des paiements
- Gérer la caisse (ouverture, fermeture, mouvements)
- Consulter l'historique local

### Ce qui doit se faire en ligne de préférence ⚠️
- Modifier les prix des produits
- Ajouter ou supprimer des produits du catalogue
- Modifier les informations clients/fournisseurs
- Effectuer des transferts de stock entre boutiques

**Pourquoi cette distinction ?**

Si deux sites modifient le même produit en même temps hors ligne, la dernière
synchronisation écrase l'autre. Pour les ventes, ce risque n'existe pas car
chaque vente est unique. Pour les modifications de catalogue, il vaut mieux
être connecté pour éviter les conflits.

**Ce qu'on dit au client :**
> "Pour les ventes et la caisse, travaillez sans souci même sans internet.
> Pour modifier vos prix ou votre catalogue, faites-le de préférence quand
> vous êtes connecté."

---

## Résumé visuel pour le client

```
                    INTERNET DISPONIBLE
                    ┌─────────────────┐
Site A ─────────────┤                 ├───────── Site B
(Douala)            │   Neon.tech     │          (Yaoundé)
Ventes en temps réel│   Base de       │          Voit les données
                    │   données       │          de Douala
                    │   partagée      │
Site C ─────────────┤                 │
(Patron étranger)   └─────────────────┘
Contrôle à distance

                    INTERNET COUPÉ
Site A              ┌─────────────────┐
(Douala)            │   Neon.tech     │          Site B
Continue de ────────┤   inaccessible  ├──────── Continue de
travailler          │                 │          travailler
en local            └─────────────────┘          en local
     │                                                │
     └──── Sync automatique dès que internet revient ─┘
```

---

## Questions fréquentes des clients

**"Et si internet ne revient pas pendant plusieurs jours ?"**
> Pas de problème. Toutes les opérations sont sauvegardées localement.
> Dès qu'internet revient, même après plusieurs jours, tout se synchronise automatiquement.

**"Est-ce que mes données sont en sécurité sur internet ?"**
> Vos données sont hébergées sur Neon.tech, une plateforme PostgreSQL sécurisée.
> La connexion est chiffrée (SSL). Seul votre backend peut y accéder avec les identifiants configurés.

**"Combien ça coûte l'hébergement cloud ?"**
> Pour la plupart des clients, le tier gratuit de Neon.tech suffit. Coût : 0 $/mois.
> Vous ne payez que la licence LOGESCO.

**"Que se passe-t-il si deux vendeurs font la même vente en même temps hors ligne ?"**
> Chaque vente a un numéro unique généré localement. Il ne peut pas y avoir de doublon.
> Les deux ventes seront synchronisées séparément.

---

## Pour l'équipe technique — Checklist installation Type 3

- [ ] Créer projet Neon pour le client (voir GUIDE_INSTALLATION_CLIENT_TYPE3.md)
- [ ] Configurer `CLOUD_DB_URL` dans le `.env` du client
- [ ] Vérifier au démarrage : `Mode sync: hybrid` dans les logs
- [ ] Vérifier la sync initiale dans les logs
- [ ] Tester une vente et vérifier qu'elle apparaît sur Neon dans les 30 secondes
- [ ] Tester le mode offline (couper internet) et vérifier que l'app continue
- [ ] Tester la resynchronisation après reconnexion
