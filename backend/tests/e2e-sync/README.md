# Tests de synchronisation de bout en bout

Ces tests lancent de **vrais postes** LOGESCO (un serveur complet, une base SQLite et une identité chacun) reliés à une
**base cloud de test** Neon. Rien n'est simulé côté application : routes, hooks Prisma, journal des envois, service de
synchronisation, file de reprise, contrôle d'écart.

## Lancer

```bash
SYNC_TEST_NEON_URL='postgresql://…'   # URL de la base Neon de DÉVELOPPEMENT (jamais écrite dans un fichier)
node --experimental-sqlite --test tests/e2e-sync/scenarios/00-fumee.test.js
npm run test:e2e-sync                  # tous les scénarios, un fichier à la fois
```

Sans `SYNC_TEST_NEON_URL`, les scénarios sont ignorés (ils ne s'exécutent jamais par accident).

## Isolation

* Les tests **ne touchent jamais** la base d'origine. Chaque scénario crée sa **propre base jetable**
  `synctest_<étiquette>_<horodatage>`, copie du schéma de la base de développement (tables, colonnes, déclencheurs), vidée,
  et la supprime à la fin (`campagne.terminer()`).
* Les postes sont des processus enfants : l'URL d'administration ne leur est jamais transmise.
* `cloud-admin.js` ne supprime que des bases dont le nom commence par `synctest_`, et le nettoyage global exige une étiquette.

## Éléments

| Fichier | Rôle |
|---|---|
| `harness/cloud-admin.js` | création / suppression des bases cloud jetables, requêtes directes de vérification |
| `harness/station.js` | un poste simulé : démarrer, arrêter (propre ou brutal), appeler l'API, lire sa base SQLite, synchroniser |
| `harness/campagne.js` | crée la base cloud + N postes, état de départ (`clone` ou `independant`), nettoyage |
| `harness/oracle.js` | compare l'état de tous les postes et du cloud ; `attendreConvergence()` |
| `scenarios/*.test.js` | les scénarios (`node:test`) |

## Écrire un scénario

```js
const { nouvelleCampagne, peutLancer } = require('../harness/campagne');
const { attendreConvergence, decrire } = require('../harness/oracle');
const lancement = peutLancer();

test('mon scénario', { skip: lancement.ok ? false : lancement.raison, timeout: 900000 }, async (t) => {
  const c = await nouvelleCampagne({ etiquette: 'monsujet', postes: ['A', 'B'] });
  t.after(() => c.terminer());          // TOUJOURS : supprime la base cloud et arrête les postes
  const { A, B } = c.postes;
  await A.api('POST', '/products', { reference: 'R1', nom: 'P1', prixUnitaire: 1500, prixAchat: 1000, seuilStockMinimum: 1 });
  const r = await attendreConvergence({ stations: [A, B], cloudUrl: c.cloudUrl });
  assert.ok(r.ok, decrire(r.differences));
});
```

Un scénario est lent (cycles réels contre Neon) : prévoir plusieurs minutes et des délais d'attente généreux.

## Résultats attendus

Un test qui échoue **n'est pas forcément un défaut du test** : c'est souvent un vrai défaut de synchronisation. Un scénario
qui met un défaut en évidence doit rester dans le dépôt, avec le défaut décrit en commentaire (`// DÉFAUT CONNU :` …) et
`{ todo: '…' }` tant qu'il n'est pas corrigé, pour documenter le problème sans faire échouer l'ensemble.
