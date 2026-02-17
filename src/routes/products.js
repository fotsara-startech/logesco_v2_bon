/**
 * Routes pour la gestion des produits - LOGESCO v2
 * Endpoints CRUD complets avec recherche, filtrage et pagination
 */

const express = require('express');
const { validate, validateId, validatePagination } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO, PaginatedResponseDTO, ProduitDTO } = require('../dto');
const { produitSchemas } = require('../validation/schemas');
const {
  buildProductSearchConditions,
  buildPrismaQuery,
  sanitizeInput
} = require('../utils/transformers');

/**
 * Crée le routeur pour les produits
 * @param {Object} models - Factory de modèles
 * @returns {Object} Routeur Express
 */
function createProductRouter(models) {
  const router = express.Router();

  /**
   * GET /products
   * Liste tous les produits avec recherche, filtrage et pagination
   */
  router.get('/',
    validatePagination,
    validate(produitSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { page, limit, ...searchParams } = req.query;

        // Construire les conditions de recherche
        const where = buildProductSearchConditions(searchParams);

        // Options de pagination
        const options = buildPrismaQuery({ page, limit });
        options.where = where;
        options.include = { 
          stock: true,
          categorie: true // Inclure les données de catégorie
        };
        options.orderBy = { dateModification: 'desc' };

        // Exécuter la recherche
        const result = await models.produit.search(searchParams, options);

        // Transformer en DTOs
        const produitsDTO = ProduitDTO.fromEntities(result.produits);

        // Réponse paginée
        const response = new PaginatedResponseDTO(
          produitsDTO,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total: result.total
          },
          'Produits récupérés avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur liste produits:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des produits')
        );
      }
    }
  );

  /**
   * GET /products/generate-reference
   * Génère automatiquement une nouvelle référence produit
   */
  router.get('/generate-reference',
    async (req, res) => {
      try {
        // Générer une référence basée sur l'année et un compteur
        const currentYear = new Date().getFullYear();
        const yearSuffix = currentYear.toString().slice(-2); // Derniers 2 chiffres de l'année

        // Trouver le dernier produit créé cette année
        const lastProduct = await models.prisma.produit.findMany({
          where: {
            reference: {
              startsWith: `PRD${yearSuffix}`
            }
          },
          orderBy: {
            reference: 'desc'
          },
          take: 1
        });

        let nextNumber = 1;
        if (lastProduct.length > 0) {
          // Extraire le numéro de la dernière référence
          const lastRef = lastProduct[0].reference;
          const match = lastRef.match(/PRD\d{2}(\d{4})$/);
          if (match) {
            nextNumber = parseInt(match[1]) + 1;
          }
        }

        // Formater le numéro sur 4 chiffres
        const formattedNumber = nextNumber.toString().padStart(4, '0');
        const newReference = `PRD${yearSuffix}${formattedNumber}`;

        res.json(BaseResponseDTO.success({ reference: newReference }, 'Référence générée avec succès'));

      } catch (error) {
        console.error('Erreur génération référence:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la génération de la référence')
        );
      }
    }
  );

  /**
   * GET /products/all
   * Récupère tous les produits (pour export)
   */
  router.get('/all', 
    authenticateToken(models.authService),
    async (req, res) => {
      try {
        console.log('📤 Export - Récupération de tous les produits');

        const produits = await models.produit.findMany({
          where: {
            companyId: req.user.companyId
          },
          include: {
            categorie: true,
            stock: true
          },
          orderBy: { nom: 'asc' }
        });

        console.log(`📦 ${produits.length} produits trouvés pour l'export`);

        const produitsDTO = ProduitDTO.fromEntities(produits);
        const response = BaseResponseDTO.success(
          produitsDTO,
          'Tous les produits récupérés pour export'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur export produits:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de l\'export des produits')
        );
      }
    }
  );

  /**
   * GET /products/barcode/:barcode
   * Recherche un produit par son code-barre
   */
  router.get('/barcode/:barcode',
    async (req, res) => {
      try {
        const { barcode } = req.params;
        
        if (!barcode || barcode.trim() === '') {
          return res.status(400).json(
            BaseResponseDTO.error('Code-barre requis')
          );
        }

        // Rechercher le produit par code-barre exact
        const produit = await models.prisma.produit.findFirst({
          where: {
            codeBarre: barcode.trim(),
            estActif: true
          },
          include: {
            stock: true,
            categorie: true // Inclure les données de catégorie
          }
        });

        if (!produit) {
          return res.status(404).json(
            BaseResponseDTO.error('Aucun produit trouvé avec ce code-barre')
          );
        }

        const produitDTO = ProduitDTO.fromEntity(produit);
        res.json(BaseResponseDTO.success(produitDTO, 'Produit trouvé par code-barre'));

      } catch (error) {
        console.error('Erreur recherche par code-barre:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la recherche par code-barre')
        );
      }
    }
  );

  /**
   * GET /products/categories
   * Liste des catégories de produits
   */
  router.get('/categories',
    async (req, res) => {
      try {
        // Récupérer toutes les catégories depuis la table Category
        const categories = await models.prisma.category.findMany({
          select: { nom: true },
          orderBy: { nom: 'asc' }
        });

        const categoriesList = categories
          .map(c => c.nom)
          .filter(nom => nom && nom.trim().length > 0);

        res.json(BaseResponseDTO.success(categoriesList, 'Catégories récupérées'));

      } catch (error) {
        console.error('Erreur catégories:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des catégories')
        );
      }
    }
  );

  /**
   * GET /products/:id
   * Récupère un produit par son ID
   */
  router.get('/:id',
    validateId,
    async (req, res) => {
      try {
        const produit = await models.produit.findById(req.params.id, {
          include: {
            stock: true,
            categorie: true, // Inclure les données de catégorie
            mouvementsStock: {
              take: 10,
              orderBy: { dateMouvement: 'desc' }
            }
          }
        });

        if (!produit) {
          return res.status(404).json(
            BaseResponseDTO.error('Produit non trouvé')
          );
        }

        const produitDTO = ProduitDTO.fromEntity(produit);
        res.json(BaseResponseDTO.success(produitDTO, 'Produit récupéré avec succès'));

      } catch (error) {
        console.error('Erreur récupération produit:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du produit')
        );
      }
    }
  );

  /**
   * POST /products
   * Crée un nouveau produit
   */
  router.post('/',
    authenticateToken(models.authService),
    validate(produitSchemas.create),
    async (req, res) => {
      try {
        // Utiliser directement les données du body pour le debug
        const produitData = req.body;
        
        // Debug: Afficher les données reçues
        console.log('=== DONNÉES PRODUIT REÇUES ===');
        console.log('Body brut:', req.body);
        console.log('==============================');

        // Vérifier l'unicité de la référence
        const existingProduct = await models.prisma.produit.findMany({
          where: { reference: produitData.reference }
        });

        if (existingProduct.length > 0) {
          return res.status(409).json(
            BaseResponseDTO.error('Cette référence produit existe déjà', [
              {
                field: 'reference',
                message: 'La référence doit être unique',
                value: produitData.reference
              }
            ])
          );
        }

        // Gérer la conversion de catégorie nom -> ID
        let categorieId = null;
        if (produitData.categorie && produitData.categorie.trim() !== '') {
          console.log('🔍 Recherche de la catégorie:', produitData.categorie);
          
          const category = await models.prisma.category.findUnique({
            where: { nom: produitData.categorie.trim() }
          });
          
          if (category) {
            categorieId = category.id;
            console.log('✅ Catégorie trouvée, ID:', categorieId);
          } else {
            console.log('⚠️ Catégorie non trouvée, création ignorée');
          }
        }

        // Créer le produit avec le nouveau schema
        const produit = await models.prisma.produit.create({
          data: {
            reference: produitData.reference,
            nom: produitData.nom,
            description: produitData.description || null,
            prixUnitaire: produitData.prixUnitaire,
            prixAchat: produitData.prixAchat || null,
            codeBarre: produitData.codeBarre || null,
            categorieId: categorieId,
            seuilStockMinimum: produitData.seuilStockMinimum || 0,
            remiseMaxAutorisee: produitData.remiseMaxAutorisee || 0,
            estActif: produitData.estActif !== undefined ? produitData.estActif : true,
            estService: produitData.estService !== undefined ? produitData.estService : false
          },
          include: {
            categorie: true // Inclure les données de catégorie dans la réponse
          }
        });

        // Créer automatiquement une entrée de stock pour les produits physiques
        if (!produit.estService) {
          console.log(`📦 Création du stock initial pour le produit ${produit.id}`);
          await models.prisma.stock.create({
            data: {
              produitId: produit.id,
              quantiteDisponible: produitData.quantiteInitiale || 0,
              quantiteReservee: 0
            }
          });
          console.log(`✅ Stock créé avec quantité initiale: ${produitData.quantiteInitiale || 0}`);
        } else {
          console.log(`ℹ️ Produit de type service, pas de stock créé`);
        }

        const produitDTO = ProduitDTO.fromEntity(produit);
        res.status(201).json(
          BaseResponseDTO.success(produitDTO, 'Produit créé avec succès')
        );

      } catch (error) {
        console.error('=== ERREUR CRÉATION PRODUIT ===');
        console.error('Type d\'erreur:', error.constructor.name);
        console.error('Code d\'erreur:', error.code);
        console.error('Message:', error.message);
        console.error('Stack:', error.stack);
        console.error('Données reçues:', produitData);
        console.error('================================');

        if (error.code === 'P2002') {
          return res.status(409).json(
            BaseResponseDTO.error('Référence produit déjà utilisée')
          );
        }

        // Erreur de validation Joi
        if (error.name === 'ValidationError') {
          return res.status(400).json(
            BaseResponseDTO.error('Erreur de validation', error.details)
          );
        }

        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la création du produit: ' + error.message)
        );
      }
    }
  );

  /**
   * PUT /products/:id
   * Met à jour un produit existant
   */
  router.put('/:id',
    authenticateToken(models.authService),
    validateId,
    validate(produitSchemas.update),
    async (req, res) => {
      try {
        const produitId = req.params.id;
        const updateData = sanitizeInput(req.body);

        // Vérifier que le produit existe
        const existingProduct = await models.produit.findById(produitId);
        if (!existingProduct) {
          return res.status(404).json(
            BaseResponseDTO.error('Produit non trouvé')
          );
        }

        // Vérifier l'unicité de la référence si elle est modifiée
        if (updateData.reference && updateData.reference !== existingProduct.reference) {
          const duplicateRef = await models.prisma.produit.findMany({
            where: {
              reference: updateData.reference,
              id: { not: parseInt(produitId) }
            }
          });

          if (duplicateRef.length > 0) {
            return res.status(409).json(
              BaseResponseDTO.error('Cette référence produit existe déjà')
            );
          }
        }

        // Gérer la conversion de catégorie nom -> ID pour la mise à jour
        let categorieId = null;
        if (updateData.categorie !== undefined) {
          if (updateData.categorie && updateData.categorie.trim() !== '') {
            console.log('🔍 Recherche de la catégorie pour mise à jour:', updateData.categorie);
            
            const category = await models.prisma.category.findUnique({
              where: { nom: updateData.categorie.trim() }
            });
            
            if (category) {
              categorieId = category.id;
              console.log('✅ Catégorie trouvée pour mise à jour, ID:', categorieId);
            } else {
              console.log('⚠️ Catégorie non trouvée pour mise à jour');
            }
          }
          // Remplacer le champ categorie par categorieId
          delete updateData.categorie;
          updateData.categorieId = categorieId;
        }

        // Mettre à jour le produit avec Prisma directement
        const produitUpdated = await models.prisma.produit.update({
          where: { id: parseInt(produitId) },
          data: updateData,
          include: { 
            stock: true,
            categorie: true // Inclure les données de catégorie
          }
        });

        const produitDTO = ProduitDTO.fromEntity(produitUpdated);
        res.json(BaseResponseDTO.success(produitDTO, 'Produit mis à jour avec succès'));

      } catch (error) {
        console.error('Erreur mise à jour produit:', error);

        if (error.code === 'P2002') {
          return res.status(409).json(
            BaseResponseDTO.error('Référence produit déjà utilisée')
          );
        }

        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la mise à jour du produit')
        );
      }
    }
  );

  /**
   * GET /products/:id/test-auth
   * Test d'authentification pour un produit spécifique
   */
  router.get('/:id/test-auth',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const produitId = parseInt(req.params.id);
        console.log(`🧪 Test auth pour produit ID: ${produitId}`);
        console.log('👤 Utilisateur authentifié:', req.user);
        
        res.json(BaseResponseDTO.success({
          produitId,
          user: req.user,
          message: 'Authentification réussie'
        }, 'Test d\'authentification réussi'));
        
      } catch (error) {
        console.error('Erreur test auth:', error);
        res.status(500).json(BaseResponseDTO.error('Erreur test auth'));
      }
    }
  );

  /**
   * DELETE /products/:id
   * Supprime un produit (soft delete en désactivant)
   */
  router.delete('/:id',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const produitId = parseInt(req.params.id);

        console.log(`=== SUPPRESSION PRODUIT ID: ${produitId} ===`);
        console.log('Paramètres reçus:', req.params);
        console.log('Headers:', req.headers.authorization ? 'Token présent' : 'Pas de token');
        
        // Vérifier que l'ID est valide
        if (isNaN(produitId) || produitId <= 0) {
          console.log('❌ ID invalide:', req.params.id);
          return res.status(400).json(
            BaseResponseDTO.error('ID de produit invalide')
          );
        }

        console.log('🔍 Recherche du produit...');
        
        // Vérifier que le produit existe
        const existingProduct = await models.prisma.produit.findUnique({
          where: { id: produitId }
        });
        
        if (!existingProduct) {
          console.log('❌ Produit non trouvé');
          return res.status(404).json(
            BaseResponseDTO.error('Produit non trouvé')
          );
        }

        console.log('✅ Produit trouvé:', existingProduct.reference);
        console.log('📋 Détails produit:', {
          id: existingProduct.id,
          reference: existingProduct.reference,
          nom: existingProduct.nom,
          estActif: existingProduct.estActif
        });

        console.log('🔍 Vérification des relations...');
        
        // Vérifier s'il y a des transactions liées
        let hasTransactions = 0;
        let hasOrders = 0;
        
        try {
          console.log('📊 Vérification table detailVente...');
          // Vérifier si la table existe d'abord
          const tableExists = await models.prisma.$queryRaw`
            SELECT name FROM sqlite_master WHERE type='table' AND name='detailVente';
          `;
          
          if (tableExists.length > 0) {
            hasTransactions = await models.prisma.detailVente.count({
              where: { produitId: produitId }
            });
            console.log(`✅ detailVente: ${hasTransactions} transactions`);
          } else {
            console.log('⚠️ Table detailVente n\'existe pas encore');
          }
        } catch (e) {
          console.log('⚠️ Erreur vérification detailVente:', e.message);
        }

        try {
          console.log('📊 Vérification table detailCommandeApprovisionnement...');
          // Vérifier si la table existe d'abord
          const tableExists = await models.prisma.$queryRaw`
            SELECT name FROM sqlite_master WHERE type='table' AND name='detailCommandeApprovisionnement';
          `;
          
          if (tableExists.length > 0) {
            hasOrders = await models.prisma.detailCommandeApprovisionnement.count({
              where: { produitId: produitId }
            });
            console.log(`✅ detailCommandeApprovisionnement: ${hasOrders} commandes`);
          } else {
            console.log('⚠️ Table detailCommandeApprovisionnement n\'existe pas encore');
          }
        } catch (e) {
          console.log('⚠️ Erreur vérification detailCommandeApprovisionnement:', e.message);
        }

        // Vérifier aussi les mouvements de stock
        let hasStockMovements = 0;
        try {
          console.log('📊 Vérification table mouvementStock...');
          const tableExists = await models.prisma.$queryRaw`
            SELECT name FROM sqlite_master WHERE type='table' AND name='mouvementStock';
          `;
          
          if (tableExists.length > 0) {
            hasStockMovements = await models.prisma.mouvementStock.count({
              where: { produitId: produitId }
            });
            console.log(`✅ mouvementStock: ${hasStockMovements} mouvements`);
          } else {
            console.log('⚠️ Table mouvementStock n\'existe pas encore');
          }
        } catch (e) {
          console.log('⚠️ Erreur vérification mouvementStock:', e.message);
        }

        console.log(`📊 Résumé - Transactions: ${hasTransactions}, Commandes: ${hasOrders}, Mouvements: ${hasStockMovements}`);

        if (hasTransactions > 0 || hasOrders > 0 || hasStockMovements > 0) {
          // Soft delete : désactiver le produit au lieu de le supprimer
          const produitDeactivated = await models.prisma.produit.update({
            where: { id: produitId },
            data: { estActif: false }
          });

          const produitDTO = ProduitDTO.fromEntity(produitDeactivated);
          console.log('✅ Produit désactivé (soft delete)');
          return res.json(
            BaseResponseDTO.success(
              produitDTO,
              'Produit désactivé (des transactions existent)'
            )
          );
        }

        // Tentative de suppression complète
        try {
          await models.prisma.produit.delete({
            where: { id: produitId }
          });
          console.log('✅ Produit supprimé définitivement');
          res.json(BaseResponseDTO.success(null, 'Produit supprimé avec succès'));
        } catch (deleteError) {
          // Si la suppression échoue à cause d'une contrainte, faire un soft delete
          if (deleteError.code === 'P2003' || deleteError.message.includes('Foreign key constraint')) {
            console.log('⚠️ Contrainte de clé étrangère détectée, soft delete appliqué');
            const produitDeactivated = await models.prisma.produit.update({
              where: { id: produitId },
              data: { estActif: false }
            });

            const produitDTO = ProduitDTO.fromEntity(produitDeactivated);
            return res.json(
              BaseResponseDTO.success(
                produitDTO,
                'Produit désactivé (utilisé dans d\'autres enregistrements)'
              )
            );
          }
          // Si c'est une autre erreur, la relancer
          throw deleteError;
        }

      } catch (error) {
        console.error('=== ERREUR SUPPRESSION PRODUIT ===');
        console.error('Type:', error.constructor.name);
        console.error('Code:', error.code);
        console.error('Message:', error.message);
        console.error('Stack:', error.stack);
        console.error('================================');
        
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la suppression du produit: ' + error.message)
        );
      }
    }
  );

  /**
   * GET /products/search/suggestions
   * Suggestions de recherche pour l'autocomplétion
   */
  router.get('/search/suggestions',
    validate(produitSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { q } = req.query;

        if (!q || q.length < 2) {
          return res.json(BaseResponseDTO.success([], 'Requête trop courte'));
        }

        const suggestions = await models.prisma.produit.findMany({
          where: {
            OR: [
              { nom: { contains: q } },
              { reference: { contains: q } }
            ],
            estActif: true
          },
          select: {
            id: true,
            reference: true,
            nom: true,
            prixUnitaire: true
          },
          take: 10,
          orderBy: { nom: 'asc' }
        });

        res.json(BaseResponseDTO.success(suggestions, 'Suggestions récupérées'));

      } catch (error) {
        console.error('Erreur suggestions:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des suggestions')
        );
      }
    }
  );

  /**
   * GET /products/check-reference
   * Vérifie l'unicité d'une référence produit
   */
  router.get('/check-reference',
    validate(produitSchemas.checkReference, 'query'),
    async (req, res) => {
      try {
        const { reference, exclude_id } = req.query;

        const whereCondition = {
          reference: reference,
        };

        // Exclure le produit en cours d'édition si spécifié
        if (exclude_id) {
          whereCondition.id = { not: parseInt(exclude_id) };
        }

        const existingProduct = await models.prisma.produit.findMany({
          where: whereCondition
        });

        const isUnique = existingProduct.length === 0;

        res.json(BaseResponseDTO.success({ is_unique: isUnique }, 'Vérification de référence effectuée'));

      } catch (error) {
        console.error('Erreur vérification référence:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la vérification de la référence')
        );
      }
    }
  );

  /**
   * GET /products/low-stock
   * Produits avec stock faible
   */
  router.get('/low-stock',
    authenticateToken(models.authService),
    validatePagination,
    async (req, res) => {
      try {
        const { page, limit } = req.query;
        const options = buildPrismaQuery({ page, limit });

        const produits = await models.produit.findLowStock();
        const total = produits.length;

        // Appliquer la pagination manuellement
        const startIndex = (parseInt(page) - 1) * parseInt(limit);
        const paginatedProducts = produits.slice(startIndex, startIndex + parseInt(limit));

        const produitsDTO = ProduitDTO.fromEntities(paginatedProducts);

        const response = new PaginatedResponseDTO(
          produitsDTO,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total
          },
          'Produits en stock faible récupérés'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur stock faible:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des produits en stock faible')
        );
      }
    }
  );



  /**
   * POST /products/import
   * Importe des produits en lot
   */
  router.post('/import',
    authenticateToken(models.authService),
    async (req, res) => {
      try {
        console.log('📥 Import - Début de l\'import des produits');
        const { products } = req.body;

        if (!products || !Array.isArray(products)) {
          return res.status(400).json(
            BaseResponseDTO.error('Liste de produits invalide')
          );
        }

        console.log(`📦 ${products.length} produits à importer`);

        const importedProducts = [];
        const errors = [];

        // Traitement par lot pour éviter les problèmes de performance
        for (let i = 0; i < products.length; i++) {
          const productData = products[i];
          
          try {
            // Vérifier que la référence n'existe pas déjà
            const existingProduct = await models.produit.findFirst({
              where: {
                reference: productData.reference,
                companyId: req.user.companyId
              }
            });

            if (existingProduct) {
              errors.push({
                index: i,
                reference: productData.reference,
                error: 'Référence déjà existante'
              });
              continue;
            }

            // Traiter la catégorie si elle existe
            let categorieId = null;
            if (productData.categorie) {
              // Chercher ou créer la catégorie
              let category = await models.prisma.category.findFirst({
                where: { nom: productData.categorie }
              });
              
              if (!category) {
                // Créer la catégorie si elle n'existe pas
                category = await models.prisma.category.create({
                  data: {
                    nom: productData.categorie,
                    description: `Catégorie ${productData.categorie}`
                  }
                });
              }
              
              categorieId = category.id;
            }

            // Préparer les données du produit sans le champ categorie
            const { categorie, ...productDataWithoutCategorie } = productData;

            // Créer le produit
            const newProduct = await models.produit.create({
              ...productDataWithoutCategorie,
              categorieId,
              companyId: req.user.companyId,
              dateCreation: new Date(),
              dateModification: new Date()
            });

            importedProducts.push(newProduct);
            console.log(`✅ Produit importé: ${newProduct.reference}`);

          } catch (error) {
            console.error(`❌ Erreur import produit ${i}:`, error);
            errors.push({
              index: i,
              reference: productData.reference || 'N/A',
              error: error.message
            });
          }
        }

        console.log(`📊 Import terminé: ${importedProducts.length} succès, ${errors.length} erreurs`);

        const importedDTO = ProduitDTO.fromEntities(importedProducts);
        const response = BaseResponseDTO.success(
          {
            imported: importedDTO,
            errors: errors,
            summary: {
              total: products.length,
              imported: importedProducts.length,
              errors: errors.length
            }
          },
          `Import terminé: ${importedProducts.length} produits importés`
        );

        res.status(201).json(response);

      } catch (error) {
        console.error('Erreur import produits:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de l\'import des produits')
        );
      }
    }
  );

  return router;
}

module.exports = { createProductRouter };