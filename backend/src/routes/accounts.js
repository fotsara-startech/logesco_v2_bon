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
 * @param {Object} models - Factory de modèles
 * @returns {Object} Routeur Express
 */
function createAccountRouter(models) {
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
          models.prisma.compteClient.findMany(options),
          models.prisma.compteClient.count({ where: options.where })
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
          models.prisma.compteFournisseur.findMany(options),
          models.prisma.compteFournisseur.count({ where: options.where })
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
        const client = await models.prisma.client.findUnique({
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
        let compte = await models.prisma.compteClient.findUnique({
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
          compte = await models.prisma.compteClient.create({
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

        const compte = await models.prisma.compteFournisseur.findUnique({
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
        const ventesImpayees = await models.prisma.vente.findMany({
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
        const client = await models.prisma.client.findUnique({
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
          const vente = await models.prisma.vente.findUnique({
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

            await models.prisma.vente.update({
              where: { id: venteId },
              data: {
                montantPaye: nouveauMontantPaye,
                montantRestant: montantRestant > 0 ? montantRestant : 0
              }
            });
          }
        }

        // Créer ou récupérer le compte client
        let compte = await models.prisma.compteClient.findUnique({
          where: { clientId }
        });

        if (!compte) {
          compte = await models.prisma.compteClient.create({
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
        const result = await models.prisma.$transaction(async (prisma) => {
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
   */
  router.post('/suppliers/:id/transactions',
    validateId,
    validate(compteSchemas.updateSolde, 'body'),
    async (req, res) => {
      try {
        const fournisseurId = parseInt(req.params.id);
        const { montant, typeTransaction, description } = req.body;

        // Vérifier que le fournisseur existe
        const fournisseur = await models.prisma.fournisseur.findUnique({
          where: { id: fournisseurId }
        });

        if (!fournisseur) {
          return res.status(404).json(
            BaseResponseDTO.error('Fournisseur non trouvé')
          );
        }

        // Créer ou récupérer le compte fournisseur
        let compte = await models.prisma.compteFournisseur.findUnique({
          where: { fournisseurId }
        });

        if (!compte) {
          compte = await models.prisma.compteFournisseur.create({
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

        // Transaction atomique pour mettre à jour le compte et créer l'historique
        const result = await models.prisma.$transaction(async (prisma) => {
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
              soldeApres: nouveauSolde
            }
          });

          return { compte: compteUpdated, transaction };
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
            dateTransaction: result.transaction.dateTransaction
          }
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
        const client = await models.prisma.client.findUnique({
          where: { id: clientId }
        });

        if (!client) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        // Créer le compte client s'il n'existe pas
        let compte = await models.prisma.compteClient.findUnique({
          where: { clientId }
        });

        if (!compte) {
          console.log(`📝 Création automatique du compte pour le client ${clientId}`);
          compte = await models.prisma.compteClient.create({
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
          models.prisma.transactionCompte.findMany(options),
          models.prisma.transactionCompte.count({ where: options.where })
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
        const compte = await models.prisma.compteFournisseur.findUnique({
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
          models.prisma.transactionCompte.findMany(options),
          models.prisma.transactionCompte.count({ where: options.where })
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
        const client = await models.prisma.client.findUnique({
          where: { id: clientId }
        });

        if (!client) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        // Créer ou mettre à jour le compte client
        const compte = await models.prisma.compteClient.upsert({
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
        const fournisseur = await models.prisma.fournisseur.findUnique({
          where: { id: fournisseurId }
        });

        if (!fournisseur) {
          return res.status(404).json(
            BaseResponseDTO.error('Fournisseur non trouvé')
          );
        }

        // Créer ou mettre à jour le compte fournisseur
        const compte = await models.prisma.compteFournisseur.upsert({
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