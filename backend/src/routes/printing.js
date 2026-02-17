/**
 * Routes pour le système d'impression et de réimpression des reçus
 * Gestion de l'historique des reçus et des réimpressions avec audit
 */

const express = require('express');
const { printingSchemas } = require('../validation/schemas');
const { validate, validateId, validatePagination } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { generateReceiptNumber } = require('../utils/transformers');

function createPrintingRouter({ prisma, authService }) {
  const router = express.Router();

  // Middleware d'authentification pour toutes les routes
  router.use(authenticateToken(authService));

  /**
   * GET /printing/receipts
   * Liste des reçus avec recherche et pagination
   */
  router.get('/receipts',
    validate(printingSchemas.searchReceipts, 'query'),
    validatePagination,
    async (req, res) => {
      try {
        const {
          page = 1,
          limit = 20,
          venteId,
          numeroVente,
          numeroRecu,
          clientNom,
          dateDebut,
          dateFin,
          formatImpression
        } = req.query;

        const skip = (page - 1) * limit;

        // Construire les conditions de recherche
        const conditions = {};

        if (venteId) {
          conditions.venteId = parseInt(venteId);
        }

        if (numeroRecu) {
          conditions.numeroRecu = {
            contains: numeroRecu
          };
        }

        if (formatImpression) {
          conditions.formatImpression = formatImpression;
        }

        if (dateDebut || dateFin) {
          conditions.dateGeneration = {};
          if (dateDebut) {
            conditions.dateGeneration.gte = new Date(dateDebut);
          }
          if (dateFin) {
            conditions.dateGeneration.lte = new Date(dateFin);
          }
        }

        // Conditions pour la vente associée
        const venteConditions = {};
        if (numeroVente) {
          venteConditions.numeroVente = {
            contains: numeroVente
          };
        }

        if (clientNom) {
          venteConditions.client = {
            OR: [
              { nom: { contains: clientNom } },
              { prenom: { contains: clientNom } }
            ]
          };
        }

        if (Object.keys(venteConditions).length > 0) {
          conditions.vente = venteConditions;
        }



        const [recus, total] = await Promise.all([
          prisma.historiqueRecu.findMany({
            where: conditions,
            include: {
              vente: {
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
                }
              },
              reimpressions: {
                orderBy: { dateReimpression: 'desc' },
                take: 5
              }
            },
            orderBy: { dateGeneration: 'desc' },
            skip,
            take: parseInt(limit)
          }),
          prisma.historiqueRecu.count({ where: conditions })
        ]);

        res.json({
          success: true,
          data: recus,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / limit)
          }
        });
      } catch (error) {
        console.error('Erreur lors de la récupération des reçus:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la récupération des reçus'
        });
      }
    }
  );

  /**
   * GET /printing/receipts/:id
   * Détails d'un reçu spécifique avec historique des réimpressions
   */
  router.get('/receipts/:id',
    validateId,
    async (req, res) => {
      try {
        const { id } = req.params;

        const recu = await prisma.historiqueRecu.findUnique({
          where: { id: parseInt(id) },
          include: {
            vente: {
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
            },
            reimpressions: {
              orderBy: { dateReimpression: 'desc' }
            }
          }
        });

        if (!recu) {
          return res.status(404).json({
            success: false,
            message: 'Reçu non trouvé'
          });
        }

        res.json({
          success: true,
          data: recu
        });
      } catch (error) {
        console.error('Erreur lors de la récupération du reçu:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la récupération du reçu'
        });
      }
    }
  );

  /**
   * POST /printing/receipts/:id/reprint
   * Réimprimer un reçu existant avec tracking
   */
  router.post('/receipts/:id/reprint',
    validateId,
    validate(printingSchemas.reprint, 'body'),
    async (req, res) => {
      try {
        const { id } = req.params;
        const {
          formatImpression = 'thermal',
          motifReimpression,
          utilisateurId
        } = req.body;

        // Vérifier que le reçu existe
        const recu = await prisma.historiqueRecu.findUnique({
          where: { id: parseInt(id) },
          include: {
            vente: {
              include: {
                client: true,
                details: {
                  include: {
                    produit: true
                  }
                }
              }
            }
          }
        });

        if (!recu) {
          return res.status(404).json({
            success: false,
            message: 'Reçu non trouvé'
          });
        }

        // Vérifier que la vente n'est pas annulée
        if (recu.vente.statut === 'annulee') {
          return res.status(400).json({
            success: false,
            message: 'Impossible de réimprimer un reçu pour une vente annulée'
          });
        }

        // Enregistrer la réimpression
        const reimpression = await prisma.reimpressionRecu.create({
          data: {
            historiqueRecuId: parseInt(id),
            formatImpression,
            motifReimpression,
            utilisateurId: utilisateurId || null
          }
        });

        // Générer le contenu du reçu avec marquage "COPIE"
        const contenuRecu = await generateReceiptContent(recu.vente, formatImpression, true);

        res.json({
          success: true,
          message: 'Reçu réimprimé avec succès',
          data: {
            reimpression,
            contenuRecu,
            numeroRecu: recu.numeroRecu,
            formatImpression,
            isReprint: true
          }
        });
      } catch (error) {
        console.error('Erreur lors de la réimpression du reçu:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la réimpression du reçu'
        });
      }
    }
  );

  /**
   * POST /printing/receipts/generate
   * Générer un nouveau reçu pour une vente existante
   */
  router.post('/receipts/generate',
    validate(printingSchemas.generateReceipt, 'body'),
    async (req, res) => {
      try {
        const {
          venteId,
          formatImpression = 'thermal',
          utilisateurId
        } = req.body;

        if (!venteId) {
          return res.status(400).json({
            success: false,
            message: 'ID de vente requis'
          });
        }

        // Vérifier que la vente existe
        const vente = await prisma.vente.findUnique({
          where: { id: parseInt(venteId) },
          include: {
            client: true,
            details: {
              include: {
                produit: true
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

        if (vente.statut === 'annulee') {
          return res.status(400).json({
            success: false,
            message: 'Impossible de générer un reçu pour une vente annulée'
          });
        }

        // Vérifier s'il existe déjà un reçu pour cette vente
        const recuExistant = await prisma.historiqueRecu.findFirst({
          where: { venteId: parseInt(venteId) }
        });

        if (recuExistant) {
          return res.status(400).json({
            success: false,
            message: 'Un reçu existe déjà pour cette vente. Utilisez la fonction de réimpression.',
            data: { recuId: recuExistant.id }
          });
        }

        // Générer le numéro de reçu
        const numeroRecu = await generateReceiptNumber(prisma);

        // Générer le contenu du reçu
        const contenuRecu = await generateReceiptContent(vente, formatImpression, false);

        // Créer l'historique du reçu
        const recu = await prisma.historiqueRecu.create({
          data: {
            venteId: parseInt(venteId),
            numeroRecu,
            formatImpression,
            contenuRecu,
            utilisateurId: utilisateurId || null
          },
          include: {
            vente: {
              include: {
                client: true,
                details: {
                  include: {
                    produit: true
                  }
                }
              }
            }
          }
        });

        res.status(201).json({
          success: true,
          message: 'Reçu généré avec succès',
          data: {
            recu,
            contenuRecu,
            isReprint: false
          }
        });
      } catch (error) {
        console.error('Erreur lors de la génération du reçu:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la génération du reçu'
        });
      }
    }
  );

  /**
   * GET /printing/formats
   * Liste des formats d'impression disponibles
   */
  router.get('/formats', (req, res) => {
    const formats = [
      {
        id: 'thermal',
        nom: 'Imprimante thermique',
        largeur: '80mm',
        description: 'Format standard pour imprimantes de reçus thermiques'
      },
      {
        id: 'a4',
        nom: 'Format A4',
        largeur: '210mm',
        description: 'Format A4 standard pour impression sur papier'
      },
      {
        id: 'a5',
        nom: 'Format A5',
        largeur: '148mm',
        description: 'Format A5 compact pour impression sur papier'
      }
    ];

    res.json({
      success: true,
      data: formats
    });
  });

  /**
   * GET /printing/stats
   * Statistiques d'impression et de réimpression
   */
  router.get('/stats',
    validate(printingSchemas.stats, 'query'),
    async (req, res) => {
      try {
        const { dateDebut, dateFin } = req.query;

        const conditions = {};
        if (dateDebut || dateFin) {
          conditions.dateGeneration = {};
          if (dateDebut) {
            conditions.dateGeneration.gte = new Date(dateDebut);
          }
          if (dateFin) {
            conditions.dateGeneration.lte = new Date(dateFin);
          }
        }

        const [
          totalRecus,
          totalReimpressions,
          recusParFormat,
          reimpressionsParJour
        ] = await Promise.all([
          prisma.historiqueRecu.count({ where: conditions }),
          prisma.reimpressionRecu.count({
            where: dateDebut || dateFin ? {
              dateReimpression: conditions.dateGeneration
            } : {}
          }),
          prisma.historiqueRecu.groupBy({
            by: ['formatImpression'],
            where: conditions,
            _count: { id: true }
          }),
          prisma.reimpressionRecu.groupBy({
            by: ['dateReimpression'],
            where: dateDebut || dateFin ? {
              dateReimpression: conditions.dateGeneration
            } : {},
            _count: { id: true },
            orderBy: { dateReimpression: 'desc' },
            take: 30
          })
        ]);

        res.json({
          success: true,
          data: {
            totalRecus,
            totalReimpressions,
            recusParFormat,
            reimpressionsParJour
          }
        });
      } catch (error) {
        console.error('Erreur lors de la récupération des statistiques:', error);
        res.status(500).json({
          success: false,
          message: 'Erreur lors de la récupération des statistiques'
        });
      }
    });

  return router;
}

/**
 * Génère le contenu d'un reçu selon le format spécifié
 * @param {Object} vente - Données de la vente
 * @param {string} format - Format d'impression (thermal, a4, a5)
 * @param {boolean} isReprint - Indique si c'est une réimpression
 * @returns {string} Contenu formaté du reçu
 */
async function generateReceiptContent(vente, format, isReprint = false) {
  // Cette fonction sera étendue dans les tâches suivantes pour inclure
  // les informations de l'entreprise et les templates spécifiques

  const header = isReprint ? '*** COPIE ***\n' : '';
  const separator = format === 'thermal' ? '--------------------------------\n' : '================================================\n';

  let content = header;
  content += `TAX INVOICE\n`;
  content += separator;
  content += `Numéro: ${vente.numeroVente}\n`;
  content += `Date: ${new Date(vente.dateVente).toLocaleString('fr-FR')}\n`;

  if (vente.client) {
    content += `Client: ${vente.client.nom} ${vente.client.prenom || ''}\n`;
  }

  content += separator;
  content += `ARTICLES:\n`;

  vente.details.forEach(detail => {
    content += `${detail.produit.nom}\n`;
    content += `  ${detail.quantite} x ${detail.prixUnitaire.toFixed(2)} = ${detail.prixTotal.toFixed(2)}\n`;
  });

  content += separator;
  content += `Sous-total: ${vente.sousTotal.toFixed(2)}\n`;
  if (vente.montantRemise > 0) {
    content += `Remise: -${vente.montantRemise.toFixed(2)}\n`;
  }
  content += `TOTAL: ${vente.montantTotal.toFixed(2)}\n`;
  content += `Mode paiement: ${vente.modePaiement}\n`;
  content += separator;

  if (isReprint) {
    content += `*** COPIE ***\n`;
    content += `Réimprimé le: ${new Date().toLocaleString('fr-FR')}\n`;
  }

  return content;
}

module.exports = createPrintingRouter;