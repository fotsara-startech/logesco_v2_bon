/**
 * Helper pour récupérer la boutique principale
 * Utilisé par toutes les routes qui nécessitent un boutiqueId par défaut
 */

let _cachedBoutiqueId = null;

/**
 * Retourne l'ID de la boutique principale.
 * Met en cache le résultat pour éviter des requêtes répétées.
 * @param {PrismaClient} prisma
 * @returns {Promise<number|null>}
 */
async function getBoutiquePrincipaleId(prisma) {
  if (_cachedBoutiqueId) return _cachedBoutiqueId;

  const boutique = await prisma.boutique.findFirst({
    where: { estPrincipale: true, isActive: true }
  });

  if (boutique) {
    _cachedBoutiqueId = boutique.id;
    return boutique.id;
  }

  // Fallback: première boutique active
  const fallback = await prisma.boutique.findFirst({ where: { isActive: true } });
  if (fallback) {
    _cachedBoutiqueId = fallback.id;
    return fallback.id;
  }

  return null;
}

/**
 * Invalide le cache (à appeler si la boutique principale change)
 */
function invalidateBoutiqueCache() {
  _cachedBoutiqueId = null;
}

/**
 * Résout le boutiqueId: utilise celui fourni ou retourne la boutique principale
 * @param {PrismaClient} prisma
 * @param {number|string|null|undefined} boutiqueId - ID fourni par la requête
 * @returns {Promise<number|null>}
 */
async function resolveBoutiqueId(prisma, boutiqueId) {
  if (boutiqueId) return parseInt(boutiqueId);
  return await getBoutiquePrincipaleId(prisma);
}

module.exports = { getBoutiquePrincipaleId, resolveBoutiqueId, invalidateBoutiqueCache };
