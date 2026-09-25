/**
 * Routes pour la gestion des commerciaux terrain — LOGESCO v2
 *
 * Un commercial est une fiche de référence (nom, téléphone, zone/ville),
 * PAS un compte utilisateur : il ne se connecte jamais à l'app. Il prospecte
 * sur le terrain, encaisse ou fait signer une vente, puis reverse l'argent
 * en magasin — c'est la caissière qui saisit la vente et l'attribue à ce
 * commercial (voir POST /sales, champ `commercialId`).
 *
 * Zone et ville sont des listes fermées gérées ici (pas de texte libre sur
 * la fiche commercial) pour que l'analyse « par zone / par ville » ne se
 * fragmente pas sur des variantes de saisie.
 */

const express = require('express');
const { validate, validateId, validatePagination } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO, PaginatedResponseDTO, VilleDTO, ZoneDTO, CommercialDTO } = require('../dto');
const { villeSchemas, zoneSchemas, commercialSchemas } = require('../validation/schemas');
const { sanitizeInput } = require('../utils/transformers');

function getSyncService(req, models) {
  return req.app.locals.syncService || models.syncService || null;
}

/**
 * GET/POST /villes, PUT/DELETE /villes/:id
 */
function createVilleRouter(models) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    try {
      const villes = await models.prisma.ville.findMany({ orderBy: { nom: 'asc' } });
      res.json(BaseResponseDTO.success(VilleDTO.fromEntities(villes), 'Villes récupérées avec succès'));
    } catch (error) {
      console.error('Erreur liste villes:', error);
      res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des villes'));
    }
  });

  router.post('/',
    authenticateToken(models.authService),
    validate(villeSchemas.create),
    async (req, res) => {
      try {
        const data = sanitizeInput(req.body);
        const ville = await models.prisma.ville.create({ data });

        const syncService = getSyncService(req, models);
        if (syncService) await syncService.enqueue('villes', 'INSERT', ville);

        res.status(201).json(BaseResponseDTO.success(VilleDTO.fromEntity(ville), 'Ville créée avec succès'));
      } catch (error) {
        console.error('Erreur création ville:', error);
        if (error.code === 'P2002') {
          return res.status(409).json(BaseResponseDTO.error('Cette ville existe déjà'));
        }
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la création de la ville'));
      }
    }
  );

  router.put('/:id',
    authenticateToken(models.authService),
    validateId,
    validate(villeSchemas.update),
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);
        const existing = await models.prisma.ville.findUnique({ where: { id } });
        if (!existing) {
          return res.status(404).json(BaseResponseDTO.error('Ville non trouvée'));
        }

        const ville = await models.prisma.ville.update({ where: { id }, data: sanitizeInput(req.body) });

        const syncService = getSyncService(req, models);
        if (syncService) await syncService.enqueue('villes', 'UPDATE', ville);

        res.json(BaseResponseDTO.success(VilleDTO.fromEntity(ville), 'Ville mise à jour avec succès'));
      } catch (error) {
        console.error('Erreur mise à jour ville:', error);
        if (error.code === 'P2002') {
          return res.status(409).json(BaseResponseDTO.error('Cette ville existe déjà'));
        }
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la mise à jour de la ville'));
      }
    }
  );

  router.delete('/:id',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);
        const existing = await models.prisma.ville.findUnique({ where: { id } });
        if (!existing) {
          return res.status(404).json(BaseResponseDTO.error('Ville non trouvée'));
        }

        const zoneCount = await models.prisma.zone.count({ where: { villeId: id } });
        if (zoneCount > 0) {
          return res.status(409).json(
            BaseResponseDTO.error('Impossible de supprimer cette ville car des zones y sont rattachées', [{
              field: 'zones',
              message: `${zoneCount} zone(s) existent pour cette ville`
            }])
          );
        }

        await models.prisma.ville.delete({ where: { id } });

        const syncService = getSyncService(req, models);
        if (syncService) await syncService.enqueue('villes', 'DELETE', { id });

        res.json(BaseResponseDTO.success(null, 'Ville supprimée avec succès'));
      } catch (error) {
        console.error('Erreur suppression ville:', error);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la suppression de la ville'));
      }
    }
  );

  return router;
}

/**
 * GET/POST /zones (filtrable par ?villeId=), PUT/DELETE /zones/:id
 */
function createZoneRouter(models) {
  const router = express.Router();

  router.get('/',
    validate(zoneSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { villeId } = req.query;
        const zones = await models.prisma.zone.findMany({
          where: villeId ? { villeId: parseInt(villeId) } : undefined,
          include: { ville: true },
          orderBy: { nom: 'asc' }
        });
        res.json(BaseResponseDTO.success(ZoneDTO.fromEntities(zones), 'Zones récupérées avec succès'));
      } catch (error) {
        console.error('Erreur liste zones:', error);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des zones'));
      }
    }
  );

  router.post('/',
    authenticateToken(models.authService),
    validate(zoneSchemas.create),
    async (req, res) => {
      try {
        const data = sanitizeInput(req.body);

        const ville = await models.prisma.ville.findUnique({ where: { id: data.villeId } });
        if (!ville) {
          return res.status(404).json(BaseResponseDTO.error('Ville non trouvée'));
        }

        const zone = await models.prisma.zone.create({ data, include: { ville: true } });

        const syncService = getSyncService(req, models);
        if (syncService) await syncService.enqueue('zones', 'INSERT', zone);

        res.status(201).json(BaseResponseDTO.success(ZoneDTO.fromEntity(zone), 'Zone créée avec succès'));
      } catch (error) {
        console.error('Erreur création zone:', error);
        if (error.code === 'P2002') {
          return res.status(409).json(BaseResponseDTO.error('Cette zone existe déjà pour cette ville'));
        }
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la création de la zone'));
      }
    }
  );

  router.put('/:id',
    authenticateToken(models.authService),
    validateId,
    validate(zoneSchemas.update),
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);
        const existing = await models.prisma.zone.findUnique({ where: { id } });
        if (!existing) {
          return res.status(404).json(BaseResponseDTO.error('Zone non trouvée'));
        }

        const data = sanitizeInput(req.body);
        if (data.villeId) {
          const ville = await models.prisma.ville.findUnique({ where: { id: data.villeId } });
          if (!ville) {
            return res.status(404).json(BaseResponseDTO.error('Ville non trouvée'));
          }
        }

        const zone = await models.prisma.zone.update({ where: { id }, data, include: { ville: true } });

        const syncService = getSyncService(req, models);
        if (syncService) await syncService.enqueue('zones', 'UPDATE', zone);

        res.json(BaseResponseDTO.success(ZoneDTO.fromEntity(zone), 'Zone mise à jour avec succès'));
      } catch (error) {
        console.error('Erreur mise à jour zone:', error);
        if (error.code === 'P2002') {
          return res.status(409).json(BaseResponseDTO.error('Cette zone existe déjà pour cette ville'));
        }
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la mise à jour de la zone'));
      }
    }
  );

  router.delete('/:id',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);
        const existing = await models.prisma.zone.findUnique({ where: { id } });
        if (!existing) {
          return res.status(404).json(BaseResponseDTO.error('Zone non trouvée'));
        }

        const commercialCount = await models.prisma.commercial.count({ where: { zoneId: id } });
        if (commercialCount > 0) {
          return res.status(409).json(
            BaseResponseDTO.error('Impossible de supprimer cette zone car des commerciaux y sont rattachés', [{
              field: 'commerciaux',
              message: `${commercialCount} commercial(aux) existent pour cette zone`
            }])
          );
        }

        await models.prisma.zone.delete({ where: { id } });

        const syncService = getSyncService(req, models);
        if (syncService) await syncService.enqueue('zones', 'DELETE', { id });

        res.json(BaseResponseDTO.success(null, 'Zone supprimée avec succès'));
      } catch (error) {
        console.error('Erreur suppression zone:', error);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la suppression de la zone'));
      }
    }
  );

  return router;
}

/**
 * GET/POST /commerciaux (filtrable par ?zoneId= ou ?villeId=), PUT/DELETE /commerciaux/:id
 */
function createCommercialRouter(models) {
  const router = express.Router();

  router.get('/',
    validatePagination,
    validate(commercialSchemas.search, 'query'),
    async (req, res) => {
      try {
        const { page, limit, zoneId, villeId, isActive, q } = req.query;

        const where = {};
        if (zoneId) where.zoneId = parseInt(zoneId);
        if (villeId) where.zone = { villeId: parseInt(villeId) };
        if (isActive !== undefined) where.isActive = isActive;
        if (q) {
          where.OR = [
            { nom: { contains: q } },
            { prenom: { contains: q } },
            { telephone: { contains: q } }
          ];
        }

        const options = {
          where,
          include: { zone: { include: { ville: true } } },
          orderBy: { nom: 'asc' }
        };
        if (page && limit) {
          options.skip = (parseInt(page) - 1) * parseInt(limit);
          options.take = parseInt(limit);
        }

        const [commerciaux, total] = await Promise.all([
          models.prisma.commercial.findMany(options),
          models.prisma.commercial.count({ where })
        ]);

        if (page && limit) {
          const response = new PaginatedResponseDTO(
            CommercialDTO.fromEntities(commerciaux),
            { page: parseInt(page), limit: parseInt(limit), total },
            'Commerciaux récupérés avec succès'
          );
          return res.json(response);
        }

        res.json(BaseResponseDTO.success(CommercialDTO.fromEntities(commerciaux), 'Commerciaux récupérés avec succès'));
      } catch (error) {
        console.error('Erreur liste commerciaux:', error);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des commerciaux'));
      }
    }
  );

  router.post('/',
    authenticateToken(models.authService),
    validate(commercialSchemas.create),
    async (req, res) => {
      try {
        const data = sanitizeInput(req.body);

        const zone = await models.prisma.zone.findUnique({ where: { id: data.zoneId } });
        if (!zone) {
          return res.status(404).json(BaseResponseDTO.error('Zone non trouvée'));
        }

        const commercial = await models.prisma.commercial.create({
          data,
          include: { zone: { include: { ville: true } } }
        });

        const syncService = getSyncService(req, models);
        if (syncService) await syncService.enqueue('commerciaux', 'INSERT', commercial);

        res.status(201).json(BaseResponseDTO.success(CommercialDTO.fromEntity(commercial), 'Commercial créé avec succès'));
      } catch (error) {
        console.error('Erreur création commercial:', error);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la création du commercial'));
      }
    }
  );

  router.put('/:id',
    authenticateToken(models.authService),
    validateId,
    validate(commercialSchemas.update),
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);
        const existing = await models.prisma.commercial.findUnique({ where: { id } });
        if (!existing) {
          return res.status(404).json(BaseResponseDTO.error('Commercial non trouvé'));
        }

        const data = sanitizeInput(req.body);
        if (data.zoneId) {
          const zone = await models.prisma.zone.findUnique({ where: { id: data.zoneId } });
          if (!zone) {
            return res.status(404).json(BaseResponseDTO.error('Zone non trouvée'));
          }
        }

        const commercial = await models.prisma.commercial.update({
          where: { id },
          data,
          include: { zone: { include: { ville: true } } }
        });

        const syncService = getSyncService(req, models);
        if (syncService) await syncService.enqueue('commerciaux', 'UPDATE', commercial);

        res.json(BaseResponseDTO.success(CommercialDTO.fromEntity(commercial), 'Commercial mis à jour avec succès'));
      } catch (error) {
        console.error('Erreur mise à jour commercial:', error);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la mise à jour du commercial'));
      }
    }
  );

  router.delete('/:id',
    authenticateToken(models.authService),
    validateId,
    async (req, res) => {
      try {
        const id = parseInt(req.params.id);
        const existing = await models.prisma.commercial.findUnique({ where: { id } });
        if (!existing) {
          return res.status(404).json(BaseResponseDTO.error('Commercial non trouvé'));
        }

        const venteCount = await models.prisma.vente.count({ where: { commercialId: id } });
        if (venteCount > 0) {
          return res.status(409).json(
            BaseResponseDTO.error(
              'Impossible de supprimer ce commercial car des ventes lui sont attribuées',
              [{
                field: 'ventes',
                message: `${venteCount} vente(s) associée(s)`,
                suggestion: 'Désactivez le commercial plutôt que de le supprimer (isActive=false)'
              }]
            )
          );
        }

        await models.prisma.commercial.delete({ where: { id } });

        const syncService = getSyncService(req, models);
        if (syncService) await syncService.enqueue('commerciaux', 'DELETE', { id });

        res.json(BaseResponseDTO.success(null, 'Commercial supprimé avec succès'));
      } catch (error) {
        console.error('Erreur suppression commercial:', error);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la suppression du commercial'));
      }
    }
  );

  return router;
}

module.exports = { createVilleRouter, createZoneRouter, createCommercialRouter };
