const environment = require('../config/environment');

/**
 * Filtre Prisma "contient" insensible a la casse, quel que soit le moteur.
 *
 * SQLite (backend local) : `contains` est deja insensible a la casse, et
 * l'option `mode` y est refusee. Postgres (Render / Neon) : `contains` est
 * sensible a la casse — chercher "ampoule" ne trouvait pas "AMPOULE
 * RECHARGEABLE" — il faut `mode: 'insensitive'`.
 */
function estPostgres() {
  return environment.databaseConfig.provider === 'postgresql' || /^postgres(ql)?:/i.test(process.env.DATABASE_URL || '');
}

function like(terme) {
  return estPostgres() ? { contains: terme, mode: 'insensitive' } : { contains: terme };
}

module.exports = { like, estPostgres };
