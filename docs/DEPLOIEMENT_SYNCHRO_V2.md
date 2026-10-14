# Déploiement des corrections de synchronisation (campagne du 13 octobre 2026)

Ce document sert à livrer les corrections de synchronisation **sans risque pour les clients**. Il décrit ce qui change,
l'ordre des étapes, ce qu'on vérifie chez le premier client et comment revenir en arrière.

> État au moment de la rédaction : les corrections sont validées par 147 tests unitaires et par les scénarios de bout en
> bout de `backend/tests/e2e-sync/` (voir `RAPPORT-CAMPAGNE.md`), y compris la fusion champ par champ des fiches.

## 1. Ce qui change

| Sujet | Effet pour le client |
|---|---|
| Stock envoyé par **différence** | Deux postes qui vendent en même temps ne s'écrasent plus (56 unités vendues sur 3 postes : 244 partout, avant : 280 à 290). |
| Soldes de comptes et stock envoyés avec la **valeur actuelle** | Un paiement enregistré juste après une vente à crédit n'est plus perdu. |
| Journal : **nouvel essai** quand la base est occupée, et **réparation** des écritures jamais journalisées (stock, historique) | Une vente ou un ajustement fait juste avant un arrêt du poste n'est plus perdu. |
| Désactivation d'un produit | Elle n'est plus transformée en suppression dans le cloud (le produit et son stock étaient effacés). Un produit désactivé n'est pas réactivé par une simple modification d'un autre poste. |
| Curseur de réception plafonné à l'heure du cloud | Un poste dont l'horloge avance ne bloque plus la réception des mises à jour. Un curseur déjà bloqué se répare seul (pull complet de la table). |
| Données de base envoyées à un cloud **neuf** | L'installation d'un nouveau client fonctionne : boutique, caisse, rôle et utilisateur arrivent dans le cloud. |
| Poste resté sans cloud puis relié (défaut n°10) | Son historique (produits, ventes, stock...) est envoyé au cloud, par lots, si le cloud n'a pas encore ces données. |
| Fusion champ par champ des fiches (défaut n°6) | La description posée par un poste et le prix posé par un autre se combinent ; la modification la plus récente gagne. |

### Objets créés automatiquement (aucune migration manuelle)

* **Cloud** : tables `sync_applied_ops` (registre du stock par différence) et `sync_edition` (dates d'édition des
  fiches). Créées par le premier poste mis à jour qui se connecte.
* **Chaque poste** (SQLite) : tables `sync_stock_base`, `sync_row_base`, `sync_graine`. Créées au démarrage.
* Aucune donnée existante n'est modifiée ni supprimée.

## 2. Postes de versions différentes

La date d'édition des fiches (fusion champ par champ) est stockée dans une **table à part** du cloud, `sync_edition`.
Aucune colonne n'est ajoutée aux tables `produits`, `clients`, `fournisseurs` et `categories` : un poste pas encore mis
à jour continue de les lire sans la moindre différence. Les autres objets ajoutés (`sync_applied_ops`, `sync_edition`)
sont aussi des tables à part. Un client à plusieurs postes peut donc être mis à jour poste par poste.

Précaution : la fusion n'est efficace que si les postes qui modifient la même fiche sont mis à jour. Un poste ancien
continue d'envoyer ses fiches en entier (comme avant) et peut donc encore écraser un champ modifié ailleurs ; mettre à
jour tous les postes d'un client dans la même séance reste préférable.

## 3. Avant de livrer

1. `npm run test:sync` dans `backend/` : tout doit passer (147 tests ou plus).
2. Série de scénarios de bout en bout sur un réseau stable (vérifier 5 connexions à Neon d'affilée avant) :
   `00-fumee`, `10-b`, `10-c`, `10-d`, `30-crash`, `30-fiches-communes`, `30-horloge-tempete-volume`.
   Lancer **un scénario à la fois**.
3. **Changer les mots de passe Neon** exposés (base de développement et base du client concerné) et retirer du suivi git
   les fichiers `backend/.env.client-alategot`, `backend/.env.dev` et `backend/.env.dev-backup`.
4. Sauvegarder la base locale de chaque poste du premier client (copie du dossier de données de LOGESCO) et noter
   l'état du cloud (nombre de lignes par table principale).

## 4. Ordre de livraison

1. Pousser `main`, puis `backend-deploy` (procédure habituelle du projet).
2. Redéployer le serveur cloud (limite de débit corrigée) et la version web mobile.
3. Reconstruire l'installateur avec `build.ps1`, mode [1] Serveur local.
4. Tester l'installateur sur un poste **propre** : installation, première connexion, création d'un produit, vente.
5. Livrer à **un seul client** d'abord, de préférence un client à peu de postes, en dehors des heures de vente.
   Mettre à jour tous ses postes dans la même séance.
6. Surveiller 2 à 3 jours avant de livrer aux autres clients.

## 5. Vérifications chez le premier client

Pendant la première journée :

* **Centre de décisions** de l'application : aucun cas nouveau inexpliqué.
* Contrôle d'écart (`/sync/drift`) : aucune ligne « jamais reçue » ou « jamais envoyée » sans explication.
* Journal des postes : pas de répétition de `⚠️` ni de `❌ Erreur replay`. Un compteur d'opérations en échec qui monte
  est le signal à prendre au sérieux (`operation_log`, statut `failed`).
* Stock : comparer le stock d'un produit très vendu sur deux postes et dans le cloud ; il doit être identique.
* Les messages `🩹 Stock : … retrouvée(s)` ou `🩹 Historique : … retrouvée(s)` sont normaux après un arrêt brutal ; ils
  signalent des écritures rattrapées, pas un problème.

## 6. Retour en arrière

* Les objets ajoutés sont **additifs** : l'ancienne version les ignore. Réinstaller l'ancien installateur suffit.
* Le stock envoyé par différence laisse chaque poste avec sa base (`sync_stock_base`) : l'ancienne version envoie de
  nouveau la valeur totale, comme avant.
* Si une table d'édition ou le registre du cloud gênait, ils peuvent rester en place sans effet.
* Ne **jamais** supprimer de lignes dans le cloud du client pour « réparer » : passer par le centre de décisions.

## 7. Limites connues après cette livraison

* Défaut n°10 (corrigé) : un poste démarré **sans** cloud puis relié envoie son historique local, table par table, quand le
  cloud n'a encore aucune ligne dans la table. Limite : si **deux** postes ont travaillé hors cloud puis sont reliés au
  même cloud, seul le premier envoie son historique ; le second est signalé par le contrôle d'écart et demande une décision.
* Défaut n°11 : les doublons de clients, fournisseurs et boutiques saisis sur deux postes (aucune clé unique) ne sont **pas**
  fusionnés : ils sont signalés dans `GET /sync/drift` (champ `doublons`) et dans le journal des postes. L'écran de
  l'application qui les affiche reste à faire : en attendant, surveiller le journal (`⚠️ … doublon(s) probable(s)`).
* Les ventes, produits et clients (tables modifiables) restent exposés à la fenêtre de quelques millisecondes entre la
  réponse du serveur et l'écriture au journal en cas d'arrêt brutal du poste (le stock et l'historique, eux, sont réparés).
* Quand deux postes modifient la **même colonne** de la même fiche hors ligne, la modification la plus récente gagne
  (d'après l'horloge du poste : une horloge très en avance gagnerait toujours).

## 8. Connexion au cloud depuis l'application (nouveau)

Jusqu'ici, activer le cloud sur un poste obligeait à modifier le fichier `.env` à la main (`CLOUD_DB_URL`). Une page
**« Connexion au cloud (Neon) »** existe maintenant dans le menu **Administration**.

* **Qui la voit** : un **administrateur**, sur l'ordinateur qui **héberge** le serveur LOGESCO. Elle n'apparaît ni en mode
  client réseau, ni sur le web. Un client 100 % local la voit aussi : c'est ce qui lui permet d'activer le cloud.
* **Comment** : coller le lien « Connection string » de la console Neon (masqué à la saisie) → *Tester la connexion* →
  *Enregistrer et redémarrer*. L'enregistrement n'est possible que si le test réussit **et** que la base contient déjà les
  tables de LOGESCO (le schéma doit être installé dans la base Neon au préalable).
* **Ce que le test dit** : si le cloud est **vide** (le poste lui enverra ses données), ou **déjà rempli** (les données
  du poste ne sont pas envoyées par-dessus : celles du cloud sont conservées).
* **Redémarrage** : le lien est écrit dans le `.env`, puis le serveur redémarre (environ une minute ; les autres postes du
  réseau perdent la connexion un instant : à faire hors des heures de vente). Il n'est volontairement **pas** appliqué à
  chaud : les hooks de journalisation des écritures locales ne s'installent qu'au démarrage.
* **Sécurité** : le mot de passe n'est jamais renvoyé par le serveur ni écrit dans un journal (seuls l'hôte, la base et
  l'utilisateur sont montrés) ; le lien est validé strictement (un retour à la ligne ou un guillemet permettrait d'injecter
  d'autres variables dans le `.env`) ; une copie `.env.avant-cloud` de l'ancien fichier est gardée.
* **Limites** : pas de bouton pour *revenir en 100 % local* (à faire à la main : retirer `CLOUD_DB_URL` du `.env`) ; l'écran
  n'a pas été exercé sur un poste Windows réel (voir « Vérifié / non vérifié » ci-dessous).

### Écran des doublons

La page **Synchronisation** affiche, pour les clients qui ont une base cloud **seulement**, une carte « doublons probables »
(clients, fournisseurs, boutiques saisis sur deux postes) avec le poste d'origine et le **solde** de chaque fiche. Aucune
fusion n'est proposée : fusionner deux comptes est une décision humaine. Un client 100 % local ne voit jamais cette carte.

### Vérifié / non vérifié

Vérifié : 174 tests serveur, 44 tests Flutter de synchronisation (dont l'absence de bouton de fusion et le refus des liens
piégés), le scénario de bout en bout `50-cloud-config` (lien testé puis enregistré sur un vrai poste 100 % local ; le mot de
passe n'apparaît ni dans les réponses ni dans le journal du poste).
**Non vérifié** : l'application Windows complète (parcours à l'écran, redémarrage réel par `BackendService`, reprise du
lien au démarrage suivant). À faire sur un poste de test avant de livrer : saisir un lien, laisser redémarrer, vérifier
que la synchronisation démarre.
