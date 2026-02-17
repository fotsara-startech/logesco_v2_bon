const express = require('express');

/**
 * Créer le routeur pour la gestion de l'inventaire de stock
 * @param {Object} dependencies - Dépendances injectées
 * @returns {Router}
 */
function createStockInventoryRouter({ prisma, authService }) {
  const router = express.Router();

  // GET /api/v1/stock-inventory - Récupérer tous les inventaires
  router.get('/', async (req, res) => {
    try {
      const { status, type } = req.query;
      
      const where = {};
      if (status) where.status = status;
      if (type) where.type = type;
      
      const inventories = await prisma.stockInventory.findMany({
        where,
        include: {
          utilisateur: true,
          categorie: true,
          items: {
            include: {
              produit: true
            }
          }
        },
        orderBy: {
          dateCreation: 'desc'
        }
      });
      
      const formattedInventories = inventories.map(inventory => {
        // Calculer les statistiques
        const totalItems = inventory.items.length;
        const countedItems = inventory.items.filter(item => item.quantiteComptee !== null).length;
        const itemsWithVariance = inventory.items.filter(item => 
          item.quantiteComptee !== null && item.ecart !== 0
        ).length;
        
        const totalSystemQuantity = inventory.items.reduce((sum, item) => 
          sum + parseFloat(item.quantiteSysteme), 0
        );
        const totalCountedQuantity = inventory.items.reduce((sum, item) => 
          sum + (parseFloat(item.quantiteComptee) || 0), 0
        );
        const totalVariance = totalCountedQuantity - totalSystemQuantity;
        
        const positiveVariance = inventory.items
          .filter(item => item.ecart > 0)
          .reduce((sum, item) => sum + parseFloat(item.ecart), 0);
        const negativeVariance = inventory.items
          .filter(item => item.ecart < 0)
          .reduce((sum, item) => sum + parseFloat(item.ecart), 0);

        return {
          id: inventory.id,
          nom: inventory.nom,
          description: inventory.description,
          type: inventory.type,
          status: inventory.status,
          categorieId: inventory.categorieId,
          nomCategorie: inventory.categorie?.nom,
          utilisateurId: inventory.utilisateurId,
          nomUtilisateur: inventory.utilisateur?.nomUtilisateur,
          dateCreation: inventory.dateCreation,
          dateDebut: inventory.dateDebut,
          dateFin: inventory.dateFin,
          stats: {
            totalItems,
            countedItems,
            itemsWithVariance,
            totalSystemQuantity,
            totalCountedQuantity,
            totalVariance,
            positiveVariance,
            negativeVariance
          }
        };
      });
      
      res.json({
        success: true,
        data: formattedInventories
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des inventaires:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'INVENTORY_FETCH_ERROR'
        }
      });
    }
  });

  // POST /api/v1/stock-inventory - Créer un nouvel inventaire
  router.post('/', async (req, res) => {
    try {
      const { nom, description, type, categorieId, utilisateurId } = req.body;
      
      console.log('📝 Création inventaire - Données reçues:', { nom, type, categorieId, utilisateurId });
      
      // Validation
      if (!nom || !type || !utilisateurId) {
        return res.status(400).json({ 
          success: false,
          error: {
            message: 'Les champs nom, type et utilisateurId sont requis',
            code: 'VALIDATION_ERROR',
            details: { nom: !!nom, type: !!type, utilisateurId: !!utilisateurId }
          }
        });
      }
      
      // Vérifier que l'utilisateur existe
      const userExists = await prisma.utilisateur.findUnique({
        where: { id: parseInt(utilisateurId) }
      });
      
      console.log('👤 Vérification utilisateur:', { utilisateurId, exists: !!userExists });
      
      if (!userExists) {
        // Lister les utilisateurs disponibles pour déboguer
        const allUsers = await prisma.utilisateur.findMany({
          select: { id: true, email: true, nomUtilisateur: true }
        });
        
        console.log('📋 Utilisateurs disponibles:', allUsers);
        
        return res.status(400).json({ 
          success: false,
          error: {
            message: `L'utilisateur avec l'ID ${utilisateurId} n'existe pas`,
            code: 'USER_NOT_FOUND',
            availableUsers: allUsers.map(u => ({ id: u.id, email: u.email }))
          }
        });
      }
      
      // Vérifier si le nom existe déjà
      const existingInventory = await prisma.stockInventory.findFirst({
        where: { nom }
      });
      
      if (existingInventory) {
        return res.status(400).json({ 
          success: false,
          error: {
            message: 'Un inventaire avec ce nom existe déjà',
            code: 'DUPLICATE_NAME'
          }
        });
      }
      
      // Vérifier que la catégorie existe si type PARTIEL
      if (type === 'PARTIEL' && categorieId) {
        const categoryExists = await prisma.category.findUnique({
          where: { id: parseInt(categorieId) }
        });
        
        if (!categoryExists) {
          return res.status(400).json({ 
            success: false,
            error: {
              message: `La catégorie avec l'ID ${categorieId} n'existe pas`,
              code: 'CATEGORY_NOT_FOUND'
            }
          });
        }
      }
      
      // Créer l'inventaire
      const newInventory = await prisma.stockInventory.create({
        data: {
          nom,
          description: description || '',
          type,
          status: 'BROUILLON',
          categorieId: type === 'PARTIEL' && categorieId ? parseInt(categorieId) : null,
          utilisateurId: parseInt(utilisateurId)
        },
        include: {
          utilisateur: true,
          categorie: true
        }
      });
      
      // Générer automatiquement les items d'inventaire
      await generateInventoryItems(prisma, newInventory.id, type, categorieId);
      
      // Récupérer l'inventaire avec ses items
      const inventoryWithItems = await prisma.stockInventory.findUnique({
        where: { id: newInventory.id },
        include: {
          utilisateur: true,
          categorie: true,
          items: {
            include: {
              produit: true
            }
          }
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
          quantiteSysteme: parseFloat(item.quantiteSysteme),
          quantiteComptee: item.quantiteComptee ? parseFloat(item.quantiteComptee) : null,
          ecart: item.ecart ? parseFloat(item.ecart) : null,
          commentaire: item.commentaire,
          dateComptage: item.dateComptage,
          utilisateurComptageId: item.utilisateurComptageId,
          nomUtilisateurComptage: item.utilisateurComptage?.nomUtilisateur
        }))
      };
      
      res.status(201).json({
        success: true,
        data: formattedInventory
      });
    } catch (error) {
      console.error('Erreur lors de la création de l\'inventaire:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'INVENTORY_CREATE_ERROR'
        }
      });
    }
  });

  // GET /api/v1/stock-inventory/:id/items - Récupérer les items d'un inventaire
  router.get('/:id/items', async (req, res) => {
    try {
      const { id } = req.params;
      console.log('🔍 Récupération des items pour inventaire:', id);
      
      const items = await prisma.inventoryItem.findMany({
        where: { inventaireId: parseInt(id) },
        include: {
          produit: {
            include: {
              categorie: true
            }
          },
          utilisateurComptage: true
        },
        orderBy: {
          id: 'asc'
        }
      });
      
      console.log('📊 Items trouvés:', items.length);
      if (items.length > 0) {
        console.log('🔍 Premier item:', JSON.stringify(items[0], null, 2));
      }
      
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
      
      res.json({
        success: true,
        data: formattedItems
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des items:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'INVENTORY_ITEMS_FETCH_ERROR'
        }
      });
    }
  });

  // PUT /api/v1/stock-inventory/items/:itemId - Mettre à jour un item d'inventaire
  router.put('/items/:itemId', async (req, res) => {
    try {
      const { itemId } = req.params;
      const { quantiteComptee, commentaire, utilisateurComptageId } = req.body;
      
      // Récupérer l'item existant
      const existingItem = await prisma.inventoryItem.findUnique({
        where: { id: parseInt(itemId) }
      });
      
      if (!existingItem) {
        return res.status(404).json({ 
          success: false,
          error: {
            message: 'Article d\'inventaire non trouvé',
            code: 'INVENTORY_ITEM_NOT_FOUND'
          }
        });
      }
      
      // Calculer l'écart
      const ecart = parseFloat(quantiteComptee) - parseFloat(existingItem.quantiteSysteme);
      
      const updatedItem = await prisma.inventoryItem.update({
        where: { id: parseInt(itemId) },
        data: {
          quantiteComptee: parseFloat(quantiteComptee),
          ecart,
          commentaire: commentaire || null,
          dateComptage: new Date(),
          utilisateurComptageId
        },
        include: {
          produit: {
            include: {
              categorie: true
            }
          },
          utilisateurComptage: true
        }
      });
      
      const formattedItem = {
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
      };
      
      res.json({
        success: true,
        data: formattedItem
      });
    } catch (error) {
      console.error('Erreur lors de la mise à jour de l\'item:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'INVENTORY_ITEM_UPDATE_ERROR'
        }
      });
    }
  });

  // GET /api/v1/stock-inventory/:id/print - Générer une feuille de comptage
  router.get('/:id/print', async (req, res) => {
    try {
      const { id } = req.params;

      // Récupérer l'inventaire avec ses items
      const inventory = await prisma.stockInventory.findUnique({
        where: { id: parseInt(id) },
        include: {
          utilisateur: true,
          categorie: true,
          items: {
            include: {
              produit: {
                include: {
                  categorie: true
                }
              }
            },
            orderBy: [
              { produit: { categorie: { nom: 'asc' } } },
              { produit: { nom: 'asc' } }
            ]
          }
        }
      });

      if (!inventory) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Inventaire non trouvé',
            code: 'INVENTORY_NOT_FOUND'
          }
        });
      }

      // Générer l'URL de la feuille de comptage (simulation)
      const printUrl = `${req.protocol}://${req.get('host')}/api/v1/stock-inventory/${id}/print-sheet.pdf`;

      // Dans un vrai système, ici on générerait un PDF
      // Pour l'instant, on retourne juste l'URL simulée
      res.json({
        success: true,
        data: {
          printUrl,
          inventory: {
            id: inventory.id,
            nom: inventory.nom,
            type: inventory.type,
            status: inventory.status,
            totalItems: inventory.items.length,
            dateCreation: inventory.dateCreation
          }
        }
      });
    } catch (error) {
      console.error('Erreur lors de la génération de la feuille:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'PRINT_GENERATION_ERROR'
        }
      });
    }
  });

  // PATCH /api/v1/stock-inventory/:id/status - Changer le statut d'un inventaire
  router.patch('/:id/status', async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;

      // Valider le statut
      const validStatuses = ['BROUILLON', 'EN_COURS', 'TERMINE', 'CLOTURE'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Statut invalide',
            code: 'INVALID_STATUS'
          }
        });
      }

      // Mettre à jour le statut
      const updatedInventory = await prisma.stockInventory.update({
        where: { id: parseInt(id) },
        data: { 
          status,
          dateDebut: status === 'EN_COURS' ? new Date() : undefined,
          dateFin: status === 'TERMINE' ? new Date() : undefined
        },
        include: {
          utilisateur: true,
          categorie: true,
          items: {
            include: {
              produit: true
            }
          }
        }
      });

      // Formater la réponse
      const formattedInventory = {
        id: updatedInventory.id,
        nom: updatedInventory.nom,
        description: updatedInventory.description,
        type: updatedInventory.type,
        status: updatedInventory.status,
        categorieId: updatedInventory.categorieId,
        nomCategorie: updatedInventory.categorie?.nom,
        utilisateurId: updatedInventory.utilisateurId,
        nomUtilisateur: updatedInventory.utilisateur?.nomUtilisateur,
        dateCreation: updatedInventory.dateCreation,
        dateDebut: updatedInventory.dateDebut,
        dateFin: updatedInventory.dateFin
      };

      res.json({
        success: true,
        data: formattedInventory
      });
    } catch (error) {
      console.error('Erreur lors de la mise à jour du statut:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'INVENTORY_STATUS_UPDATE_ERROR'
        }
      });
    }
  });

  return router;
}

/**
 * Génère automatiquement les items d'inventaire
 */
async function generateInventoryItems(prisma, inventoryId, type, categorieId) {
  try {
    const where = {};
    if (type === 'PARTIEL' && categorieId) {
      where.categorieId = categorieId;
    }
    
    const products = await prisma.produit.findMany({
      where,
      include: {
        stock: true
      }
    });
    
    const inventoryItems = products.map(product => {
      // Calculer la quantité système (stock actuel)
      let quantiteSysteme = 0;
      if (product.stock && product.stock.quantiteDisponible !== null && product.stock.quantiteDisponible !== undefined) {
        const parsed = parseFloat(product.stock.quantiteDisponible);
        quantiteSysteme = isNaN(parsed) ? 0 : parsed;
      } else {
        // Quantités de démonstration si pas de stock défini
        quantiteSysteme = Math.floor(Math.random() * 50) + 10; // Entre 10 et 59
      }
      
      return {
        inventaireId: inventoryId,
        produitId: product.id,
        quantiteSysteme: quantiteSysteme,
        prixUnitaire: parseFloat(product.prixUnitaire) || 0,
        prixAchat: parseFloat(product.prixAchat) || 0
      };
    });
    
    if (inventoryItems.length > 0) {
      await prisma.inventoryItem.createMany({
        data: inventoryItems
      });
    }
  } catch (error) {
    console.error('Erreur lors de la génération des items d\'inventaire:', error);
    throw error;
  }
}

module.exports = { createStockInventoryRouter };