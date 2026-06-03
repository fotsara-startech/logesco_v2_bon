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
        // Extraire boutiqueId depuis le body, header ou query params
        const boutiqueId = req.body.boutiqueId || 
                          req.headers['x-boutique-id'] || 
                          req.query.boutiqueId;

        console.log('🏪 [Inventory] boutiqueId reçu:', {
          body: req.body.boutiqueId,
          header: req.headers['x-boutique-id'],
          query: req.query.boutiqueId,
          final: boutiqueId
        });

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

        if (boutiqueId) {
          // ── Mode multi-boutique : utiliser StockBoutique ──────────────────
          const boutiqueIdInt = parseInt(boutiqueId);
          
          // Vérifier si un stock existe déjà pour cette boutique
          const existingStock = await models.prisma.stockBoutique.findUnique({
            where: { 
              boutiqueId_produitId: { 
                boutiqueId: boutiqueIdInt, 
                produitId 
              } 
            }
          });

          if (existingStock) {
            return res.status(409).json(
              BaseResponseDTO.error('Un stock existe déjà pour ce produit dans cette boutique. Utilisez /adjust pour le modifier.')
            );
          }

          // Créer le stock boutique
          const stock = await models.prisma.stockBoutique.create({
            data: {
              boutiqueId: boutiqueIdInt,
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
              },
              boutique: {
                select: {
                  id: true,
                  nom: true
                }
              }
            }
          });

          console.log(`✅ Stock boutique créé: produit ${produitId} - boutique ${boutiqueIdInt} - quantité ${quantiteInitiale}`);

          // Créer un mouvement de stock pour tracer l'initialisation
          if (quantiteInitiale > 0) {
            await models.prisma.mouvementStock.create({
              data: {
                produitId,
                typeMouvement: 'initialisation',
                changementQuantite: quantiteInitiale,
                notes: `Initialisation du stock pour boutique ${stock.boutique.nom}`
              }
            });
          }

          // Adapter la réponse pour correspondre au format StockDTO
          const stockFormatted = {
            id: stock.id,
            produitId: stock.produitId,
            quantiteDisponible: stock.quantiteDisponible,
            quantiteReservee: stock.quantiteReservee,
            derniereMaj: stock.derniereMaj,
            produit: stock.produit,
            boutique: stock.boutique
          };

          const stockDTO = StockDTO.fromEntity(stockFormatted);
          return res.status(201).json(
            BaseResponseDTO.success(stockDTO, 'Stock boutique créé avec succès')
          );
        }

        // ── Mode classique : utiliser Stock global ──────────────────────────
        // Vérifier si un stock existe déjà
        const existingStock = await models.prisma.stock.findUnique({
          where: { produitId }
        });

        if (existingStock) {
          return res.status(409).json(
            BaseResponseDTO.error('Un stock existe déjà pour ce produit. Utilisez /adjust pour le modifier.')
          );
        }

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

        // Si boutiqueId fourni, lire depuis stock_boutiques
        const boutiqueId = req.query.boutiqueId ? parseInt(req.query.boutiqueId) : null;

        console.log('🏪 [Inventory GET] boutiqueId reçu:', {
          query: req.query.boutiqueId,
          parsed: boutiqueId,
          type: typeof req.query.boutiqueId
        });

        if (boutiqueId) {
          console.log('🏪 [Inventory GET] Mode multi-boutique activé pour boutique', boutiqueId);
          // ── Mode multi-boutique : tous les produits avec quantité boutique (0 si absent) ──
          const produitWhere = { estActif: true };
          if (produitId) produitWhere.id = parseInt(produitId);
          if (search && search.trim()) {
            const s = search.trim();
            produitWhere.OR = [
              { nom: { contains: s } }, 
              { reference: { contains: s } }, 
              { codeBarre: { contains: s } }
            ];
          }
          if (category && category.trim()) {
            produitWhere.categorie = { is: { nom: category.trim() } };
          }

          // Pour les alertes en mode boutique, charger tous les produits puis filtrer
          if (alerteStock === 'true' || alerteStock === true) {
            const allProduits = await models.prisma.produit.findMany({
              where: produitWhere,
              include: {
                stocksBoutiques: { 
                  where: { boutiqueId },
                  include: { boutique: { select: { id: true, nom: true, adresse: true } } }
                },
                categorie: true
              },
              orderBy: { nom: 'asc' }
            });

            const allStocks = allProduits.map(p => {
              const sb = p.stocksBoutiques[0];
              const qte = sb?.quantiteDisponible ?? 0;
              const seuil = p.seuilStockMinimum ?? 0;
              const estRupture = qte === 0;
              const estAlerte = seuil > 0 && qte <= seuil;
              return {
                id: sb?.id ?? `temp_${p.id}`,
                produitId: p.id,
                boutiqueId: boutiqueId,
                quantiteDisponible: qte,
                quantiteReservee: sb?.quantiteReservee ?? 0,
                derniereMaj: sb?.derniereMaj ?? p.dateModification,
                stockFaible: estAlerte && !estRupture, // alerte mais pas rupture
                produit: p,
                boutique: sb?.boutique ?? null
              };
            }).filter(s => s.quantiteDisponible === 0 || s.stockFaible); // rupture OU alerte

            const paginated = allStocks.slice(offset, offset + limitNum);
            return res.json(new PaginatedResponseDTO(
              StockDTO.fromEntities(paginated),
              { page: pageNum, limit: limitNum, total: allStocks.length },
              'Alertes stock boutique récupérées avec succès'
            ));
          }

          const [produits, totalCount] = await Promise.all([
            models.prisma.produit.findMany({
              where: produitWhere,
              include: {
                stocksBoutiques: { 
                  where: { boutiqueId },
                  include: {
                    boutique: { select: { id: true, nom: true, adresse: true } }
                  }
                },
                categorie: true
              },
              orderBy: { nom: 'asc' },
              skip: offset,
              take: limitNum
            }),
            models.prisma.produit.count({ where: produitWhere })
          ]);

          const stocks = produits.map(p => {
            const sb = p.stocksBoutiques[0];
            const qte = sb?.quantiteDisponible ?? 0;
            const seuil = p.seuilStockMinimum ?? 0;
            return {
              id: sb?.id ?? `temp_${p.id}`,
              produitId: p.id,
              boutiqueId: boutiqueId,
              quantiteDisponible: qte,
              quantiteReservee: sb?.quantiteReservee ?? 0,
              derniereMaj: sb?.derniereMaj ?? p.dateModification,
              stockFaible: seuil > 0 && qte <= seuil,
              produit: p,
              boutique: sb?.boutique ?? null
            };
          });

          const stocksDTO = StockDTO.fromEntities(stocks);
          return res.json(new PaginatedResponseDTO(
            stocksDTO,
            { page: pageNum, limit: limitNum, total: totalCount },
            'Stocks boutique récupérés avec succès'
          ));
        }

        console.log('🏪 [Inventory GET] Mode classique activé (pas de boutiqueId)');

        // ── Mode classique : lire stock global ──────────────────────────────
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
          // Récupérer TOUS les produits actifs pour filtrer les alertes
          const allProduits = await models.prisma.produit.findMany({
            where: produitWhere,
            include: {
              stock: true,
              categorie: true
            },
            orderBy: { nom: 'asc' }
          });

          // Filtrer pour ne garder que les produits en alerte OU en rupture
          // Alerte : seuil > 0 ET qté <= seuil
          // Rupture : qté = 0 (peu importe le seuil)
          const produitsEnAlerte = allProduits.filter(p => {
            const qte = p.stock?.quantiteDisponible ?? 0;
            const seuil = p.seuilStockMinimum ?? 0;
            const estRupture = qte === 0;
            const estAlerte = seuil > 0 && qte <= seuil;
            return estRupture || estAlerte;
          });

          // Appliquer la pagination APRÈS le filtrage
          const paginatedAlerts = produitsEnAlerte.slice(offset, offset + limitNum);

          // Mapper vers le format attendu
          const alertStocks = paginatedAlerts.map(p => {
            const qte = p.stock?.quantiteDisponible ?? 0;
            const seuil = p.seuilStockMinimum ?? 0;
            return {
              id: p.stock?.id || `alert_${p.id}`,
              produitId: p.id,
              quantiteDisponible: qte,
              quantiteReservee: p.stock?.quantiteReservee ?? 0,
              derniereMaj: p.stock?.derniereMaj || new Date(),
              stockFaible: seuil > 0 && qte <= seuil && qte > 0, // alerte mais pas rupture
              produit: p
            };
          });

          const totalAlerts = produitsEnAlerte.length;

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
        const stocks = produits.map(p => {
          const qte = p.stock?.quantiteDisponible ?? 0;
          const seuil = p.seuilStockMinimum ?? 0;
          return {
            id: p.stock?.id || `temp_${p.id}`,
            produitId: p.id,
            quantiteDisponible: qte,
            quantiteReservee: p.stock?.quantiteReservee ?? 0,
            derniereMaj: p.stock?.derniereMaj || new Date(),
            stockFaible: seuil > 0 && qte <= seuil,
            produit: p
          };
        });

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

        // Requête pour les stocks en alerte (quantité <= seuil minimum, seuil > 0)
        const alertes = await models.prisma.$queryRaw`
          SELECT s.id, s.produit_id, s.quantite_disponible, s.quantite_reservee, s.derniere_maj,
                 p.reference, p.nom, p.seuil_stock_minimum, p.est_actif
          FROM stock s
          INNER JOIN produits p ON s.produit_id = p.id
          WHERE s.quantite_disponible <= p.seuil_stock_minimum
          AND p.seuil_stock_minimum > 0
          AND p.est_actif = 1
          ORDER BY (s.quantite_disponible - p.seuil_stock_minimum) ASC
          LIMIT ${parseInt(limit)} OFFSET ${(parseInt(page) - 1) * parseInt(limit)}
        `;

        const totalAlertes = await models.prisma.$queryRaw`
          SELECT COUNT(*) as count
          FROM stock s
          INNER JOIN produits p ON s.produit_id = p.id
          WHERE s.quantite_disponible <= p.seuil_stock_minimum
          AND p.seuil_stock_minimum > 0
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

        // Extraire boutiqueId depuis query ou header
        const boutiqueId = req.query.boutiqueId
          ? parseInt(req.query.boutiqueId)
          : req.headers['x-boutique-id']
            ? parseInt(req.headers['x-boutique-id'])
            : null;

        const options = buildPrismaQuery({ page, limit });

        // Construire les conditions de recherche
        const where = {};

        // Filtrer par boutique si fourni
        if (boutiqueId) {
          where.boutiqueId = boutiqueId;
        }

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
              stock: true,
              stocksBoutiques: boutiqueId ? {
                where: { boutiqueId }
              } : true
            }
          },
          boutique: true
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
        // Extraire boutiqueId depuis body, header ou query
        const boutiqueId = req.body.boutiqueId ||
          req.headers['x-boutique-id'] ||
          req.query.boutiqueId;
        const boutiqueIdInt = boutiqueId ? parseInt(boutiqueId) : null;

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
          // 1. Récupérer le stock AVANT le mouvement
          let stockInitial = 0;
          if (boutiqueIdInt) {
            const stockBoutique = await tx.stockBoutique.findUnique({
              where: { boutiqueId_produitId: { boutiqueId: boutiqueIdInt, produitId } }
            });
            stockInitial = stockBoutique?.quantiteDisponible || 0;
          } else {
            stockInitial = produit.stock?.quantiteDisponible || 0;
          }

          // 2. Calculer le stock APRÈS le mouvement
          const stockFinal = stockInitial + changementQuantite;

          // 3. Créer le mouvement avec les snapshots
          const mouvement = await tx.mouvementStock.create({
            data: {
              produitId,
              boutiqueId: boutiqueIdInt,
              typeMouvement,
              changementQuantite,
              stockInitial,
              stockFinal,
              notes: notes || `Mouvement ${typeMouvement}`,
              referenceId,
              typeReference
            },
            include: { produit: true }
          });

          // Mettre à jour le stock si le type de mouvement l'affecte
          if (typesAffectantStock.includes(typeMouvement)) {
            if (boutiqueIdInt) {
              // ── Mode multi-boutique : mettre à jour StockBoutique ──────────
              const stockBoutique = await tx.stockBoutique.findUnique({
                where: { boutiqueId_produitId: { boutiqueId: boutiqueIdInt, produitId } }
              });

              if (!stockBoutique) {
                if (changementQuantite > 0) {
                  await tx.stockBoutique.create({
                    data: { boutiqueId: boutiqueIdInt, produitId, quantiteDisponible: changementQuantite, quantiteReservee: 0 }
                  });
                } else {
                  throw new Error('Impossible de créer un stock avec une quantité négative');
                }
              } else {
                const nouvelleQuantite = stockBoutique.quantiteDisponible + changementQuantite;
                if (nouvelleQuantite < 0) {
                  throw new Error(`Stock insuffisant. Disponible: ${stockBoutique.quantiteDisponible}, demandé: ${changementQuantite}`);
                }
                await tx.stockBoutique.update({
                  where: { boutiqueId_produitId: { boutiqueId: boutiqueIdInt, produitId } },
                  data: { quantiteDisponible: nouvelleQuantite }
                });
              }
            } else {
              // ── Mode classique : mettre à jour Stock global ────────────────
              if (!produit.stock) {
                if (changementQuantite > 0) {
                  await tx.stock.create({
                    data: { produitId, quantiteDisponible: changementQuantite, quantiteReservee: 0 }
                  });
                } else {
                  throw new Error('Impossible de créer un stock avec une quantité négative');
                }
              } else {
                const nouvelleQuantite = produit.stock.quantiteDisponible + changementQuantite;
                if (nouvelleQuantite < 0) {
                  throw new Error(`Stock insuffisant. Disponible: ${produit.stock.quantiteDisponible}, demandé: ${changementQuantite}`);
                }
                await tx.stock.update({
                  where: { produitId },
                  data: { quantiteDisponible: nouvelleQuantite }
                });
              }
            }
          }

          return mouvement;
        });

        // Synchroniser manuellement vers Neon (les extensions Prisma ne fonctionnent pas dans les transactions)
        if (process.env.CLOUD_DB_URL) {
          setImmediate(async () => {
            try {
              console.log('🔧 [Sync Inventory] Synchronisation mouvement de stock manuel...');
              const syncService = require('../services/sync-service');
              
              // Récupérer le mouvement créé
              const mouvement = await models.prisma.mouvementStock.findFirst({
                where: { produitId, typeMouvement, changementQuantite },
                orderBy: { id: 'desc' }
              });
              
              if (mouvement) {
                await syncService.enqueue('mouvements_stock', 'INSERT', {
                  id: mouvement.id,
                  produit_id: mouvement.produitId,
                  boutique_id: mouvement.boutiqueId,
                  type_mouvement: mouvement.typeMouvement,
                  changement_quantite: mouvement.changementQuantite,
                  reference_id: mouvement.referenceId,
                  type_reference: mouvement.typeReference,
                  date_mouvement: mouvement.dateMouvement,
                  notes: mouvement.notes
                });
                console.log(`✅ [Sync Inventory] mouvements_stock synchronisé: ${mouvement.id}`);
              }
              
              // Synchroniser le stock mis à jour
              if (typesAffectantStock.includes(typeMouvement)) {
                if (boutiqueIdInt) {
                  const stockBoutique = await models.prisma.stockBoutique.findUnique({
                    where: { boutiqueId_produitId: { boutiqueId: boutiqueIdInt, produitId } }
                  });
                  
                  if (stockBoutique) {
                    await syncService.enqueue('stock_boutiques', 'UPDATE', {
                      id: stockBoutique.id,
                      boutique_id: stockBoutique.boutiqueId,
                      produit_id: stockBoutique.produitId,
                      quantite_disponible: stockBoutique.quantiteDisponible,
                      quantite_reservee: stockBoutique.quantiteReservee,
                      derniere_maj: stockBoutique.derniereMaj,
                      date_modification: stockBoutique.dateModification
                    });
                    console.log(`✅ [Sync Inventory] stock_boutiques synchronisé: ${stockBoutique.id}`);
                  }
                } else {
                  const stock = await models.prisma.stock.findUnique({
                    where: { produitId }
                  });
                  
                  if (stock) {
                    await syncService.enqueue('stock', 'UPDATE', {
                      id: stock.id,
                      produit_id: stock.produitId,
                      quantite_disponible: stock.quantiteDisponible,
                      quantite_reservee: stock.quantiteReservee,
                      derniere_maj: stock.derniereMaj,
                      date_modification: stock.dateModification
                    });
                    console.log(`✅ [Sync Inventory] stock synchronisé: ${stock.id}`);
                  }
                }
              }
              
              console.log('✅ [Sync Inventory] Synchronisation terminée');
            } catch (error) {
              console.error('❌ Erreur sync inventory:', error.message);
            }
          });
        }

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
        const boutiqueId = req.query.boutiqueId ? parseInt(req.query.boutiqueId) : null;

        if (boutiqueId) {
          // ── Mode multi-boutique : stats depuis stock_boutiques ──────────────
          const [
            totalProduits,
            stocksBoutique,
            valeurBoutique
          ] = await Promise.all([
            models.prisma.produit.count({ where: { estActif: true } }),
            models.prisma.stockBoutique.findMany({
              where: { boutiqueId },
              include: {
                produit: {
                  select: { prixUnitaire: true, prixAchat: true, seuilStockMinimum: true, estActif: true }
                }
              }
            }),
            models.prisma.$queryRaw`
              SELECT 
                SUM(sb.quantite_disponible * COALESCE(p.cump, p.prix_achat, p.prix_unitaire * 0.8)) as valeurAchat,
                SUM(sb.quantite_disponible * p.prix_unitaire) as valeurVente
              FROM stock_boutiques sb
              INNER JOIN produits p ON sb.produit_id = p.id
              WHERE sb.boutique_id = ${boutiqueId} AND p.est_actif = 1
            `
          ]);

          const produitsEnStock = stocksBoutique.filter(sb => sb.quantiteDisponible > 0).length;
          // Alerte : seuil > 0 ET qté <= seuil ET qté > 0 (pas rupture)
          const produitsEnAlerte = stocksBoutique.filter(sb => {
            const seuil = sb.produit?.seuilStockMinimum ?? 0;
            return seuil > 0 && sb.quantiteDisponible > 0 && sb.quantiteDisponible <= seuil;
          }).length;
          // Rupture : qté = 0 (produits avec stock boutique à 0 + produits sans entrée stock boutique)
          const produitsAvecStockBoutique = stocksBoutique.length;
          const produitsEnRuptureAvecStock = stocksBoutique.filter(sb => sb.quantiteDisponible === 0).length;
          const produitsSansStockBoutique = totalProduits - produitsAvecStockBoutique;
          const produitsEnRupture = produitsEnRuptureAvecStock + produitsSansStockBoutique;

          const summary = {
            totalProduits,
            produitsEnStock,
            produitsEnAlerte,
            produitsEnRupture,
            valeurTotaleStock: parseFloat(valeurBoutique[0]?.valeurVente || 0),
            valeurStockAchat: parseFloat(valeurBoutique[0]?.valeurAchat || 0),
            valeurStockVente: parseFloat(valeurBoutique[0]?.valeurVente || 0),
            pourcentageEnStock: totalProduits > 0 ? Math.round((produitsEnStock / totalProduits) * 100) : 0,
            pourcentageEnAlerte: totalProduits > 0 ? Math.round((produitsEnAlerte / totalProduits) * 100) : 0,
            pourcentageEnRupture: totalProduits > 0 ? Math.round((produitsEnRupture / totalProduits) * 100) : 0
          };

          return res.json(BaseResponseDTO.success(summary, 'Résumé du stock boutique récupéré avec succès'));
        }

        // ── Mode classique : stats globales ────────────────────────────────
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

          // Produits en alerte (stock <= seuil, seuil > 0)
          models.prisma.$queryRaw`
            SELECT COUNT(*) as count
            FROM stock s
            INNER JOIN produits p ON s.produit_id = p.id
            WHERE s.quantite_disponible <= p.seuil_stock_minimum
            AND p.seuil_stock_minimum > 0
            AND p.est_actif = 1
          `,

          // Produits en rupture (stock = 0 OU pas d'entrée stock)
          models.prisma.$queryRaw`
            SELECT COUNT(*) as count
            FROM produits p
            LEFT JOIN stock s ON s.produit_id = p.id
            WHERE (s.quantite_disponible = 0 OR s.id IS NULL)
            AND p.est_actif = 1
            AND p.est_service = 0
          `,

          // Valeur totale du stock (prix d'achat et de vente)
          models.prisma.$queryRaw`
            SELECT 
              SUM(s.quantite_disponible * COALESCE(p.cump, p.prix_achat, p.prix_unitaire * 0.8)) as valeurAchat,
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
          produitsEnRupture: parseInt(produitsEnRupture[0].count),
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
        const boutiqueId = req.query.boutiqueId
          ? parseInt(req.query.boutiqueId)
          : req.headers['x-boutique-id']
          ? parseInt(req.headers['x-boutique-id'])
          : null;

        let stocks;

        if (boutiqueId) {
          // ── Mode multi-boutique : quantités depuis stock_boutiques ──────────
          const whereProduct = { estActif: true };
          if (produitId) whereProduct.id = parseInt(produitId);
          if (search && search.trim()) {
            whereProduct.OR = [
              { nom: { contains: search.trim() } },
              { reference: { contains: search.trim() } },
              { codeBarre: { contains: search.trim() } }
            ];
          }
          if (category && category.trim()) {
            whereProduct.categorie = { is: { nom: category.trim() } };
          }

          const stocksBoutique = await models.prisma.stockBoutique.findMany({
            where: {
              boutiqueId,
              produit: whereProduct,
              ...(alerteStock === 'true' ? {} : {})
            },
            include: {
              produit: {
                select: {
                  reference: true,
                  nom: true,
                  seuilStockMinimum: true,
                  prixUnitaire: true,
                  prixAchat: true,
                  cump: true
                }
              }
            },
            orderBy: { derniereMaj: 'desc' }
          });

          stocks = stocksBoutique
            .filter(sb => alerteStock !== 'true' || sb.quantiteDisponible <= (sb.produit?.seuilStockMinimum || 0))
            .map(sb => ({
              quantiteDisponible: sb.quantiteDisponible,
              quantiteReservee: sb.quantiteReservee,
              derniereMaj: sb.derniereMaj,
              produit: sb.produit
            }));

        } else {
          // ── Mode classique : quantités depuis stock global ─────────────────
          const where = {};
          const produitWhere = { estActif: true };

          if (produitId) where.produitId = parseInt(produitId);
          if (search && search.trim()) {
            produitWhere.OR = [
              { nom: { contains: search.trim() } },
              { reference: { contains: search.trim() } },
              { codeBarre: { contains: search.trim() } }
            ];
          }
          if (category && category.trim()) {
            produitWhere.categorie = { is: { nom: category.trim() } };
          }
          where.produit = produitWhere;

          if (alerteStock === 'true') {
            const raw = await models.prisma.$queryRaw`
              SELECT s.quantite_disponible, s.quantite_reservee, s.derniere_maj,
                     p.reference, p.nom, p.seuil_stock_minimum, p.prix_unitaire, p.prix_achat, p.cump
              FROM stock s
              INNER JOIN produits p ON s.produit_id = p.id
              WHERE s.quantite_disponible <= p.seuil_stock_minimum
              AND p.seuil_stock_minimum > 0
              AND p.est_actif = 1
              ORDER BY s.derniere_maj DESC
            `;
            stocks = raw.map(r => ({
              quantiteDisponible: r.quantite_disponible,
              quantiteReservee: r.quantite_reservee,
              derniereMaj: r.derniere_maj,
              produit: {
                reference: r.reference,
                nom: r.nom,
                seuilStockMinimum: r.seuil_stock_minimum,
                prixUnitaire: r.prix_unitaire,
                prixAchat: r.prix_achat,
                cump: r.cump
              }
            }));
          } else {
            const raw = await models.prisma.stock.findMany({
              where,
              include: {
                produit: {
                  select: {
                    reference: true,
                    nom: true,
                    seuilStockMinimum: true,
                    prixUnitaire: true,
                    prixAchat: true,
                    cump: true
                  }
                }
              },
              orderBy: { derniereMaj: 'desc' }
            });
            stocks = raw.map(s => ({
              quantiteDisponible: s.quantiteDisponible,
              quantiteReservee: s.quantiteReservee,
              derniereMaj: s.derniereMaj,
              produit: s.produit
            }));
          }
        }

        // Générer le CSV
        const csvHeaders = [
          'Référence',
          'Nom du produit',
          'Quantité disponible',
          'Quantité réservée',
          'Seuil minimum',
          'Prix unitaire',
          'CUMP',
          'Valeur stock (vente)',
          'Valeur stock (achat/CUMP)',
          'Statut',
          'Dernière MAJ'
        ];

        const csvRows = stocks.map(stock => {
          const produit = stock.produit;
          const qteDisponible = stock.quantiteDisponible || 0;
          const qteReservee = stock.quantiteReservee || 0;
          const seuilMinimum = produit.seuilStockMinimum || 0;
          const prixUnitaire = produit.prixUnitaire || 0;
          // Utiliser CUMP en priorité, sinon prixAchat, sinon estimation 80%
          const cump = produit.cump || produit.prixAchat || prixUnitaire * 0.8;

          const valeurVente = qteDisponible * prixUnitaire;
          const valeurAchat = qteDisponible * cump;

          let statut = 'Normal';
          if (qteDisponible === 0) statut = 'Rupture';
          else if (qteDisponible <= seuilMinimum) statut = 'Alerte';

          return [
            `"${produit.reference || ''}"`,
            `"${produit.nom || ''}"`,
            qteDisponible,
            qteReservee,
            seuilMinimum,
            prixUnitaire.toFixed(2),
            cump.toFixed(2),
            valeurVente.toFixed(2),
            valeurAchat.toFixed(2),
            `"${statut}"`,
            `"${stock.derniereMaj?.toISOString() || ''}"`
          ].join(',');
        });

        const csvContent = [csvHeaders.join(','), ...csvRows].join('\n');

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
        const boutiqueId = req.query.boutiqueId || req.headers['x-boutique-id'];

        if (boutiqueId) {
          // ── Mode multi-boutique : retourner le stock boutique ──────────────
          const boutiqueIdInt = parseInt(boutiqueId);
          const stockBoutique = await models.prisma.stockBoutique.findUnique({
            where: { boutiqueId_produitId: { boutiqueId: boutiqueIdInt, produitId } },
            include: {
              produit: true,
              boutique: { select: { id: true, nom: true } }
            }
          });

          // Si pas de stock boutique, retourner quantité 0
          const stockFormatted = stockBoutique ? {
            id: stockBoutique.id,
            produitId: stockBoutique.produitId,
            boutiqueId: stockBoutique.boutiqueId,
            quantiteDisponible: stockBoutique.quantiteDisponible,
            quantiteReservee: stockBoutique.quantiteReservee,
            derniereMaj: stockBoutique.derniereMaj,
            produit: stockBoutique.produit,
            boutique: stockBoutique.boutique
          } : {
            id: null,
            produitId,
            boutiqueId: boutiqueIdInt,
            quantiteDisponible: 0,
            quantiteReservee: 0,
            derniereMaj: new Date(),
            produit: null
          };

          return res.json(BaseResponseDTO.success(StockDTO.fromEntity(stockFormatted), 'Stock boutique récupéré avec succès'));
        }

        // ── Mode classique : stock global ──────────────────────────────────
        const stock = await models.prisma.stock.findUnique({
          where: { produitId },
          include: { produit: true }
        });

        if (!stock) {
          return res.status(404).json(
            BaseResponseDTO.error('Stock non trouvé pour ce produit')
          );
        }

        res.json(BaseResponseDTO.success(StockDTO.fromEntity(stock), 'Stock récupéré avec succès'));

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