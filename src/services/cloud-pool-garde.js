/**
 * Garde contre l'arrêt du serveur quand la connexion à Neon tombe en pleine utilisation.
 *
 * Le piège : le pool `pg` n'écoute les erreurs d'une connexion que lorsqu'elle est INACTIVE (événement `error` du pool).
 * Dès qu'une connexion est prêtée à une requête (`pool.connect()`), c'est à l'appelant d'écouter ses erreurs. Sans écouteur,
 * une coupure réseau ("Connection terminated unexpectedly") devient une exception non capturée, et le gestionnaire du
 * serveur arrête alors tout le processus : la synchronisation et l'application sont interrompues à chaque coupure.
 *
 * Ici, chaque nouvelle connexion reçoit un écouteur permanent qui journalise l'incident. La requête en cours échoue
 * normalement (erreur gérée par le code appelant), et la connexion défectueuse est retirée du pool par `pg`.
 */
function protegerConnexions(pool, journal = console.warn) {
  pool.on('connect', (client) => {
    client.on('error', (e) => journal(`⚠️  Neon: connexion interrompue pendant son utilisation — ${e && e.message ? e.message : e}`));
  });
  return pool;
}

module.exports = { protegerConnexions };
