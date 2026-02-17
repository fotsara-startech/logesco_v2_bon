/**
 * Routes pour la gestion des clients - LOGESCO v2
 * Endpoints CRUD complets avec recherche, filtrage et pagination
 */

const express = require('express');
const { validate, validateId, validatePagination } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO, PaginatedResponseDTO, ClientDTO } = require('../dto');
const { clientSchemas } = require('../validation/schemas');
const { 
  buildPrismaQuery,
  sanitizeInput 
} = require('../utils/transformers');

/**
 * Crée le routeur pour les clients
 * @param {Object} models - Factory de modèles
 * @returns {Object} Routeur Express
 */
function createCustomerRouter(models) {
  const router = express.Router();

  /**
   * GET /customers
   * Liste tous les clients avec recherche, filtrage et pagination
   */
  router.get('/',
    validatePagination,
    validate(clientSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { page, limit, ...searchParams } = req.query;

        // Options de pagination
        const options = buildPrismaQuery({ page, limit });
        options.orderBy = { dateModification: 'desc' };
        // Inclure le compte pour avoir le solde
        options.include = { compte: true };

        // Exécuter la recherche
        const result = await models.client.search(searchParams, options);
        
        // Transformer en DTOs
        const clientsDTO = ClientDTO.fromEntities(result.clients);

        // Réponse paginée
        const response = new PaginatedResponseDTO(
          clientsDTO,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total: result.total
          },
          'Clients récupérés avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur liste clients:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des clients')
        );
      }
    }
  );

  /**
   * GET /customers/:id
   * Récupère un client par son ID
   */
  router.get('/:id',
    validateId,
    async (req, res) => {
      try {
        const client = await models.client.findById(req.params.id, {
          include: { 
            compte: true,
            ventes: {
              take: 10,
              orderBy: { dateVente: 'desc' },
              include: {
                details: {
                  include: { produit: true }
                }
              }
            }
          }
        });

        if (!client) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        const clientDTO = ClientDTO.fromEntity(client);
        res.json(BaseResponseDTO.success(clientDTO, 'Client récupéré avec succès'));

      } catch (error) {
        console.error('Erreur récupération client:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du client')
        );
      }
    }
  );

  /**
   * POST /customers
   * Crée un nouveau client
   */
  router.post('/',
    authenticateToken(models.authService),
    validate(clientSchemas.create),
    async (req, res) => {
      try {
        // Nettoyer les données d'entrée
        const clientData = sanitizeInput(req.body);

        // Vérifier l'unicité de l'email si fourni
        if (clientData.email) {
          const existingClient = await models.client.findMany({
            where: { email: clientData.email }
          });

          if (existingClient.length > 0) {
            return res.status(409).json(
              BaseResponseDTO.error('Cette adresse email est déjà utilisée par un autre client', [
                {
                  field: 'email',
                  message: 'L\'email doit être unique',
                  value: clientData.email
                }
              ])
            );
          }
        }

        // Créer le client avec son compte
        const client = await models.client.createWithAccount(clientData);
        
        const clientDTO = ClientDTO.fromEntity(client);
        res.status(201).json(
          BaseResponseDTO.success(clientDTO, 'Client créé avec succès')
        );

      } catch (error) {
        console.error('Erreur création client:', error);
        
        if (error.code === 'P2002') {
          return res.status(409).json(
            BaseResponseDTO.error('Email déjà utilisé par un autre client')
          );
        }

        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la création du client')
        );
      }
    }
  );

  /**
   * PUT /customers/:id
   * Met à jour un client existant
   */
  router.put('/:id',
    authenticateToken(models.authService),
    validateId,
    validate(clientSchemas.update),
    async (req, res) => {
      try {
        const clientId = req.params.id;
        const updateData = sanitizeInput(req.body);

        // Vérifier que le client existe
        const existingClient = await models.client.findById(clientId);
        if (!existingClient) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        // Vérifier l'unicité de l'email si modifié
        if (updateData.email && updateData.email !== existingClient.email) {
          const duplicateEmail = await models.client.findMany({
            where: { 
              email: updateData.email,
              id: { not: parseInt(clientId) }
            }
          });

          if (duplicateEmail.length > 0) {
            return res.status(409).json(
              BaseResponseDTO.error('Cette adresse email est déjà utilisée par un autre client')
            );
          }
        }

        // Mettre à jour le client
        const clientUpdated = await models.client.update(clientId, updateData, {
          include: { compte: true }
        });

        const clientDTO = ClientDTO.fromEntity(clientUpdated);
        res.json(BaseResponseDTO.success(clientDTO, 'Client mis à jour avec succès'));

      } catch (error) {
        console.error('Erreur mise à jour client:', error);
        
        if (error.code === 'P2002') {
          return res.status(409).json(
            BaseResponseDTO.error('Email déjà utilisé par un autre client')
          );
        }

        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la mise à jour du client')
        );
      }
    }
  );

  /**
   * DELETE /customers/:id
   * Supprime un client (si aucune transaction liée)
   */
  router.delete('/:id',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const clientId = req.params.id;

        // Vérifier que le client existe
        const existingClient = await models.client.findById(clientId);
        if (!existingClient) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        // Vérifier s'il y a des ventes liées
        const canDelete = await models.client.canDelete(parseInt(clientId));

        if (!canDelete) {
          return res.status(409).json(
            BaseResponseDTO.error(
              'Impossible de supprimer ce client car il a des ventes associées',
              [{
                field: 'ventes',
                message: 'Des ventes existent pour ce client',
                suggestion: 'Vous pouvez modifier les informations du client mais pas le supprimer'
              }]
            )
          );
        }

        // Supprimer le client et son compte
        await models.prisma.$transaction(async (tx) => {
          // Supprimer le compte s'il existe
          await tx.compteClient.deleteMany({
            where: { clientId: parseInt(clientId) }
          });

          // Supprimer le client
          await tx.client.delete({
            where: { id: parseInt(clientId) }
          });
        });
        
        res.json(BaseResponseDTO.success(null, 'Client supprimé avec succès'));

      } catch (error) {
        console.error('Erreur suppression client:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la suppression du client')
        );
      }
    }
  );

  /**
   * GET /customers/search/suggestions
   * Suggestions de recherche pour l'autocomplétion
   */
  router.get('/search/suggestions',
    validate(clientSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { q } = req.query;

        if (!q || q.length < 2) {
          return res.json(BaseResponseDTO.success([], 'Requête trop courte'));
        }

        const suggestions = await models.client.findMany({
          where: {
            OR: [
              { nom: { contains: q } },
              { prenom: { contains: q } },
              { telephone: { contains: q } },
              { email: { contains: q } }
            ]
          },
          select: {
            id: true,
            nom: true,
            prenom: true,
            telephone: true,
            email: true
          },
          take: 10,
          orderBy: { nom: 'asc' }
        });

        // Ajouter le nom complet pour l'affichage
        const suggestionsWithFullName = suggestions.map(client => ({
          ...client,
          nomComplet: client.prenom ? `${client.nom} ${client.prenom}` : client.nom
        }));

        res.json(BaseResponseDTO.success(suggestionsWithFullName, 'Suggestions récupérées'));

      } catch (error) {
        console.error('Erreur suggestions clients:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des suggestions')
        );
      }
    }
  );

  /**
   * GET /customers/:id/sales
   * Historique des ventes d'un client
   */
  router.get('/:id/sales',
    validateId,
    validatePagination,
    async (req, res) => {
      try {
        const { page, limit } = req.query;
        const clientId = parseInt(req.params.id);

        // Vérifier que le client existe
        const client = await models.client.findById(clientId);
        if (!client) {
          return res.status(404).json(
            BaseResponseDTO.error('Client non trouvé')
          );
        }

        const options = buildPrismaQuery({ page, limit });
        options.where = { clientId };
        options.include = {
          details: {
            include: { produit: true }
          }
        };
        options.orderBy = { dateVente: 'desc' };

        const [ventes, total] = await Promise.all([
          models.vente.findMany(options),
          models.vente.count({ where: { clientId } })
        ]);

        const response = new PaginatedResponseDTO(
          ventes,
          {
            page: parseInt(page),
            limit: parseInt(limit),
            total
          },
          'Historique des ventes récupéré'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur historique ventes client:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération de l\'historique')
        );
      }
    }
  );

  /**
   * GET /customers/:id/account
   * Informations du compte client
   */
  router.get('/:id/account',
    validateId,
    async (req, res) => {
      try {
        const clientId = parseInt(req.params.id);

        // Récupérer le compte client avec les transactions récentes
        const compte = await models.prisma.compteClient.findUnique({
          where: { clientId },
          include: {
            client: true
          }
        });

        if (!compte) {
          return res.status(404).json(
            BaseResponseDTO.error('Compte client non trouvé')
          );
        }

        // Récupérer les transactions récentes
        const transactions = await models.prisma.transactionCompte.findMany({
          where: {
            typeCompte: 'client',
            compteId: compte.id
          },
          orderBy: { dateTransaction: 'desc' },
          take: 20
        });

        const response = {
          compte: {
            id: compte.id,
            clientId: compte.clientId,
            soldeActuel: parseFloat(compte.soldeActuel),
            limiteCredit: parseFloat(compte.limiteCredit),
            creditDisponible: parseFloat(compte.limiteCredit) - parseFloat(compte.soldeActuel),
            estEnDepassement: parseFloat(compte.soldeActuel) > parseFloat(compte.limiteCredit),
            dateDerniereMaj: compte.dateDerniereMaj,
            client: {
              id: compte.client.id,
              nom: compte.client.nom,
              prenom: compte.client.prenom,
              nomComplet: compte.client.prenom ? `${compte.client.nom} ${compte.client.prenom}` : compte.client.nom
            }
          },
          transactions: transactions.map(t => ({
            id: t.id,
            typeTransaction: t.typeTransaction,
            montant: parseFloat(t.montant),
            description: t.description,
            referenceType: t.referenceType,
            referenceId: t.referenceId,
            dateTransaction: t.dateTransaction,
            soldeApres: parseFloat(t.soldeApres)
          }))
        };

        res.json(BaseResponseDTO.success(response, 'Informations du compte récupérées'));

      } catch (error) {
        console.error('Erreur compte client:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération du compte')
        );
      }
    }
  );

  /**
   * GET /customers/:id/statement
   * Génère un relevé de compte PDF pour un client
   */
  router.get('/:id/statement',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const { id } = req.params;
        const { format = 'a4' } = req.query;

        // Vérifier que le client existe
        const client = await models.prisma.client.findUnique({
          where: { id: parseInt(id) },
          select: { 
            id: true, 
            nom: true, 
            prenom: true,
            telephone: true,
            email: true,
            adresse: true
          }
        });

        if (!client) {
          return res.status(404).json({
            success: false,
            message: 'Client non trouvé'
          });
        }

        // Récupérer le compte client
        const compte = await models.prisma.compteClient.findUnique({
          where: { clientId: parseInt(id) }
        });

        if (!compte) {
          return res.status(404).json({
            success: false,
            message: 'Compte client non trouvé'
          });
        }

        // Récupérer les informations de l'entreprise
        const entreprise = await models.prisma.parametresEntreprise.findFirst({
          orderBy: { dateCreation: 'desc' }
        });

        console.log('📋 Informations entreprise:', entreprise ? 'Trouvées' : 'Non trouvées');
        if (entreprise) {
          console.log(`   Nom: ${entreprise.nomEntreprise}`);
        }

        // Récupérer les transactions (CORRECTION: utiliser compte.id au lieu de parseInt(id))
        const transactions = await models.prisma.transactionCompte.findMany({
          where: {
            typeCompte: 'client',
            compteId: compte.id  // CORRECTION: ID du compte, pas du client
          },
          orderBy: { dateTransaction: 'desc' },
          take: 100 // Limiter à 100 dernières transactions
        });

        console.log(`📊 Relevé de compte client ${id}:`);
        console.log(`   Compte ID: ${compte.id}`);
        console.log(`   Transactions trouvées: ${transactions.length}`);

        // Préparer les données pour le PDF
        const statementData = {
          entreprise: entreprise ? {
            nom: entreprise.nomEntreprise,
            adresse: entreprise.adresse,
            localisation: entreprise.localisation,
            telephone: entreprise.telephone,
            email: entreprise.email,
            nuiRccm: entreprise.nuiRccm
          } : null,
          client: {
            id: client.id,
            nom: client.nom,
            prenom: client.prenom,
            nomComplet: client.prenom ? `${client.nom} ${client.prenom}` : client.nom,
            telephone: client.telephone,
            email: client.email,
            adresse: client.adresse
          },
          compte: {
            soldeActuel: parseFloat(compte.soldeActuel),
            limiteCredit: parseFloat(compte.limiteCredit),
            aDette: parseFloat(compte.soldeActuel) < 0,
            montantDette: parseFloat(compte.soldeActuel) < 0 ? Math.abs(parseFloat(compte.soldeActuel)) : 0,
            creditDisponible: parseFloat(compte.soldeActuel) > 0 ? parseFloat(compte.soldeActuel) : 0
          },
          transactions: transactions.map(t => ({
            id: t.id,
            typeTransaction: t.typeTransaction,
            typeTransactionDetail: t.typeTransactionDetail,
            montant: parseFloat(t.montant),
            description: t.description,
            dateTransaction: t.dateTransaction,
            soldeApres: parseFloat(t.soldeApres),
            venteReference: t.venteReference,
            isCredit: t.typeTransaction === 'paiement' || t.typeTransaction.includes('paiement')
          })),
          dateGeneration: new Date(),
          format: format
        };

        res.json({
          success: true,
          message: 'Relevé de compte généré',
          data: statementData
        });

      } catch (error) {
        console.error('Erreur lors de la génération du relevé:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la génération du relevé'
        });
      }
    }
  );

  /**
   * POST /customers/:id/payment
   * Enregistre un paiement de dette pour un client
   */
  router.post('/:id/payment',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const { id } = req.params;
        const { montant, description, venteId, typeTransactionDetail } = req.body;

        // Validation
        if (!montant || montant <= 0) {
          return res.status(400).json({
            success: false,
            message: 'Le montant doit être supérieur à 0'
          });
        }

        // Vérifier que le client existe
        const client = await models.prisma.client.findUnique({
          where: { id: parseInt(id) },
          select: { id: true, nom: true, prenom: true }
        });

        if (!client) {
          return res.status(404).json({
            success: false,
            message: 'Client non trouvé'
          });
        }

        let venteReference = null;

        // Si une vente est spécifiée, récupérer sa référence et mettre à jour le paiement
        if (venteId) {
          const vente = await models.prisma.vente.findUnique({
            where: { id: venteId },
            select: { id: true, numeroVente: true, montantPaye: true, montantTotal: true, clientId: true }
          });

          if (!vente) {
            return res.status(404).json({
              success: false,
              message: 'Vente non trouvée'
            });
          }

          if (vente.clientId !== parseInt(id)) {
            return res.status(400).json({
              success: false,
              message: 'Cette vente n\'appartient pas à ce client'
            });
          }

          venteReference = vente.numeroVente;

          // Mettre à jour le montant payé de la vente
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

        // Récupérer ou créer le compte client
        let compte = await models.prisma.compteClient.findUnique({
          where: { clientId: parseInt(id) }
        });

        if (!compte) {
          compte = await models.prisma.compteClient.create({
            data: {
              clientId: parseInt(id),
              soldeActuel: 0,
              limiteCredit: 0
            }
          });
        }

        // Calculer le nouveau solde
        // Dans notre système: solde négatif = dette, solde positif = crédit
        // Un paiement AUGMENTE le solde (réduit la dette)
        const nouveauSolde = parseFloat(compte.soldeActuel) + parseFloat(montant);

        console.log('💰 Calcul du nouveau solde:');
        console.log(`  - Solde actuel: ${compte.soldeActuel}`);
        console.log(`  - Montant payé: ${montant}`);
        console.log(`  - Nouveau solde: ${nouveauSolde}`);

        // Mettre à jour le compte et créer la transaction
        await models.prisma.$transaction(async (tx) => {
          // Mettre à jour le solde
          await tx.compteClient.update({
            where: { clientId: parseInt(id) },
            data: { soldeActuel: nouveauSolde }
          });

          // Créer la transaction
          await tx.transactionCompte.create({
            data: {
              typeCompte: 'client',
              compteId: compte.id,
              typeTransaction: 'paiement',
              typeTransactionDetail: typeTransactionDetail || 'paiement_dette',
              montant: montant,
              description: description || `Paiement de dette de ${montant} FCFA`,
              referenceType: venteId ? 'vente' : 'paiement_direct',
              referenceId: venteId || null,
              venteId: venteId || null,
              venteReference: venteReference,
              soldeApres: nouveauSolde
            }
          });
        });

        res.json({
          success: true,
          message: 'Paiement enregistré avec succès',
          data: {
            montantPaye: montant,
            nouveauSolde: nouveauSolde,
            client: {
              id: client.id,
              nom: client.nom,
              prenom: client.prenom
            }
          }
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

  return router;
}

module.exports = { createCustomerRouter };