# Rapport d'étape — synchronisation LOGESCO (état au 12/10/2026)

Document de reprise : ce qui est fait, ce qui est trouvé, ce qui reste. À lire avant de relancer quoi que ce soit.

## 1. Objectif
Ne plus jamais subir les blocages de synchronisation chez les clients (produits jamais reçus, lignes jamais envoyées,
doublons, stocks faux), puis vérifier par une campagne de tests de bout en bout (plusieurs postes réels, réseau dégradé).

## 2. Livré et poussé (main + backend-deploy)
| Sujet | Résultat |
|---|---|
| Centre « Décisions à prendre » | cas de stock douteux + conflits de doublons (produits, comptes, utilisateurs, caisses, boutiques, inventaires, numéros) tranchés par l'utilisateur |
| Contrôle d'écart avec le cloud | compare identifiants et valeurs (stock, soldes), distingue « connu » / « inexpliqué », carte dans l'écran Synchronisation |
| Renvoi / Envoyer quand même / Ignorer / Réafficher | renvoi sans risque des lignes jamais envoyées, refus expliqués |
| Rattrapage automatique des lignes jamais reçues | par identifiant, déclenché par le contrôle d'écart (2 min après démarrage, puis toutes les 3 h) |
| File de reprise sans abandon définitif | lignes en pause rejouées 1 fois par heure ; une ligne périmée n'écrase plus une version plus récente |
| Références produit avec identifiant de poste | `PRD20260100-P15` (poste 1 inchangé) |
| Formulaire produit | type (produit/service) choisi en premier, champs adaptés, dialogue de changement de type, alerte « vendu à perte » |
| Erreurs lisibles + reprise des lectures | traducteur d'erreurs central, 2 reprises des GET, plus de messages dupliqués |
| Serveur cloud | limite de débit réaliste (2000/15 min), `trust proxy`, refus 429 en JSON (cause des « Trop de requêtes » sur mobile) |

Backend installé sur ce PC : à jour sur tout ce qui précède (sauf le correctif de limite de débit, qui concerne le cloud Render).

## 3. Livré en local, NON poussé
* `12bfe44` harnais de test de bout en bout ; `fed3a98` scénarios des agents + garde-fou du harnais.
* À vérifier avant poussée : `git status -sb`. Les fichiers de la campagne sont dans `backend/tests/e2e-sync/`.

## 4. La campagne de tests
Dossier `backend/tests/e2e-sync/` (voir `README.md`) : de VRAIS postes LOGESCO (serveur + SQLite + identité) reliés à une
base cloud Neon JETABLE `synctest_<étiquette>_*` (copie du schéma de la base de dev, vidée, supprimée à la fin).
* Lancer : `SYNC_TEST_NEON_URL='<url>' node --experimental-sqlite --test tests/e2e-sync/scenarios/<fichier>.test.js`
* Garde-fou : un poste de test ne démarre que sur une base `synctest_*` ; un poste sans cloud reçoit `CLOUD_DB_URL=''`.
* Un scénario dure plusieurs minutes (cycles réels contre Neon).

### Avancement des agents
| Agent | Fichiers | État |
|---|---|---|
| Multi-postes (même saisie sur plusieurs postes) | `10-*.test.js`, `harness/aide-multi.js` | TERMINÉ — rapport reçu |
| Hors ligne / crash / reprise | `30-*.test.js`, `harness/aide-horsligne.js`, `aide-sans-cloud.js`, `aide-reseau.js` | TERMINÉ — rapport reçu |
| Intégrité métier + contrôle d'écart | `40-*.test.js`, `harness/aide-metier.js` | EN COURS — scénarios écrits, rapport NON reçu |
| Réseau lent / instable | `20-*.test.js`, `harness/network-faults.js`, `preload-reseau.js`, `charge-reseau.js` | scénarios et banc écrits, NON exécutés jusqu'au bout, rapport NON reçu |

## 5. Ce qui est démontré (fonctionne)
* Même référence produit sur 2 postes : conflit détecté, résolu par « renommer », convergence.
* Références automatiques distinctes entre postes ; création massive 3×20 produits sans doublon ; prix modifié simultanément : convergence.
* Installation d'un 2ᵉ poste sur un cloud établi : 0 décision à prendre, données de base fusionnées.
* **Rattrapage des lignes jamais reçues : démontré (56 s).** **File de reprise sans abandon : démontrée.** Ligne périmée : n'écrase pas.
* Coupures de courant brutales (3 en pleine réception de 800 lignes ; 3 en plein envoi de 283 opérations) : aucune perte ni doublon.
* Mauvais mot de passe cloud puis corrigé : poste utilisable en local, aucune opération refusée, bascule en hybride.
* Mémoire correcte en volume (124 Mo pour 800 opérations).

## 6. Défauts trouvés (à corriger — rien n'est corrigé dans `backend/src`)
Gravité décroissante. « Confirmé » = lu dans le code ; « probable » = hypothèse de l'agent à vérifier.

1. **Stock écrasé en valeur absolue (perte de données).** Ventes simultanées sur 3 postes (stock 300, 56 vendus) : 290 ou 280 partout au lieu de 244 ; les mouvements sont corrects (−56). Même racine : stock envoyé en valeur et non en cumul (50+10+5 donne 60). *Cause probable* : `sync-service.js` envoi `INSERT … ON CONFLICT DO UPDATE` de `stock_boutiques`.
2. **[CORRIGÉ le 13 octobre — voir 6 sexies] Écriture locale parfois jamais journalisée, donc jamais envoyée (perte de données).** 1 à 4 lignes sur 70–400 (surtout `mouvements_stock`). *Probable* : `logOperation` avale « database is locked » (`sync-service.js` ~l.2040) ; `sales.js` ~l.1263 journalise en `setImmediate` après la réponse. En volume, une ligne de détail dont la vente manque reste `failed` à jamais (clé étrangère).
3. **[CORRIGÉ le 13 octobre — voir 6 quinquies] Curseur de réception qui saute dans le futur (synchro bloquée).** Une ligne poussée avec une horloge en avance fixe le curseur de `produits` à demain ; les mises à jour suivantes ne sont plus jamais reçues, et le rattrapage ne couvre que les lignes absentes.
4. **Paiement client perdu après une vente à crédit.** Le solde du cloud revient à la valeur d'avant paiement. *Probable* : instantané du compte envoyé après le paiement (`routes/sales.js` ~l.1283-1285).
5. **Écritures `achat_credit` jamais envoyées au cloud.** *Confirmé* : `routes/sales.js` l.1142 `const createdTransactionIds` masque le `let` de la l.862 ; la l.1251 renvoie un tableau vide.
6. **[CORRIGÉ le 14 octobre — voir 6 septies] Dernière écriture gagne même si plus ancienne** : un poste reconnecté en dernier avec une vieille modification écrase la plus récente (`sync-service.js` ~l.1856, sans comparaison de date). Fiche synchronisée EN ENTIER : A change la description, B le prix → un seul survit.
7. **Suppression contre modification** : produit « supprimé » (en fait désactivé) sur A pendant que B le modifie → reste actif sur B et peut être revendu.
8. **Numéros de commande d'approvisionnement sans suffixe de poste.** *Confirmé* : `routes/procurement.js` `generateNumeroCommande` n'appelle pas `documentSuffix()` (le conflit est ensuite tranché par « renommer »).
9. **[CORRIGÉ le 13 octobre — voir 6 sexies] Données de base du tout premier poste jamais envoyées** (rôle, boutique, caisse, utilisateur créés au premier démarrage, non journalisés) : sur un cloud vide, les lignes qui en dépendent (stock) sont refusées par clé étrangère. Concerne l'installation d'un client neuf.
10. **[CORRIGÉ le 14 octobre — voir 6 octies] Poste démarré sans cloud** : relié ensuite, il n'envoie jamais son historique local (décision de conception à prendre).
11. Mineurs : doublons silencieux sans clé unique (boutiques, fournisseurs, clients homonymes) ; `GET /sync/drift?refresh=1` renvoie l'ancien rapport si un contrôle est en cours ; ventes lentes (~2,5 s) quand un cloud est configuré.

## 6 bis. Corrections faites depuis le rapport (13/10/2026) — locales, non poussées
* **Défaut 5 (écritures `achat_credit`)** : corrigé (`e639905`) ET démontré : le sous-test e2e « les 4 écritures de compte … présentes dans le cloud » passe.
* **Défaut 8 (numéros de commande)** : corrigé (`e639905`), 4 cas vérifiés.
* **Défaut 4 (paiement perdu)** : CAUSE RACINE TROUVÉE par diagnostic (`10-b`, poste unique, solde mesuré à chaque étape) : c'est une **course entre la réception et la journalisation**. Les routes journalisent (`enqueue`) APRÈS avoir répondu (`setImmediate`) : pendant quelques instants une ligne est déjà modifiée localement sans opération en attente ; si un cycle de réception tombe dans ce créneau, il remet l'ancienne valeur du cloud par-dessus (le solde local lui-même redevenait −3000). Même mécanisme probable pour le défaut 1 (stock) et une partie du défaut 2.
  Correctif en place (non démontré de bout en bout) : `_localeModifieeRecemment` dans `sync-service.js` — une ligne locale modifiée il y a moins de 60 s n'est pas écrasée par la réception, elle est mémorisée et redemandée au cycle suivant (test unitaire ajouté, 100 tests passent). Correctif complémentaire dans `routes/sales.js` : l'envoi du compte client relit la valeur ACTUELLE au lieu d'un instantané de la transaction.
  **Solution durable à décider** : journaliser DANS la transaction d'écriture (ou avant la réponse) route par route, au lieu de `setImmediate` après la réponse.
* Vérification de bout en bout du défaut 4 : relancer `scenarios/10-b-fiches-homonymes.test.js` et regarder le sous-test « la somme de tous les soldes … » (devrait passer ; la course étant intermittente, relancer 2 fois).

## 6 ter. Diagnostic du stock (défaut 1) — 13/10/2026
Deux postes, produit à 1000 : A vend 3, B vend 2. Observé : A=997, B=998, cloud=998 (attendu 995 partout). Les mouvements sont corrects (`vente-3`, `vente-2` présents partout). Après 65 s de calme, A reçoit bien la valeur du cloud (la protection des lignes récentes fonctionne) et tout converge… vers 998 : la valeur est fausse.
**Cause** : chaque vente envoie au cloud le stock TOTAL du poste (`stock UPDATE quantite=997`) ; le dernier envoi écrase les autres (dernière écriture gagne sur une valeur absolue).
**Solution IMPLÉMENTÉE le 13/10/2026 (`stock-difference.js`)** — démontrée : diagnostic e2e → 995 partout (A, B, cloud). Reste à confirmer à grande échelle : `10-c-concurrence.test.js` (3 postes, 56 unités vendues, attendu 244). Description d'origine :
**Solution proposée** : envoi par DIFFÉRENCE avec reprise sûre. Pour `stock` et `stock_boutiques` : le poste retient en local la dernière valeur synchronisée (« base ») de chaque ligne ; à l'envoi, le cloud applique `quantite = quantite + (nouvelle − base)` dans une transaction qui inscrit l'identifiant de l'opération dans une table `sync_applied_ops` (clé unique) : une opération rejouée après un accusé perdu n'est jamais appliquée deux fois. Après l'envoi, la base = valeur renvoyée par le cloud ; la réception rapporte le total du cloud sur les postes. Sans base connue (anciennes données) : comportement actuel (valeur absolue), puis base établie. Fichiers : `sync-service.js` (`_applyToCloud`, `_ensureTablesCloud`, réception), tests unitaires + `diag-stock` e2e (attendu 995 partout). À valider avant de coder : risque élevé (cœur de la synchro).

## 7. Incident (déjà corrigé)
Un essai « poste sans cloud » s'est relié à la base de dev `neondb` (dotenv réinjectait l'URL). Effet : 5 lignes parasites dans la table `installations` (n° 15 à 19, 11/10/2026 04:54–04:57). **Aucune donnée métier touchée** (18 produits / 48 ventes / 10 clients inchangés). Garde-fou ajouté (`fed3a98`). Nettoyage des 5 lignes : en attente de l'accord de l'utilisateur.

## 8. Reste à faire (dans l'ordre)
1. Récupérer le rapport de l'agent « métier » ; puis exécuter l'agent « réseau » (banc de pannes à valider d'abord).
2. Corriger les défauts 1 à 5 (les plus graves), chacun démontré par le test e2e qui échoue avant et réussit après ; trancher 6, 9 et 10 (décisions de conception).
3. Retirer les `{ todo }` des tests corrigés ; lancer la suite e2e complète sur réseau stable.
4. Pousser (`main` + `backend-deploy`), mettre à jour le backend installé, reconstruire l'installateur (`build.ps1`, mode [1] Serveur local).
5. Redéployer le serveur cloud Render (limite de débit) et la version web mobile.
6. Tester l'installateur sur un poste propre ; déployer chez UN client d'abord.

## 9. Pour reprendre
* Réseau : les coupures DNS de ce PC ont interrompu les agents plusieurs fois ; vérifier 5 connexions Neon d'affilée avant de relancer.
* Nettoyer avant de relancer : processus `node` dont la ligne de commande contient `logesco_app\backend\src\server.js` (ne jamais tuer tous les `node.exe` : le serveur réel du PC en fait partie), et bases `synctest_*` oubliées.
* Lancer les agents UN À LA FOIS (quatre ensemble épuisent la limite d'usage en quelques minutes).
* L'URL de la base Neon de dev n'est écrite nulle part ; elle se passe en variable d'environnement. **Renouveler son mot de passe** à la fin de la campagne (il est apparu dans le chat et dans les consignes des agents). Idem le mot de passe Neon du client, apparu plus tôt.

## 6 quater. Stock et soldes : corrections du 13 octobre (confirmées par les scénarios)

Causes trouvées par le diagnostic à 3 postes (`10-c`) et corrigées dans `sync-service.js` :

1. **Reprise des lignes mises de côté** : `_reprendreProtegees` effaçait la mémoire APRÈS réapplication ; une ligne encore « récente » était donc oubliée et le poste restait en retard (ex. 285 au lieu de 249). Les identifiants sont retirés AVANT.
2. **Réception relative du stock** (`_mergeRemoteRow`) : valeur du cloud + (quantité locale − base). Une vente locale pas encore envoyée n'est plus écrasée, même si elle tombe pendant la réception.
3. **Quantité périmée à l'envoi** : les routes journalisent après la réponse, dans le désordre, et la fusion des opérations en attente garde la dernière arrivée (une vente ancienne masquait la plus récente : −7 au lieu de −21). Le stock (`stock`, `stock_boutiques`) et les soldes (`comptes_clients`, `comptes_fournisseurs`) sont maintenant envoyés avec la valeur ACTUELLE de la ligne locale.

Résultats : diagnostic 3 postes 4 fois sur 4 à 244 partout ; `10-c` automatique 244 partout ; `10-b` « somme des soldes » correcte 2 fois sur 2 (avait échoué 2 fois sur 3 avant). Les annotations « défaut connu » de ces deux sous-tests sont retirées.

Reste ouvert : lignes `details_ventes` d'un poste parfois absentes du cloud (défaut n°2, écritures non journalisées) ; `10-c` manuel a échoué une fois sur « fetch failed » (incident du banc, à relancer) ; défauts 3, 6, 7, 9, 10, 11.

## 6 quinquies. Défauts 7 et 3 : corrigés (13 octobre)

**Défaut 7 (suppression de produit)** — deux causes :
- le middleware de synchro prenait la réponse d'une DÉSACTIVATION (`DELETE /products/:id` sur un produit déjà utilisé renvoie le produit) pour une suppression : il envoyait un DELETE au cloud (qui effaçait produit ET stock) et annulait la mise à jour. `/products` est maintenant `softDelete` (la route journalise elle-même UPDATE ou DELETE) ;
- une modification ordinaire d'un poste qui ignorait la désactivation renvoyait `est_actif = vrai` et ressuscitait le produit. Dans le cloud, `est_actif` d'un produit ne repasse à vrai que par une réactivation explicite (marque `__reactivation` posée par `PUT /products/:id`). Reste le défaut 6 : la ligne entière est envoyée (le prix modifié par un poste peut être perdu face à l'autre).
Scénario 7 complet : 6 réussis, 0 échec.

**Défaut 3 (curseur dans le futur)** : le curseur de réception d'une table devenait la date de modification la plus récente reçue ; une ligne poussée par un poste à l'horloge avancée le fixait dans le futur et plus aucune mise à jour n'arrivait. Le curseur est maintenant plafonné à l'heure du cloud (`LOCALTIMESTAMP`), et un curseur déjà dans le futur (poste touché avant le correctif) repart de zéro pour cette table. Scénario « dérive d'horloge » : la mise à jour normale arrive, curseur dans le présent. 4 tests unitaires (3 échouent sans la correction).

Reste ouvert : 6 (ligne entière, dernière écriture gagnante), 9 (lignes de base du premier poste), 10 (conception), 11 (mineurs) ; agents métier et réseau à valider.

## 6 sexies. Défauts 2 et 9 : corrigés (13 octobre)

**Défaut 9 (graine d'un cloud neuf)** : le rôle, l'utilisateur, la boutique, la caisse, les paramètres et l'affectation du premier poste ne passent pas par le journal et le script d'installation du cloud n'en insère aucune : le stock par boutique était refusé par clé étrangère. Nouveau module `sync-graine.js` : pour chaque table de base VIDE dans le cloud et remplie en local, un INSERT est journalisé par ligne, une seule fois (marqueur local `sync_graine`). Un cloud qui contient déjà des lignes n'est jamais touché. Vérifié : poste neuf sur cloud vide (4/4), 2ᵉ poste neuf sur cloud alimenté (`10-d` n°8, aucun doublon, aucune décision).

**Défaut 2 (écriture jamais journalisée)** — deux causes :
- `logOperation` avalait « database is locked » : il réessaie maintenant (8 fois, attente croissante) ;
- les routes journalisent APRÈS la réponse HTTP (`setImmediate`) : si le poste s'arrête dans ce court délai (relance, coupure), l'écriture existe sans journal. Réparation au démarrage de chaque rejeu : le STOCK est retrouvé grâce à la base de référence (quantité locale − base = non envoyé, sans opération en attente) ; l'HISTORIQUE (mouvements de stock, lignes de vente, écritures de compte, mouvements de caisse, historique des prix d'achat) est retrouvé parce qu'une ligne du bloc d'identifiants du poste sans aucune entrée de journal n'a jamais été envoyée (le journal n'est jamais purgé). Les tables modifiables (ventes, produits, clients) ne sont PAS traitées : renvoyer une version périmée pourrait écraser une plus récente. Elles restent exposées à la fenêtre de quelques millisecondes.

Autres corrections : registre `sync_applied_ops` créé au besoin (et non plus seulement au démarrage : un cloud injoignable à ce moment-là bloquait tous les envois de stock) ; garde-fou du banc de test ouvert à l'URL volontairement injoignable `127.0.0.1:9` ; les scénarios hors ligne `30-*` n'avaient jamais pu démarrer depuis l'ajout du garde-fou.

Scénarios : `30-crash` 3/3, `30-fiches-communes` 2b : stock 65 partout, plus aucune écriture perdue. Reste dans 2b le défaut 6 (modification ancienne qui écrase la récente ; champs de postes différents) : le cloud n'a pas de date d'édition fiable (la colonne `date_modification` est réécrite par un déclencheur à chaque envoi), la comparaison de dates exige une nouvelle colonne côté cloud.

## 6 septies. Défaut 6 : fusion champ par champ des fiches (14 octobre)

Les fiches (produits, clients, fournisseurs, catégories) partaient EN ENTIER et le dernier envoi gagnait : un poste relié tard avec une ancienne modification écrasait la plus récente, et deux postes qui modifiaient des champs différents se perdaient mutuellement une modification.

Nouveau module `sync-fusion.js` (fusion à trois, comme le stock par différence) :
- chaque poste retient la **base** de chaque fiche (la version qu'il a vue la dernière fois : table locale `sync_row_base`, mise à jour à la réception et à l'envoi) ;
- à l'envoi, **seules les colonnes réellement modifiées** partent ;
- dans le cloud, une colonne n'est écrasée que si personne ne l'a changée depuis la base du poste, OU si la modification est **plus récente** que la dernière édition de la fiche. Cette date d'édition vit dans une **table à part** du cloud, `sync_edition` : la colonne `date_modification` est réécrite par un déclencheur à chaque envoi et ne peut pas servir. Aucune colonne n'est ajoutée aux tables de fiches : les postes pas encore mis à jour continuent de les lire sans différence (une colonne ajoutée aurait fait échouer leurs insertions locales) ;
- mise à jour et date d'édition dans une transaction ; sans base connue, la fiche part en entier mais jamais par-dessus une édition plus récente ;
- les colonnes que le cloud ne connaît pas (ex. `image_url`, propre au poste) ne partent jamais ; une colonne vide absente de la base n'est pas une modification ; la règle « une modification ordinaire ne réactive pas un produit désactivé » est conservée.

Résultats : `30-fiches-communes` 4/4 (2 et 2b : B plus récent l'emporte sur le nom, le prix, l'adresse ; la description posée par A est conservée ; stock 65) ; `10-c` : ★4 stock 244 partout (manuel et automatique), ★5 prix 3/3, ★6, ★7 5/5. 147 tests unitaires.

Reste ouvert : 10 (poste démarré sans cloud, décision), 11 (mineurs), tables modifiables exposées à la fenêtre de quelques millisecondes entre la réponse et le journal, agents métier et réseau à valider. Quand deux postes modifient la MÊME colonne, la plus récente gagne d'après l'horloge du poste (une horloge très en avance gagnerait toujours).

## 6 octies. Défaut 10 : poste démarré sans cloud (14 octobre)

Un poste démarré sans `CLOUD_DB_URL` ne journalise rien (mode 100 % local) ; relié ensuite à un cloud, il n'envoyait jamais son historique (produits, ventes, stock...).

Correction : `sync-graine.js` (déjà utilisé pour la graine du défaut 9) est étendu à TOUTES les tables métier (ordre de `PULL_TABLES`, parents d'abord). Règle table par table : si le cloud n'a AUCUNE ligne dans la table et que le poste en a, un INSERT est journalisé pour chaque ligne locale sans entrée de journal, par lots de 1000, jusqu'à épuisement. La décision est mémorisée (`sync_graine`, état `en_cours`) : l'envoi continue quand la table du cloud commence à se remplir. Une table déjà alimentée dans le cloud n'est jamais touchée. Un index `operation_log(table_name, record_id)` est créé (sans lui, la sélection « lignes sans journal » parcourait tout le journal pour chaque ligne ; il accélère aussi les réparations du défaut 2).

Vérifié : `30-hors-ligne` cas 1b (10 produits et 4 ventes saisis sans cloud puis envoyés, écarts : aucun, identité réservée) ; 154 tests unitaires, dont 11 pour ce module.

**Non couvert, volontairement** : deux postes qui ont travaillé hors cloud puis sont reliés au MÊME cloud. Le premier envoie tout ; le second trouve des tables non vides et n'envoie pas (ses identifiants, tous inférieurs au premier bloc réservé, peuvent chevaucher ceux du premier). C'est une décision humaine ; le contrôle d'écart la signale (« présent ici, jamais arrivé dans le cloud »).
