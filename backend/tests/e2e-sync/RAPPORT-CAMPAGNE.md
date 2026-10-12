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
2. **Écriture locale parfois jamais journalisée, donc jamais envoyée (perte de données).** 1 à 4 lignes sur 70–400 (surtout `mouvements_stock`). *Probable* : `logOperation` avale « database is locked » (`sync-service.js` ~l.2040) ; `sales.js` ~l.1263 journalise en `setImmediate` après la réponse. En volume, une ligne de détail dont la vente manque reste `failed` à jamais (clé étrangère).
3. **Curseur de réception qui saute dans le futur (synchro bloquée).** Une ligne poussée avec une horloge en avance fixe le curseur de `produits` à demain ; les mises à jour suivantes ne sont plus jamais reçues, et le rattrapage ne couvre que les lignes absentes.
4. **Paiement client perdu après une vente à crédit.** Le solde du cloud revient à la valeur d'avant paiement. *Probable* : instantané du compte envoyé après le paiement (`routes/sales.js` ~l.1283-1285).
5. **Écritures `achat_credit` jamais envoyées au cloud.** *Confirmé* : `routes/sales.js` l.1142 `const createdTransactionIds` masque le `let` de la l.862 ; la l.1251 renvoie un tableau vide.
6. **Dernière écriture gagne même si plus ancienne** : un poste reconnecté en dernier avec une vieille modification écrase la plus récente (`sync-service.js` ~l.1856, sans comparaison de date). Fiche synchronisée EN ENTIER : A change la description, B le prix → un seul survit.
7. **Suppression contre modification** : produit « supprimé » (en fait désactivé) sur A pendant que B le modifie → reste actif sur B et peut être revendu.
8. **Numéros de commande d'approvisionnement sans suffixe de poste.** *Confirmé* : `routes/procurement.js` `generateNumeroCommande` n'appelle pas `documentSuffix()` (le conflit est ensuite tranché par « renommer »).
9. **Données de base du tout premier poste jamais envoyées** (rôle, boutique, caisse, utilisateur créés au premier démarrage, non journalisés) : sur un cloud vide, les lignes qui en dépendent (stock) sont refusées par clé étrangère. Concerne l'installation d'un client neuf.
10. **Poste démarré sans cloud** : relié ensuite, il n'envoie jamais son historique local (décision de conception à prendre).
11. Mineurs : doublons silencieux sans clé unique (boutiques, fournisseurs, clients homonymes) ; `GET /sync/drift?refresh=1` renvoie l'ancien rapport si un contrôle est en cours ; ventes lentes (~2,5 s) quand un cloud est configuré.

## 6 bis. Corrections faites depuis le rapport (13/10/2026) — locales, non poussées
* **Défaut 5 (écritures `achat_credit`)** : corrigé (`e639905`) ET démontré : le sous-test e2e « les 4 écritures de compte … présentes dans le cloud » passe.
* **Défaut 8 (numéros de commande)** : corrigé (`e639905`), 4 cas vérifiés.
* **Défaut 4 (paiement perdu)** : CAUSE RACINE TROUVÉE par diagnostic (`10-b`, poste unique, solde mesuré à chaque étape) : c'est une **course entre la réception et la journalisation**. Les routes journalisent (`enqueue`) APRÈS avoir répondu (`setImmediate`) : pendant quelques instants une ligne est déjà modifiée localement sans opération en attente ; si un cycle de réception tombe dans ce créneau, il remet l'ancienne valeur du cloud par-dessus (le solde local lui-même redevenait −3000). Même mécanisme probable pour le défaut 1 (stock) et une partie du défaut 2.
  Correctif en place (non démontré de bout en bout) : `_localeModifieeRecemment` dans `sync-service.js` — une ligne locale modifiée il y a moins de 60 s n'est pas écrasée par la réception, elle est mémorisée et redemandée au cycle suivant (test unitaire ajouté, 100 tests passent). Correctif complémentaire dans `routes/sales.js` : l'envoi du compte client relit la valeur ACTUELLE au lieu d'un instantané de la transaction.
  **Solution durable à décider** : journaliser DANS la transaction d'écriture (ou avant la réponse) route par route, au lieu de `setImmediate` après la réponse.
* Vérification de bout en bout du défaut 4 : relancer `scenarios/10-b-fiches-homonymes.test.js` et regarder le sous-test « la somme de tous les soldes … » (devrait passer ; la course étant intermittente, relancer 2 fois).

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
