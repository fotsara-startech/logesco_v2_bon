/**
 * Routes pour la gestion des ventes
 * Gestion complète du système de ventes avec vérification de stock
 */

const express = require('express');
const { venteSchemas } = require('../validation/schemas');
const { validate, validateId, validatePagination } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { buildSalesSearchConditions, generateSaleNumber } = require('../utils/transformers');
const { updateExpirationDatesAfterSale } = require('../utils/expiration-manager');
const { resolveBoutiqueId } = require('../utils/boutique-helper');

function createSalesRouter({ prisma, authService, syncService }) {
  const router = express.Router();

  // Middleware d'authentification pour toutes les routes
  router.use(authenticateToken(authService));

  /**
   * POST /sales/validate-discount
   * Valider une remise avant application
   */
  router.post('/validate-discount',
    validate(venteSchemas.validateDiscount, 'body'),
    async (req, res) => {
      try {
        const { produitId, remiseAppliquee, justificationRemise } = req.body;

        // Récupérer les informations du produit
        const produit = await prisma.produit.findUnique({
          where: { id: produitId },
          select: {
            id: true,
            nom: true,
            reference: true,
            prixUnitaire: true,
            remiseMaxAutorisee: true
          }
        });

        if (!produit) {
          return res.status(404).json({
            success: false,
            message: 'Produit non trouvé'
          });
        }

        // Vérifier la remise
        const isValid = remiseAppliquee <= produit.remiseMaxAutorisee;
        const prixFinal = produit.prixUnitaire - remiseAppliquee;

        res.json({
          success: true,
          data: {
            isValid,
            produit: {
              id: produit.id,
              nom: produit.nom,
              reference: produit.reference,
              prixUnitaire: produit.prixUnitaire
            },
            remise: {
              appliquee: remiseAppliquee,
              maxAutorisee: produit.remiseMaxAutorisee,
              justification: justificationRemise
            },
            prixFinal,
            message: isValid 
              ? 'Remise autorisée' 
              : `Remise trop élevée. Maximum autorisé: ${produit.remiseMaxAutorisee} FCFA`
          }
        });
      } catch (error) {
        console.error('Erreur lors de la validation de la remise:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la validation de la remise'
        });
      }
    }
  );

  /**
   * GET /sales
   * Liste des ventes avec recherche et pagination
   */
  router.get('/',
    validate(venteSchemas.search, 'query'),
    validatePagination,
    async (req, res) => {
      try {
        console.log('🔍 [SALES API] Requête reçue');
        console.log('   - Query params:', JSON.stringify(req.query));
        console.log('   - User:', req.user?.nomUtilisateur || 'inconnu');
        
        const { page = 1, limit = 20, dateDebut, dateFin, ...otherParams } = req.query;
        const skip = (page - 1) * limit;

        // Si on a des filtres de date, utiliser une requête SQL brute pour éviter les problèmes de timezone
        if (dateDebut || dateFin) {
          console.log('📅 [SALES ROUTE] Utilisation de requête SQL brute pour filtrage par date');
          
          // Construire les autres conditions
          const conditions = buildSalesSearchConditions(otherParams);
          
          // Construire la clause WHERE SQL pour les dates
          let dateWhereClause = '';
          const params = [];
          
          if (dateDebut) {
            // Le paramètre peut être une string ou un objet Date
            let dateStr = String(dateDebut);
            
            // Si c'est un format ISO avec T, extraire les composants
            const isoMatch = dateStr.match(/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/);
            if (isoMatch) {
              // SQLite stocke les dates en format ISO, donc on doit comparer avec ce format
              // Convertir la date locale en ISO UTC pour la comparaison
              const d = new Date(parseInt(isoMatch[1]), parseInt(isoMatch[2]) - 1, parseInt(isoMatch[3]), 
                                parseInt(isoMatch[4]), parseInt(isoMatch[5]), parseInt(isoMatch[6]));
              const dateISO = d.toISOString();
              dateWhereClause += ' AND date_vente >= ?';
              params.push(dateISO);
              console.log('📅 [SQL] dateDebut (ISO):', dateISO);
            } else {
              // Sinon, essayer de parser comme Date et formater en ISO
              const d = new Date(dateDebut);
              const dateISO = d.toISOString();
              dateWhereClause += ' AND date_vente >= ?';
              params.push(dateISO);
              console.log('📅 [SQL] dateDebut (parsed ISO):', dateISO);
            }
          }
          
          if (dateFin) {
            let dateStr = String(dateFin);
            
            const isoMatch = dateStr.match(/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/);
            if (isoMatch) {
              const d = new Date(parseInt(isoMatch[1]), parseInt(isoMatch[2]) - 1, parseInt(isoMatch[3]), 
                                parseInt(isoMatch[4]), parseInt(isoMatch[5]), parseInt(isoMatch[6]));
              const dateISO = d.toISOString();
              dateWhereClause += ' AND date_vente <= ?';
              params.push(dateISO);
              console.log('📅 [SQL] dateFin (ISO):', dateISO);
            } else {
              const d = new Date(dateFin);
              const dateISO = d.toISOString();
              dateWhereClause += ' AND date_vente <= ?';
              params.push(dateISO);
              console.log('📅 [SQL] dateFin (parsed ISO):', dateISO);
            }
          }
          
          // Construire la clause WHERE complète
          let whereClause = '1=1' + dateWhereClause;
          
          // Ajouter les autres conditions (utiliser les noms de colonnes mappés)
          if (conditions.clientId) {
            whereClause += ' AND client_id = ?';
            params.push(conditions.clientId);
          }
          if (conditions.vendeurId) {
            whereClause += ' AND vendeur_id = ?';
            params.push(conditions.vendeurId);
          }
          if (conditions.statut) {
            whereClause += ' AND statut = ?';
            params.push(conditions.statut);
          }
          if (conditions.modePaiement) {
            whereClause += ' AND mode_paiement = ?';
            params.push(conditions.modePaiement);
          }
          if (conditions.boutiqueId) {
            whereClause += ' AND boutique_id = ?';
            params.push(conditions.boutiqueId);
          }
          
          console.log('📅 [SQL] WHERE clause:', whereClause);
          console.log('📅 [SQL] Params:', params);
          
          // DEBUG: Voir toutes les dates de vente pour comprendre le format
          const allDates = await prisma.$queryRawUnsafe(
            `SELECT id, date_vente FROM ventes WHERE boutique_id = ? ORDER BY id DESC LIMIT 5`,
            conditions.boutiqueId || 7
          );
          console.log('📅 [DEBUG] Dernières dates de vente:', allDates);
          
          // Exécuter la requête SQL brute (table name: ventes)
          // CORRECTION: Tri par ID DESC au lieu de date_vente DESC pour éviter le tri alphabétique
          const ventesRaw = await prisma.$queryRawUnsafe(
            `SELECT * FROM ventes WHERE ${whereClause} ORDER BY id DESC LIMIT ? OFFSET ?`,
            ...params,
            parseInt(limit),
            skip
          );
          
          const totalRaw = await prisma.$queryRawUnsafe(
            `SELECT COUNT(*) as count FROM ventes WHERE ${whereClause}`,
            ...params
          );
          
          // SQLite retourne BigInt, il faut le convertir en Number
          const total = Number(totalRaw[0].count);
          
          console.log('📅 [SQL] Résultats trouvés:', ventesRaw.length);
          
          // Enrichir les ventes avec les relations
          const ventes = await Promise.all(
            ventesRaw.map(async (vente) => {
              return await prisma.vente.findUnique({
                where: { id: vente.id },
                include: {
                  client: {
                    select: { id: true, nom: true, prenom: true, telephone: true, adresse: true, nui: true, rccm: true }
                  },
                  vendeur: {
                    select: { id: true, nomUtilisateur: true }
                  },
                  details: {
                    include: {
                      produit: {
                        select: { id: true, nom: true, reference: true }
                      }
                    }
                  }
                }
              });
            })
          );
          
          res.json({
            success: true,
            data: ventes,
            pagination: {
              page: parseInt(page),
              limit: parseInt(limit),
              total,
              pages: Math.ceil(total / limit)
            }
          });
        } else {
          // Pas de filtre de date, utiliser la méthode normale
          const conditions = buildSalesSearchConditions(otherParams);

          // CORRECTION: Tri par ID DESC au lieu de dateVente DESC pour éviter le tri alphabétique
          const [ventes, total] = await Promise.all([
            prisma.vente.findMany({
              where: conditions,
              include: {
                client: {
                  select: { id: true, nom: true, prenom: true, telephone: true, adresse: true, nui: true, rccm: true }
                },
                vendeur: {
                  select: { id: true, nomUtilisateur: true }
                },
                details: {
                  include: {
                    produit: {
                      select: { id: true, nom: true, reference: true }
                    }
                  }
                }
              },
              orderBy: { id: 'desc' },
              skip,
              take: parseInt(limit)
            }),
            prisma.vente.count({ where: conditions })
          ]);

          res.json({
            success: true,
            data: ventes,
            pagination: {
              page: parseInt(page),
              limit: parseInt(limit),
              total,
              pages: Math.ceil(total / limit)
            }
          });
        }
      } catch (error) {
        console.error('❌ ====== ERREUR GET /SALES ======');
        console.error('Type:', error.constructor.name);
        console.error('Message:', error.message);
        console.error('Code:', error.code);
        console.error('Stack:', error.stack);
        console.error('Query params:', req.query);
        console.error('User:', req.user);
        console.error('=====================================');
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la récupération des ventes',
          error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
      }
    }
  );

  /**
   * GET /sales/analytics/products
   * Analyse des ventes par produit sur une période définie
   * Retourne les produits triés par chiffre d'affaires décroissant
   */
  router.get('/analytics/products',
    validate(venteSchemas.analyticsProducts, 'query'),
    async (req, res) => {
      try {
        const { 
          dateDebut, 
          dateFin, 
          categorieId, 
          limit = 50,
          includeServices = true 
        } = req.query;

        // Construire les conditions de filtrage
        const whereConditions = {
          statut: { not: 'annulee' }, // Exclure les ventes annulées
        };

        // Filtrage par période
        if (dateDebut || dateFin) {
          whereConditions.dateVente = {};
          if (dateDebut) {
            whereConditions.dateVente.gte = new Date(dateDebut);
          }
          if (dateFin) {
            whereConditions.dateVente.lte = new Date(dateFin);
          }
        }

        // Construire les conditions pour les produits
        const produitConditions = {};
        if (categorieId) {
          produitConditions.categorieId = parseInt(categorieId);
        }
        if (includeServices === 'false') {
          produitConditions.estService = false;
        }

        // CORRECTION FINALE: Calculer le chiffre d'affaires réel par produit
        // Récupérer toutes les ventes avec leurs détails pour un calcul précis
        const ventesAvecDetails = await prisma.vente.findMany({
          where: whereConditions,
          select: {
            id: true,
            sousTotal: true,
            montantTotal: true,
            details: {
              where: produitConditions.categorieId || produitConditions.estService !== undefined ? {
                produit: produitConditions
              } : undefined,
              select: {
                produitId: true,
                quantite: true,
                prixTotal: true
              }
            }
          }
        });

        // Calculer les statistiques par produit avec le ratio de remise correct
        const statsParProduit = new Map();
        
        ventesAvecDetails.forEach(vente => {
          // Calculer le ratio de remise pour cette vente
          const ratioRemise = vente.sousTotal > 0 ? vente.montantTotal / vente.sousTotal : 1;
          
          vente.details.forEach(detail => {
            const produitId = detail.produitId;
            const chiffreAffairesReel = detail.prixTotal * ratioRemise;
            
            if (!statsParProduit.has(produitId)) {
              statsParProduit.set(produitId, {
                quantiteVendue: 0,
                chiffreAffaires: 0,
                nombreTransactions: 0
              });
            }
            
            const stats = statsParProduit.get(produitId);
            stats.quantiteVendue += detail.quantite;
            stats.chiffreAffaires += chiffreAffairesReel;
            stats.nombreTransactions += 1;
          });
        });

        // Convertir en format attendu pour la suite du code
        const ventesData = Array.from(statsParProduit.entries()).map(([produitId, stats]) => ({
          produitId: parseInt(produitId),
          _sum: {
            quantite: stats.quantiteVendue,
            prixTotal: stats.chiffreAffaires // Utiliser le CA réel calculé
          },
          _count: {
            id: stats.nombreTransactions
          }
        }));

        // Enrichir avec les informations des produits
        const produitsAnalytics = await Promise.all(
          ventesData.map(async (data) => {
            const produit = await prisma.produit.findUnique({
              where: { id: data.produitId },
              include: {
                categorie: {
                  select: { id: true, nom: true }
                }
              }
            });

            if (!produit) return null;

            const quantiteVendue = data._sum.quantite || 0;
            const chiffreAffaires = data._sum.prixTotal || 0; // Maintenant c'est le CA réel
            const nombreTransactions = data._count.id || 0;
            const prixMoyenVente = quantiteVendue > 0 ? chiffreAffaires / quantiteVendue : 0;

            // Calculer le pourcentage de marge si prix d'achat disponible
            let margeUnitaire = 0;
            let pourcentageMarge = 0;
            if (produit.prixAchat && produit.prixAchat > 0) {
              margeUnitaire = prixMoyenVente - produit.prixAchat;
              pourcentageMarge = (margeUnitaire / prixMoyenVente) * 100;
            }

            return {
              produit: {
                id: produit.id,
                nom: produit.nom,
                reference: produit.reference,
                prixUnitaire: produit.prixUnitaire,
                prixAchat: produit.prixAchat,
                estService: produit.estService,
                categorie: produit.categorie
              },
              statistiques: {
                quantiteVendue,
                chiffreAffaires,
                nombreTransactions,
                prixMoyenVente: Math.round(prixMoyenVente * 100) / 100,
                margeUnitaire: Math.round(margeUnitaire * 100) / 100,
                pourcentageMarge: Math.round(pourcentageMarge * 100) / 100
              }
            };
          })
        );

        // Filtrer les résultats null et trier par chiffre d'affaires décroissant
        const resultats = produitsAnalytics
          .filter(item => item !== null)
          .sort((a, b) => b.statistiques.chiffreAffaires - a.statistiques.chiffreAffaires)
          .slice(0, parseInt(limit));

        // Calculer les statistiques globales
        const statistiquesGlobales = {
          nombreProduitsVendus: resultats.length,
          chiffreAffairesTotal: resultats.reduce((sum, item) => sum + item.statistiques.chiffreAffaires, 0),
          quantiteTotaleVendue: resultats.reduce((sum, item) => sum + item.statistiques.quantiteVendue, 0),
          nombreTransactionsTotal: resultats.reduce((sum, item) => sum + item.statistiques.nombreTransactions, 0)
        };

        // Identifier les produits à faible performance (bottom 20%)
        const seuilFaiblePerformance = Math.ceil(resultats.length * 0.2);
        const produitsFaiblePerformance = resultats.slice(-seuilFaiblePerformance);

        res.json({
          success: true,
          data: {
            periode: {
              dateDebut: dateDebut || null,
              dateFin: dateFin || null
            },
            filtres: {
              categorieId: categorieId ? parseInt(categorieId) : null,
              includeServices: includeServices !== 'false'
            },
            statistiquesGlobales,
            produits: resultats,
            produitsAFaiblePerformance: produitsFaiblePerformance.map(p => ({
              ...p,
              recommandation: 'Analyser les raisons de la faible performance et envisager des actions correctives'
            }))
          },
          message: 'Analyse des ventes par produit récupérée avec succès'
        });

      } catch (error) {
        console.error('Erreur lors de l\'analyse des ventes par produit:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de l\'analyse des ventes par produit'
        });
      }
    }
  );

  /**
   * GET /sales/:id
   * Détails d'une vente spécifique
   */
  router.get('/:id',
    validateId,
    async (req, res) => {
      try {
        const { id } = req.params;

        const vente = await prisma.vente.findUnique({
          where: { id: parseInt(id) },
          include: {
            client: true,
            details: {
              include: {
                produit: {
                  select: { 
                    id: true, 
                    nom: true, 
                    reference: true,
                    prixUnitaire: true 
                  }
                }
              }
            }
          }
        });

        if (!vente) {
          return res.status(404).json({
            success: false,
            message: 'Vente non trouvée'
          });
        }

        res.json({
          success: true,
          data: vente
        });
      } catch (error) {
        console.error('Erreur lors de la récupération de la vente:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la récupération de la vente'
        });
      }
    }
  );  /**
  
 * POST /sales
   * Créer une nouvelle vente avec vérification de stock
   */
  router.post('/',
    validate(venteSchemas.create, 'body'),
    async (req, res) => {
      try {
        // Extraire boutiqueId depuis le body, header ou query params
        const boutiqueIdFromRequest = req.body.boutiqueId || 
                                     req.headers['x-boutique-id'] || 
                                     req.query.boutiqueId;

        console.log('🏪 [Sales] boutiqueId reçu:', {
          body: req.body.boutiqueId,
          header: req.headers['x-boutique-id'],
          query: req.query.boutiqueId,
          final: boutiqueIdFromRequest
        });

        const { clientId, modePaiement, montantRemise, montantPaye, montantTva, tauxTva, details, dateVente } = req.body;
        const boutiqueId = boutiqueIdFromRequest;

        // DEBUG: Log des données reçues
        console.log('📥 Données reçues pour création vente:');
        console.log(`   - clientId: ${clientId}`);
        console.log(`   - modePaiement: ${modePaiement}`);
        console.log(`   - montantRemise: ${montantRemise}`);
        console.log(`   - montantTva: ${montantTva}`);
        console.log(`   - tauxTva: ${tauxTva}`);
        console.log(`   - montantPaye: ${montantPaye} (type: ${typeof montantPaye})`);
        console.log(`   - dateVente: ${dateVente}`);
        console.log(`   - nombre de détails: ${details?.length}`);

        // Vérifier les privilèges d'antidatage si une date personnalisée est fournie
        if (dateVente) {
          const customDate = new Date(dateVente);
          const today = new Date();
          today.setHours(0, 0, 0, 0);
          customDate.setHours(0, 0, 0, 0);

          // Si la date est antérieure à aujourd'hui, vérifier les privilèges
          if (customDate < today) {
            const user = req.user;
            if (!user) {
              return res.status(401).json({
                success: false,
                message: 'Utilisateur non authentifié'
              });
            }

            // Récupérer les informations complètes de l'utilisateur avec son rôle
            const fullUser = await prisma.utilisateur.findUnique({
              where: { id: user.id },
              include: {
                role: true
              }
            });

            if (!fullUser) {
              return res.status(401).json({
                success: false,
                message: 'Utilisateur non trouvé'
              });
            }

            // Vérifier si l'utilisateur a le privilège d'antidatage
            let hasBackdatePrivilege = false;

            // Les admins ont automatiquement tous les privilèges
            if (fullUser.role && fullUser.role.isAdmin) {
              hasBackdatePrivilege = true;
            } else if (fullUser.role && fullUser.role.privileges) {
              // Parser les privilèges JSON
              try {
                const privileges = JSON.parse(fullUser.role.privileges);
                hasBackdatePrivilege = privileges.sales && privileges.sales.includes('BACKDATE');
              } catch (e) {
                console.error('Erreur parsing privilèges:', e);
                hasBackdatePrivilege = false;
              }
            }

            console.log(`🔐 Vérification privilège BACKDATE pour ${fullUser.nomUtilisateur}:`);
            console.log(`   - Est admin: ${fullUser.role?.isAdmin}`);
            console.log(`   - Privilèges: ${fullUser.role?.privileges}`);
            console.log(`   - A privilège BACKDATE: ${hasBackdatePrivilege}`);

            if (!hasBackdatePrivilege) {
              return res.status(403).json({
                success: false,
                message: 'Vous n\'avez pas l\'autorisation d\'antidater les ventes'
              });
            }
          }
        }

        // Vérifier les remises autorisées et la disponibilité du stock
        const stockChecks = await Promise.all(
          details.map(async (detail) => {
            // D'abord, récupérer les informations du produit
            const produit = await prisma.produit.findUnique({
              where: { id: detail.produitId },
              select: { 
                id: true, 
                nom: true, 
                reference: true, 
                estService: true,
                remiseMaxAutorisee: true,
                prixUnitaire: true
              }
            });

            if (!produit) {
              throw new Error(`Produit ${detail.produitId} non trouvé`);
            }

            // Vérifier la remise autorisée
            const remiseAppliquee = detail.remiseAppliquee || 0;
            if (remiseAppliquee > produit.remiseMaxAutorisee) {
              throw new Error(
                `Remise non autorisée pour ${produit.nom} (${produit.reference}). ` +
                `Maximum autorisé: ${produit.remiseMaxAutorisee} FCFA, Demandé: ${remiseAppliquee} FCFA`
              );
            }

            // Vérifier que le prix affiché est cohérent (peut être majoré)
            // Pour les majorations, le prix affiché peut être supérieur au prix système
            if (detail.prixAffiche < produit.prixUnitaire && detail.remiseAppliquee === 0) {
              throw new Error(
                `Prix affiché incorrect pour ${produit.nom}. ` +
                `Prix système: ${produit.prixUnitaire} FCFA, Prix affiché: ${detail.prixAffiche} FCFA`
              );
            }

            // Vérifier que le prix unitaire final est cohérent
            const prixAttendu = detail.prixAffiche - remiseAppliquee;
            
            // Pour les majorations (quand prixAffiche > prix système et remise = 0)
            const isMajoration = detail.prixAffiche > produit.prixUnitaire && remiseAppliquee === 0;
            
            if (!isMajoration && Math.abs(detail.prixUnitaire - prixAttendu) > 0.01) {
              throw new Error(
                `Prix final incohérent pour ${produit.nom}. ` +
                `Attendu: ${prixAttendu} FCFA, Reçu: ${detail.prixUnitaire} FCFA`
              );
            }
            
            // Pour les majorations, vérifier que prixUnitaire = prixAffiche
            if (isMajoration && Math.abs(detail.prixUnitaire - detail.prixAffiche) > 0.01) {
              throw new Error(
                `Prix majoré incohérent pour ${produit.nom}. ` +
                `Prix affiché: ${detail.prixAffiche} FCFA, Prix unitaire: ${detail.prixUnitaire} FCFA`
              );
            }

            // Si c'est un service, pas besoin de vérifier le stock
            if (produit.estService) {
              return { 
                stock: null, 
                detail, 
                produit,
                isService: true 
              };
            }

            // Pour les produits physiques, vérifier le stock
            // Si boutiqueId fourni → vérifier StockBoutique, sinon Stock global
            let stock;
            if (boutiqueId) {
              const boutiqueIdInt = parseInt(boutiqueId);
              stock = await prisma.stockBoutique.findUnique({
                where: { boutiqueId_produitId: { boutiqueId: boutiqueIdInt, produitId: detail.produitId } },
                include: { produit: { select: { nom: true, reference: true } } }
              });
              if (stock) stock._isBoutiqueStock = true;
            } else {
              stock = await prisma.stock.findUnique({
                where: { produitId: detail.produitId },
                include: { produit: { select: { nom: true, reference: true } } }
              });
            }

            if (!stock) {
              throw new Error(`Produit physique ${detail.produitId} non trouvé en stock`);
            }

            if (stock.quantiteDisponible < detail.quantite) {
              throw new Error(
                `Stock insuffisant pour ${stock.produit.nom} (${stock.produit.reference}). ` +
                `Disponible: ${stock.quantiteDisponible}, Demandé: ${detail.quantite}`
              );
            }

            return { 
              stock, 
              detail, 
              produit,
              isService: false 
            };
          })
        );

        // Calculer le montant total de la vente
        const montantVente = details.reduce((total, detail) => {
          return total + (detail.quantite * detail.prixUnitaire);
        }, 0);

        const montantVenteNet = montantVente - (montantRemise || 0);
        const montantTvaVal = montantTva || 0;
        const montantVenteTotal = montantVenteNet + montantTvaVal; // HT - remise + TVA = TTC

        // Si un client est sélectionné, vérifier son crédit existant
        let dettePrecedente = 0;
        let montantTotalAPayer = montantVenteTotal;

        if (clientId) {
          const compteClient = await prisma.compteClient.findUnique({
            where: { clientId },
            include: { client: { select: { nom: true, prenom: true } } }
          });

          if (compteClient && compteClient.soldeActuel < 0) {
            dettePrecedente = Math.abs(compteClient.soldeActuel);
            montantTotalAPayer = montantVenteTotal + dettePrecedente;
            console.log(`Client ${compteClient.client.nom} a une dette de ${dettePrecedente} FCFA`);
            console.log(`Montant total à payer: ${montantTotalAPayer} FCFA`);
          }
        }

        // Déterminer automatiquement le mode de paiement
        const montantVerse = montantPaye || 0;
        let modeDeTermine;
        let montantRestant = 0;
        
        // CORRECTION: La monnaie à rendre ne doit être calculée QUE si le client n'a pas de dette
        // Si le client a une dette, l'excédent sert à la rembourser
        let monnaieARendre = 0;
        
        if (montantVerse >= montantTotalAPayer) {
          // Le client a payé le total (commande + dette)
          modeDeTermine = 'comptant';
          monnaieARendre = montantVerse - montantTotalAPayer;
        } else if (montantVerse >= montantVenteTotal && dettePrecedente === 0) {
          // Pas de dette et paiement >= commande
          modeDeTermine = 'comptant';
          monnaieARendre = montantVerse - montantVenteTotal;
        } else {
          // Paiement partiel
          modeDeTermine = 'credit';
          montantRestant = montantTotalAPayer - montantVerse;
        }

        console.log(`Mode de paiement déterminé: ${modeDeTermine}`);
        console.log(`Montant versé: ${montantVerse} FCFA`);
        console.log(`Montant restant: ${montantRestant} FCFA`);
        console.log(`Monnaie à rendre: ${monnaieARendre} FCFA`);

        // Calculer le montant payé pour CETTE vente uniquement (pour le reçu)
        // Si le client a une dette, l'excédent sert à la rembourser, pas à payer cette vente
        const montantPayePourCetteVente = Math.min(montantVerse, montantVenteTotal);
        console.log(`💰 Montant payé pour cette vente (reçu): ${montantPayePourCetteVente} FCFA`);

        // Générer le numéro de vente
        const numeroVente = await generateSaleNumber(prisma);

        // Créer la vente dans une transaction avec timeout augmenté
        const result = await prisma.$transaction(async (tx) => {
          // Récupérer la session active de l'utilisateur connecté (filtrée par boutique)
          const sessionWhere = {
            utilisateurId: req.user.id,
            isActive: true,
            dateFermeture: null
          };
          let compteClientToSync = null;
          let createdTransactionIds = [];
          if (boutiqueId) sessionWhere.boutiqueId = parseInt(boutiqueId);

          const activeSession = await tx.cashSession.findFirst({
            where: sessionWhere
          });

          const sessionId = activeSession ? activeSession.id : null;
          
          if (!activeSession) {
            console.log('⚠️ Aucune session active trouvée - la vente sera créée sans session');
          } else {
            console.log(`✅ Session active trouvée: ID ${activeSession.id}`);
          }

          // Créer la vente avec la logique automatique
          // SOLUTION 2: Toutes les ventes sont marquées "terminee"
          // Le compte client gère les dettes, pas le statut de la vente
          const nouvelleVente = await tx.vente.create({
            data: {
              numeroVente,
              ...(clientId ? { client: { connect: { id: clientId } } } : {}),
              ...(sessionId ? { session: { connect: { id: sessionId } } } : {}),
              ...(req.user?.id ? { vendeur: { connect: { id: req.user.id } } } : {}),
              ...(boutiqueId ? { boutique: { connect: { id: parseInt(boutiqueId) } } } : {}),
              modePaiement: modeDeTermine,
              sousTotal: montantVente,
              montantRemise: montantRemise || 0,
              montantTva: montantTvaVal,
              tauxTva: tauxTva || null,
              montantTotal: montantVenteTotal, // Montant TTC (HT - remise + TVA)
              montantPaye: montantPayePourCetteVente,
              montantRestant: Math.max(0, montantVenteTotal - montantPayePourCetteVente),
              statut: 'terminee',
              dateVente: dateVente ? new Date(dateVente) : new Date(),
              details: {
                create: details.map(detail => ({
                  produitId: detail.produitId,
                  quantite: detail.quantite,
                  prixUnitaire: detail.prixUnitaire,
                  prixAffiche: detail.prixAffiche,
                  remiseAppliquee: detail.remiseAppliquee || 0,
                  justificationRemise: detail.justificationRemise || null,
                  prixTotal: detail.quantite * detail.prixUnitaire
                }))
              }
            },
            include: {
              client: true,
              details: {
                include: {
                  produit: {
                    select: { id: true, nom: true, reference: true }
                  }
                }
              }
            }
          });

          // Mettre à jour le stock pour les produits physiques uniquement
          for (const { stock, detail, isService } of stockChecks) {
            if (isService) {
              console.log(`Service vendu: ${detail.produitId} - pas de gestion de stock`);
              continue;
            }

            // 1. Récupérer le stock AVANT le mouvement
            let stockInitial = 0;
            if (stock._isBoutiqueStock) {
              stockInitial = stock.quantiteDisponible;
              await tx.stockBoutique.update({
                where: { id: stock.id },
                data: { quantiteDisponible: stock.quantiteDisponible - detail.quantite }
              });
            } else {
              stockInitial = stock.quantiteDisponible;
              await tx.stock.update({
                where: { id: stock.id },
                data: { quantiteDisponible: stock.quantiteDisponible - detail.quantite }
              });
            }

            // 2. Calculer le stock APRÈS le mouvement
            const stockFinal = stockInitial - detail.quantite;

            // Créer le mouvement de stock avec snapshots
            await tx.mouvementStock.create({
              data: {
                produitId: detail.produitId,
                boutiqueId: boutiqueId ? parseInt(boutiqueId) : null,
                typeMouvement: 'vente',
                changementQuantite: -detail.quantite,
                stockInitial,
                stockFinal,
                notes: `Vente ${numeroVente}`,
                referenceId: nouvelleVente.id,
                typeReference: 'vente'
              }
            });

            // Mettre à jour automatiquement les dates de péremption (FEFO)
            try {
              const resultatPeremption = await updateExpirationDatesAfterSale(
                tx,
                detail.produitId,
                detail.quantite
              );

              if (resultatPeremption.updated) {
                console.log(`✅ Dates de péremption mises à jour pour produit ${detail.produitId}`);
                if (resultatPeremption.quantiteNonCouverte > 0) {
                  console.log(`⚠️ Attention: ${resultatPeremption.quantiteNonCouverte} unités non couvertes par les dates de péremption`);
                }
              }
            } catch (errorPeremption) {
              // Ne pas bloquer la vente si la mise à jour des dates échoue
              console.error(`⚠️ Erreur mise à jour dates de péremption pour produit ${detail.produitId}:`, errorPeremption);
            }
          }

          // SOLUTION 2: Gestion centralisée du compte client
          // Le compte client est la seule source de vérité pour les dettes
          if (clientId) {
            // Récupérer les ventes impayées du client (de la plus ancienne à la plus récente)
            const ventesImpayees = await tx.vente.findMany({
              where: {
                clientId,
                montantRestant: { gt: 0 },
                statut: { not: 'annulee' }
              },
              orderBy: { id: 'asc' }, // Plus ancienne en premier (ordre d'insertion)
              select: {
                id: true,
                numeroVente: true,
                montantTotal: true,
                montantPaye: true,
                montantRestant: true,
                dateVente: true
              }
            });

            console.log('=== DISTRIBUTION DU PAIEMENT (COMMANDE PRIORITAIRE) ===');
            console.log(`Ventes impayées trouvées: ${ventesImpayees.length}`);
            console.log(`Montant nouvelle commande: ${montantVenteNet} FCFA`);
            console.log(`Montant versé total: ${montantVerse} FCFA`);
            
            const transactionsCreees = [];

            // Étape 1: Payer d'abord la nouvelle commande (PRIORITAIRE)
            const montantPourNouvelleVente = Math.min(montantVerse, montantVenteNet);
            let montantRestantADistribuer = montantVerse - montantPourNouvelleVente;

            console.log(`📝 Paiement nouvelle vente ${numeroVente}: ${montantPourNouvelleVente} FCFA`);
            
            if (montantPourNouvelleVente > 0) {
              transactionsCreees.push({
                type: montantPourNouvelleVente >= montantVenteNet ? 'paiement_comptant' : 'paiement',
                montant: montantPourNouvelleVente,
                venteId: nouvelleVente.id,
                venteReference: numeroVente,
                description: `Paiement de ${montantPourNouvelleVente} FCFA pour vente ${numeroVente}`
              });
            }

            // Étape 2: Distribuer l'excédent sur les anciennes dettes (de la plus ancienne à la plus récente)
            if (montantRestantADistribuer > 0) {
              console.log(`💰 Excédent à distribuer sur anciennes dettes: ${montantRestantADistribuer} FCFA`);
              
              for (const venteImpayee of ventesImpayees) {
                if (montantRestantADistribuer <= 0) break;

                const montantARembourser = Math.min(montantRestantADistribuer, venteImpayee.montantRestant);
                
                console.log(`📝 Remboursement vente ${venteImpayee.numeroVente}:`);
                console.log(`   Dette: ${venteImpayee.montantRestant} FCFA`);
                console.log(`   Montant remboursé: ${montantARembourser} FCFA`);

                // Mettre à jour la vente
                await tx.vente.update({
                  where: { id: venteImpayee.id },
                  data: {
                    montantPaye: venteImpayee.montantPaye + montantARembourser,
                    montantRestant: venteImpayee.montantRestant - montantARembourser
                  }
                });

                transactionsCreees.push({
                  type: 'paiement_dette',
                  montant: montantARembourser,
                  venteId: venteImpayee.id,
                  venteReference: venteImpayee.numeroVente,
                  description: `Paiement de ${montantARembourser} FCFA pour vente ${venteImpayee.numeroVente} (dette)`
                });

                montantRestantADistribuer -= montantARembourser;
              }
            }

            // Calculer le nouveau solde du compte
            // CORRECTION: La monnaie à rendre ne doit PAS être enregistrée comme crédit client
            // Solde négatif = Dette client (montant dû par le client)
            // Solde positif = Crédit client (montant dû au client - SEULEMENT si paiement volontaire en excès)
            // Si montantVerse > montantTotalAPayer, c'est de la monnaie à rendre, PAS un crédit
            
            let nouveauSolde;
            if (montantRestantADistribuer > 0) {
              // Il reste de l'argent après paiement de toutes les dettes
              // C'est de la MONNAIE À RENDRE, pas un crédit client
              // Le solde reste 0 (ou le solde précédent s'il y en avait un)
              nouveauSolde = 0;
              console.log(`💵 Monnaie à rendre au client: ${montantRestantADistribuer} FCFA`);
            } else {
              // Le client a payé exactement ou moins que le total
              // Calculer le solde réel: montantVerse - montantTotalAPayer
              nouveauSolde = montantVerse - montantTotalAPayer;
            }
            
            const compteClientUpdated = await tx.compteClient.upsert({
              where: { clientId },
              create: {
                clientId,
                soldeActuel: nouveauSolde,
                limiteCredit: 0
              },
              update: {
                soldeActuel: nouveauSolde
              }
            });

            console.log('=== CRÉATION DES TRANSACTIONS ===');
            console.log(`Dette précédente: ${dettePrecedente} FCFA`);
            console.log(`Montant vente: ${montantVenteNet} FCFA`);
            console.log(`Montant versé: ${montantVerse} FCFA`);
            console.log(`Nouveau solde: ${nouveauSolde} FCFA`);
            console.log(`Compte client ID: ${compteClientUpdated.id}`);
            
            // Transaction 1: Achat (débit) - Pour la nouvelle vente
            console.log(`✅ Création transaction ACHAT: -${montantVenteNet} FCFA`);
            
            const achatTx = await tx.transactionCompte.create({
              data: {
                typeCompte: 'client',
                compteId: compteClientUpdated.id,
                typeTransaction: 'achat_credit',
                typeTransactionDetail: montantPourNouvelleVente >= montantVenteNet ? 'achat_comptant' : 'achat_credit',
                montant: montantVenteNet,
                description: `Achat ${montantPourNouvelleVente >= montantVenteNet ? 'comptant' : 'à crédit'} - Vente ${numeroVente}`,
                referenceType: 'vente',
                referenceId: nouvelleVente.id,
                venteId: nouvelleVente.id,
                venteReference: numeroVente,
                soldeApres: nouveauSolde
              }
            });

            // Transactions 2+: Paiements distribués
            const createdTransactionIds = [achatTx.id];
            for (const transaction of transactionsCreees) {
              console.log(`✅ Création transaction ${transaction.type.toUpperCase()}: +${transaction.montant} FCFA`);
              
              const createdTx = await tx.transactionCompte.create({
                data: {
                  typeCompte: 'client',
                  compteId: compteClientUpdated.id,
                  typeTransaction: 'paiement',
                  typeTransactionDetail: transaction.type,
                  montant: transaction.montant,
                  description: transaction.description,
                  referenceType: 'vente',
                  referenceId: transaction.venteId,
                  venteId: transaction.venteId,
                  venteReference: transaction.venteReference,
                  soldeApres: nouveauSolde
                }
              });
              createdTransactionIds.push(createdTx.id);
            }
            
            console.log('=== FIN CRÉATION TRANSACTIONS ===');

            // Afficher le statut du compte
            if (nouveauSolde < 0) {
              console.log(`⚠️ Dette restante pour le client: ${Math.abs(nouveauSolde)} FCFA`);
            } else if (nouveauSolde > 0) {
              console.log(`✅ Crédit positif pour le client: ${nouveauSolde} FCFA`);
            } else {
              console.log(`✅ Compte soldé (solde = 0)`);
            }

            // Stocker pour sync après transaction
            compteClientToSync = compteClientUpdated;
          }

          // CORRECTION: Créer un mouvement de caisse pour traçabilité (DANS la transaction)
          let cashMovementCreated = null;
          if (sessionId && montantVerse > 0) {
            const clientInfo = nouvelleVente.client;
            cashMovementCreated = await tx.cashMovement.create({
              data: {
                caisseId: activeSession.caisseId,
                sessionId: sessionId,
                boutiqueId: activeSession.boutiqueId || null,
                type: 'vente',
                montant: montantVerse,
                description: `Vente ${nouvelleVente.numeroVente}${clientInfo ? ` - Client: ${clientInfo.nom} ${clientInfo.prenom || ''}` : ''}`,
                utilisateurId: req.user?.id || null,
                metadata: JSON.stringify({
                  categorie: 'vente',
                  referenceType: 'vente',
                  referenceId: nouvelleVente.id,
                  venteReference: nouvelleVente.numeroVente,
                  clientId: clientInfo?.id || null,
                  clientNom: clientInfo ? `${clientInfo.nom} ${clientInfo.prenom || ''}` : null,
                  montantTotal: montantVenteNet,
                  montantVerse: montantVerse,
                  montantRestant: montantRestant
                })
              }
            });
            console.log(`✅ Mouvement de caisse créé pour la vente (${montantVerse} FCFA)`);
          }

          return { vente: nouvelleVente, cashMovement: cashMovementCreated, compteClient: compteClientToSync, transactionIds: createdTransactionIds };
        }, {
          timeout: 15000 // Augmenter le timeout à 15 secondes pour les transactions complexes
        });

        const vente = result.vente;

        // Synchroniser manuellement les mouvements de stock et stock_boutiques vers Neon
        // (Les extensions Prisma ne s'appliquent pas aux transactions)
        // IMPORTANT: Exécuter de manière asynchrone pour ne pas bloquer la réponse
        if (process.env.CLOUD_DB_URL) {
          // Utiliser setImmediate pour exécuter la sync APRÈS avoir renvoyé la réponse
          setImmediate(async () => {
            try {
              console.log('🔧 [Sync] Début de la synchronisation manuelle...');
              console.log('🔧 [Sync] Nombre de détails à synchroniser:', details.length);
              const syncSvc = syncService || require('../services/sync-service');
              
              // Synchroniser le cash_movement si créé
              if (result.cashMovement) {
                try {
                  await syncSvc.enqueue('cash_movements', 'INSERT', result.cashMovement);
                  console.log(`✅ [Manual Sync] Cash movement synchronisé: ${result.cashMovement.id}`);
                } catch (syncError) {
                  console.error('❌ Erreur sync cash_movement:', syncError.message);
                }
              }

              // Synchroniser le compte client si mis à jour
              if (result.compteClient) {
                try {
                  await syncSvc.enqueue('comptes_clients', 'UPDATE', result.compteClient);
                  console.log(`✅ [Manual Sync] Compte client synchronisé: ${result.compteClient.id}`);
                } catch (syncError) {
                  console.error('❌ Erreur sync compte client:', syncError.message);
                }
              }

              // Synchroniser les transactions de compte créées
              if (result.compteClient && result.transactionIds?.length > 0) {
                try {
                  const txComptes = await prisma.transactionCompte.findMany({
                    where: { id: { in: result.transactionIds } }
                  });
                  for (const txC of txComptes) {
                    await syncSvc.enqueue('transactions_comptes', 'INSERT', txC);
                  }
                  console.log(`✅ [Manual Sync] ${txComptes.length} transaction(s) compte synchronisée(s)`);
                } catch (syncError) {
                  console.error('❌ Erreur sync transactions_comptes:', syncError.message);
                }
              }
              
              // IMPORTANT: Synchroniser d'abord la vente principale
              try {
                await syncSvc.enqueue('ventes', 'INSERT', {
                  id: vente.id,
                  numero_vente: vente.numeroVente,
                  client_id: vente.clientId,
                  sous_total: vente.sousTotal,
                  montant_remise: vente.montantRemise,
                  montant_tva: vente.montantTva,
                  taux_tva: vente.tauxTva,
                  montant_total: vente.montantTotal,
                  montant_paye: vente.montantPaye,
                  montant_restant: vente.montantRestant,
                  statut: vente.statut,
                  date_vente: vente.dateVente,
                  boutique_id: boutiqueId ? parseInt(boutiqueId) : null,
                  vendeur_id: vente.utilisateurId,
                  session_id: vente.sessionId,
                  mode_paiement: vente.modePaiement,
                });
                console.log(`✅ [Manual Sync] Vente principale synchronisée: ${vente.id}`);
              } catch (syncError) {
                console.error('❌ Erreur sync vente principale:', syncError.message);
              }

              // IMPORTANT: Synchroniser les détails de vente
              try {
                for (const detail of vente.details) {
                  await syncSvc.enqueue('details_ventes', 'INSERT', {
                    id: detail.id,
                    vente_id: detail.venteId,
                    produit_id: detail.produitId,
                    quantite: detail.quantite,
                    prix_unitaire: detail.prixUnitaire,
                    prix_affiche: detail.prixAffiche,
                    remise_appliquee: detail.remiseAppliquee,
                    justification_remise: detail.justificationRemise,
                    prix_total: detail.prixTotal,
                  });
                  console.log(`✅ [Manual Sync] Détail de vente synchronisé: ${detail.id} (produit ${detail.produitId})`);
                }
              } catch (syncError) {
                console.error('❌ Erreur sync détails vente:', syncError.message);
              }
              
              // Synchroniser les mouvements de stock créés
              for (const detail of details) {
                console.log(`🔧 [Sync] Traitement produit ${detail.produitId}, type: ${detail.type}`);
                if (detail.type !== 'service') {
              try {
                // Récupérer le mouvement de stock créé
                const mouvement = await prisma.mouvementStock.findFirst({
                  where: {
                    produitId: detail.produitId,
                    referenceId: vente.id,
                    typeReference: 'vente'
                  },
                  orderBy: { id: 'desc' } // Utiliser id au lieu de dateModification
                });
                
                if (mouvement) {
                  console.log(`🔄 [Manual Sync] mouvements_stock trouvé: ${mouvement.id}`);
                  await syncSvc.enqueue('mouvements_stock', 'INSERT', {
                    id: mouvement.id,
                    produit_id: mouvement.produitId,
                    boutique_id: mouvement.boutiqueId,
                    type_mouvement: mouvement.typeMouvement,
                    changement_quantite: mouvement.changementQuantite,
                    stock_initial: mouvement.stockInitial,
                    stock_final: mouvement.stockFinal,
                    reference_id: mouvement.referenceId,
                    type_reference: mouvement.typeReference,
                    date_mouvement: mouvement.dateMouvement,
                    notes: mouvement.notes
                  });
                  
                  console.log(`✅ [Manual Sync] mouvements_stock synchronisé: ${mouvement.id}`);
                } else {
                  console.log(`⚠️  [Manual Sync] Mouvement de stock non trouvé pour produit ${detail.produitId}`);
                }
                
                // Synchroniser le stock_boutiques mis à jour
                if (boutiqueId) {
                  const stockBoutique = await prisma.stockBoutique.findUnique({
                    where: {
                      boutiqueId_produitId: {
                        boutiqueId: parseInt(boutiqueId),
                        produitId: detail.produitId
                      }
                    }
                  });
                  
                  if (stockBoutique) {
                    console.log(`🔄 [Manual Sync] stock_boutiques trouvé: ${stockBoutique.id}`);
                    await syncSvc.enqueue('stock_boutiques', 'UPDATE', {
                      id: stockBoutique.id,
                      boutique_id: stockBoutique.boutiqueId,
                      produit_id: stockBoutique.produitId,
                      quantite_disponible: stockBoutique.quantiteDisponible,
                      quantite_reservee: stockBoutique.quantiteReservee,
                      derniere_maj: stockBoutique.derniereMaj,
                      date_modification: stockBoutique.dateModification
                    });
                    
                    console.log(`✅ [Manual Sync] stock_boutiques synchronisé: ${stockBoutique.id}`);
                  } else {
                    console.log(`⚠️  [Manual Sync] stock_boutiques non trouvé pour produit ${detail.produitId}`);
                  }
                } else {
                  // Synchroniser le stock global
                  const stock = await prisma.stock.findUnique({
                    where: { produitId: detail.produitId }
                  });
                  
                  if (stock) {
                    await syncSvc.enqueue('stock', 'UPDATE', {
                      id: stock.id,
                      produit_id: stock.produitId,
                      quantite_disponible: stock.quantiteDisponible,
                      quantite_reservee: stock.quantiteReservee,
                      derniere_maj: stock.derniereMaj,
                      date_modification: stock.dateModification
                    });
                    
                    console.log(`✅ [Manual Sync] stock synchronisé: ${stock.id}`);
                  } else {
                    console.log(`⚠️  [Manual Sync] stock non trouvé pour produit ${detail.produitId}`);
                  }
                }
              } catch (syncError) {
                console.error('❌ Erreur sync manuelle:', syncError.message);
                console.error('   Stack:', syncError.stack);
                // Ne pas bloquer la vente si la sync échoue
              }
            }
          }
          console.log('✅ [Sync] Synchronisation manuelle terminée');
            } catch (error) {
              console.error('❌ Erreur sync manuelle globale:', error.message);
            }
          });
        } else {
          console.log('ℹ️  [Sync] CLOUD_DB_URL non défini, sync manuelle ignorée');
        }

        // Mettre à jour le solde attendu de la session de caisse active
        try {
          const boutiqueIdForSession = boutiqueId ? parseInt(boutiqueId) : null;
          const sessionWhere = {
            utilisateurId: req.user.id,
            isActive: true,
            dateFermeture: null
          };
          if (boutiqueIdForSession) sessionWhere.boutiqueId = boutiqueIdForSession;

          const activeSession = await prisma.cashSession.findFirst({
            where: sessionWhere
          });

          if (activeSession) {
            const currentSoldeAttendu = activeSession.soldeAttendu ? parseFloat(activeSession.soldeAttendu) : parseFloat(activeSession.soldeOuverture);
            const newSoldeAttendu = currentSoldeAttendu + montantVerse; // Ajouter le montant payé

            await prisma.cashSession.update({
              where: { id: activeSession.id },
              data: {
                soldeAttendu: newSoldeAttendu
              }
            });

            console.log(`💰 Session de caisse mise à jour:`);
            console.log(`   Solde attendu avant: ${currentSoldeAttendu} FCFA`);
            console.log(`   Montant vente: +${montantVerse} FCFA`);
            console.log(`   Solde attendu après: ${newSoldeAttendu} FCFA`);

            // CORRECTION: Mettre à jour aussi le solde de la caisse (pas seulement la session)
            console.log(`💰 Mise à jour atomique du solde de la caisse (ID: ${activeSession.caisseId})`);
            const caisseUpdated = await prisma.cashRegister.update({
              where: { id: activeSession.caisseId },
              data: {
                soldeActuel: {
                  increment: montantVerse
                }
              }
            });
            console.log(`✅ Solde caisse mis à jour: ${caisseUpdated.soldeActuel} FCFA`);

            // Sync cash_session et cash_register vers Neon
            try {
              const syncSvc = syncService || require('../services/sync-service');
              const updatedSession = await prisma.cashSession.findUnique({ where: { id: activeSession.id } });
              if (updatedSession) {
                await syncSvc.enqueue('cash_sessions', 'UPDATE', {
                  id: updatedSession.id,
                  caisse_id: updatedSession.caisseId,
                  utilisateur_id: updatedSession.utilisateurId,
                  boutique_id: updatedSession.boutiqueId,
                  solde_ouverture: updatedSession.soldeOuverture,
                  solde_attendu: updatedSession.soldeAttendu,
                  solde_fermeture: updatedSession.soldeFermeture,
                  ecart: updatedSession.ecart,
                  date_ouverture: updatedSession.dateOuverture,
                  date_fermeture: updatedSession.dateFermeture,
                  is_active: updatedSession.isActive,
                });
              }
              await syncSvc.enqueue('cash_registers', 'UPDATE', caisseUpdated);
            } catch (syncErr) {
              console.warn('⚠️ Erreur sync session/caisse après vente:', syncErr.message);
            }
          }
        } catch (error) {
          console.error('⚠️ Erreur lors de la mise à jour de la session de caisse:', error);
          // Ne pas bloquer la vente si la mise à jour de la session échoue
        }

        // Préparer les informations de paiement pour le frontend
        const paiementInfo = {
          modeDeTermine,
          montantVente: montantVenteNet,
          dettePrecedente,
          montantTotalAPayer,
          montantVerse,
          montantRestant,
          monnaieARendre
        };

        res.status(201).json({
          success: true,
          message: 'Vente créée avec succès',
          data: vente,
          paiement: paiementInfo
        });
      } catch (error) {
        console.error('Erreur lors de la création de la vente:', error);
        res.status(400).json({
          success: false,
          message: error.message || 'Erreur lors de la création de la vente'
        });
      }
    }
  ); 
 /**
   * PUT /sales/:id
   * Mettre à jour une vente (statut uniquement)
   */
  router.put('/:id',
    validateId,
    validate(venteSchemas.update, 'body'),
    async (req, res) => {
      try {
        const { id } = req.params;
        const updateData = req.body;

        const vente = await prisma.vente.findUnique({
          where: { id: parseInt(id) }
        });

        if (!vente) {
          return res.status(404).json({
            success: false,
            message: 'Vente non trouvée'
          });
        }

        if (vente.statut === 'annulee') {
          return res.status(400).json({
            success: false,
            message: 'Impossible de modifier une vente annulée'
          });
        }

        const venteModifiee = await prisma.vente.update({
          where: { id: parseInt(id) },
          data: updateData,
          include: {
            client: true,
            details: {
              include: {
                produit: {
                  select: { id: true, nom: true, reference: true }
                }
              }
            }
          }
        });

        res.json({
          success: true,
          message: 'Vente modifiée avec succès',
          data: venteModifiee
        });
      } catch (error) {
        console.error('Erreur lors de la modification de la vente:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la modification de la vente'
        });
      }
    }
  );

  /**
   * POST /sales/:id/payment
   * Enregistrer un paiement pour une vente à crédit
   */
  router.post('/:id/payment',
    validateId,
    validate(venteSchemas.paiement, 'body'),
    async (req, res) => {
      try {
        const { id } = req.params;
        const { montantPaye, description } = req.body;

        const vente = await prisma.vente.findUnique({
          where: { id: parseInt(id) },
          include: { client: true }
        });

        if (!vente) {
          return res.status(404).json({
            success: false,
            message: 'Vente non trouvée'
          });
        }

        if (vente.statut === 'annulee') {
          return res.status(400).json({
            success: false,
            message: 'Impossible d\'enregistrer un paiement pour une vente annulée'
          });
        }

        if (vente.montantRestant <= 0) {
          return res.status(400).json({
            success: false,
            message: 'Cette vente est déjà entièrement payée'
          });
        }

        if (montantPaye > vente.montantRestant) {
          return res.status(400).json({
            success: false,
            message: `Le montant payé (${montantPaye}) ne peut pas dépasser le montant restant (${vente.montantRestant})`
          });
        }

        const result = await prisma.$transaction(async (tx) => {
          // Mettre à jour la vente
          const venteModifiee = await tx.vente.update({
            where: { id: parseInt(id) },
            data: {
              montantPaye: vente.montantPaye + montantPaye,
              montantRestant: vente.montantRestant - montantPaye
            }
          });

          // Si la vente a un client, mettre à jour son compte
          if (vente.clientId) {
            await tx.compteClient.update({
              where: { clientId: vente.clientId },
              data: {
                soldeActuel: {
                  increment: montantPaye
                }
              }
            });

            // Créer la transaction de paiement
            const compteApres = await tx.compteClient.findUnique({
              where: { clientId: vente.clientId }
            });
            
            await tx.transactionCompte.create({
              data: {
                typeCompte: 'client',
                compteId: compteApres.id, // CORRECTION: Utiliser l'ID du compte, pas l'ID du client
                typeTransaction: 'paiement',
                montant: montantPaye,
                description: description || `Paiement vente ${vente.numeroVente}`,
                referenceType: 'vente',
                referenceId: parseInt(id),
                soldeApres: (compteApres?.soldeActuel || 0) + montantPaye
              }
            });
          }

          return venteModifiee;
        });

        res.json({
          success: true,
          message: 'Paiement enregistré avec succès',
          data: result
        });
      } catch (error) {
        console.error('Erreur lors de l\'enregistrement du paiement:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de l\'enregistrement du paiement'
        });
      }
    }
  );

  /**
   * DELETE /sales/:id
   * Annuler une vente (restaurer le stock, déduire de la session de caisse, exclure de la comptabilité)
   */
  router.delete('/:id',
    validateId,
    async (req, res) => {
      try {
        const { id } = req.params;

        const vente = await prisma.vente.findUnique({
          where: { id: parseInt(id) },
          include: {
            details: true,
            client: true,
            session: true
          }
        });

        if (!vente) {
          return res.status(404).json({
            success: false,
            message: 'Vente non trouvée'
          });
        }

        if (vente.statut === 'annulee') {
          return res.status(400).json({
            success: false,
            message: 'Cette vente est déjà annulée'
          });
        }

        console.log(`🔄 Annulation de la vente ${vente.numeroVente}`);
        console.log(`   - Montant: ${vente.montantTotal} FCFA`);
        console.log(`   - Montant payé: ${vente.montantPaye} FCFA`);
        console.log(`   - Session ID: ${vente.sessionId}`);

        const result = await prisma.$transaction(async (tx) => {
          // Marquer la vente comme annulée
          const venteAnnulee = await tx.vente.update({
            where: { id: parseInt(id) },
            data: { statut: 'annulee' }
          });

          // Restaurer le stock pour les produits physiques uniquement
          for (const detail of vente.details) {
            const produit = await tx.produit.findUnique({
              where: { id: detail.produitId },
              select: { estService: true }
            });

            if (produit?.estService) {
              console.log(`Service annulé: ${detail.produitId} - pas de restauration de stock`);
              continue;
            }

            // 1. Récupérer le stock AVANT le mouvement
            let stockInitial = 0;
            if (vente.boutiqueId) {
              const stockBoutique = await tx.stockBoutique.findUnique({
                where: { boutiqueId_produitId: { boutiqueId: vente.boutiqueId, produitId: detail.produitId } }
              });
              stockInitial = stockBoutique?.quantiteDisponible || 0;
              if (stockBoutique) {
                await tx.stockBoutique.update({
                  where: { id: stockBoutique.id },
                  data: { quantiteDisponible: { increment: detail.quantite } }
                });
              }
            } else {
              const stock = await tx.stock.findUnique({
                where: { produitId: detail.produitId }
              });
              stockInitial = stock?.quantiteDisponible || 0;
              await tx.stock.update({
                where: { produitId: detail.produitId },
                data: { quantiteDisponible: { increment: detail.quantite } }
              });
            }

            // 2. Calculer le stock APRÈS le mouvement
            const stockFinal = stockInitial + detail.quantite;

            // Créer le mouvement de stock d'annulation avec snapshots
            await tx.mouvementStock.create({
              data: {
                produitId: detail.produitId,
                boutiqueId: vente.boutiqueId || null,
                typeMouvement: 'retour',
                changementQuantite: detail.quantite,
                stockInitial,
                stockFinal,
                notes: `Annulation vente ${vente.numeroVente}`,
                referenceId: parseInt(id),
                typeReference: 'vente_annulee'
              }
            });
          }

          // CORRECTION 1 : restituer le montant payé au client dans la caisse.
          //
          // Imputé à la session OUVERTE au moment de l'annulation, jamais à
          // vente.sessionId (la session d'origine, parfois clôturée depuis).
          // Rouvrir une session déjà clôturée reviendrait à modifier un écart
          // de caisse déjà validé par le caissier — un état arrêté ne se
          // corrige pas rétroactivement, on compense dans la période courante.
          let cancelMovementCreated = null;
          let sessionCorrigee = null;
          if (vente.montantPaye > 0) {
            const sessionOuverte = await tx.cashSession.findFirst({
              where: {
                isActive: true,
                dateFermeture: null,
                ...(vente.boutiqueId ? { boutiqueId: vente.boutiqueId } : {})
              },
              orderBy: { id: 'desc' }
            });

            if (!sessionOuverte) {
              throw new Error(
                'Aucune caisse ouverte : ouvrez une session pour enregistrer le remboursement de cette annulation'
              );
            }

            const surSessionOrigine = sessionOuverte.id === vente.sessionId;
            console.log(`💰 Remboursement de ${vente.montantPaye} FCFA sur la session ${sessionOuverte.id}` +
              (surSessionOrigine ? '' : ` (session d'origine ${vente.sessionId} clôturée)`));

            // Montant NÉGATIF : une vente comptant avait fait ENTRER l'argent
            // en caisse ; l'annuler consiste à rembourser le client, donc à le
            // faire SORTIR. (Sens inverse d'une annulation de dépense, où
            // l'argent revient en caisse.)
            cancelMovementCreated = await tx.cashMovement.create({
              data: {
                caisseId: sessionOuverte.caisseId,
                sessionId: sessionOuverte.id,
                boutiqueId: sessionOuverte.boutiqueId || vente.boutiqueId || null,
                type: 'annulation_vente',
                montant: -vente.montantPaye,
                description: `Annulation vente ${vente.numeroVente}`,
                utilisateurId: req.user?.id || null,
                metadata: JSON.stringify({
                  categorie: 'annulation_vente',
                  referenceType: 'vente_annulee',
                  referenceId: parseInt(id),
                  venteReference: vente.numeroVente,
                  montantOriginal: vente.montantPaye,
                  sessionOrigine: vente.sessionId,
                  imputeSurSessionCourante: !surSessionOrigine
                })
              }
            });

            const soldeCourant = sessionOuverte.soldeAttendu != null
              ? sessionOuverte.soldeAttendu
              : sessionOuverte.soldeOuverture;
            const nouveauSoldeAttendu = soldeCourant - vente.montantPaye;

            sessionCorrigee = await tx.cashSession.update({
              where: { id: sessionOuverte.id },
              data: { soldeAttendu: nouveauSoldeAttendu }
            });

            await tx.cashRegister.update({
              where: { id: sessionOuverte.caisseId },
              data: { soldeActuel: { decrement: vente.montantPaye } }
            });

            console.log(`✅ Solde attendu de la session ${sessionOuverte.id}: ${nouveauSoldeAttendu} FCFA`);
          }

          // CORRECTION 2: Supprimer les mouvements financiers liés à cette vente
          // pour l'exclure de la comptabilité
          const mouvementsFinanciers = await tx.financialMovement.findMany({
            where: {
              OR: [
                { reference: { contains: `VENTE-${vente.numeroVente}` } },
                { description: { contains: vente.numeroVente } }
              ]
            }
          });

          if (mouvementsFinanciers.length > 0) {
            console.log(`🗑️ Suppression de ${mouvementsFinanciers.length} mouvement(s) financier(s)`);
            
            for (const mouvement of mouvementsFinanciers) {
              // Supprimer les pièces jointes d'abord
              await tx.movementAttachment.deleteMany({
                where: { mouvementId: mouvement.id }
              });

              // Supprimer le mouvement financier
              await tx.financialMovement.delete({
                where: { id: mouvement.id }
              });
            }
          }

          // Annuler la DETTE créée par cette vente — et elle seule.
          //
          // Seule la part non payée (montantRestant) a été portée au débit du
          // client à la création. Créditer le montant total, comme le faisait
          // l'ancien code, fabriquait un avoir fictif sur les ventes réglées
          // comptant : un client ayant tout payé se retrouvait créditeur du
          // montant de la vente annulée.
          let compteClientAnnulation = null;
          const detteAAnnuler = vente.montantRestant || 0;

          if (vente.clientId && detteAAnnuler > 0) {
            console.log(`👤 Annulation de la dette client ${vente.clientId} : ${detteAAnnuler} FCFA`);

            const compteClient = await tx.compteClient.findUnique({
              where: { clientId: vente.clientId }
            });

            if (compteClient) {
              // Le solde est négatif lorsqu'il y a dette : on la résorbe
              const nouveauSolde = compteClient.soldeActuel + detteAAnnuler;

              compteClientAnnulation = await tx.compteClient.update({
                where: { clientId: vente.clientId },
                data: { soldeActuel: nouveauSolde }
              });

              console.log(`   Solde: ${compteClient.soldeActuel} -> ${nouveauSolde} FCFA`);

              // Écriture de contre-passation. L'historique des paiements est
              // CONSERVÉ : l'ancien code supprimait toutes les transactions
              // portant ce referenceId — y compris celle-ci, créée juste avant,
              // ce qui effaçait la trace de l'annulation elle-même.
              await tx.transactionCompte.create({
                data: {
                  typeCompte: 'client',
                  compteId: compteClient.id,
                  typeTransaction: 'annulation',
                  typeTransactionDetail: 'annulation_vente',
                  montant: detteAAnnuler,
                  description: `Annulation vente ${vente.numeroVente}`,
                  referenceType: 'vente_annulee',
                  referenceId: parseInt(id),
                  venteId: parseInt(id),
                  venteReference: vente.numeroVente,
                  soldeApres: nouveauSolde
                }
              });
            }
          } else if (vente.clientId) {
            console.log(`👤 Vente réglée intégralement : aucune dette à annuler, compte client inchangé`);
          }

          return {
            updatedVente: venteAnnulee,
            cancelMovement: cancelMovementCreated,
            sessionCorrigee,
            compteClient: compteClientAnnulation
          };
        });

        const updatedVente = result.updatedVente;

        // Sync cash_movement + session corrigée si un remboursement a eu lieu
        if (result.cancelMovement && syncService) {
          setImmediate(async () => {
            try {
              const syncSvc = syncService || require('../services/sync-service');
              await syncSvc.enqueue('cash_movements', 'INSERT', result.cancelMovement);
              if (result.sessionCorrigee) {
                await syncSvc.enqueue('cash_sessions', 'UPDATE', result.sessionCorrigee);
                const caisseMaj = await prisma.cashRegister.findUnique({
                  where: { id: result.cancelMovement.caisseId }
                });
                if (caisseMaj) await syncSvc.enqueue('cash_registers', 'UPDATE', caisseMaj);
              }
              console.log(`✅ [Cancel Sync] Remboursement d'annulation synchronisé: ${result.cancelMovement.id}`);
            } catch (syncError) {
              console.error('❌ Erreur sync cash_movement annulation:', syncError.message);
            }
          });
        }

        if (result.compteClient && syncService) {
          setImmediate(async () => {
            try {
              const syncSvc = syncService || require('../services/sync-service');
              await syncSvc.enqueue('comptes_clients', 'UPDATE', result.compteClient);
              console.log(`✅ [Cancel Sync] Compte client synchronisé après annulation: ${result.compteClient.id}`);
            } catch (syncError) {
              console.error('❌ Erreur sync compte client annulation:', syncError.message);
            }
          });
        }

        // L'annulation est un changement de statut, pas une suppression.
        // La réponse ne portant pas de données, le middleware de sync ne peut
        // rien intercepter : sans cet appel, la vente resterait « terminée »
        // dans Neon et sur tous les autres postes.
        try {
          const syncSvc = syncService || require('../services/sync-service');
          if (syncSvc && updatedVente) {
            await syncSvc.enqueue('ventes', 'UPDATE', updatedVente, req.user?.id);
          }
        } catch (syncErr) {
          console.warn('⚠️  Sync annulation vente:', syncErr.message);
        }

        const message = result.sessionCorrigee && result.sessionCorrigee.id !== updatedVente.sessionId
          ? `Vente annulée — ${vente.montantPaye} FCFA remboursés depuis la caisse ouverte (la session d'origine était clôturée)`
          : 'Vente annulée avec succès - montant remboursé depuis la session de caisse';

        res.json({ success: true, message });
      } catch (error) {
        console.error('Erreur lors de l\'annulation de la vente:', error);

        if (error.message?.includes('Aucune caisse ouverte')) {
          return res.status(409).json({ success: false, message: error.message });
        }

        res.status(500).json({
          success: false,
          message: 'Erreur lors de l\'annulation de la vente'
        });
      }
    }
  );

  return router;
}

module.exports = createSalesRouter;