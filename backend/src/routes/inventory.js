/**
 * Routes pour la gestion du stock - LOGESCO v2
 * Endpoints pour la gestion du stock, mouvements et alertes
 */

const express = require('express');
const Joi = require('joi');
const { validate, validateId, validatePagination } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO, PaginatedResponseDTO, StockDTO, MouvementStockDTO } = require('../dto');
const { stockSchemas } = require('../validation/schemas');
const {
  buildPrismaQuery,
  sanitizeInput
} = require('../utils/transformers');

/**
 * Crée le routeur pour la gestion du stock
 * @param {Object} models - Factory de modèles
 * @returns {Object} Routeur Express
 */
function createInventoryRouter(models) {
  const router = express.Router();

  /**
   * POST /inventory
   * Crée ou initialise un stock pour un produit
   */
  router.post('/',
    authenticateToken(models.authService),
    validate(stockSchemas.create),
    async (req, res) => {
      try {
        const { produitId, quantiteInitiale } = req.body;

        // Vérifier que le produit existe
        const produit = await models.prisma.produit.findUnique({
          where: { id: produitId }
        });

        if (!produit) {
          return res.status(404).json(
            BaseResponseDTO.error('Produit non trouvé')
          );
        }

        // Vérifier si un stock existe déjà
        const existingStock = await models.prisma.stock.findUnique({
          where: { produitId }
        });

        if (existingStock) {
          return res.status(409).json(
            BaseResponseDTO.error('Un stock existe déjà pour ce produit. Utilisez /adjust pour le modifier.')
          );
        }

        // Créer le stock
        const stock = await models.prisma.stock.create({
          data: {
            produitId,
            quantiteDisponible: quantiteInitiale || 0,
            quantiteReservee: 0
          },
          include: {
            produit: {
              select: {
                id: true,
                reference: true,
                nom: true,
                seuilStockMinimum: true
              }
            }
          }
        });

        // Créer un mouvement de stock pour tracer l'initialisation
        if (quantiteInitiale > 0) {
          await models.prisma.mouvementStock.create({
            data: {
              produitId,
              typeMouvement: 'initialisation',
              changementQuantite: quantiteInitiale,
              notes: 'Initialisation du stock'
            }
          });
        }

        const stockDTO = StockDTO.fromEntity(stock);
        res.status(201).json(
          BaseResponseDTO.success(stockDTO, 'Stock créé avec succès')
        );

      } catch (error) {
        console.error('Erreur création stock:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la création du stock')
        );
      }
    }
  );

  /**
   * GET /inventory
   * Liste tous les stocks avec pagination et filtres
   * Utilise Prisma avec LEFT JOIN pour afficher tous les produits actifs, même ceux sans stock
   */
  router.get('/',
    authenticateToken(models.authService),
    validatePagination,
    validate(stockSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { page, limit, alerteStock, produitId, search, category } = req.query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        // Construire les conditions de recherche pour les produits
        const produitWhere = { estActif: true };

        if (produitId) {
          produitWhere.id = parseInt(produitId);
        }

        if (search && search.trim()) {
          const searchTerm = search.trim();
          produitWhere.OR = [
            { nom: { contains: searchTerm } },
            { reference: { contains: searchTerm } },
            { codeBarre: { contains: searchTerm } }
          ];
        }

        if (category && category.trim()) {
          produitWhere.categorie = {
            is: {
              nom: category.trim()
            }
          };
        }

        // Filtrer par alerte de stock si demandé
        if (alerteStock === true || alerteStock === 'true') {
          // Récupérer tous les produits actifs en alerte avec pagination
          const produits = await models.prisma.produit.findMany({
            where: produitWhere,
            include: {
              stock: true,
              categorie: true
            },
            orderBy: { nom: 'asc' },
            skip: offset,
            take: limitNum
          });

          // Filtrer côté JavaScript pour les alertes
          const alertStocks = produits
            .filter(p => !p.stock || p.stock.quantiteDisponible <= p.seuilStockMinimum)
            .map(p => ({
              id: p.stock?.id || `alert_${p.id}`,
              produitId: p.id,
              quantiteDisponible: p.stock?.quantiteDisponible ?? 0,
              quantiteReservee: p.stock?.quantiteReservee ?? 0,
              derniereMaj: p.stock?.derniereMaj || new Date(),
              produit: p
            }));

          // Compter le total
          const allProduitsAlerte = await models.prisma.produit.findMany({
            where: produitWhere,
            include: {
              stock: true
            }
          });

          const totalAlerts = allProduitsAlerte.filter(
            p => !p.stock || p.stock.quantiteDisponible <= p.seuilStockMinimum
          ).length;

          const stocksDTO = StockDTO.fromEntities(alertStocks);
          const response = new PaginatedResponseDTO(
            stocksDTO,
            { page: pageNum, limit: limitNum, total: totalAlerts },
            'Stocks en alerte récupérés avec succès'
          );

          return res.json(response);
        }

        // Requête normale: tous les produits actifs avec ou sans stock
        const [produits, totalCount] = await Promise.all([
          models.prisma.produit.findMany({
            where: produitWhere,
            include: {
              stock: true,
              categorie: true
            },
            orderBy: [
              { stock: { derniereMaj: 'desc' } },
              { nom: 'asc' }
            ],
            skip: offset,
            take: limitNum
          }),
          models.prisma.produit.count({
            where: produitWhere
          })
        ]);

        // Transformer en objets Stock
        const stocks = produits.map(p => ({
          id: p.stock?.id || `temp_${p.id}`,
          produitId: p.id,
          quantiteDisponible: p.stock?.quantiteDisponible ?? 0,
          quantiteReservee: p.stock?.quantiteReservee ?? 0,
          derniereMaj: p.stock?.derniereMaj || new Date(),
          stockFaible: (p.stock?.quantiteDisponible ?? 0) <= p.seuilStockMinimum,
          produit: p
        }));

        const stocksDTO = StockDTO.fromEntities(stocks);

        const response = new PaginatedResponseDTO(
          stocksDTO,
          { page: pageNum, limit: limitNum, total: totalCount },
          'Stocks récupérés avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur liste stocks:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des stocks')
        );
      }
    }
  );

  /**
   * POST /inventory/adjust
   * Ajuste manuellement le stock d'un produit
   */
  router.post('/adjust',
    authenticateToken(models.authService),
    validate(stockSchemas.ajustement),
    async (req, res) => {
      try {
        const { produitId, changementQuantite, notes } = sanitizeInput(req.body);

        // Vérifier que le produit existe
        const produit = await models.produit.findById(produitId);
        if (!produit) {
          return res.status(404).json(
            BaseResponseDTO.error('Produit non trouvé')
          );
        }

        // Vérifier que le stock existe
        const stockActuel = await models.prisma.stock.findUnique({
          where: { produitId },
          include: { produit: true }
        });

        if (!stockActuel) {
          return res.status(404).json(
            BaseResponseDTO.error('Stock non trouvé pour ce produit')
          );
        }

        // Vérifier que l'ajustement ne rend pas le stock négatif
        const nouvelleQuantite = stockActuel.quantiteDisponible + changementQuantite;
        if (nouvelleQuantite < 0) {
          return res.status(400).json(
            BaseResponseDTO.error(
              `Ajustement impossible: la quantité résultante serait négative (${nouvelleQuantite})`
            )
          );
        }

        // Effectuer l'ajustement
        const stockAjuste = await models.stock.adjustStock(
          produitId,
          changementQuantite,
          'ajustement',
          null,
          notes || 'Ajustement manuel'
        );

        // Récupérer le stock mis à jour avec les informations du produit
        const stockComplet = await models.prisma.stock.findUnique({
          where: { produitId },
          include: { produit: true }
        });

        const stockDTO = StockDTO.fromEntity(stockComplet);

        res.json(BaseResponseDTO.success(
          stockDTO,
          `Stock ajusté avec succès (${changementQuantite > 0 ? '+' : ''}${changementQuantite})`
        ));

      } catch (error) {
        console.error('Erreur ajustement stock:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de l\'ajustement du stock')
        );
      }
    }
  );

  /**
   * GET /inventory/alerts
   * Récupère tous les produits en alerte de stock
   */
  router.get('/alerts',
    authenticateToken(models.authService),
    validatePagination,
    async (req, res) => {
      try {
        const { page, limit } = req.query;

        // Requête pour les stocks en alerte (quantité <= seuil minimum)
        const alertes = await models.prisma.$queryRaw`
          SELECT s.id, s.produit_id, s.quantite_disponible, s.quantite_reservee, s.derniere_maj,
                 p.reference, p.nom, p.seuil_stock_minimum, p.est_actif
          FROM stock s
          INNER JOIN produits p ON s.produit_id = p.id
          WHERE s.quantite_disponible <= p.seuil_stock_minimum
          AND p.est_actif = 1
          ORDER BY (s.quantite_disponible - p.seuil_stock_minimum) ASC
          LIMIT ${parseInt(limit)} OFFSET ${(parseInt(page) - 1) * parseInt(limit)}
        `;

        const totalAlertes = await models.prisma.$queryRaw`
          SELECT COUNT(*) as count
          FROM stock s
          INNER JOIN produits p ON s.produit_id = p.id
          WHERE s.quantite_disponible <= p.seuil_stock_minimum
          AND p.est_actif = 1
        `;

        // Transformer les résultats en format attendu
        const stocksAlertes = alertes.map(row => ({
          id: row.id,
          produitId: row.produit_id,
          quantiteDisponible: row.quantite_disponible,
          quantiteReservee: row.quantite_reservee,
          derniereMaj: row.derniere_maj,
          produit: {
            id: row.produit_id,
            reference: row.reference,
            nom: row.nom,
            seuilStockMinimum: row.seuil_stock_minimum,
            estActif: row.est_actif
          }
        }));

        const stocksDTO = StockDTO.fromEntities(stocksAlertes);

        const response = new PaginatedResponseDTO(
          stocksDTO,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total: parseInt(totalAlertes[0].count)
          },
          'Alertes de stock récupérées avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur alertes stock:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des alertes de stock')
        );
      }
    }
  );

  /**
   * GET /inventory/movements
   * Récupère l'historique des mouvements de stock
   */
  router.get('/movements',
    authenticateToken(models.authService),
    validate(stockSchemas.mouvements, 'query'),
    async (req, res) => {
      try {
        console.log('🔍 GET /movements - Paramètres reçus:', req.query);
        const { page, limit, q, produitId, typeMouvement, dateDebut, dateFin } = req.query;
        const options = buildPrismaQuery({ page, limit });

        // Construire les conditions de recherche
        const where = {};

        // Recherche par nom de produit (sans mode insensitive dans les relations)
        if (q && q.trim().length > 0) {
          where.produit = {
            OR: [
              { nom: { contains: q } },
              { reference: { contains: q } },
            ]
          };
        }

        if (produitId) {
          where.produitId = parseInt(produitId);
        }

        if (typeMouvement) {
          where.typeMouvement = typeMouvement;
        }

        if (dateDebut || dateFin) {
          where.dateMouvement = {};
          if (dateDebut) {
            where.dateMouvement.gte = new Date(dateDebut);
          }
          if (dateFin) {
            where.dateMouvement.lte = new Date(dateFin);
          }
        }

        options.where = where;
        options.include = { 
          produit: {
            include: {
              stock: true
            }
          }
        };
        options.orderBy = { dateMouvement: 'desc' };

        console.log('📊 Requête Prisma construite:', { where: options.where, include: options.include });

        const [mouvements, total] = await Promise.all([
          models.prisma.mouvementStock.findMany(options),
          models.prisma.mouvementStock.count({ where })
        ]);

        console.log('📋 Résultats de la base:');
        console.log(`  - ${mouvements.length} mouvements trouvés sur ${total} total`);
        if (mouvements.length > 0) {
          console.log('  - Premier mouvement:', {
            id: mouvements[0].id,
            type: mouvements[0].typeMouvement,
            quantite: mouvements[0].changementQuantite,
            produit: mouvements[0].produit?.nom
          });
        }

        const mouvementsDTO = MouvementStockDTO.fromEntities(mouvements);

        const response = new PaginatedResponseDTO(
          mouvementsDTO,
          { page: parseInt(page), limit: parseInt(limit), total },
          'Mouvements de stock récupérés avec succès'
        );

        console.log('✅ Réponse envoyée:', {
          success: true,
          dataLength: mouvementsDTO.length,
          pagination: response.pagination
        });

        res.json(response);

      } catch (error) {
        console.error('Erreur mouvements stock:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des mouvements de stock')
        );
      }
    }
  );

  /**
   * POST /inventory/movements
   * Crée un nouveau mouvement de stock
   */
  router.post('/movements',
    authenticateToken(models.authService),
    validate(stockSchemas.createMouvement),
    async (req, res) => {
      try {
        const { produitId, typeMouvement, changementQuantite, notes, referenceId, typeReference } = sanitizeInput(req.body);

        // Vérifier que le produit existe
        const produit = await models.prisma.produit.findUnique({
          where: { id: produitId },
          include: { stock: true }
        });

        if (!produit) {
          return res.status(404).json(
            BaseResponseDTO.error('Produit non trouvé')
          );
        }

        // Pour les mouvements qui affectent le stock (achat, ajustement, retour, correction)
        const typesAffectantStock = ['achat', 'vente', 'ajustement', 'retour', 'correction', 'transfert'];

        await models.prisma.$transaction(async (tx) => {
          // Créer le mouvement de stock
          const mouvement = await tx.mouvementStock.create({
            data: {
              produitId,
              typeMouvement,
              changementQuantite,
              notes: notes || `Mouvement ${typeMouvement}`,
              referenceId,
              typeReference
            },
            include: {
              produit: true
            }
          });

          // Mettre à jour le stock si le type de mouvement l'affecte
          if (typesAffectantStock.includes(typeMouvement)) {
            // Vérifier si le stock existe
            if (!produit.stock) {
              // Créer le stock s'il n'existe pas (pour les nouveaux produits)
              if (changementQuantite > 0) {
                await tx.stock.create({
                  data: {
                    produitId,
                    quantiteDisponible: changementQuantite,
                    quantiteReservee: 0
                  }
                });
              } else {
                throw new Error('Impossible de créer un stock avec une quantité négative');
              }
            } else {
              // Mettre à jour le stock existant
              const nouvelleQuantite = produit.stock.quantiteDisponible + changementQuantite;

              if (nouvelleQuantite < 0) {
                throw new Error(`Stock insuffisant. Quantité disponible: ${produit.stock.quantiteDisponible}, changement demandé: ${changementQuantite}`);
              }

              await tx.stock.update({
                where: { produitId },
                data: {
                  quantiteDisponible: nouvelleQuantite
                }
              });
            }
          }

          return mouvement;
        });

        // Récupérer le mouvement créé avec les informations du produit
        const mouvementCree = await models.prisma.mouvementStock.findFirst({
          where: { produitId, typeMouvement, changementQuantite },
          include: { produit: true },
          orderBy: { dateMouvement: 'desc' }
        });

        const mouvementDTO = MouvementStockDTO.fromEntity(mouvementCree);

        res.status(201).json(BaseResponseDTO.success(
          mouvementDTO,
          `Mouvement de stock créé avec succès`
        ));

      } catch (error) {
        console.error('Erreur création mouvement stock:', error);
        res.status(500).json(
          BaseResponseDTO.error(error.message || 'Erreur lors de la création du mouvement de stock')
        );
      }
    }
  );

  /**
   * GET /inventory/summary
   * Résumé global du stock
   */
  router.get('/summary',
    authenticateToken(models.authService),
    async (req, res) => {
      try {
        // Statistiques globales
        const [
          totalProduits,
          produitsEnStock,
          produitsEnAlerte,
          produitsEnRupture,
          valeurTotaleStock
        ] = await Promise.all([
          // Total des produits actifs
          models.prisma.produit.count({ where: { estActif: true } }),

          // Produits avec stock disponible
          models.prisma.stock.count({
            where: {
              quantiteDisponible: { gt: 0 },
              produit: { estActif: true }
            }
          }),

          // Produits en alerte (stock <= seuil)
          models.prisma.$queryRaw`
            SELECT COUNT(*) as count
            FROM stock s
            INNER JOIN produits p ON s.produit_id = p.id
            WHERE s.quantite_disponible <= p.seuil_stock_minimum
            AND s.quantite_disponible > 0
            AND p.est_actif = 1
          `,

          // Produits en rupture (stock = 0)
          models.prisma.stock.count({
            where: {
              quantiteDisponible: 0,
              produit: { estActif: true }
            }
          }),

          // Valeur totale du stock (prix d'achat et de vente)
          models.prisma.$queryRaw`
            SELECT 
              SUM(s.quantite_disponible * COALESCE(p.prix_achat, p.prix_unitaire * 0.8)) as valeurAchat,
              SUM(s.quantite_disponible * p.prix_unitaire) as valeurVente
            FROM stock s
            INNER JOIN produits p ON s.produit_id = p.id
            WHERE p.est_actif = 1
          `
        ]);

        const summary = {
          totalProduits,
          produitsEnStock,
          produitsEnAlerte: parseInt(produitsEnAlerte[0].count),
          produitsEnRupture,
          valeurTotaleStock: parseFloat(valeurTotaleStock[0].valeurVente || 0), // Compatibilité
          valeurStockAchat: parseFloat(valeurTotaleStock[0].valeurAchat || 0),
          valeurStockVente: parseFloat(valeurTotaleStock[0].valeurVente || 0),
          pourcentageEnStock: totalProduits > 0 ? Math.round((produitsEnStock / totalProduits) * 100) : 0,
          pourcentageEnAlerte: totalProduits > 0 ? Math.round((parseInt(produitsEnAlerte[0].count) / totalProduits) * 100) : 0,
          pourcentageEnRupture: totalProduits > 0 ? Math.round((produitsEnRupture / totalProduits) * 100) : 0
        };

        res.json(BaseResponseDTO.success(summary, 'Résumé du stock récupéré avec succès'));

      } catch (error) {
        console.error('Erreur résumé stock:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du résumé du stock')
        );
      }
    }
  );

  /**
   * POST /inventory/bulk-adjust
   * Ajustement en lot de plusieurs produits
   */
  router.post('/bulk-adjust',
    authenticateToken(models.authService),
    validate(stockSchemas.bulkAdjust),
    async (req, res) => {
      try {
        const { ajustements, notes: notesGlobales } = sanitizeInput(req.body);

        const resultats = [];
        const erreurs = [];

        // Traiter chaque ajustement dans une transaction
        await models.prisma.$transaction(async (tx) => {
          for (const ajustement of ajustements) {
            try {
              const { produitId, changementQuantite, notes } = ajustement;

              // Vérifier que le produit existe
              const produit = await tx.produit.findUnique({
                where: { id: produitId },
                include: { stock: true }
              });

              if (!produit) {
                erreurs.push({
                  produitId,
                  erreur: 'Produit non trouvé'
                });
                continue;
              }

              if (!produit.stock) {
                erreurs.push({
                  produitId,
                  erreur: 'Stock non trouvé pour ce produit'
                });
                continue;
              }

              // Vérifier que l'ajustement ne rend pas le stock négatif
              const nouvelleQuantite = produit.stock.quantiteDisponible + changementQuantite;
              if (nouvelleQuantite < 0) {
                erreurs.push({
                  produitId,
                  erreur: `Ajustement impossible: quantité résultante négative (${nouvelleQuantite})`
                });
                continue;
              }

              // Effectuer l'ajustement
              await tx.stock.update({
                where: { produitId },
                data: {
                  quantiteDisponible: {
                    increment: changementQuantite
                  }
                }
              });

              // Enregistrer le mouvement
              await tx.mouvementStock.create({
                data: {
                  produitId,
                  typeMouvement: 'ajustement',
                  changementQuantite,
                  typeReference: 'ajustement',
                  notes: notes || notesGlobales || 'Ajustement en lot'
                }
              });

              resultats.push({
                produitId,
                changementQuantite,
                nouvelleQuantite,
                succes: true
              });

            } catch (error) {
              erreurs.push({
                produitId: ajustement.produitId,
                erreur: error.message
              });
            }
          }
        });

        const response = {
          ajustementsReussis: resultats.length,
          ajustementsEchoues: erreurs.length,
          resultats,
          erreurs
        };

        if (erreurs.length > 0) {
          res.status(207).json(BaseResponseDTO.success(
            response,
            `Ajustement en lot terminé avec ${erreurs.length} erreur(s)`
          ));
        } else {
          res.json(BaseResponseDTO.success(
            response,
            'Ajustement en lot effectué avec succès'
          ));
        }

      } catch (error) {
        console.error('Erreur ajustement en lot:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de l\'ajustement en lot')
        );
      }
    }
  );

  /**
   * GET /inventory/export/csv
   * Exporte les stocks au format CSV
   */
  router.get('/export/csv',
    authenticateToken(models.authService),
    validate(stockSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { alerteStock, produitId, search, category } = req.query;

        // Construire les conditions de recherche
        const where = {};
        const produitWhere = { estActif: true };

        if (produitId) {
          where.produitId = parseInt(produitId);
        }

        // Ajouter la recherche par texte
        if (search && search.trim()) {
          const searchTerm = search.trim();
          produitWhere.OR = [
            { nom: { contains: searchTerm } },
            { reference: { contains: searchTerm } },
            { codeBarre: { contains: searchTerm } }
          ];
        }

        // Ajouter le filtre par catégorie
        if (category && category.trim()) {
          produitWhere.categorie = {
            is: {
              nom: category.trim()
            }
          };
        }

        where.produit = produitWhere;

        let stocks;

        // Filtrer par alerte de stock si demandé
        if (alerteStock === true || alerteStock === 'true') {
          stocks = await models.prisma.$queryRaw`
            SELECT s.*, p.reference, p.nom, p.seuil_stock_minimum, p.prix_unitaire, p.prix_achat
            FROM stock s
            INNER JOIN produits p ON s.produit_id = p.id
            WHERE s.quantite_disponible <= p.seuil_stock_minimum
            AND p.est_actif = 1
            ORDER BY s.derniere_maj DESC
          `;
        } else {
          stocks = await models.prisma.stock.findMany({
            where,
            include: {
              produit: {
                select: {
                  reference: true,
                  nom: true,
                  seuilStockMinimum: true,
                  prixUnitaire: true,
                  prixAchat: true
                }
              }
            },
            orderBy: { derniereMaj: 'desc' }
          });
        }

        // Générer le CSV
        const csvHeaders = [
          'Référence',
          'Nom du produit',
          'Quantité disponible',
          'Quantité réservée',
          'Seuil minimum',
          'Prix unitaire',
          'Prix d\'achat',
          'Valeur stock (vente)',
          'Valeur stock (achat)',
          'Statut',
          'Dernière MAJ'
        ];

        const csvRows = stocks.map(stock => {
          const produit = alerteStock ? {
            reference: stock.reference,
            nom: stock.nom,
            seuilStockMinimum: stock.seuil_stock_minimum,
            prixUnitaire: stock.prix_unitaire,
            prixAchat: stock.prix_achat
          } : stock.produit;

          const quantiteDisponible = alerteStock ? stock.quantite_disponible : stock.quantiteDisponible;
          const quantiteReservee = alerteStock ? stock.quantite_reservee : stock.quantiteReservee;
          const seuilMinimum = produit.seuilStockMinimum || 0;
          const prixUnitaire = produit.prixUnitaire || 0;
          const prixAchat = produit.prixAchat || prixUnitaire * 0.8;

          const valeurVente = quantiteDisponible * prixUnitaire;
          const valeurAchat = quantiteDisponible * prixAchat;

          let statut = 'Normal';
          if (quantiteDisponible === 0) {
            statut = 'Rupture';
          } else if (quantiteDisponible <= seuilMinimum) {
            statut = 'Alerte';
          }

          return [
            `"${produit.reference || ''}"`,
            `"${produit.nom || ''}"`,
            quantiteDisponible,
            quantiteReservee,
            seuilMinimum,
            prixUnitaire.toFixed(2),
            prixAchat.toFixed(2),
            valeurVente.toFixed(2),
            valeurAchat.toFixed(2),
            `"${statut}"`,
            `"${(alerteStock ? stock.derniere_maj : stock.derniereMaj)?.toISOString() || ''}"`
          ].join(',');
        });

        const csvContent = [csvHeaders.join(','), ...csvRows].join('\n');

        // Définir les en-têtes pour le téléchargement
        const filename = `stocks_export_${new Date().toISOString().split('T')[0]}.csv`;
        res.setHeader('Content-Type', 'text/csv; charset=utf-8');
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
        res.setHeader('Content-Length', Buffer.byteLength(csvContent, 'utf8'));

        res.send('\uFEFF' + csvContent); // BOM pour Excel

      } catch (error) {
        console.error('Erreur export CSV stocks:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de l\'export CSV des stocks')
        );
      }
    }
  );

  /**
   * GET /inventory/movements/export/csv
   * Exporte les mouvements de stock au format CSV
   */
  router.get('/movements/export/csv',
    authenticateToken(models.authService),
    validate(stockSchemas.mouvements, 'query'),
    async (req, res) => {
      try {
        const { produitId, typeMouvement, dateDebut, dateFin } = req.query;

        // Construire les conditions de recherche
        const where = {};

        if (produitId) {
          where.produitId = parseInt(produitId);
        }

        if (typeMouvement) {
          where.typeMouvement = typeMouvement;
        }

        if (dateDebut || dateFin) {
          where.dateMouvement = {};
          if (dateDebut) {
            where.dateMouvement.gte = new Date(dateDebut);
          }
          if (dateFin) {
            where.dateMouvement.lte = new Date(dateFin);
          }
        }

        const mouvements = await models.prisma.mouvementStock.findMany({
          where,
          include: {
            produit: {
              select: {
                reference: true,
                nom: true
              }
            }
          },
          orderBy: { dateMouvement: 'desc' }
        });

        // Générer le CSV
        const csvHeaders = [
          'Date',
          'Référence produit',
          'Nom du produit',
          'Type de mouvement',
          'Changement quantité',
          'Type référence',
          'ID référence',
          'Notes'
        ];

        const csvRows = mouvements.map(mouvement => [
          `"${mouvement.dateMouvement.toISOString()}"`,
          `"${mouvement.produit?.reference || ''}"`,
          `"${mouvement.produit?.nom || ''}"`,
          `"${mouvement.typeMouvement}"`,
          mouvement.changementQuantite,
          `"${mouvement.typeReference || ''}"`,
          mouvement.referenceId || '',
          `"${mouvement.notes || ''}"`
        ].join(','));

        const csvContent = [csvHeaders.join(','), ...csvRows].join('\n');

        // Définir les en-têtes pour le téléchargement
        const filename = `mouvements_stock_export_${new Date().toISOString().split('T')[0]}.csv`;
        res.setHeader('Content-Type', 'text/csv; charset=utf-8');
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
        res.setHeader('Content-Length', Buffer.byteLength(csvContent, 'utf8'));

        res.send('\uFEFF' + csvContent); // BOM pour Excel

      } catch (error) {
        console.error('Erreur export CSV mouvements:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de l\'export CSV des mouvements')
        );
      }
    }
  );

  /**
   * GET /inventory/:id
   * Récupère le stock d'un produit spécifique
   */
  router.get('/:id',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const produitId = parseInt(req.params.id);

        const stock = await models.prisma.stock.findUnique({
          where: { produitId },
          include: {
            produit: true
          }
        });

        if (!stock) {
          return res.status(404).json(
            BaseResponseDTO.error('Stock non trouvé pour ce produit')
          );
        }

        const stockDTO = StockDTO.fromEntity(stock);

        res.json(BaseResponseDTO.success(stockDTO, 'Stock récupéré avec succès'));

      } catch (error) {
        console.error('Erreur récupération stock:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du stock')
        );
      }
    }
  );

  return router;
}

module.exports = { createInventoryRouter };