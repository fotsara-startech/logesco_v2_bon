/**
 * Routes pour la gestion des dates de péremption - LOGESCO v2
 * Endpoints pour gérer les dates de péremption des produits
 */

const express = require('express');
const { validate, validateId } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO, PaginatedResponseDTO, DatePeremptionDTO } = require('../dto');
const { datePeremptionSchemas } = require('../validation/schemas');

/**
 * Crée le routeur pour la gestion des dates de péremption
 * @param {Object} models - Factory de modèles
 * @returns {Object} Routeur Express
 */
function createExpirationDatesRouter(models) {
  const router = express.Router();

  /**
   * POST /expiration-dates
   * Crée une nouvelle date de péremption pour un produit
   */
  router.post('/',
    authenticateToken(models.authService),
    validate(datePeremptionSchemas.create),
    async (req, res) => {
      try {
        const { produitId, datePeremption, quantite, numeroLot, notes } = req.body;

        // Vérifier que le produit existe et a la gestion de péremption activée
        const produit = await models.prisma.produit.findUnique({
          where: { id: produitId },
          include: {
            stock: true
          }
        });

        if (!produit) {
          return res.status(404).json(
            BaseResponseDTO.error('Produit non trouvé')
          );
        }

        if (!produit.gestionPeremption) {
          return res.status(400).json(
            BaseResponseDTO.error('La gestion de péremption n\'est pas activée pour ce produit')
          );
        }

        // Vérifier la cohérence des quantités
        const stockDisponible = produit.stock?.quantiteDisponible || 0;
        
        // Calculer le total des quantités déjà enregistrées (non épuisées)
        const datesExistantes = await models.prisma.datePeremption.findMany({
          where: {
            produitId,
            estEpuise: false
          },
          select: {
            quantite: true
          }
        });

        const totalQuantitesEnregistrees = datesExistantes.reduce((sum, d) => sum + d.quantite, 0);
        const nouvelleQuantiteTotale = totalQuantitesEnregistrees + quantite;

        if (nouvelleQuantiteTotale > stockDisponible) {
          return res.status(400).json(
            BaseResponseDTO.error(
              `Quantité incohérente. Stock disponible: ${stockDisponible}, ` +
              `Déjà enregistré: ${totalQuantitesEnregistrees}, ` +
              `Tentative d'ajout: ${quantite}. ` +
              `Le total (${nouvelleQuantiteTotale}) dépasse le stock disponible.`
            )
          );
        }

        // Créer la date de péremption
        const datePerem = await models.prisma.datePeremption.create({
          data: {
            produitId,
            datePeremption: new Date(datePeremption),
            quantite,
            numeroLot,
            notes
          },
          include: {
            produit: {
              select: {
                id: true,
                reference: true,
                nom: true,
                prixUnitaire: true,
                prixAchat: true
              }
            }
          }
        });

        const datePeremDTO = DatePeremptionDTO.fromEntity(datePerem);

        res.status(201).json(
          BaseResponseDTO.success(datePeremDTO, 'Date de péremption créée avec succès')
        );

      } catch (error) {
        console.error('Erreur création date de péremption:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la création de la date de péremption')
        );
      }
    }
  );

  /**
   * GET /expiration-dates
   * Liste toutes les dates de péremption avec filtres
   */
  router.get('/',
    authenticateToken(models.authService),
    validate(datePeremptionSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { page = 1, limit = 20, produitId, estPerime, joursRestants, estEpuise } = req.query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        // Construire les conditions de recherche
        const where = {};

        if (produitId) {
          where.produitId = parseInt(produitId);
        }

        if (estEpuise !== undefined) {
          where.estEpuise = estEpuise === 'true' || estEpuise === true;
        }

        // Filtrer par date de péremption
        if (estPerime !== undefined) {
          const isPerime = estPerime === 'true' || estPerime === true;
          if (isPerime) {
            where.datePeremption = { lt: new Date() };
          } else {
            where.datePeremption = { gte: new Date() };
          }
        }

        if (joursRestants !== undefined) {
          const jours = parseInt(joursRestants);
          const dateLimite = new Date();
          dateLimite.setDate(dateLimite.getDate() + jours);
          where.datePeremption = { lte: dateLimite };
        }

        const [datesPeremption, total] = await Promise.all([
          models.prisma.datePeremption.findMany({
            where,
            include: {
              produit: {
                select: {
                  id: true,
                  reference: true,
                  nom: true
                }
              }
            },
            orderBy: { datePeremption: 'asc' },
            skip: offset,
            take: limitNum
          }),
          models.prisma.datePeremption.count({ where })
        ]);

        const datesPeremDTO = DatePeremptionDTO.fromEntities(datesPeremption);

        const response = new PaginatedResponseDTO(
          datesPeremDTO,
          { page: pageNum, limit: limitNum, total },
          'Dates de péremption récupérées avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur liste dates de péremption:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des dates de péremption')
        );
      }
    }
  );

  /**
   * GET /expiration-dates/alertes
   * Récupère les alertes de péremption (produits périmés ou proches de la péremption)
   */
  router.get('/alertes',
    authenticateToken(models.authService),
    validate(datePeremptionSchemas.alertes, 'query'),
    async (req, res) => {
      try {
        const { niveauAlerte, joursMax = 30, page = 1, limit = 20 } = req.query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        const now = new Date();
        const dateLimite = new Date();
        dateLimite.setDate(dateLimite.getDate() + parseInt(joursMax));

        const where = {
          estEpuise: false,
          datePeremption: { lte: dateLimite }
        };

        // Filtrer par niveau d'alerte si spécifié
        if (niveauAlerte) {
          switch (niveauAlerte) {
            case 'perime':
              where.datePeremption = { lt: now };
              break;
            case 'critique':
              const dateCritique = new Date();
              dateCritique.setDate(dateCritique.getDate() + 7);
              where.datePeremption = { gte: now, lte: dateCritique };
              break;
            case 'avertissement':
              const dateAvertissement = new Date();
              dateAvertissement.setDate(dateAvertissement.getDate() + 30);
              where.datePeremption = { gte: now, lte: dateAvertissement };
              break;
            case 'attention':
              const dateAttention = new Date();
              dateAttention.setDate(dateAttention.getDate() + 90);
              where.datePeremption = { gte: now, lte: dateAttention };
              break;
          }
        }

        const [alertes, total] = await Promise.all([
          models.prisma.datePeremption.findMany({
            where,
            include: {
              produit: {
                select: {
                  id: true,
                  reference: true,
                  nom: true,
                  prixUnitaire: true,
                  prixAchat: true
                }
              }
            },
            orderBy: { datePeremption: 'asc' },
            skip: offset,
            take: limitNum
          }),
          models.prisma.datePeremption.count({ where })
        ]);

        const alertesDTO = DatePeremptionDTO.fromEntities(alertes);

        // Calculer les statistiques
        const stats = {
          totalAlertes: total,
          perimes: alertesDTO.filter(a => a.estPerime).length,
          critiques: alertesDTO.filter(a => a.niveauAlerte === 'critique').length,
          avertissements: alertesDTO.filter(a => a.niveauAlerte === 'avertissement').length,
          valeurTotale: alertesDTO.reduce((sum, a) => {
            const prix = a.produit?.prixAchat || a.produit?.prixUnitaire || 0;
            return sum + (prix * a.quantite);
          }, 0)
        };

        const response = new PaginatedResponseDTO(
          alertesDTO,
          { page: pageNum, limit: limitNum, total },
          'Alertes de péremption récupérées avec succès'
        );

        response.stats = stats;

        res.json(response);

      } catch (error) {
        console.error('Erreur alertes péremption:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des alertes de péremption')
        );
      }
    }
  );

  /**
   * GET /expiration-dates/product/:produitId/stats
   * Récupère les statistiques de péremption pour un produit
   */
  router.get('/product/:produitId/stats',
    authenticateToken(models.authService),
    async (req, res) => {
      try {
        const produitId = parseInt(req.params.produitId);

        // Récupérer le produit avec son stock
        const produit = await models.prisma.produit.findUnique({
          where: { id: produitId },
          include: { stock: true }
        });

        if (!produit) {
          return res.status(404).json(
            BaseResponseDTO.error('Produit non trouvé')
          );
        }

        const stockDisponible = produit.stock?.quantiteDisponible || 0;

        // Calculer les quantités enregistrées
        const datesActives = await models.prisma.datePeremption.findMany({
          where: {
            produitId,
            estEpuise: false
          },
          select: {
            quantite: true
          }
        });

        const quantiteEnregistree = datesActives.reduce((sum, d) => sum + d.quantite, 0);
        const quantiteRestante = stockDisponible - quantiteEnregistree;

        const stats = {
          stockDisponible,
          quantiteEnregistree,
          quantiteRestante,
          pourcentageEnregistre: stockDisponible > 0 
            ? Math.round((quantiteEnregistree / stockDisponible) * 100) 
            : 0
        };

        res.json(BaseResponseDTO.success(stats, 'Statistiques récupérées avec succès'));

      } catch (error) {
        console.error('Erreur récupération statistiques:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération des statistiques')
        );
      }
    }
  );

  /**
   * GET /expiration-dates/history
   * Récupère l'historique des lots épuisés
   */
  router.get('/history',
    authenticateToken(models.authService),
    validate(datePeremptionSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { page = 1, limit = 20, produitId } = req.query;
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const offset = (pageNum - 1) * limitNum;

        const where = {
          estEpuise: true
        };

        if (produitId) {
          where.produitId = parseInt(produitId);
        }

        const [datesPeremption, total] = await Promise.all([
          models.prisma.datePeremption.findMany({
            where,
            include: {
              produit: {
                select: {
                  id: true,
                  reference: true,
                  nom: true,
                  prixUnitaire: true,
                  prixAchat: true
                }
              }
            },
            orderBy: { dateModification: 'desc' },
            skip: offset,
            take: limitNum
          }),
          models.prisma.datePeremption.count({ where })
        ]);

        const datesPeremDTO = DatePeremptionDTO.fromEntities(datesPeremption);

        const response = new PaginatedResponseDTO(
          datesPeremDTO,
          { page: pageNum, limit: limitNum, total },
          'Historique récupéré avec succès'
        );

        res.json(response);

      } catch (error) {
        console.error('Erreur récupération historique:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération de l\'historique')
        );
      }
    }
  );

  /**
   * GET /expiration-dates/:id
   * Récupère une date de péremption spécifique
   */
  router.get('/:id',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);

        const datePerem = await models.prisma.datePeremption.findUnique({
          where: { id },
          include: {
            produit: {
              select: {
                id: true,
                reference: true,
                nom: true
              }
            }
          }
        });

        if (!datePerem) {
          return res.status(404).json(
            BaseResponseDTO.error('Date de péremption non trouvée')
          );
        }

        const datePeremDTO = DatePeremptionDTO.fromEntity(datePerem);

        res.json(BaseResponseDTO.success(datePeremDTO, 'Date de péremption récupérée avec succès'));

      } catch (error) {
        console.error('Erreur récupération date de péremption:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la récupération de la date de péremption')
        );
      }
    }
  );

  /**
   * PUT /expiration-dates/:id
   * Met à jour une date de péremption
   */
  router.put('/:id',
    authenticateToken(models.authService),
    validateId,
    validate(datePeremptionSchemas.update),
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);
        const updateData = { ...req.body };

        // Récupérer la date de péremption actuelle
        const datePeremActuelle = await models.prisma.datePeremption.findUnique({
          where: { id },
          include: {
            produit: {
              include: {
                stock: true
              }
            }
          }
        });

        if (!datePeremActuelle) {
          return res.status(404).json(
            BaseResponseDTO.error('Date de péremption non trouvée')
          );
        }

        // Si la quantité est modifiée, vérifier la cohérence
        if (updateData.quantite !== undefined && updateData.quantite !== datePeremActuelle.quantite) {
          const stockDisponible = datePeremActuelle.produit.stock?.quantiteDisponible || 0;
          
          // Calculer le total des quantités des autres dates (non épuisées, sauf celle-ci)
          const autresDates = await models.prisma.datePeremption.findMany({
            where: {
              produitId: datePeremActuelle.produitId,
              estEpuise: false,
              id: { not: id }
            },
            select: {
              quantite: true
            }
          });

          const totalAutresQuantites = autresDates.reduce((sum, d) => sum + d.quantite, 0);
          const nouvelleQuantiteTotale = totalAutresQuantites + updateData.quantite;

          if (nouvelleQuantiteTotale > stockDisponible) {
            return res.status(400).json(
              BaseResponseDTO.error(
                `Quantité incohérente. Stock disponible: ${stockDisponible}, ` +
                `Autres lots: ${totalAutresQuantites}, ` +
                `Nouvelle quantité: ${updateData.quantite}. ` +
                `Le total (${nouvelleQuantiteTotale}) dépasse le stock disponible.`
              )
            );
          }
        }

        // Convertir la date si présente
        if (updateData.datePeremption) {
          updateData.datePeremption = new Date(updateData.datePeremption);
        }

        const datePerem = await models.prisma.datePeremption.update({
          where: { id },
          data: updateData,
          include: {
            produit: {
              select: {
                id: true,
                reference: true,
                nom: true,
                prixUnitaire: true,
                prixAchat: true
              }
            }
          }
        });

        const datePeremDTO = DatePeremptionDTO.fromEntity(datePerem);

        res.json(BaseResponseDTO.success(datePeremDTO, 'Date de péremption mise à jour avec succès'));

      } catch (error) {
        if (error.code === 'P2025') {
          return res.status(404).json(
            BaseResponseDTO.error('Date de péremption non trouvée')
          );
        }

        console.error('Erreur mise à jour date de péremption:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la mise à jour de la date de péremption')
        );
      }
    }
  );

  /**
   * DELETE /expiration-dates/:id
   * Supprime une date de péremption
   */
  router.delete('/:id',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);

        await models.prisma.datePeremption.delete({
          where: { id }
        });

        res.json(BaseResponseDTO.success(null, 'Date de péremption supprimée avec succès'));

      } catch (error) {
        if (error.code === 'P2025') {
          return res.status(404).json(
            BaseResponseDTO.error('Date de péremption non trouvée')
          );
        }

        console.error('Erreur suppression date de péremption:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors de la suppression de la date de péremption')
        );
      }
    }
  );

  /**
   * POST /expiration-dates/:id/marquer-epuise
   * Marque une date de péremption comme épuisée
   */
  router.post('/:id/marquer-epuise',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);

        const datePerem = await models.prisma.datePeremption.update({
          where: { id },
          data: { estEpuise: true },
          include: {
            produit: {
              select: {
                id: true,
                reference: true,
                nom: true,
                prixUnitaire: true,
                prixAchat: true
              }
            }
          }
        });

        const datePeremDTO = DatePeremptionDTO.fromEntity(datePerem);

        res.json(BaseResponseDTO.success(datePeremDTO, 'Date de péremption marquée comme épuisée'));

      } catch (error) {
        if (error.code === 'P2025') {
          return res.status(404).json(
            BaseResponseDTO.error('Date de péremption non trouvée')
          );
        }

        console.error('Erreur marquage épuisé:', error);
        res.status(500).json(
          BaseResponseDTO.error('Erreur lors du marquage comme épuisé')
        );
      }
    }
  );

  return router;
}

module.exports = { createExpirationDatesRouter };
