/**
 * Gestionnaire automatique des dates de péremption
 * Implémente le système FEFO (First Expired, First Out)
 */

/**
 * Met à jour les quantités des dates de péremption après une vente
 * Déduit automatiquement les quantités vendues en commençant par les lots qui expirent en premier
 * 
 * @param {Object} prisma - Instance Prisma
 * @param {number} produitId - ID du produit
 * @param {number} quantiteVendue - Quantité vendue
 * @returns {Promise<Object>} Résultat de la mise à jour
 */
async function updateExpirationDatesAfterSale(prisma, produitId, quantiteVendue) {
  try {
    // Vérifier si le produit a la gestion de péremption activée
    const produit = await prisma.produit.findUnique({
      where: { id: produitId },
      select: { gestionPeremption: true, nom: true }
    });

    if (!produit || !produit.gestionPeremption) {
      // Pas de gestion de péremption pour ce produit
      return {
        updated: false,
        reason: 'Gestion de péremption non activée'
      };
    }

    // Récupérer tous les lots actifs (non épuisés) triés par date de péremption (FEFO)
    const lotsActifs = await prisma.datePeremption.findMany({
      where: {
        produitId,
        estEpuise: false
      },
      orderBy: {
        datePeremption: 'asc' // Les plus proches de la péremption en premier
      }
    });

    if (lotsActifs.length === 0) {
      return {
        updated: false,
        reason: 'Aucun lot actif trouvé'
      };
    }

    let quantiteRestante = quantiteVendue;
    const lotsModifies = [];
    const lotsEpuises = [];

    // Déduire les quantités en commençant par les lots qui expirent en premier
    for (const lot of lotsActifs) {
      if (quantiteRestante <= 0) break;

      if (lot.quantite <= quantiteRestante) {
        // Le lot est complètement épuisé
        await prisma.datePeremption.update({
          where: { id: lot.id },
          data: { 
            quantite: 0,
            estEpuise: true 
          }
        });

        lotsEpuises.push({
          id: lot.id,
          numeroLot: lot.numeroLot,
          quantiteInitiale: lot.quantite,
          quantiteDeduite: lot.quantite
        });

        quantiteRestante -= lot.quantite;
      } else {
        // Le lot est partiellement consommé
        const nouvelleQuantite = lot.quantite - quantiteRestante;
        
        await prisma.datePeremption.update({
          where: { id: lot.id },
          data: { quantite: nouvelleQuantite }
        });

        lotsModifies.push({
          id: lot.id,
          numeroLot: lot.numeroLot,
          quantiteInitiale: lot.quantite,
          quantiteDeduite: quantiteRestante,
          quantiteRestante: nouvelleQuantite
        });

        quantiteRestante = 0;
      }
    }

    console.log(`✅ Dates de péremption mises à jour pour ${produit.nom}:`);
    console.log(`   - Quantité vendue: ${quantiteVendue}`);
    console.log(`   - Lots modifiés: ${lotsModifies.length}`);
    console.log(`   - Lots épuisés: ${lotsEpuises.length}`);

    return {
      updated: true,
      produitNom: produit.nom,
      quantiteVendue,
      lotsModifies,
      lotsEpuises,
      quantiteNonCouverte: quantiteRestante > 0 ? quantiteRestante : 0
    };

  } catch (error) {
    console.error('❌ Erreur mise à jour dates de péremption:', error);
    throw error;
  }
}

/**
 * Met à jour les quantités des dates de péremption après un retour/annulation
 * Réintègre les quantités dans les lots existants ou crée un nouveau lot
 * 
 * @param {Object} prisma - Instance Prisma
 * @param {number} produitId - ID du produit
 * @param {number} quantiteRetournee - Quantité retournée
 * @returns {Promise<Object>} Résultat de la mise à jour
 */
async function updateExpirationDatesAfterReturn(prisma, produitId, quantiteRetournee) {
  try {
    // Vérifier si le produit a la gestion de péremption activée
    const produit = await prisma.produit.findUnique({
      where: { id: produitId },
      select: { gestionPeremption: true, nom: true }
    });

    if (!produit || !produit.gestionPeremption) {
      return {
        updated: false,
        reason: 'Gestion de péremption non activée'
      };
    }

    // Récupérer le lot le plus récent (dernière date de péremption)
    const dernierLot = await prisma.datePeremption.findFirst({
      where: {
        produitId,
        estEpuise: false
      },
      orderBy: {
        datePeremption: 'desc'
      }
    });

    if (dernierLot) {
      // Ajouter la quantité au lot existant
      await prisma.datePeremption.update({
        where: { id: dernierLot.id },
        data: {
          quantite: dernierLot.quantite + quantiteRetournee
        }
      });

      console.log(`✅ Quantité retournée ajoutée au lot existant pour ${produit.nom}`);

      return {
        updated: true,
        action: 'added_to_existing_lot',
        lotId: dernierLot.id,
        quantiteRetournee
      };
    }

    // Si aucun lot actif, on ne crée pas automatiquement de nouveau lot
    // L'utilisateur devra le faire manuellement
    console.log(`⚠️ Aucun lot actif pour ${produit.nom}, retour non appliqué aux dates de péremption`);

    return {
      updated: false,
      reason: 'Aucun lot actif, création manuelle requise'
    };

  } catch (error) {
    console.error('❌ Erreur mise à jour dates de péremption (retour):', error);
    throw error;
  }
}

module.exports = {
  updateExpirationDatesAfterSale,
  updateExpirationDatesAfterReturn
};
