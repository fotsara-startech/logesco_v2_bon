/**
 * Routes pour la gestion des approvisionnements
 * Endpoints CRUD pour les commandes d'approvisionnement avec gestion des réceptions
 */

const express = require('express');
const { validate } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { commandeApprovisionnementSchemas, idParamSchema } = require('../validation/schemas');
const logger = require('../utils/logger');
const transformers = require('../utils/transformers');
const { enregistrerPrixAchatEtRecalculerCump } = require('../services/cump-service');

/**
 * Crée le routeur pour les approvisionnements
 * @param {Object} services - Services injectés (models, authService, prisma)
 * @returns {Router}
 */
function createProcurementRouter(services) {
  const router = express.Router();
  const { prisma } = services;

  // TODO: Add authentication middleware when auth service is properly configured

  /**
   * GET /procurement - Liste des commandes d'approvisionnement
   */
  router.get('/', 
    validate(commandeApprovisionnementSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { 
          fournisseurId, 
          statut, 
          dateDebut, 
          dateFin,
          search,
          page = 1, 
          limit = 20 
        } = req.query;

        // Construction des filtres
        const where = {};
        if (fournisseurId) where.fournisseurId = parseInt(fournisseurId);
        if (statut) where.statut = statut;
        if (dateDebut || dateFin) {
          where.dateCommande = {};
          if (dateDebut) where.dateCommande.gte = new Date(dateDebut);
          if (dateFin) where.dateCommande.lte = new Date(dateFin);
        }

        // Recherche par numéro de commande ou nom de fournisseur
        if (search && search.trim()) {
          const searchTerm = search.trim().toLowerCase();
          where.OR = [
            {
              numeroCommande: {
                contains: searchTerm
              }
            },
            {
              fournisseur: {
                nom: {
                  contains: searchTerm
                }
              }
            }
          ];
        }

        // Filtrer par boutique si fourni
        const boutiqueId = req.query.boutiqueId || req.headers['x-boutique-id'];
        if (boutiqueId) where.boutiqueId = parseInt(boutiqueId);

        // Pagination
        const skip = (page - 1) * limit;
        const take = parseInt(limit);

        // Requête avec relations
        const [commandes, total] = await Promise.all([
          prisma.commandeApprovisionnement.findMany({
            where,
            include: {
              fournisseur: true,
              details: {
                include: {
                  produit: true
                }
              }
            },
            orderBy: { dateCommande: 'desc' },
            skip,
            take
          }),
          prisma.commandeApprovisionnement.count({ where })
        ]);

        res.json({
          success: true,
          data: {
            commandes: commandes.map(transformers.commandeApprovisionnement),
            pagination: {
              page: parseInt(page),
              limit: take,
              total,
              pages: Math.ceil(total / take)
            }
          }
        });

      } catch (error) {
        logger.error('❌ [Procurement GET] Erreur liste commandes', { error: error.message, stack: error.stack });
        console.error('Erreur lors de la récupération des commandes:', error);
        res.status(500).json({
          success: false,
          error: {
            message: 'Erreur lors de la récupération des commandes',
            code: 'FETCH_ORDERS_ERROR'
          }
        });
      }
    }
  );

  /**
   * POST /procurement - Créer une nouvelle commande d'approvisionnement
   */
  router.post('/',
    validate(commandeApprovisionnementSchemas.create, 'body'),
    async (req, res) => {
      try {
        const { fournisseurId, dateLivraisonPrevue, modePaiement, notes, details } = req.body;

        // Extraire boutiqueId
        const boutiqueId = req.body.boutiqueId ||
          req.headers['x-boutique-id'] ||
          req.query.boutiqueId;
        const boutiqueIdInt = boutiqueId ? parseInt(boutiqueId) : null;

        // Vérifier que le fournisseur existe
        const fournisseur = await prisma.fournisseur.findUnique({
          where: { id: fournisseurId }
        });

        if (!fournisseur) {
          return res.status(404).json({
            success: false,
            error: {
              message: 'Fournisseur non trouvé',
              code: 'SUPPLIER_NOT_FOUND'
            }
          });
        }

        // Vérifier que tous les produits existent
        const produitIds = details.map(d => d.produitId);
        const produits = await prisma.produit.findMany({
          where: { id: { in: produitIds } }
        });

        if (produits.length !== produitIds.length) {
          return res.status(400).json({
            success: false,
            error: {
              message: 'Un ou plusieurs produits n\'existent pas',
              code: 'PRODUCTS_NOT_FOUND'
            }
          });
        }

        // Générer le numéro de commande unique
        const numeroCommande = await generateNumeroCommande(prisma);

        // Calculer le montant total
        const montantTotal = details.reduce((total, detail) => {
          return total + (detail.quantiteCommandee * detail.coutUnitaire);
        }, 0);

        // Créer la commande avec ses détails
        const commande = await prisma.commandeApprovisionnement.create({
          data: {
            numeroCommande,
            fournisseurId,
            boutiqueId: boutiqueIdInt,
            dateLivraisonPrevue: dateLivraisonPrevue ? new Date(dateLivraisonPrevue) : null,
            modePaiement: modePaiement || 'credit',
            notes,
            montantTotal,
            details: {
              create: details.map(detail => ({
                produitId: detail.produitId,
                quantiteCommandee: detail.quantiteCommandee,
                coutUnitaire: detail.coutUnitaire
              }))
            }
          },
          include: {
            fournisseur: true,
            details: {
              include: {
                produit: true
              }
            }
          }
        });

        res.status(201).json({
          success: true,
          data: transformers.commandeApprovisionnement(commande),
          message: 'Commande d\'approvisionnement créée avec succès'
        });

      } catch (error) {
        console.error('Erreur lors de la création de la commande:', error);
        res.status(500).json({
          success: false,
          error: {
            message: 'Erreur lors de la création de la commande',
            code: 'CREATE_ORDER_ERROR'
          }
        });
      }
    }
  );

  /**
   * GET /procurement/suggestions - Suggestions d'approvisionnement basées sur les ventes et stocks
   */
  router.get('/suggestions', async (req, res) => {
    try {
      const { fournisseurId, periodeAnalyse = 30, seuilRotation = 0.5 } = req.query;

      console.log('📊 Génération des suggestions avec paramètres:', { fournisseurId, periodeAnalyse, seuilRotation });

      // Version simplifiée : récupérer les produits avec stock faible
      // Note: Le modèle Produit n'a pas de fournisseurId, on récupère tous les produits actifs
      const produits = await prisma.produit.findMany({
        where: {
          estActif: true
        },
        include: {
          stock: true
        },
        take: 50 // Limiter pour éviter les problèmes de performance
      });

      console.log(`📦 ${produits.length} produits trouvés pour analyse`);

      // Analyser chaque produit pour générer des suggestions
      const suggestions = [];
      
      for (let i = 0; i < produits.length; i++) {
        const produit = produits[i];
        const stock = produit.stock;
        const stockActuel = stock?.quantiteDisponible || 0;
        const seuilMinimum = produit.seuilStockMinimum || 0;

        // Critères pour suggérer un réapprovisionnement
        let needsRestock = false;
        let priorite = 'faible';
        let raison = '';
        let quantiteSuggeree = 0;

        if (stockActuel === 0) {
          needsRestock = true;
          priorite = 'haute';
          raison = 'Produit en rupture de stock';
          quantiteSuggeree = Math.max(seuilMinimum * 2, 10);
        } else if (stockActuel <= seuilMinimum) {
          needsRestock = true;
          priorite = 'haute';
          raison = 'Stock sous le seuil minimum';
          quantiteSuggeree = Math.max(seuilMinimum * 1.5, 5);
        } else if (stockActuel <= seuilMinimum * 1.5) {
          needsRestock = true;
          priorite = 'moyenne';
          raison = 'Stock faible - réapprovisionnement préventif';
          quantiteSuggeree = seuilMinimum;
        }

        if (needsRestock) {
          const coutUnitaire = produit.prixAchat || produit.prixUnitaire * 0.8;
          const montantTotal = quantiteSuggeree * coutUnitaire;

          suggestions.push({
            id: i + 1,
            produit: {
              id: produit.id,
              nom: produit.nom,
              reference: produit.reference,
              prixUnitaire: produit.prixUnitaire,
              prixAchat: produit.prixAchat,
              seuilStockMinimum: seuilMinimum
            },
            stockActuel,
            seuilMinimum,
            moyenneVentesJournalieres: 1.0, // Valeur par défaut
            quantiteSuggeree,
            coutUnitaireEstime: coutUnitaire,
            montantTotal,
            priorite,
            raison,
            joursStockRestant: stockActuel === 0 ? 0 : Math.ceil(stockActuel / 1.0),
            tauxRotation: 0.5 // Valeur par défaut
          });
        }
      }

      console.log(`💡 ${suggestions.length} suggestions générées`);

      // Trier les suggestions par priorité
      suggestions.sort((a, b) => {
        const priorityOrder = { 'haute': 0, 'moyenne': 1, 'faible': 2 };
        const aPriority = priorityOrder[a.priorite] || 3;
        const bPriority = priorityOrder[b.priorite] || 3;
        
        if (aPriority !== bPriority) {
          return aPriority - bPriority;
        }
        
        return a.joursStockRestant - b.joursStockRestant;
      });

      res.json({
        success: true,
        data: {
          suggestions: suggestions,
          statistiques: {
            total: suggestions.length,
            urgentes: suggestions.filter(s => s.priorite === 'haute').length,
            moyennes: suggestions.filter(s => s.priorite === 'moyenne').length,
            faibles: suggestions.filter(s => s.priorite === 'faible').length,
            montantTotal: suggestions.reduce((sum, s) => sum + s.montantTotal, 0)
          }
        }
      });

    } catch (error) {
      console.error('Erreur lors de la génération des suggestions:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la génération des suggestions',
          code: 'GENERATE_SUGGESTIONS_ERROR'
        }
      });
    }
  });

  /**
   * GET /procurement/alerts - Alertes d'approvisionnement (produits en rupture ou stock faible)
   */
  router.get('/alerts', async (req, res) => {
    try {
      // Version simplifiée pour éviter les problèmes avec prisma.raw
      const produits = await prisma.produit.findMany({
        where: {
          estActif: true
        },
        include: {
          stock: true
        }
      });

      // Filtrer les produits en alerte côté JavaScript
      const produitsEnAlerte = produits.filter(produit => {
        if (!produit.stock) return true; // Pas de stock = rupture
        return produit.stock.quantiteDisponible <= produit.seuilStockMinimum;
      });

      const alertes = produitsEnAlerte.map(produit => ({
        produit: {
          id: produit.id,
          nom: produit.nom,
          reference: produit.reference,
          seuilStockMinimum: produit.seuilStockMinimum
        },
        stock: produit.stock ? {
          quantiteDisponible: produit.stock.quantiteDisponible,
          quantiteReservee: produit.stock.quantiteReservee,
          seuilMinimum: produit.seuilStockMinimum
        } : null,
        typeAlerte: !produit.stock || produit.stock.quantiteDisponible === 0 ? 'rupture' : 'stock_faible',
        priorite: !produit.stock || produit.stock.quantiteDisponible === 0 ? 'haute' : 'moyenne'
      }));

      res.json({
        success: true,
        data: {
          alertes,
          statistiques: {
            total: alertes.length,
            ruptures: alertes.filter(a => a.typeAlerte === 'rupture').length,
            stocksFaibles: alertes.filter(a => a.typeAlerte === 'stock_faible').length
          }
        }
      });

    } catch (error) {
      console.error('Erreur lors de la récupération des alertes:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération des alertes',
          code: 'FETCH_ALERTS_ERROR'
        }
      });
    }
  });

  /**
   * GET /procurement/suppliers - Liste des fournisseurs disponibles
   */
  router.get('/suppliers', async (req, res) => {
    try {
      const fournisseurs = await prisma.fournisseur.findMany({
        orderBy: { nom: 'asc' }
      });

      res.json({
        success: true,
        data: { fournisseurs }
      });

    } catch (error) {
      console.error('Erreur lors de la récupération des fournisseurs:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération des fournisseurs',
          code: 'FETCH_SUPPLIERS_ERROR'
        }
      });
    }
  });

  /**
   * GET /procurement/:id - Détails d'une commande d'approvisionnement
   */
  router.get('/:id',
    validate(idParamSchema, 'params'),
    async (req, res) => {
      try {
        const { id } = req.params;

        const commande = await prisma.commandeApprovisionnement.findUnique({
          where: { id: parseInt(id) },
          include: {
            fournisseur: true,
            details: {
              include: {
                produit: true
              }
            }
          }
        });

        if (!commande) {
          return res.status(404).json({
            success: false,
            error: {
              message: 'Commande non trouvée',
              code: 'ORDER_NOT_FOUND'
            }
          });
        }

        res.json({
          success: true,
          data: transformers.commandeApprovisionnement(commande)
        });

      } catch (error) {
        console.error('Erreur lors de la récupération de la commande:', error);
        res.status(500).json({
          success: false,
          error: {
            message: 'Erreur lors de la récupération de la commande',
            code: 'FETCH_ORDER_ERROR'
          }
        });
      }
    }
  );

  /**
   * PUT /procurement/:id - Mettre à jour une commande d'approvisionnement
   */
  router.put('/:id',
    validate(idParamSchema, 'params'),
    validate(commandeApprovisionnementSchemas.update, 'body'),
    async (req, res) => {
      try {
        const { id } = req.params;
        const updates = req.body;

        // Vérifier que la commande existe
        const commandeExistante = await prisma.commandeApprovisionnement.findUnique({
          where: { id: parseInt(id) }
        });

        if (!commandeExistante) {
          return res.status(404).json({
            success: false,
            error: {
              message: 'Commande non trouvée',
              code: 'ORDER_NOT_FOUND'
            }
          });
        }

        // Empêcher la modification des commandes terminées
        if (commandeExistante.statut === 'terminee') {
          return res.status(400).json({
            success: false,
            error: {
              message: 'Impossible de modifier une commande terminée',
              code: 'ORDER_COMPLETED'
            }
          });
        }

        // Préparer les données de mise à jour
        const updateData = {};
        if (updates.dateLivraisonPrevue !== undefined) {
          updateData.dateLivraisonPrevue = updates.dateLivraisonPrevue ? new Date(updates.dateLivraisonPrevue) : null;
        }
        if (updates.modePaiement) updateData.modePaiement = updates.modePaiement;
        if (updates.notes !== undefined) updateData.notes = updates.notes;
        if (updates.statut) updateData.statut = updates.statut;

        const commande = await prisma.commandeApprovisionnement.update({
          where: { id: parseInt(id) },
          data: updateData,
          include: {
            fournisseur: true,
            details: {
              include: {
                produit: true
              }
            }
          }
        });

        res.json({
          success: true,
          data: transformers.commandeApprovisionnement(commande),
          message: 'Commande mise à jour avec succès'
        });

      } catch (error) {
        console.error('Erreur lors de la mise à jour de la commande:', error);
        res.status(500).json({
          success: false,
          error: {
            message: 'Erreur lors de la mise à jour de la commande',
            code: 'UPDATE_ORDER_ERROR'
          }
        });
      }
    }
  );
 
  /**
   * PUT /procurement/:id/receive - Réceptionner une commande (partielle ou totale)
   */
  router.put('/:id/receive',
    validate(idParamSchema, 'params'),
    validate(commandeApprovisionnementSchemas.reception, 'body'),
    async (req, res) => {
      try {
        const { id } = req.params;
        const { details, modePaiement: modePaiementReception } = req.body;

        // Vérifier que la commande existe
        const commande = await prisma.commandeApprovisionnement.findUnique({
          where: { id: parseInt(id) },
          include: {
            fournisseur: true,
            details: {
              include: {
                produit: true
              }
            }
          }
        });

        if (!commande) {
          return res.status(404).json({
            success: false,
            error: {
              message: 'Commande non trouvée',
              code: 'ORDER_NOT_FOUND'
            }
          });
        }

        // Vérifier que la commande n'est pas annulée
        if (commande.statut === 'annulee') {
          return res.status(400).json({
            success: false,
            error: {
              message: 'Impossible de réceptionner une commande annulée',
              code: 'ORDER_CANCELLED'
            }
          });
        }

        // Utiliser le mode de paiement fourni lors de la réception, sinon celui de la commande
        const modePaiementFinal = modePaiementReception || commande.modePaiement;
        console.log(`🔍 Mode de paiement: ${modePaiementFinal} (reçu: ${modePaiementReception}, commande: ${commande.modePaiement})`);

        // Traitement de la réception dans une transaction
        const result = await prisma.$transaction(async (tx) => {
          const cumpUpdates = []; // Collecter les mises à jour CUMP pour après la transaction
          let commandeComplete = true;
          let compteFournisseurToSync = null;
          let compteFournisseurCreated = null;

          // Traiter chaque détail de réception
          for (const receptionDetail of details) {
            const { detailId, quantiteRecue } = receptionDetail;

            // Trouver le détail de commande correspondant
            const detailCommande = commande.details.find(d => d.id === detailId);
            if (!detailCommande) {
              throw new Error(`Détail de commande ${detailId} non trouvé`);
            }

            // Vérifier que la quantité reçue ne dépasse pas la quantité commandée
            const nouvelleQuantiteRecue = detailCommande.quantiteRecue + quantiteRecue;
            if (nouvelleQuantiteRecue > detailCommande.quantiteCommandee) {
              throw new Error(`Quantité reçue (${nouvelleQuantiteRecue}) supérieure à la quantité commandée (${detailCommande.quantiteCommandee}) pour le produit ${detailCommande.produit.nom}`);
            }

            // Mettre à jour le détail de commande
            await tx.detailCommandeApprovisionnement.update({
              where: { id: detailId },
              data: { quantiteRecue: nouvelleQuantiteRecue }
            });

            // Mettre à jour le stock si quantité reçue > 0
            if (quantiteRecue > 0) {
              // 1. Récupérer le stock AVANT le mouvement
              let stockInitial = 0;
              if (commande.boutiqueId) {
                // ── Mode multi-boutique : SQL brut pour éviter le deadlock avec les hooks Prisma ──
                const stockBoutique = await tx.stockBoutique.findUnique({
                  where: { boutiqueId_produitId: { boutiqueId: commande.boutiqueId, produitId: detailCommande.produitId } }
                });
                stockInitial = stockBoutique?.quantiteDisponible || 0;

                await tx.$executeRawUnsafe(`
                  INSERT INTO stock_boutiques (boutique_id, produit_id, quantite_disponible, quantite_reservee, derniere_maj)
                  VALUES (?, ?, ?, 0, CURRENT_TIMESTAMP)
                  ON CONFLICT(boutique_id, produit_id)
                  DO UPDATE SET
                    quantite_disponible = stock_boutiques.quantite_disponible + ?,
                    derniere_maj = CURRENT_TIMESTAMP
                `, commande.boutiqueId, detailCommande.produitId, quantiteRecue, quantiteRecue);
                console.log(`📦 Stock boutique mis à jour: Produit ${detailCommande.produitId}, Boutique ${commande.boutiqueId}, +${quantiteRecue}`);
              } else {
                // ── Mode classique : SQL brut pour éviter le deadlock avec les hooks Prisma ──
                const stock = await tx.stock.findUnique({
                  where: { produitId: detailCommande.produitId }
                });
                stockInitial = stock?.quantiteDisponible || 0;

                await tx.$executeRawUnsafe(`
                  INSERT INTO stock (produit_id, quantite_disponible, quantite_reservee, derniere_maj)
                  VALUES (?, ?, 0, CURRENT_TIMESTAMP)
                  ON CONFLICT(produit_id)
                  DO UPDATE SET
                    quantite_disponible = stock.quantite_disponible + ?,
                    derniere_maj = CURRENT_TIMESTAMP
                `, detailCommande.produitId, quantiteRecue, quantiteRecue);
                console.log(`📦 Stock global mis à jour: Produit ${detailCommande.produitId}, +${quantiteRecue}`);
              }

              // 2. Calculer le stock APRÈS le mouvement
              const stockFinal = stockInitial + quantiteRecue;

              // Créer le mouvement de stock avec snapshots
              await tx.mouvementStock.create({
                data: {
                  produitId: detailCommande.produitId,
                  boutiqueId: commande.boutiqueId || null,
                  typeMouvement: 'achat',
                  changementQuantite: quantiteRecue,
                  stockInitial,
                  stockFinal,
                  referenceId: parseInt(id),
                  typeReference: 'approvisionnement',
                  notes: `Réception commande ${commande.numeroCommande}`
                }
              });
              console.log(`📝 Mouvement de stock créé: Produit ${detailCommande.produitId}, Quantité +${quantiteRecue}, Stock: ${stockInitial} → ${stockFinal}`);

              // Collecter pour recalcul CUMP après la transaction (évite deadlock)
              cumpUpdates.push({
                produitId: detailCommande.produitId,
                prixAchat: detailCommande.coutUnitaire,
                source: 'approvisionnement',
                referenceId: parseInt(id),
                quantite: quantiteRecue
              });
            }

            // Vérifier si ce détail est complet
            if (nouvelleQuantiteRecue < detailCommande.quantiteCommandee) {
              commandeComplete = false;
            }
          }

          // Déterminer le nouveau statut de la commande
          let nouveauStatut = commande.statut;
          if (commandeComplete) {
            nouveauStatut = 'terminee';
          } else if (commande.statut === 'en_attente') {
            nouveauStatut = 'partielle';
          }

          // Mettre à jour le statut ET le mode de paiement de la commande si nécessaire
          const updateData = {};
          if (nouveauStatut !== commande.statut) {
            updateData.statut = nouveauStatut;
          }
          if (modePaiementReception && modePaiementReception !== commande.modePaiement) {
            updateData.modePaiement = modePaiementReception;
            console.log(`📝 Mise à jour du mode de paiement: ${commande.modePaiement} → ${modePaiementReception}`);
          }

          if (Object.keys(updateData).length > 0) {
            await tx.commandeApprovisionnement.update({
              where: { id: parseInt(id) },
              data: updateData
            });
          }

          // Gérer le compte fournisseur selon le mode de paiement
          let montantReception = 0;
          console.log(`🔍 Vérification mode paiement: ${modePaiementFinal} pour commande ${commande.id}`);

          // Calculer le montant de la réception (pour crédit ET comptant)
          for (const receptionDetail of details) {
            const { detailId, quantiteRecue } = receptionDetail;
            const detailCommande = commande.details.find(d => d.id === detailId);
            if (detailCommande) {
              montantReception += quantiteRecue * detailCommande.coutUnitaire;
            }
          }

          console.log(`💰 Montant de la réception: ${montantReception} FCFA`);

          if (montantReception > 0) {
            // Vérifier/créer le compte fournisseur
            let compteFournisseur = await tx.compteFournisseur.findUnique({
              where: { fournisseurId: commande.fournisseurId }
            });

            if (!compteFournisseur) {
              console.log(`📝 Création du compte fournisseur pour ${commande.fournisseurId}`);
              compteFournisseur = await tx.compteFournisseur.create({
                data: {
                  fournisseurId: commande.fournisseurId,
                  soldeActuel: 0,
                  limiteCredit: 0
                }
              });
              compteFournisseurCreated = compteFournisseur;
            }

            if (modePaiementFinal === 'credit') {
              console.log(`💳 Commande à crédit - Enregistrement de la dette fournisseur`);

              const nouveauSolde = compteFournisseur.soldeActuel + montantReception;

              const compteFournisseurUpdated = await tx.compteFournisseur.update({
                where: { id: compteFournisseur.id },
                data: { soldeActuel: nouveauSolde }
              });

              await tx.transactionCompte.create({
                data: {
                  typeCompte: 'fournisseur',
                  compteId: compteFournisseur.id,
                  typeTransaction: 'achat',
                  montant: montantReception,
                  description: `Réception commande ${commande.numeroCommande} à crédit`,
                  referenceId: parseInt(id),
                  referenceType: 'commande_approvisionnement',
                  soldeApres: nouveauSolde
                }
              });

              console.log(`✅ Compte fournisseur mis à jour: ${compteFournisseur.soldeActuel} → ${nouveauSolde} FCFA`);

              // Stocker pour sync
              compteFournisseurToSync = compteFournisseurUpdated;

            } else if (modePaiementFinal === 'comptant') {
              console.log(`💵 Commande comptant - Enregistrement achat + paiement immédiat`);

              // 1. Transaction d'achat (dette temporaire)
              const soldeApresAchat = compteFournisseur.soldeActuel + montantReception;

              await tx.transactionCompte.create({
                data: {
                  typeCompte: 'fournisseur',
                  compteId: compteFournisseur.id,
                  typeTransaction: 'achat',
                  montant: montantReception,
                  description: `Réception commande ${commande.numeroCommande} (comptant)`,
                  referenceId: parseInt(id),
                  referenceType: 'commande_approvisionnement',
                  soldeApres: soldeApresAchat
                }
              });

              // 2. Transaction de paiement immédiat (solde la dette)
              const soldeApresPaiement = soldeApresAchat - montantReception; // = solde initial

              const compteFournisseurUpdated2 = await tx.compteFournisseur.update({
                where: { id: compteFournisseur.id },
                data: { soldeActuel: soldeApresPaiement }
              });

              await tx.transactionCompte.create({
                data: {
                  typeCompte: 'fournisseur',
                  compteId: compteFournisseur.id,
                  typeTransaction: 'paiement',
                  montant: montantReception,
                  description: `Paiement comptant commande ${commande.numeroCommande}`,
                  referenceId: parseInt(id),
                  referenceType: 'commande_approvisionnement',
                  soldeApres: soldeApresPaiement
                }
              });

              console.log(`✅ Paiement comptant enregistré - Solde fournisseur inchangé: ${soldeApresPaiement} FCFA`);

              // Stocker pour sync
              compteFournisseurToSync = compteFournisseurUpdated2;
            }

            // Si le compte vient d'être créé, le syncer aussi
            if (compteFournisseurCreated) {
              compteFournisseurToSync = compteFournisseurToSync || compteFournisseurCreated;
            }
          }

          return { nouveauStatut, montantReception, modePaiementFinal, cumpUpdates, compteFournisseurToSync, compteFournisseurCreated };
        });

        // Recalculer le CUMP APRÈS la transaction (évite les deadlocks)
        for (const update of result.cumpUpdates) {
          try {
            const cump = await enregistrerPrixAchatEtRecalculerCump(
              prisma,
              update.produitId,
              update.prixAchat,
              update.source,
              update.referenceId,
              update.quantite
            );
            console.log(`💰 CUMP recalculé pour produit ${update.produitId}: ${cump}`);
          } catch (e) {
            console.warn(`⚠️  Erreur CUMP produit ${update.produitId}:`, e.message);
          }
        }

        // Enqueue explicite des stocks vers Neon (les hooks tx ne déclenchent pas la sync)
        const syncService = require('../services/sync-service');

        // Sync du compte fournisseur si créé ou mis à jour
        if (result.compteFournisseurCreated) {
          try {
            await syncService.enqueue('comptes_fournisseurs', 'INSERT', result.compteFournisseurCreated);
            console.log(`📤 comptes_fournisseurs INSERT enqueued: ID ${result.compteFournisseurCreated.id}`);
          } catch (e) {
            console.warn(`⚠️  Erreur enqueue compte fournisseur (create):`, e.message);
          }
        }
        if (result.compteFournisseurToSync && (!result.compteFournisseurCreated || result.compteFournisseurToSync.id !== result.compteFournisseurCreated.id)) {
          try {
            await syncService.enqueue('comptes_fournisseurs', 'UPDATE', result.compteFournisseurToSync);
            console.log(`📤 comptes_fournisseurs UPDATE enqueued: ID ${result.compteFournisseurToSync.id}`);
          } catch (e) {
            console.warn(`⚠️  Erreur enqueue compte fournisseur (update):`, e.message);
          }
        }

        // Sync des transactions de compte créées lors de la réception
        if (result.compteFournisseurToSync || result.compteFournisseurCreated) {
          const compteId = (result.compteFournisseurToSync || result.compteFournisseurCreated).id;
          try {
            const txComptes = await prisma.transactionCompte.findMany({
              where: {
                compteId,
                referenceId: parseInt(id),
                referenceType: 'commande_approvisionnement'
              }
            });
            for (const txC of txComptes) {
              await syncService.enqueue('transactions_comptes', 'INSERT', txC);
            }
            console.log(`📤 transactions_comptes enqueued: ${txComptes.length} enregistrement(s)`);
          } catch (e) {
            console.warn(`⚠️  Erreur enqueue transactions_comptes:`, e.message);
          }
        }
        for (const update of result.cumpUpdates) {
          try {
            if (commande.boutiqueId) {
              const sb = await prisma.stockBoutique.findUnique({
                where: { boutiqueId_produitId: { boutiqueId: commande.boutiqueId, produitId: update.produitId } }
              });
              if (sb) {
                await syncService.enqueue('stock_boutiques', 'UPDATE', sb);
                console.log(`📤 stock_boutiques enqueued: Produit ${update.produitId}, Boutique ${commande.boutiqueId}, Qté ${sb.quantiteDisponible}`);
              }
            } else {
              const sg = await prisma.stock.findUnique({ where: { produitId: update.produitId } });
              if (sg) {
                await syncService.enqueue('stock', 'UPDATE', sg);
                console.log(`📤 stock enqueued: Produit ${update.produitId}, Qté ${sg.quantiteDisponible}`);
              }
            }
          } catch (e) {
            console.warn(`⚠️  Erreur enqueue stock produit ${update.produitId}:`, e.message);
          }
        }

        // Enqueue des mouvements de stock créés dans la transaction
        // Les mouvements sont créés individuellement, on les récupère par référence
        const mvtCreated = await prisma.mouvementStock.findMany({
          where: {
            referenceId: parseInt(id),
            typeReference: 'approvisionnement',
            typeMouvement: 'achat'
          }
        });

        for (const mvt of mvtCreated) {
          try {
            await syncService.enqueue('mouvements_stock', 'INSERT', mvt);
            console.log(`📤 mouvements_stock enqueued: ID ${mvt.id}, Produit ${mvt.produitId}, +${mvt.changementQuantite}`);
          } catch (e) {
            console.warn(`⚠️  Erreur enqueue mouvement produit ${mvt.produitId}:`, e.message);
          }
        }

        // Enqueue des détails de commande mis à jour lors de la réception
        const detailsMisAJour = await prisma.detailCommandeApprovisionnement.findMany({
          where: { commandeId: parseInt(id) }
        });
        for (const detail of detailsMisAJour) {
          try {
            await syncService.enqueue('details_commandes_approvisionnement', 'UPDATE', detail);
            console.log(`📤 details_commandes_approvisionnement enqueued: ID ${detail.id}, quantiteRecue=${detail.quantiteRecue}`);
          } catch (e) {
            console.warn(`⚠️  Erreur enqueue detail commande ${detail.id}:`, e.message);
          }
        }

        // Récupérer la commande mise à jour
        const commandeMiseAJour = await prisma.commandeApprovisionnement.findUnique({
          where: { id: parseInt(id) },
          include: {
            fournisseur: true,
            details: {
              include: {
                produit: true
              }
            }
          }
        });

        res.json({
          success: true,
          data: transformers.commandeApprovisionnement(commandeMiseAJour),
          message: `Réception enregistrée avec succès. Statut: ${result.nouveauStatut}, Mode: ${result.modePaiementFinal}`,
          meta: {
            statut: result.nouveauStatut,
            modePaiement: result.modePaiementFinal
          }
        });

      } catch (error) {
        console.error('Erreur lors de la réception:', error);
        res.status(500).json({
          success: false,
          error: {
            message: error.message || 'Erreur lors de la réception',
            code: 'RECEIVE_ORDER_ERROR'
          }
        });
      }
    }
  );

  /**
   * DELETE /procurement/:id - Annuler une commande d'approvisionnement
   */
  router.delete('/:id',
    validate(idParamSchema, 'params'),
    async (req, res) => {
      try {
        const { id } = req.params;

        // Vérifier que la commande existe
        const commande = await prisma.commandeApprovisionnement.findUnique({
          where: { id: parseInt(id) },
          include: {
            details: true
          }
        });

        if (!commande) {
          return res.status(404).json({
            success: false,
            error: {
              message: 'Commande non trouvée',
              code: 'ORDER_NOT_FOUND'
            }
          });
        }

        // Vérifier que la commande peut être annulée
        if (commande.statut === 'terminee') {
          return res.status(400).json({
            success: false,
            error: {
              message: 'Impossible d\'annuler une commande terminée',
              code: 'ORDER_COMPLETED'
            }
          });
        }

        // Vérifier s'il y a des réceptions partielles
        const aDesReceptions = commande.details.some(detail => detail.quantiteRecue > 0);
        if (aDesReceptions) {
          return res.status(400).json({
            success: false,
            error: {
              message: 'Impossible d\'annuler une commande avec des réceptions partielles',
              code: 'ORDER_HAS_RECEPTIONS'
            }
          });
        }

        // Annuler la commande
        const commandeAnnulee = await prisma.commandeApprovisionnement.update({
          where: { id: parseInt(id) },
          data: { statut: 'annulee' },
          include: {
            fournisseur: true,
            details: {
              include: {
                produit: true
              }
            }
          }
        });

        res.json({
          success: true,
          data: transformers.commandeApprovisionnement(commandeAnnulee),
          message: 'Commande annulée avec succès'
        });

      } catch (error) {
        console.error('Erreur lors de l\'annulation de la commande:', error);
        res.status(500).json({
          success: false,
          error: {
            message: 'Erreur lors de l\'annulation de la commande',
            code: 'CANCEL_ORDER_ERROR'
          }
        });
      }
    }
  );



  /**
   * POST /procurement/test-create - Test de création de commande
   */
  router.post('/test-create', async (req, res) => {
    try {
      console.log('🧪 Test de création de commande...');
      
      const numeroCommande = `TEST${Date.now()}`;
      
      const commande = await prisma.commandeApprovisionnement.create({
        data: {
          numeroCommande,
          fournisseurId: 1,
          dateCommande: new Date(),
          modePaiement: 'credit',
          notes: 'Test de création',
          statut: 'en_attente',
          montantTotal: 500
        }
      });
      
      res.json({
        success: true,
        data: { commande }
      });
      
    } catch (error) {
      console.error('Erreur test:', error);
      res.status(500).json({
        success: false,
        error: { message: error.message }
      });
    }
  });

  /**
   * POST /procurement/generate-from-suggestions - Génère une commande à partir des suggestions
   */
  router.post('/generate-from-suggestions', async (req, res) => {
    try {
      const { fournisseurId, suggestions, modePaiement, dateLivraisonPrevue, notes } = req.body;
      
      console.log('📦 Génération de commande depuis suggestions:', { fournisseurId, suggestions: suggestions?.length, modePaiement });

      // Validation des paramètres
      if (!fournisseurId || !suggestions || !Array.isArray(suggestions) || suggestions.length === 0) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Paramètres manquants ou invalides (fournisseurId et suggestions requis)',
            code: 'INVALID_PARAMETERS'
          }
        });
      }

      // Créer une commande simple avec les produits suggérés
      const numeroCommande = `CMD${Date.now()}`;
      
      console.log('✅ Paramètres validés, création de la commande...');
      
      // Créer la commande principale
      const commande = await prisma.commandeApprovisionnement.create({
        data: {
          numeroCommande,
          fournisseurId: parseInt(fournisseurId),
          dateCommande: new Date(),
          dateLivraisonPrevue: dateLivraisonPrevue ? new Date(dateLivraisonPrevue) : null,
          modePaiement: modePaiement || 'credit',
          notes: notes || 'Commande générée automatiquement à partir des suggestions',
          statut: 'en_attente',
          montantTotal: 0 // Sera mis à jour après création des détails
        }
      });
      
      console.log('✅ Commande créée avec ID:', commande.id);

      // Créer les détails de commande basés sur les suggestions personnalisées
      let montantTotal = 0;
      const details = [];
      
      console.log(`🔍 Création de ${suggestions.length} détails avec quantités personnalisées...`);
      
      for (let i = 0; i < suggestions.length; i++) {
        const suggestion = suggestions[i];
        const produitId = suggestion.produitId;
        const quantite = Math.round(suggestion.quantiteSuggeree); // Quantité modifiée par l'utilisateur
        const coutUnitaire = suggestion.coutUnitaireEstime;
        const montantDetail = quantite * coutUnitaire;
        
        console.log(`🔍 Création détail ${i + 1}: Produit ${produitId}, Qté personnalisée ${quantite}, Coût ${coutUnitaire}`);
        
        try {
          const detail = await prisma.detailCommandeApprovisionnement.create({
            data: {
              commandeId: commande.id,
              produitId: produitId,
              quantiteCommandee: quantite,
              coutUnitaire: coutUnitaire
            }
          });
          
          details.push(detail);
          montantTotal += montantDetail;
          console.log(`✅ Détail créé avec quantité personnalisée: ID ${detail.id}, Produit ${produitId}, Qté ${quantite}, Montant ${montantDetail}`);
        } catch (detailError) {
          console.error(`❌ Erreur création détail pour produit ${produitId}:`, detailError);
        }
      }

      // Mettre à jour le montant total de la commande
      await prisma.commandeApprovisionnement.update({
        where: { id: commande.id },
        data: { montantTotal }
      });

      console.log('✅ Commande finalisée avec montant total:', montantTotal);

      // Récupérer la commande complète avec tous les détails pour la réponse
      const commandeComplete = await prisma.commandeApprovisionnement.findUnique({
        where: { id: commande.id },
        include: {
          fournisseur: true,
          details: {
            include: {
              produit: true
            }
          }
        }
      });

      res.status(201).json({
        success: true,
        data: {
          commande: transformers.commandeApprovisionnement(commandeComplete),
          message: `Commande générée avec succès avec ${details.length} produits`
        }
      });

    } catch (error) {
      console.error('Erreur lors de la génération de commande:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la génération de commande',
          code: 'GENERATE_ORDER_ERROR'
        }
      });
    }
  });



  return router;
}

/**
 * Génère un numéro de commande unique
 * @param {PrismaClient} prisma - Client Prisma
 * @returns {Promise<string>}
 */
async function generateNumeroCommande(prisma) {
  const today = new Date();
  const year = today.getFullYear();
  const month = String(today.getMonth() + 1).padStart(2, '0');
  const day = String(today.getDate()).padStart(2, '0');
  
  const prefix = `CMD${year}${month}${day}`;
  
  // Trouver le dernier numéro de commande du jour
  const lastOrder = await prisma.commandeApprovisionnement.findFirst({
    where: {
      numeroCommande: {
        startsWith: prefix
      }
    },
    orderBy: {
      numeroCommande: 'desc'
    }
  });

  let sequence = 1;
  if (lastOrder) {
    const lastSequence = parseInt(lastOrder.numeroCommande.slice(-3));
    sequence = lastSequence + 1;
  }

  return `${prefix}${String(sequence).padStart(3, '0')}`;
}

module.exports = { createProcurementRouter };