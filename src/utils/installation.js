/**
 * Identité du poste (installation).
 *
 * Chaque installation reçoit un numéro unique et une plage d'identifiants
 * réservée, afin que deux postes ne génèrent jamais le même id local pour
 * des enregistrements différents (ce qui provoquerait un écrasement
 * silencieux lors de la synchronisation vers Neon).
 *
 * Le poste historique porte le numéro 1 et conserve la plage 1…9 999 999 :
 * les données existantes ne sont donc jamais renumérotées.
 */

// 10 millions d'ids par poste → 214 postes possibles dans un entier 32 bits
const ID_BLOCK_SIZE = 10000000;

let installationId = null;

function setInstallationId(id) {
  installationId = id ? Number(id) : null;
}

function getInstallationId() {
  return installationId;
}

/**
 * Début de la plage d'ids réservée à un poste.
 *
 * La plage [0 … ID_BLOCK_SIZE[ n'est attribuée à AUCUN poste : elle est
 * réservée aux données antérieures à la mise en place des plages. Un poste
 * neuf ne peut donc jamais réutiliser un identifiant historique, quel que
 * soit l'ordre dans lequel les postes s'enregistrent.
 *
 * Poste 1 → 10 000 000, poste 2 → 20 000 000, etc.
 */
function blockStartFor(id) {
  return Number(id) * ID_BLOCK_SIZE;
}

/**
 * Suffixe à intégrer dans les numéros de document (vente, commande, reçu).
 * Vide pour le poste 1 : le format des documents existants reste inchangé.
 */
function documentSuffix() {
  return installationId && installationId > 1 ? `-P${installationId}` : '';
}

module.exports = {
  ID_BLOCK_SIZE,
  setInstallationId,
  getInstallationId,
  blockStartFor,
  documentSuffix,
};
