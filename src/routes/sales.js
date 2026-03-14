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

function createSalesRouter({ prisma, authService }) {
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
        const { page = 1, limit = 20, ...searchParams } = req.query;
        const skip = (page - 1) * limit;

        const conditions = buildSalesSearchConditions(searchParams);

        const [ventes, total] = await Promise.all([
          prisma.vente.findMany({
            where: conditions,
            include: {
              client: {
                select: { id: true, nom: true, prenom: true }
              },
              details: {
                include: {
                  produit: {
                    select: { id: true, nom: true, reference: true }
                  }
                }
              }
            },
            orderBy: { dateVente: 'desc' },
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
      } catch (error) {
        console.error('Erreur lors de la récupération des ventes:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la récupération des ventes'
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
        const { clientId, modePaiement, montantRemise, montantPaye, details, dateVente } = req.body;

        // DEBUG: Log des données reçues
        console.log('📥 Données reçues pour création vente:');
        console.log(`   - clientId: ${clientId}`);
        console.log(`   - modePaiement: ${modePaiement}`);
        console.log(`   - montantRemise: ${montantRemise}`);
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
            const stock = await prisma.stock.findUnique({
              where: { produitId: detail.produitId },
              include: { produit: { select: { nom: true, reference: true } } }
            });

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

        // Si un client est sélectionné, vérifier son crédit existant
        let dettePrecedente = 0;
        let montantTotalAPayer = montantVenteNet;

        if (clientId) {
          const compteClient = await prisma.compteClient.findUnique({
            where: { clientId },
            include: { client: { select: { nom: true, prenom: true } } }
          });

          if (compteClient && compteClient.soldeActuel < 0) {
            dettePrecedente = Math.abs(compteClient.soldeActuel);
            montantTotalAPayer = montantVenteNet + dettePrecedente;
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
        } else if (montantVerse >= montantVenteNet && dettePrecedente === 0) {
          // Pas de dette et paiement >= commande
          modeDeTermine = 'comptant';
          monnaieARendre = montantVerse - montantVenteNet;
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
        const montantPayePourCetteVente = Math.min(montantVerse, montantVenteNet);
        console.log(`💰 Montant payé pour cette vente (reçu): ${montantPayePourCetteVente} FCFA`);

        // Générer le numéro de vente
        const numeroVente = await generateSaleNumber(prisma);

        // Créer la vente dans une transaction
        const vente = await prisma.$transaction(async (tx) => {
          // Récupérer la session active de l'utilisateur
          const activeSession = await tx.cashSession.findFirst({
            where: {
              utilisateurId: req.user?.id || 1,
              isActive: true,
              dateFermeture: null
            }
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
              clientId: clientId || null,
              sessionId: sessionId,
              modePaiement: modeDeTermine, // Mode déterminé automatiquement
              sousTotal: montantVente,
              montantRemise: montantRemise || 0,
              montantTotal: montantVenteNet, // Montant de cette vente uniquement
              montantPaye: montantPayePourCetteVente, // CORRECTION: Montant payé pour CETTE vente uniquement (pas le total avec dette)
              montantRestant: Math.max(0, montantVenteNet - montantPayePourCetteVente), // Reste pour CETTE vente uniquement
              statut: 'terminee', // Toujours "terminee" - le compte client gère les dettes
              vendeurId: req.user?.id || null,
              dateVente: dateVente ? new Date(dateVente) : new Date(), // Date personnalisée ou actuelle
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
            // Ignorer les services pour la gestion de stock
            if (isService) {
              console.log(`Service vendu: ${detail.produitId} - pas de gestion de stock`);
              continue;
            }

            await tx.stock.update({
              where: { id: stock.id },
              data: {
                quantiteDisponible: stock.quantiteDisponible - detail.quantite
              }
            });

            // Créer le mouvement de stock pour les produits physiques uniquement
            await tx.mouvementStock.create({
              data: {
                produitId: detail.produitId,
                typeMouvement: 'vente',
                changementQuantite: -detail.quantite,
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
              orderBy: { dateVente: 'asc' }, // Plus ancienne en premier
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
            // Solde = Paiements - Achats
            const nouveauSolde = montantVerse - montantTotalAPayer;
            
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
            
            await tx.transactionCompte.create({
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
            for (const transaction of transactionsCreees) {
              console.log(`✅ Création transaction ${transaction.type.toUpperCase()}: +${transaction.montant} FCFA`);
              
              await tx.transactionCompte.create({
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
          }

          // CORRECTION: Créer un mouvement de caisse pour traçabilité (DANS la transaction)
          if (sessionId && montantVerse > 0) {
            const clientInfo = nouvelleVente.client;
            await tx.cashMovement.create({
              data: {
                caisseId: activeSession.caisseId,
                sessionId: sessionId,
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

          return nouvelleVente;
        });

        // Mettre à jour le solde attendu de la session de caisse active
        try {
          const activeSession = await prisma.cashSession.findFirst({
            where: {
              utilisateurId: req.user?.id || 1,
              isActive: true,
              dateFermeture: null
            }
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

        await prisma.$transaction(async (tx) => {
          // Marquer la vente comme annulée
          await tx.vente.update({
            where: { id: parseInt(id) },
            data: { statut: 'annulee' }
          });

          // Restaurer le stock pour les produits physiques uniquement
          for (const detail of vente.details) {
            // Vérifier si c'est un service
            const produit = await tx.produit.findUnique({
              where: { id: detail.produitId },
              select: { estService: true }
            });

            // Ignorer les services pour la restauration de stock
            if (produit?.estService) {
              console.log(`Service annulé: ${detail.produitId} - pas de restauration de stock`);
              continue;
            }

            await tx.stock.update({
              where: { produitId: detail.produitId },
              data: {
                quantiteDisponible: {
                  increment: detail.quantite
                }
              }
            });

            // Créer le mouvement de stock d'annulation pour les produits physiques uniquement
            await tx.mouvementStock.create({
              data: {
                produitId: detail.produitId,
                typeMouvement: 'retour',
                changementQuantite: detail.quantite,
                notes: `Annulation vente ${vente.numeroVente}`,
                referenceId: parseInt(id),
                typeReference: 'vente_annulee'
              }
            });
          }

          // CORRECTION 1: Déduire le montant payé de la session de caisse
          if (vente.sessionId && vente.montantPaye > 0) {
            console.log(`💰 Déduction de ${vente.montantPaye} FCFA de la session ${vente.sessionId}`);
            
            // Créer un mouvement de caisse d'annulation (négatif)
            await tx.cashMovement.create({
              data: {
                caisseId: vente.session.caisseId,
                sessionId: vente.sessionId,
                type: 'annulation_vente',
                montant: -vente.montantPaye, // Montant négatif pour déduire
                description: `Annulation vente ${vente.numeroVente}`,
                utilisateurId: req.user?.id || null,
                metadata: JSON.stringify({
                  categorie: 'annulation_vente',
                  referenceType: 'vente_annulee',
                  referenceId: parseInt(id),
                  venteReference: vente.numeroVente,
                  montantOriginal: vente.montantPaye
                })
              }
            });

            // Mettre à jour le solde attendu de la session
            const session = await tx.cashSession.findUnique({
              where: { id: vente.sessionId }
            });

            if (session) {
              const nouveauSoldeAttendu = (session.soldeAttendu || 0) - vente.montantPaye;
              await tx.cashSession.update({
                where: { id: vente.sessionId },
                data: {
                  soldeAttendu: nouveauSoldeAttendu
                }
              });
              console.log(`✅ Solde attendu mis à jour: ${nouveauSoldeAttendu} FCFA`);
            }
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

          // Si vente à crédit avec client, ajuster le compte
          if (vente.clientId) {
            console.log(`👤 Ajustement du compte client ${vente.clientId}`);
            
            // Récupérer le compte client
            const compteClient = await tx.compteClient.findUnique({
              where: { clientId: vente.clientId }
            });

            if (compteClient) {
              // Annuler l'achat: ajouter le montant de la vente au solde
              // (car le solde est négatif quand il y a une dette)
              const nouveauSolde = compteClient.soldeActuel + vente.montantTotal;
              
              await tx.compteClient.update({
                where: { clientId: vente.clientId },
                data: {
                  soldeActuel: nouveauSolde
                }
              });

              console.log(`   Ancien solde: ${compteClient.soldeActuel} FCFA`);
              console.log(`   Nouveau solde: ${nouveauSolde} FCFA`);

              // Créer une transaction d'annulation
              await tx.transactionCompte.create({
                data: {
                  typeCompte: 'client',
                  compteId: compteClient.id,
                  typeTransaction: 'annulation',
                  typeTransactionDetail: 'annulation_vente',
                  montant: vente.montantTotal,
                  description: `Annulation vente ${vente.numeroVente}`,
                  referenceType: 'vente_annulee',
                  referenceId: parseInt(id),
                  venteId: parseInt(id),
                  venteReference: vente.numeroVente,
                  soldeApres: nouveauSolde
                }
              });

              // Supprimer les transactions de paiement liées à cette vente
              const transactionsVente = await tx.transactionCompte.findMany({
                where: {
                  compteId: compteClient.id,
                  referenceId: parseInt(id)
                }
              });

              if (transactionsVente.length > 0) {
                console.log(`🗑️ Suppression de ${transactionsVente.length} transaction(s) de compte`);
                await tx.transactionCompte.deleteMany({
                  where: {
                    compteId: compteClient.id,
                    referenceId: parseInt(id)
                  }
                });
              }
            }
          }
        });

        res.json({
          success: true,
          message: 'Vente annulée avec succès - montant déduit de la session de caisse et exclu de la comptabilité'
        });
      } catch (error) {
        console.error('Erreur lors de l\'annulation de la vente:', error);
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