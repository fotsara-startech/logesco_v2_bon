const express = require('express');

function createStockInventoryRouter({ prisma, authService }) {
  const router = express.Router();

  // GET /api/v1/stock-inventory - Récupérer tous les inventaires (filtrés par boutique)
  router.get('/', async (req, res) => {
    try {
      const { status, type, boutiqueId } = req.query;

      const where = {};
      if (status) where.status = status;
      if (type) where.type = type;
      if (boutiqueId) where.boutiqueId = parseInt(boutiqueId);

      const inventories = await prisma.stockInventory.findMany({
        where,
        include: {
          utilisateur: true,
          categorie: true,
          boutique: { select: { id: true, nom: true } },
          items: { include: { produit: true } }
        },
        orderBy: { dateCreation: 'desc' }
      });

      const formattedInventories = inventories.map(inventory => {
        const totalItems = inventory.items.length;
        const countedItems = inventory.items.filter(item => item.quantiteComptee !== null).length;
        const itemsWithVariance = inventory.items.filter(item =>
          item.quantiteComptee !== null && item.ecart !== 0
        ).length;
        const totalSystemQuantity = inventory.items.reduce((sum, item) => sum + parseFloat(item.quantiteSysteme), 0);
        const totalCountedQuantity = inventory.items.reduce((sum, item) => sum + (parseFloat(item.quantiteComptee) || 0), 0);
        const totalVariance = totalCountedQuantity - totalSystemQuantity;
        const positiveVariance = inventory.items.filter(item => item.ecart > 0).reduce((sum, item) => sum + parseFloat(item.ecart), 0);
        const negativeVariance = inventory.items.filter(item => item.ecart < 0).reduce((sum, item) => sum + parseFloat(item.ecart), 0);

        return {
          id: inventory.id,
          nom: inventory.nom,
          description: inventory.description,
          type: inventory.type,
          status: inventory.status,
          categorieId: inventory.categorieId,
          nomCategorie: inventory.categorie?.nom,
          boutiqueId: inventory.boutiqueId,
          nomBoutique: inventory.boutique?.nom,
          utilisateurId: inventory.utilisateurId,
          nomUtilisateur: inventory.utilisateur?.nomUtilisateur,
          dateCreation: inventory.dateCreation,
          dateDebut: inventory.dateDebut,
          dateFin: inventory.dateFin,
          stats: { totalItems, countedItems, itemsWithVariance, totalSystemQuantity, totalCountedQuantity, totalVariance, positiveVariance, negativeVariance }
        };
      });

      res.json({ success: true, data: formattedInventories });
    } catch (error) {
      console.error('Erreur lors de la recuperation des inventaires:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur serveur', code: 'INVENTORY_FETCH_ERROR' } });
    }
  });

  // POST /api/v1/stock-inventory - Creer un nouvel inventaire
  router.post('/', async (req, res) => {
    try {
      const { nom, description, type, categorieId, utilisateurId, boutiqueId } = req.body;

      if (!nom || !type || !utilisateurId) {
        return res.status(400).json({
          success: false,
          error: { message: 'Les champs nom, type et utilisateurId sont requis', code: 'VALIDATION_ERROR' }
        });
      }

      const userExists = await prisma.utilisateur.findUnique({ where: { id: parseInt(utilisateurId) } });
      if (!userExists) {
        return res.status(400).json({
          success: false,
          error: { message: `L'utilisateur avec l'ID ${utilisateurId} n'existe pas`, code: 'USER_NOT_FOUND' }
        });
      }

      const existingInventory = await prisma.stockInventory.findFirst({ where: { nom } });
      if (existingInventory) {
        return res.status(400).json({
          success: false,
          error: { message: 'Un inventaire avec ce nom existe deja', code: 'DUPLICATE_NAME' }
        });
      }

      if (type === 'PARTIEL' && categorieId) {
        const categoryExists = await prisma.category.findUnique({ where: { id: parseInt(categorieId) } });
        if (!categoryExists) {
          return res.status(400).json({
            success: false,
            error: { message: `La categorie avec l'ID ${categorieId} n'existe pas`, code: 'CATEGORY_NOT_FOUND' }
          });
        }
      }

      // Determiner la boutique active
      let activeBoutiqueId = boutiqueId ? parseInt(boutiqueId) : null;
      if (!activeBoutiqueId) {
        const boutiquePrincipale = await prisma.boutique.findFirst({ where: { estPrincipale: true } });
        activeBoutiqueId = boutiquePrincipale?.id || null;
      }

      const newInventory = await prisma.stockInventory.create({
        data: {
          nom,
          description: description || '',
          type,
          status: 'BROUILLON',
          categorieId: type === 'PARTIEL' && categorieId ? parseInt(categorieId) : null,
          utilisateurId: parseInt(utilisateurId),
          boutiqueId: activeBoutiqueId
        },
        include: { utilisateur: true, categorie: true, boutique: { select: { id: true, nom: true } } }
      });

      // Generer les items avec le stock de la boutique active
      await generateInventoryItems(prisma, newInventory.id, type, categorieId, activeBoutiqueId);

      const inventoryWithItems = await prisma.stockInventory.findUnique({
        where: { id: newInventory.id },
        include: {
          utilisateur: true,
          categorie: true,
          boutique: { select: { id: true, nom: true } },
          items: { include: { produit: { include: { categorie: true } } } }
        }
      });

      const formattedInventory = {
        id: inventoryWithItems.id,
        nom: inventoryWithItems.nom,
        description: inventoryWithItems.description,
        type: inventoryWithItems.type,
        status: inventoryWithItems.status,
        categorieId: inventoryWithItems.categorieId,
        nomCategorie: inventoryWithItems.categorie?.nom,
        boutiqueId: inventoryWithItems.boutiqueId,
        nomBoutique: inventoryWithItems.boutique?.nom,
        utilisateurId: inventoryWithItems.utilisateurId,
        nomUtilisateur: inventoryWithItems.utilisateur?.nomUtilisateur,
        dateCreation: inventoryWithItems.dateCreation,
        dateDebut: inventoryWithItems.dateDebut,
        dateFin: inventoryWithItems.dateFin,
        items: inventoryWithItems.items.map(item => ({
          id: item.id,
          inventaireId: item.inventaireId,
          produitId: item.produitId,
          nomProduit: item.produit?.nom,
          codeProduit: item.produit?.reference,
          categorieProduit: item.produit?.categorie?.nom,
          prixUnitaire: parseFloat(item.produit?.prixUnitaire) || 0,
          prixAchat: parseFloat(item.produit?.prixAchat) || 0,
          quantiteSysteme: parseFloat(item.quantiteSysteme),
          quantiteComptee: item.quantiteComptee ? parseFloat(item.quantiteComptee) : null,
          ecart: item.ecart ? parseFloat(item.ecart) : null,
          commentaire: item.commentaire,
          dateComptage: item.dateComptage
        }))
      };

      res.status(201).json({ success: true, data: formattedInventory });
    } catch (error) {
      console.error('Erreur lors de la creation de l inventaire:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur serveur', code: 'INVENTORY_CREATE_ERROR' } });
    }
  });

  // GET /api/v1/stock-inventory/:id/items
  router.get('/:id/items', async (req, res) => {
    try {
      const { id } = req.params;

      const items = await prisma.inventoryItem.findMany({
        where: { inventaireId: parseInt(id) },
        include: { produit: { include: { categorie: true } }, utilisateurComptage: true },
        orderBy: { id: 'asc' }
      });

      const formattedItems = items.map(item => ({
        id: item.id,
        inventaireId: item.inventaireId,
        produitId: item.produitId,
        nomProduit: item.produit?.nom,
        codeProduit: item.produit?.reference,
        categorieProduit: item.produit?.categorie?.nom,
        prixUnitaire: parseFloat(item.produit?.prixUnitaire) || 0,
        prixAchat: parseFloat(item.produit?.prixAchat) || 0,
        quantiteSysteme: parseFloat(item.quantiteSysteme),
        quantiteComptee: item.quantiteComptee ? parseFloat(item.quantiteComptee) : null,
        ecart: item.ecart ? parseFloat(item.ecart) : null,
        commentaire: item.commentaire,
        dateComptage: item.dateComptage,
        utilisateurComptageId: item.utilisateurComptageId,
        nomUtilisateurComptage: item.utilisateurComptage?.nomUtilisateur
      }));

      res.json({ success: true, data: formattedItems });
    } catch (error) {
      console.error('Erreur lors de la recuperation des items:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur serveur', code: 'INVENTORY_ITEMS_FETCH_ERROR' } });
    }
  });

  // PUT /api/v1/stock-inventory/items/:itemId
  router.put('/items/:itemId', async (req, res) => {
    try {
      const { itemId } = req.params;
      const { quantiteComptee, commentaire, utilisateurComptageId } = req.body;

      const existingItem = await prisma.inventoryItem.findUnique({ where: { id: parseInt(itemId) } });
      if (!existingItem) {
        return res.status(404).json({ success: false, error: { message: "Article d'inventaire non trouve", code: 'INVENTORY_ITEM_NOT_FOUND' } });
      }

      const ecart = parseFloat(quantiteComptee) - parseFloat(existingItem.quantiteSysteme);

      const updatedItem = await prisma.inventoryItem.update({
        where: { id: parseInt(itemId) },
        data: { quantiteComptee: parseFloat(quantiteComptee), ecart, commentaire: commentaire || null, dateComptage: new Date(), utilisateurComptageId },
        include: { produit: { include: { categorie: true } }, utilisateurComptage: true }
      });

      res.json({
        success: true,
        data: {
          id: updatedItem.id,
          inventaireId: updatedItem.inventaireId,
          produitId: updatedItem.produitId,
          nomProduit: updatedItem.produit?.nom,
          codeProduit: updatedItem.produit?.reference,
          categorieProduit: updatedItem.produit?.categorie?.nom,
          quantiteSysteme: parseFloat(updatedItem.quantiteSysteme),
          quantiteComptee: parseFloat(updatedItem.quantiteComptee),
          ecart: parseFloat(updatedItem.ecart),
          commentaire: updatedItem.commentaire,
          dateComptage: updatedItem.dateComptage,
          utilisateurComptageId: updatedItem.utilisateurComptageId,
          nomUtilisateurComptage: updatedItem.utilisateurComptage?.nomUtilisateur
        }
      });
    } catch (error) {
      console.error('Erreur lors de la mise a jour de l item:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur serveur', code: 'INVENTORY_ITEM_UPDATE_ERROR' } });
    }
  });

  // GET /api/v1/stock-inventory/:id/print
  router.get('/:id/print', async (req, res) => {
    try {
      const { id } = req.params;
      const inventory = await prisma.stockInventory.findUnique({ where: { id: parseInt(id) } });
      if (!inventory) {
        return res.status(404).json({ success: false, error: { message: 'Inventaire non trouve', code: 'INVENTORY_NOT_FOUND' } });
      }
      const printUrl = `${req.protocol}://${req.get('host')}/api/v1/stock-inventory/${id}/print-sheet.pdf`;
      res.json({ success: true, data: { printUrl, inventory: { id: inventory.id, nom: inventory.nom, type: inventory.type, status: inventory.status } } });
    } catch (error) {
      res.status(500).json({ success: false, error: { message: 'Erreur serveur', code: 'PRINT_GENERATION_ERROR' } });
    }
  });

  // PATCH /api/v1/stock-inventory/:id/status
  router.patch('/:id/status', async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;

      const validStatuses = ['BROUILLON', 'EN_COURS', 'TERMINE', 'CLOTURE'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({ success: false, error: { message: 'Statut invalide', code: 'INVALID_STATUS' } });
      }

      const updatedInventory = await prisma.stockInventory.update({
        where: { id: parseInt(id) },
        data: {
          status,
          dateDebut: status === 'EN_COURS' ? new Date() : undefined,
          dateFin: status === 'TERMINE' ? new Date() : undefined
        },
        include: { utilisateur: true, categorie: true, boutique: { select: { id: true, nom: true } } }
      });

      res.json({
        success: true,
        data: {
          id: updatedInventory.id,
          nom: updatedInventory.nom,
          description: updatedInventory.description,
          type: updatedInventory.type,
          status: updatedInventory.status,
          categorieId: updatedInventory.categorieId,
          nomCategorie: updatedInventory.categorie?.nom,
          boutiqueId: updatedInventory.boutiqueId,
          nomBoutique: updatedInventory.boutique?.nom,
          utilisateurId: updatedInventory.utilisateurId,
          nomUtilisateur: updatedInventory.utilisateur?.nomUtilisateur,
          dateCreation: updatedInventory.dateCreation,
          dateDebut: updatedInventory.dateDebut,
          dateFin: updatedInventory.dateFin
        }
      });
    } catch (error) {
      console.error('Erreur lors de la mise a jour du statut:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur serveur', code: 'INVENTORY_STATUS_UPDATE_ERROR' } });
    }
  });

  // POST /api/v1/stock-inventory/:id/close - Cloture avec equilibrage du stock boutique
  router.post('/:id/close', async (req, res) => {
    try {
      const id = parseInt(req.params.id);

      const inventory = await prisma.stockInventory.findUnique({
        where: { id },
        include: { items: { include: { produit: true } } }
      });

      if (!inventory) {
        return res.status(404).json({ success: false, error: { message: 'Inventaire non trouve', code: 'INVENTORY_NOT_FOUND' } });
      }

      if (inventory.status === 'CLOTURE') {
        return res.status(400).json({ success: false, error: { message: 'Inventaire deja cloture', code: 'ALREADY_CLOSED' } });
      }

      // Filtrer les items avec une quantite comptee et un ecart
      const itemsAvecEcart = inventory.items.filter(item =>
        item.quantiteComptee !== null && item.ecart !== null && item.ecart !== 0
      );

      await prisma.$transaction(async (tx) => {
        for (const item of itemsAvecEcart) {
          const ecart = parseFloat(item.ecart);
          const produit = item.produit;

          // Ignorer les services
          if (produit?.estService) continue;

          if (inventory.boutiqueId) {
            // Mettre a jour le stock specifique a la boutique
            const stockBoutique = await tx.stockBoutique.findUnique({
              where: { boutiqueId_produitId: { boutiqueId: inventory.boutiqueId, produitId: item.produitId } }
            });

            if (stockBoutique) {
              const nouvelleQte = Math.max(0, parseFloat(stockBoutique.quantiteDisponible) + ecart);
              await tx.stockBoutique.update({
                where: { boutiqueId_produitId: { boutiqueId: inventory.boutiqueId, produitId: item.produitId } },
                data: { quantiteDisponible: nouvelleQte, derniereMaj: new Date() }
              });
            } else {
              // Creer l'entree stock boutique si elle n'existe pas
              const qteSysteme = Math.max(0, parseFloat(item.quantiteSysteme) + ecart);
              await tx.stockBoutique.create({
                data: { boutiqueId: inventory.boutiqueId, produitId: item.produitId, quantiteDisponible: qteSysteme }
              });
            }
          } else {
            // Fallback : mettre a jour le stock global
            const stock = await tx.stock.findUnique({ where: { produitId: item.produitId } });
            if (stock) {
              const nouvelleQte = Math.max(0, parseFloat(stock.quantiteDisponible) + ecart);
              await tx.stock.update({
                where: { produitId: item.produitId },
                data: { quantiteDisponible: nouvelleQte }
              });
            }
          }

          // Creer un mouvement de stock pour traçabilite
          await tx.mouvementStock.create({
            data: {
              produitId: item.produitId,
              boutiqueId: inventory.boutiqueId || null,
              typeMouvement: ecart > 0 ? 'entree' : 'sortie',
              changementQuantite: ecart,
              referenceId: inventory.id,
              typeReference: 'inventaire',
              notes: `Ajustement inventaire: ${inventory.nom}`
            }
          });
        }

        // Marquer l'inventaire comme cloture
        await tx.stockInventory.update({
          where: { id },
          data: { status: 'CLOTURE', dateFin: new Date() }
        });
      });

      const updatedInventory = await prisma.stockInventory.findUnique({
        where: { id },
        include: { utilisateur: true, categorie: true, boutique: { select: { id: true, nom: true } } }
      });

      res.json({
        success: true,
        message: `Inventaire cloture. ${itemsAvecEcart.length} produit(s) ajuste(s).`,
        data: {
          id: updatedInventory.id,
          nom: updatedInventory.nom,
          description: updatedInventory.description || '',
          type: updatedInventory.type,
          status: updatedInventory.status,
          categorieId: updatedInventory.categorieId,
          nomCategorie: updatedInventory.categorie?.nom,
          boutiqueId: updatedInventory.boutiqueId,
          nomBoutique: updatedInventory.boutique?.nom,
          utilisateurId: updatedInventory.utilisateurId,
          nomUtilisateur: updatedInventory.utilisateur?.nomUtilisateur || '',
          dateCreation: updatedInventory.dateCreation,
          dateDebut: updatedInventory.dateDebut,
          dateFin: updatedInventory.dateFin,
          stats: { totalItems: 0, countedItems: 0, itemsWithVariance: 0, totalSystemQuantity: 0, totalCountedQuantity: 0, totalVariance: 0, positiveVariance: 0, negativeVariance: 0 }
        }
      });
    } catch (error) {
      console.error('Erreur lors de la cloture:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur serveur', code: 'INVENTORY_CLOSE_ERROR' } });
    }
  });

  return router;
}

/**
 * Genere les items d'inventaire en utilisant le stock boutique si disponible
 */
async function generateInventoryItems(prisma, inventoryId, type, categorieId, boutiqueId) {
  try {
    const where = { estActif: true };
    if (type === 'PARTIEL' && categorieId) {
      where.categorieId = parseInt(categorieId);
    }

    const products = await prisma.produit.findMany({
      where,
      include: {
        stock: true,
        stocksBoutiques: boutiqueId ? { where: { boutiqueId } } : false
      }
    });

    const inventoryItems = products.map(product => {
      let quantiteSysteme = 0;

      if (boutiqueId && product.stocksBoutiques && product.stocksBoutiques.length > 0) {
        // Stock specifique a la boutique
        quantiteSysteme = parseFloat(product.stocksBoutiques[0].quantiteDisponible) || 0;
      } else if (product.stock) {
        // Fallback sur le stock global
        quantiteSysteme = parseFloat(product.stock.quantiteDisponible) || 0;
      }

      return {
        inventaireId: inventoryId,
        produitId: product.id,
        quantiteSysteme,
        prixUnitaire: parseFloat(product.prixUnitaire) || 0,
        prixAchat: parseFloat(product.prixAchat) || 0
      };
    });

    if (inventoryItems.length > 0) {
      await prisma.inventoryItem.createMany({ data: inventoryItems });
    }
  } catch (error) {
    console.error("Erreur lors de la generation des items d'inventaire:", error);
    throw error;
  }
}

module.exports = { createStockInventoryRouter };
