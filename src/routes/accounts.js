/**
 * Routes pour la gestion des comptes clients et fournisseurs - LOGESCO v2
 * Endpoints pour les transactions de crédit/débit et gestion des soldes
 */

const express = require('express');
const { validate, validateId, validatePagination } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO, PaginatedResponseDTO } = require('../dto');
const { compteSchemas } = require('../validation/schemas');
const { 
  buildPrismaQuery,
  sanitizeInput 
} = require('../utils/transformers');

/**
 * Crée le routeur pour les comptes
 * @param {Object} params - Paramètres du routeur
 * @param {Object} params.prisma - Instance Prisma
 * @param {Object} params.authService - Service d'authentification
 * @returns {Object} Routeur Express
 */
function createAccountRouter({ prisma, authService, ...models }) {
  const router = express.Router();

  /**
   * GET /accounts/customers
   * Liste tous les comptes clients avec leurs soldes
   */
  router.get('/customers',
    validatePagination,
    validate(compteSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { page, limit, ...searchParams } = req.query;

        // Options de pagination
        const options = buildPrismaQuery({ page, limit });
        options.include = {
          client: {
            select: {
              id: true,
              nom: true,
              prenom: true,
              telephone: true,
              email: true
            }
          }
        };
        options.orderBy = { dateDerniereMaj: 'desc' };

        // Filtres de recherche
        if (searchParams.q) {
          options.where = {
            client: {
              OR: [
                { nom: { contains: searchParams.q } },
                { prenom: { contains: searchParams.q } },
                { telephone: { contains: searchParams.q } },
                { email: { contains: searchParams.q } }
              ]
            }
          };
        }

        // Filtres par solde
        if (searchParams.soldeMin !== undefined) {
          options.where = {
            ...options.where,
            soldeActuel: {
              ...options.where?.soldeActuel,
              gte: parseFloat(searchParams.soldeMin)
            }
          };
        }

        if (searchParams.soldeMax !== undefined) {
          options.where = {
            ...options.where,
            soldeActuel: {
              ...options.where?.soldeActuel,
              lte: parseFloat(searchParams.soldeMax)
            }
          };
        }

        const [comptes, total] = await Promise.all([
          prisma.compteClient.findMany(options),
          prisma.compteClient.count({ where: options.where })
        ]);

        // Transformer les données
        const comptesFormatted = comptes.map(compte => ({
          id: compte.id,
          clientId: compte.clientId,
          soldeActuel: parseFloat(compte.soldeActuel),
          limiteCredit: parseFloat(compte.limiteCredit),
          creditDisponible: parseFloat(compte.limiteCredit) - parseFloat(compte.soldeActuel),
          estEnDepassement: parseFloat(compte.soldeActuel) > parseFloat(compte.limiteCredit),
          dateDerniereMaj: compte.dateDerniereMaj,
          client: {
            ...compte.client,
            nomComplet: compte.client.prenom ? 
              `${compte.client.nom} ${compte.client.prenom}` : 
              compte.client.nom
          }
        }));

        const response = new PaginatedResponseDTO(
          comptesFormatted,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total
          },
          'Comptes clients récupérés avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur liste comptes clients:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des comptes clients')
        );
      }
    }
  );

  /**
   * GET /accounts/suppliers
   * Liste tous les comptes fournisseurs avec leurs soldes
   */
  router.get('/suppliers',
    validatePagination,
    validate(compteSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { page, limit, ...searchParams } = req.query;

        // Options de pagination
        const options = buildPrismaQuery({ page, limit });
        options.include = {
          fournisseur: {
            select: {
              id: true,
              nom: true,
              personneContact: true,
              telephone: true,
              email: true
            }
          }
        };
        options.orderBy = { dateDerniereMaj: 'desc' };

        // Filtres de recherche
        if (searchParams.q) {
          options.where = {
            fournisseur: {
              OR: [
                { nom: { contains: searchParams.q } },
                { personneContact: { contains: searchParams.q } },
                { telephone: { contains: searchParams.q } },
                { email: { contains: searchParams.q } }
              ]
            }
          };
        }

        // Filtres par solde
        if (searchParams.soldeMin !== undefined) {
          options.where = {
            ...options.where,
            soldeActuel: {
              ...options.where?.soldeActuel,
              gte: parseFloat(searchParams.soldeMin)
            }
          };
        }

        if (searchParams.soldeMax !== undefined) {
          options.where = {
            ...options.where,
            soldeActuel: {
              ...options.where?.soldeActuel,
              lte: parseFloat(searchParams.soldeMax)
            }
          };
        }

        const [comptes, total] = await Promise.all([
          prisma.compteFournisseur.findMany(options),
          prisma.compteFournisseur.count({ where: options.where })
        ]);

        // Transformer les données
        const comptesFormatted = comptes.map(compte => ({
          id: compte.id,
          fournisseurId: compte.fournisseurId,
          soldeActuel: parseFloat(compte.soldeActuel),
          limiteCredit: parseFloat(compte.limiteCredit),
          creditDisponible: parseFloat(compte.limiteCredit) - parseFloat(compte.soldeActuel),
          estEnDepassement: parseFloat(compte.soldeActuel) > parseFloat(compte.limiteCredit),
          dateDerniereMaj: compte.dateDerniereMaj,
          fournisseur: compte.fournisseur
        }));

        const response = new PaginatedResponseDTO(
          comptesFormatted,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total
          },
          'Comptes fournisseurs récupérés avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur liste comptes fournisseurs:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des comptes fournisseurs')
        );
      }
    }
  );

  /**
   * GET /accounts/customers/:id/balance
   * Récupère le solde d'un compte client spécifique
   */
  router.get('/customers/:id/balance',
    validateId,
    async (req, res) => {
      try {
        const clientId = parseInt(req.params.id);

        // Vérifier que le client existe
        const client = await prisma.client.findUnique({
          where: { id: clientId },
          select: {
            id: true,
            nom: true,
            prenom: true
          }
        });

        if (!client) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        // Créer le compte client s'il n'existe pas
        let compte = await prisma.compteClient.findUnique({
          where: { clientId },
          include: {
            client: {
              select: {
                id: true,
                nom: true,
                prenom: true
              }
            }
          }
        });

        if (!compte) {
          console.log(`📝 Création automatique du compte pour le client ${clientId}`);
          compte = await prisma.compteClient.create({
            data: {
              clientId,
              soldeActuel: 0,
              limiteCredit: 0
            },
            include: {
              client: {
                select: {
                  id: true,
                  nom: true,
                  prenom: true
                }
              }
            }
          });
          console.log(`✅ Compte créé avec succès (ID: ${compte.id})`);
        }

        const compteFormatted = {
          id: compte.id,
          clientId: compte.clientId,
          soldeActuel: parseFloat(compte.soldeActuel),
          limiteCredit: parseFloat(compte.limiteCredit),
          creditDisponible: parseFloat(compte.limiteCredit) - parseFloat(compte.soldeActuel),
          estEnDepassement: parseFloat(compte.soldeActuel) > parseFloat(compte.limiteCredit),
          dateDerniereMaj: compte.dateDerniereMaj,
          client: {
            ...compte.client,
            nomComplet: compte.client.prenom ? 
              `${compte.client.nom} ${compte.client.prenom}` : 
              compte.client.nom
          }
        };

        res.json(BaseResponseDTO.success(compteFormatted, 'Solde client récupéré avec succès'));

      } catch (error) {
        console.error('Erreur récupération solde client:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du solde client')
        );
      }
    }
  );

  /**
   * GET /accounts/suppliers/:id/balance
   * Récupère le solde d'un compte fournisseur spécifique
   */
  router.get('/suppliers/:id/balance',
    validateId,
    async (req, res) => {
      try {
        const fournisseurId = parseInt(req.params.id);

        const compte = await prisma.compteFournisseur.findUnique({
          where: { fournisseurId },
          include: {
            fournisseur: {
              select: {
                id: true,
                nom: true,
                personneContact: true
              }
            }
          }
        });

        if (!compte) {
          return res.status(404).json(
            BaseResponseDTO.error('Compte fournisseur non trouvé')
          );
        }

        const compteFormatted = {
          id: compte.id,
          fournisseurId: compte.fournisseurId,
          soldeActuel: parseFloat(compte.soldeActuel),
          limiteCredit: parseFloat(compte.limiteCredit),
          creditDisponible: parseFloat(compte.limiteCredit) - parseFloat(compte.soldeActuel),
          estEnDepassement: parseFloat(compte.soldeActuel) > parseFloat(compte.limiteCredit),
          dateDerniereMaj: compte.dateDerniereMaj,
          fournisseur: compte.fournisseur
        };

        res.json(BaseResponseDTO.success(compteFormatted, 'Solde fournisseur récupéré avec succès'));

      } catch (error) {
        console.error('Erreur récupération solde fournisseur:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du solde fournisseur')
        );
      }
    }
  );

  /**
   * GET /accounts/customers/:id/unpaid-sales
   * Récupère les ventes impayées d'un client
   */
  router.get('/customers/:id/unpaid-sales',
    validateId,
    async (req, res) => {
      try {
        const clientId = parseInt(req.params.id);

        // Récupérer les ventes du client avec montantRestant > 0
        const ventesImpayees = await prisma.vente.findMany({
          where: {
            clientId,
            montantRestant: { gt: 0 },
            statut: { not: 'annulee' }
          },
          select: {
            id: true,
            numeroVente: true,
            dateVente: true,
            montantTotal: true,
            montantPaye: true,
            montantRestant: true,
            details: {
              select: {
                produitId: true,
                quantite: true,
                prixUnitaire: true,
                prixTotal: true
              }
            }
          },
          orderBy: { dateVente: 'desc' }
        });

        const ventesFormatted = ventesImpayees.map(v => ({
          id: v.id,
          reference: v.numeroVente,
          dateVente: v.dateVente,
          montantTotal: parseFloat(v.montantTotal),
          montantPaye: parseFloat(v.montantPaye),
          montantRestant: parseFloat(v.montantRestant),
          nombreArticles: v.details.length
        }));

        res.json(BaseResponseDTO.success(
          ventesFormatted,
          'Ventes impayées récupérées avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération ventes impayées:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des ventes impayées')
        );
      }
    }
  );

  /**
   * POST /accounts/customers/:id/transactions
   * Crée une transaction sur un compte client (crédit/débit/paiement)
   */
  router.post('/customers/:id/transactions',
    validateId,
    validate(compteSchemas.updateSolde, 'body'),
    async (req, res) => {
      try {
        const clientId = parseInt(req.params.id);
        const { montant, typeTransaction, description, venteId, typeTransactionDetail } = req.body;

        // Vérifier que le client existe
        const client = await prisma.client.findUnique({
          where: { id: clientId }
        });

        if (!client) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        let venteReference = null;

        // Si une vente est spécifiée, récupérer sa référence et mettre à jour le paiement
        if (venteId) {
          const vente = await prisma.vente.findUnique({
            where: { id: venteId },
            select: { id: true, numeroVente: true, montantPaye: true, montantTotal: true, clientId: true }
          });

          if (!vente) {
            return res.status(404).json(BaseResponseDTO.error('Vente non trouvée'));
          }

          if (vente.clientId !== clientId) {
            return res.status(400).json(BaseResponseDTO.error('Cette vente n\'appartient pas à ce client'));
          }

          venteReference = vente.numeroVente;

          // Mettre à jour le montant payé de la vente
          if (typeTransaction === 'paiement' || typeTransaction === 'credit') {
            const nouveauMontantPaye = parseFloat(vente.montantPaye) + parseFloat(montant);
            const montantRestant = parseFloat(vente.montantTotal) - nouveauMontantPaye;

            await prisma.vente.update({
              where: { id: venteId },
              data: {
                montantPaye: nouveauMontantPaye,
                montantRestant: montantRestant > 0 ? montantRestant : 0
              }
            });
          }
        }

        // Créer ou récupérer le compte client
        let compte = await prisma.compteClient.findUnique({
          where: { clientId }
        });

        if (!compte) {
          compte = await prisma.compteClient.create({
            data: {
              clientId,
              soldeActuel: 0,
              limiteCredit: 0
            }
          });
        }

        // Calculer le nouveau solde selon le type de transaction
        let nouveauSolde = parseFloat(compte.soldeActuel);
        
        switch (typeTransaction) {
          case 'debit':
            // Augmente la dette du client
            nouveauSolde += parseFloat(montant);
            break;
          case 'credit':
          case 'paiement':
            // Diminue la dette du client
            nouveauSolde -= parseFloat(montant);
            break;
          default:
            return res.status(400).json(
              BaseResponseDTO.error('Type de transaction invalide')
            );
        }

        // S'assurer que le solde ne devient pas négatif
        if (nouveauSolde < 0) {
          nouveauSolde = 0;
        }

        // Transaction atomique pour mettre à jour le compte et créer l'historique
        const result = await prisma.$transaction(async (prisma) => {
          // Mettre à jour le compte
          const compteUpdated = await prisma.compteClient.update({
            where: { clientId },
            data: { soldeActuel: nouveauSolde },
            include: {
              client: {
                select: {
                  id: true,
                  nom: true,
                  prenom: true
                }
              }
            }
          });

          // Créer l'enregistrement de transaction
          const transaction = await prisma.transactionCompte.create({
            data: {
              typeCompte: 'client',
              compteId: compteUpdated.id,
              typeTransaction,
              typeTransactionDetail: typeTransactionDetail || typeTransaction,
              montant: parseFloat(montant),
              description: description || `Transaction ${typeTransaction}`,
              soldeApres: nouveauSolde,
              venteId: venteId || null,
              venteReference: venteReference
            }
          });

          return { compte: compteUpdated, transaction };
        });

        const compteFormatted = {
          id: result.compte.id,
          clientId: result.compte.clientId,
          soldeActuel: parseFloat(result.compte.soldeActuel),
          limiteCredit: parseFloat(result.compte.limiteCredit),
          creditDisponible: parseFloat(result.compte.limiteCredit) - parseFloat(result.compte.soldeActuel),
          estEnDepassement: parseFloat(result.compte.soldeActuel) > parseFloat(result.compte.limiteCredit),
          dateDerniereMaj: result.compte.dateDerniereMaj,
          client: {
            ...result.compte.client,
            nomComplet: result.compte.client.prenom ? 
              `${result.compte.client.nom} ${result.compte.client.prenom}` : 
              result.compte.client.nom
          },
          derniereTransaction: {
            id: result.transaction.id,
            typeTransaction: result.transaction.typeTransaction,
            montant: parseFloat(result.transaction.montant),
            description: result.transaction.description,
            dateTransaction: result.transaction.dateTransaction
          }
        };

        res.status(201).json(
          BaseResponseDTO.success(compteFormatted, 'Transaction client créée avec succès')
        );

      } catch (error) {
        console.error('Erreur création transaction client:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la création de la transaction client')
        );
      }
    }
  );

  /**
   * POST /accounts/suppliers/:id/transactions
   * Crée une transaction sur un compte fournisseur (crédit/débit/paiement)
   * Supporte la création de mouvement financier et le lien avec une commande
   */
  router.post('/suppliers/:id/transactions',
    authenticateToken(authService),
    validateId,
    validate(compteSchemas.updateSolde, 'body'),
    async (req, res) => {
      try {
        const fournisseurId = parseInt(req.params.id);
        const { 
          montant, 
          typeTransaction, 
          description,
          referenceType,
          referenceId,
          createFinancialMovement = false
        } = req.body;

        console.log('💰 Création transaction fournisseur:', {
          fournisseurId,
          montant,
          typeTransaction,
          referenceType,
          referenceId,
          createFinancialMovement
        });

        // Vérifier que le fournisseur existe
        const fournisseur = await prisma.fournisseur.findUnique({
          where: { id: fournisseurId }
        });

        if (!fournisseur) {
          return res.status(404).json(
            BaseResponseDTO.error('Fournisseur non trouvé')
          );
        }

        // Si création de mouvement financier demandée, vérifier la session de caisse
        let sessionCaisse = null;
        if (createFinancialMovement && (typeTransaction === 'paiement' || typeTransaction === 'credit')) {
          // Vérifier que l'utilisateur est authentifié
          if (!req.user || !req.user.id) {
            console.error('❌ Utilisateur non authentifié pour créer un mouvement financier');
            return res.status(401).json(
              BaseResponseDTO.error('Authentification requise pour créer un mouvement financier')
            );
          }

          // Récupérer la session de caisse active de l'utilisateur
          sessionCaisse = await prisma.cashSession.findFirst({
            where: {
              utilisateurId: req.user.id,
              isActive: true
            },
            include: {
              caisse: true
            }
          });

          if (!sessionCaisse) {
            return res.status(400).json(
              BaseResponseDTO.error('Aucune session de caisse active. Veuillez ouvrir une session de caisse.')
            );
          }

          console.log('✅ Session de caisse active trouvée:', {
            sessionId: sessionCaisse.id,
            caisseId: sessionCaisse.caisseId,
            soldeOuverture: sessionCaisse.soldeOuverture
          });
        }

        // Créer ou récupérer le compte fournisseur
        let compte = await prisma.compteFournisseur.findUnique({
          where: { fournisseurId }
        });

        if (!compte) {
          compte = await prisma.compteFournisseur.create({
            data: {
              fournisseurId,
              soldeActuel: 0,
              limiteCredit: 0
            }
          });
        }

        // Calculer le nouveau solde selon le type de transaction
        let nouveauSolde = parseFloat(compte.soldeActuel);
        
        switch (typeTransaction) {
          case 'debit':
          case 'achat':
            // Augmente la dette envers le fournisseur
            nouveauSolde += parseFloat(montant);
            break;
          case 'credit':
          case 'paiement':
            // Diminue la dette envers le fournisseur
            nouveauSolde -= parseFloat(montant);
            break;
          default:
            return res.status(400).json(
              BaseResponseDTO.error('Type de transaction invalide')
            );
        }

        // S'assurer que le solde ne devient pas négatif
        if (nouveauSolde < 0) {
          nouveauSolde = 0;
        }

        // Transaction atomique pour mettre à jour le compte, créer l'historique et le mouvement financier
        const result = await prisma.$transaction(async (prisma) => {
          // Mettre à jour le compte
          const compteUpdated = await prisma.compteFournisseur.update({
            where: { fournisseurId },
            data: { soldeActuel: nouveauSolde },
            include: {
              fournisseur: {
                select: {
                  id: true,
                  nom: true,
                  personneContact: true
                }
              }
            }
          });

          // Créer l'enregistrement de transaction
          const transaction = await prisma.transactionCompte.create({
            data: {
              typeCompte: 'fournisseur',
              compteId: compteUpdated.id,
              typeTransaction,
              montant: parseFloat(montant),
              description: description || `Transaction ${typeTransaction}`,
              soldeApres: nouveauSolde,
              referenceType: referenceType || null,
              referenceId: referenceId ? parseInt(referenceId) : null
            }
          });

          // Mettre à jour le montant payé de la commande si c'est un paiement lié à une commande
          if ((typeTransaction === 'paiement' || typeTransaction === 'credit') && 
              referenceType === 'approvisionnement' && referenceId) {
            const commande = await prisma.commandeApprovisionnement.findUnique({
              where: { id: parseInt(referenceId) },
              select: { id: true, numeroCommande: true, montantPaye: true, montantTotal: true }
            });

            if (commande) {
              const nouveauMontantPaye = parseFloat(commande.montantPaye || 0) + parseFloat(montant);
              const montantRestant = parseFloat(commande.montantTotal) - nouveauMontantPaye;

              await prisma.commandeApprovisionnement.update({
                where: { id: parseInt(referenceId) },
                data: {
                  montantPaye: nouveauMontantPaye,
                  montantRestant: montantRestant > 0 ? montantRestant : 0
                }
              });

              console.log('✅ Commande mise à jour:', {
                commandeId: referenceId,
                numeroCommande: commande.numeroCommande,
                ancienMontantPaye: parseFloat(commande.montantPaye || 0),
                nouveauMontantPaye,
                montantRestant: montantRestant > 0 ? montantRestant : 0
              });
            }
          }

          let mouvementFinancier = null;
          let mouvementFinancierRecord = null;

          // Créer le mouvement financier si demandé
          if (createFinancialMovement && sessionCaisse) {
            console.log('💸 Création du mouvement de caisse...');

            // Créer le mouvement de caisse
            mouvementFinancier = await prisma.cashMovement.create({
              data: {
                caisseId: sessionCaisse.caisseId,
                type: 'sortie',
                montant: parseFloat(montant),
                description: description || `Paiement fournisseur ${fournisseur.nom}${referenceId ? ` - Commande #${referenceId}` : ''}`,
                utilisateurId: req.user.id,
                metadata: JSON.stringify({
                  typeTransaction: 'paiement_fournisseur',
                  fournisseurId,
                  transactionCompteId: transaction.id,
                  referenceType: referenceType || null,
                  referenceId: referenceId || null,
                  sessionCaisseId: sessionCaisse.id
                })
              }
            });

            console.log('✅ Mouvement de caisse créé:', {
              mouvementId: mouvementFinancier.id,
              type: 'sortie',
              montant: parseFloat(montant),
              caisseId: sessionCaisse.caisseId
            });

            // Mettre à jour le solde attendu de la session de caisse
            const currentSoldeAttendu = sessionCaisse.soldeAttendu ? parseFloat(sessionCaisse.soldeAttendu) : parseFloat(sessionCaisse.soldeOuverture);
            const newSoldeAttendu = currentSoldeAttendu - parseFloat(montant);

            await prisma.cashSession.update({
              where: { id: sessionCaisse.id },
              data: {
                soldeAttendu: newSoldeAttendu
              }
            });

            console.log('💰 Solde de la session de caisse mis à jour:', {
              sessionId: sessionCaisse.id,
              soldeAvant: currentSoldeAttendu,
              montantSortie: parseFloat(montant),
              soldeApres: newSoldeAttendu
            });

            // Créer aussi un mouvement financier pour la traçabilité
            console.log('💰 Création du mouvement financier...');
            
            // Générer une référence unique
            const timestamp = Date.now();
            const random = Math.floor(Math.random() * 1000);
            const reference = `MF-${timestamp}-${random}`;

            mouvementFinancierRecord = await prisma.financialMovement.create({
              data: {
                reference,
                montant: parseFloat(montant),
                categorieId: 11, // Catégorie "approvisionnement"
                description: description || `Paiement fournisseur ${fournisseur.nom}${referenceId ? ` - Commande #${referenceId}` : ''}`,
                date: new Date(),
                utilisateurId: req.user.id,
                notes: `Paiement fournisseur ${fournisseur.nom} - Transaction compte ID: ${transaction.id}`
              }
            });

            console.log('✅ Mouvement financier créé:', {
              mouvementId: mouvementFinancierRecord.id,
              reference: mouvementFinancierRecord.reference,
              montant: parseFloat(montant)
            });
          }

          return { compte: compteUpdated, transaction, mouvementFinancier, mouvementFinancierRecord };
        });

        const compteFormatted = {
          id: result.compte.id,
          fournisseurId: result.compte.fournisseurId,
          soldeActuel: parseFloat(result.compte.soldeActuel),
          limiteCredit: parseFloat(result.compte.limiteCredit),
          creditDisponible: parseFloat(result.compte.limiteCredit) - parseFloat(result.compte.soldeActuel),
          estEnDepassement: parseFloat(result.compte.soldeActuel) > parseFloat(result.compte.limiteCredit),
          dateDerniereMaj: result.compte.dateDerniereMaj,
          fournisseur: result.compte.fournisseur,
          derniereTransaction: {
            id: result.transaction.id,
            typeTransaction: result.transaction.typeTransaction,
            montant: parseFloat(result.transaction.montant),
            description: result.transaction.description,
            dateTransaction: result.transaction.dateTransaction,
            referenceType: result.transaction.referenceType,
            referenceId: result.transaction.referenceId
          },
          mouvementFinancier: result.mouvementFinancier ? {
            id: result.mouvementFinancier.id,
            montant: parseFloat(result.mouvementFinancier.montant),
            description: result.mouvementFinancier.description
          } : null
        };

        res.status(201).json(
          BaseResponseDTO.success(compteFormatted, 'Transaction fournisseur créée avec succès')
        );

      } catch (error) {
        console.error('Erreur création transaction fournisseur:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la création de la transaction fournisseur')
        );
      }
    }
  );

  /**
   * GET /accounts/customers/:id/transactions
   * Récupère l'historique des transactions d'un compte client
   */
  router.get('/customers/:id/transactions',
    validateId,
    validatePagination,
    async (req, res) => {
      try {
        const clientId = parseInt(req.params.id);
        const { page, limit } = req.query;

        // Vérifier que le client existe
        const client = await prisma.client.findUnique({
          where: { id: clientId }
        });

        if (!client) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        // Créer le compte client s'il n'existe pas
        let compte = await prisma.compteClient.findUnique({
          where: { clientId }
        });

        if (!compte) {
          console.log(`📝 Création automatique du compte pour le client ${clientId}`);
          compte = await prisma.compteClient.create({
            data: {
              clientId,
              soldeActuel: 0,
              limiteCredit: 0
            }
          });
          console.log(`✅ Compte créé avec succès (ID: ${compte.id})`);
        }

        const options = buildPrismaQuery({ page, limit });
        options.where = {
          typeCompte: 'client',
          compteId: compte.id  // Utiliser l'ID du compte, pas l'ID du client
        };
        options.orderBy = { dateTransaction: 'desc' };

        const [transactions, total] = await Promise.all([
          prisma.transactionCompte.findMany(options),
          prisma.transactionCompte.count({ where: options.where })
        ]);

        const transactionsFormatted = transactions.map(t => ({
          id: t.id,
          typeTransaction: t.typeTransaction,
          montant: parseFloat(t.montant),
          description: t.description,
          referenceId: t.referenceId,
          referenceType: t.referenceType,
          dateTransaction: t.dateTransaction,
          soldeApres: parseFloat(t.soldeApres)
        }));

        const response = new PaginatedResponseDTO(
          transactionsFormatted,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total
          },
          'Historique des transactions client récupéré avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur récupération historique client:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération de l\'historique client')
        );
      }
    }
  );

  /**
   * GET /accounts/suppliers/:id/transactions
   * Récupère l'historique des transactions d'un compte fournisseur
   */
  router.get('/suppliers/:id/transactions',
    validateId,
    validatePagination,
    async (req, res) => {
      try {
        const fournisseurId = parseInt(req.params.id);
        const { page, limit } = req.query;

        // Vérifier que le compte fournisseur existe
        const compte = await prisma.compteFournisseur.findUnique({
          where: { fournisseurId }
        });

        if (!compte) {
          return res.status(404).json(
            BaseResponseDTO.error('Compte fournisseur non trouvé')
          );
        }

        const options = buildPrismaQuery({ page, limit });
        options.where = {
          typeCompte: 'fournisseur',
          compteId: compte.id
        };
        options.orderBy = { dateTransaction: 'desc' };

        const [transactions, total] = await Promise.all([
          prisma.transactionCompte.findMany(options),
          prisma.transactionCompte.count({ where: options.where })
        ]);

        const transactionsFormatted = transactions.map(t => ({
          id: t.id,
          typeTransaction: t.typeTransaction,
          montant: parseFloat(t.montant),
          description: t.description,
          referenceId: t.referenceId,
          referenceType: t.referenceType,
          dateTransaction: t.dateTransaction,
          soldeApres: parseFloat(t.soldeApres)
        }));

        const response = new PaginatedResponseDTO(
          transactionsFormatted,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total
          },
          'Historique des transactions fournisseur récupéré avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur récupération historique fournisseur:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération de l\'historique fournisseur')
        );
      }
    }
  );

  /**
   * GET /accounts/suppliers/:id/statement
   * Récupère le relevé de compte complet d'un fournisseur (pour impression PDF)
   */
  router.get('/suppliers/:id/statement',
    validateId,
    async (req, res) => {
      try {
        const fournisseurId = parseInt(req.params.id);

        console.log('📄 Récupération relevé fournisseur:', fournisseurId);

        // Récupérer le fournisseur
        const fournisseur = await prisma.fournisseur.findUnique({
          where: { id: fournisseurId },
          select: {
            id: true,
            nom: true,
            personneContact: true,
            telephone: true,
            email: true,
            adresse: true
          }
        });

        if (!fournisseur) {
          return res.status(404).json(
            BaseResponseDTO.error('Fournisseur non trouvé')
          );
        }

        // Récupérer ou créer le compte fournisseur
        let compte = await prisma.compteFournisseur.findUnique({
          where: { fournisseurId }
        });

        if (!compte) {
          compte = await prisma.compteFournisseur.create({
            data: {
              fournisseurId,
              soldeActuel: 0,
              limiteCredit: 0
            }
          });
        }

        // Récupérer toutes les transactions (sans pagination pour le relevé)
        const transactions = await prisma.transactionCompte.findMany({
          where: {
            typeCompte: 'fournisseur',
            compteId: compte.id
          },
          orderBy: { dateTransaction: 'desc' },
          take: 100 // Limiter à 100 dernières transactions pour le PDF
        });

        // Récupérer les informations de l'entreprise
        const entreprise = await prisma.parametresEntreprise.findFirst({
          select: {
            nomEntreprise: true,
            localisation: true,
            telephone: true,
            email: true,
            nuiRccm: true,
            logo: true
          }
        });

        const statementData = {
          entreprise: entreprise ? {
            nom: entreprise.nomEntreprise,
            localisation: entreprise.localisation,
            telephone: entreprise.telephone,
            email: entreprise.email,
            nuiRccm: entreprise.nuiRccm,
            logoPath: entreprise.logo || null  // Utiliser 'logo' du schéma
          } : null,
          fournisseur: {
            id: fournisseur.id,
            nom: fournisseur.nom,
            personneContact: fournisseur.personneContact,
            telephone: fournisseur.telephone,
            email: fournisseur.email,
            adresse: fournisseur.adresse
          },
          compte: {
            solde: parseFloat(compte.soldeActuel),
            limiteCredit: parseFloat(compte.limiteCredit)
          },
          transactions: transactions.map(t => ({
            id: t.id,
            typeTransaction: t.typeTransaction,
            montant: parseFloat(t.montant),
            description: t.description,
            dateTransaction: t.dateTransaction,
            soldeApres: parseFloat(t.soldeApres),
            referenceType: t.referenceType,
            referenceId: t.referenceId
          }))
        };

        console.log('✅ Relevé généré:', {
          fournisseur: fournisseur.nom,
          solde: compte.soldeActuel,
          nbTransactions: transactions.length
        });

        res.json(
          BaseResponseDTO.success(statementData, 'Relevé de compte récupéré avec succès')
        );

      } catch (error) {
        console.error('Erreur récupération relevé fournisseur:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du relevé fournisseur')
        );
      }
    }
  );

  /**
   * GET /accounts/suppliers/:id/unpaid-procurements
   * Récupère les commandes impayées d'un fournisseur
   */
  router.get('/suppliers/:id/unpaid-procurements',
    validateId,
    async (req, res) => {
      try {
        const fournisseurId = parseInt(req.params.id);

        console.log('🔍 Récupération commandes impayées fournisseur:', fournisseurId);

        // Récupérer toutes les commandes du fournisseur non annulées
        const commandes = await prisma.commandeApprovisionnement.findMany({
          where: {
            fournisseurId,
            statut: { not: 'annulee' }
          },
          select: {
            id: true,
            numeroCommande: true,
            dateCommande: true,
            montantTotal: true,
            modePaiement: true,
            statut: true,
            details: {
              select: {
                produitId: true,
                quantiteCommandee: true,
                coutUnitaire: true
              }
            }
          },
          orderBy: { dateCommande: 'desc' }
        });

        console.log(`📦 ${commandes.length} commande(s) trouvée(s)`);

        // Récupérer les transactions de paiement pour ce fournisseur
        const compteFournisseur = await prisma.compteFournisseur.findUnique({
          where: { fournisseurId }
        });

        let paiementsParCommande = {};
        if (compteFournisseur) {
          // Récupérer les transactions liées aux commandes
          const transactions = await prisma.transactionCompte.findMany({
            where: {
              typeCompte: 'fournisseur',
              compteId: compteFournisseur.id,
              referenceType: 'approvisionnement'
            },
            select: {
              referenceId: true,
              montant: true,
              typeTransaction: true
            }
          });

          console.log(`💰 ${transactions.length} transaction(s) de paiement trouvée(s)`);

          // Calculer le montant payé par commande
          transactions.forEach(t => {
            if (t.referenceId) {
              if (!paiementsParCommande[t.referenceId]) {
                paiementsParCommande[t.referenceId] = 0;
              }
              // Les paiements sont des crédits (positifs)
              if (t.typeTransaction === 'paiement' || t.typeTransaction === 'credit') {
                paiementsParCommande[t.referenceId] += parseFloat(t.montant);
                console.log(`  ✅ Commande ${t.referenceId}: +${t.montant} (total: ${paiementsParCommande[t.referenceId]})`);
              }
            }
          });
        }

        console.log('📊 Paiements par commande:', paiementsParCommande);

        // Formater les commandes avec calcul du montant restant
        const commandesFormatted = commandes
          .map(c => {
            const montantTotal = parseFloat(c.montantTotal || 0);
            const montantPaye = paiementsParCommande[c.id] || 0;
            const montantRestant = montantTotal - montantPaye;

            console.log(`📋 Commande ${c.numeroCommande}:`, {
              id: c.id,
              montantTotal,
              montantPaye,
              montantRestant
            });

            return {
              id: c.id,
              reference: c.numeroCommande,
              dateCommande: c.dateCommande,
              montantTotal,
              montantPaye,
              montantRestant,
              nombreArticles: c.details.length,
              statut: c.statut
            };
          })
          // Filtrer uniquement les commandes avec un montant restant > 0
          .filter(c => {
            const isUnpaid = c.montantRestant > 0;
            console.log(`  ${isUnpaid ? '✅' : '❌'} Commande ${c.reference}: montantRestant=${c.montantRestant} (${isUnpaid ? 'INCLUSE' : 'EXCLUE'})`);
            return isUnpaid;
          });

        console.log(`✅ ${commandesFormatted.length} commande(s) impayée(s) retournée(s)`);

        res.json(BaseResponseDTO.success(
          commandesFormatted,
          'Commandes impayées récupérées avec succès'
        ));

      } catch (error) {
        console.error('Erreur récupération commandes impayées:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des commandes impayées')
        );
      }
    }
  );

  /**
   * PUT /accounts/customers/:id/credit-limit
   * Met à jour la limite de crédit d'un client
   */
  router.put('/customers/:id/credit-limit',
    validateId,
    validate(compteSchemas.updateLimite, 'body'),
    async (req, res) => {
      try {
        const clientId = parseInt(req.params.id);
        const { limiteCredit } = req.body;

        // Vérifier que le client existe
        const client = await prisma.client.findUnique({
          where: { id: clientId }
        });

        if (!client) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        // Créer ou mettre à jour le compte client
        const compte = await prisma.compteClient.upsert({
          where: { clientId },
          update: { limiteCredit: parseFloat(limiteCredit) },
          create: {
            clientId,
            soldeActuel: 0,
            limiteCredit: parseFloat(limiteCredit)
          },
          include: {
            client: {
              select: {
                id: true,
                nom: true,
                prenom: true
              }
            }
          }
        });

        const compteFormatted = {
          id: compte.id,
          clientId: compte.clientId,
          soldeActuel: parseFloat(compte.soldeActuel),
          limiteCredit: parseFloat(compte.limiteCredit),
          creditDisponible: parseFloat(compte.limiteCredit) - parseFloat(compte.soldeActuel),
          estEnDepassement: parseFloat(compte.soldeActuel) > parseFloat(compte.limiteCredit),
          dateDerniereMaj: compte.dateDerniereMaj,
          client: {
            ...compte.client,
            nomComplet: compte.client.prenom ? 
              `${compte.client.nom} ${compte.client.prenom}` : 
              compte.client.nom
          }
        };

        res.json(
          BaseResponseDTO.success(compteFormatted, 'Limite de crédit client mise à jour avec succès')
        );

      } catch (error) {
        console.error('Erreur mise à jour limite crédit client:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la mise à jour de la limite de crédit client')
        );
      }
    }
  );

  /**
   * PUT /accounts/suppliers/:id/credit-limit
   * Met à jour la limite de crédit d'un fournisseur
   */
  router.put('/suppliers/:id/credit-limit',
    validateId,
    validate(compteSchemas.updateLimite, 'body'),
    async (req, res) => {
      try {
        const fournisseurId = parseInt(req.params.id);
        const { limiteCredit } = req.body;

        // Vérifier que le fournisseur existe
        const fournisseur = await prisma.fournisseur.findUnique({
          where: { id: fournisseurId }
        });

        if (!fournisseur) {
          return res.status(404).json(
            BaseResponseDTO.error('Fournisseur non trouvé')
          );
        }

        // Créer ou mettre à jour le compte fournisseur
        const compte = await prisma.compteFournisseur.upsert({
          where: { fournisseurId },
          update: { limiteCredit: parseFloat(limiteCredit) },
          create: {
            fournisseurId,
            soldeActuel: 0,
            limiteCredit: parseFloat(limiteCredit)
          },
          include: {
            fournisseur: {
              select: {
                id: true,
                nom: true,
                personneContact: true
              }
            }
          }
        });

        const compteFormatted = {
          id: compte.id,
          fournisseurId: compte.fournisseurId,
          soldeActuel: parseFloat(compte.soldeActuel),
          limiteCredit: parseFloat(compte.limiteCredit),
          creditDisponible: parseFloat(compte.limiteCredit) - parseFloat(compte.soldeActuel),
          estEnDepassement: parseFloat(compte.soldeActuel) > parseFloat(compte.limiteCredit),
          dateDerniereMaj: compte.dateDerniereMaj,
          fournisseur: compte.fournisseur
        };

        res.json(
          BaseResponseDTO.success(compteFormatted, 'Limite de crédit fournisseur mise à jour avec succès')
        );

      } catch (error) {
        console.error('Erreur mise à jour limite crédit fournisseur:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la mise à jour de la limite de crédit fournisseur')
        );
      }
    }
  );

  return router;
}

module.exports = { createAccountRouter };
