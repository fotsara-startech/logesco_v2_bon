/**
 * Routes de rapport « ventes par commercial / zone / ville ».
 * Voir commercial-report.js pour la logique d'agrégation.
 */

const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO } = require('../dto');

function createCommercialReportRouter({ commercialReportService, authService }) {
  const router = express.Router();

  /**
   * GET /commercial-reports/summary
   * Résumé global des ventes attribuées à un commercial sur une période
   */
  router.get('/summary',
    authenticateToken(authService),
    async (req, res) => {
      try {
        const { startDate, endDate, boutiqueId } = req.query;

        if (!startDate || !endDate) {
          return res.status(400).json(
            BaseResponseDTO.error('Les dates de début et de fin sont obligatoires')
          );
        }

        const summary = await commercialReportService.getSummary(
          startDate, endDate, boutiqueId ? parseInt(boutiqueId) : null
        );

        res.json(BaseResponseDTO.success(summary, 'Résumé récupéré avec succès'));
      } catch (error) {
        console.error('Erreur récupération résumé commerciaux:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération du résumé'));
      }
    }
  );

  /**
   * GET /commercial-reports/by-commercial
   * Ventes agrégées par commercial (avec zone/ville) sur une période — le
   * regroupement par zone ou par ville se fait côté client à partir de
   * cette même liste.
   */
  router.get('/by-commercial',
    authenticateToken(authService),
    async (req, res) => {
      try {
        const { startDate, endDate, boutiqueId } = req.query;

        if (!startDate || !endDate) {
          return res.status(400).json(
            BaseResponseDTO.error('Les dates de début et de fin sont obligatoires')
          );
        }

        const rows = await commercialReportService.getByCommercial(
          startDate, endDate, boutiqueId ? parseInt(boutiqueId) : null
        );

        res.json(BaseResponseDTO.success(rows, 'Ventes par commercial récupérées avec succès'));
      } catch (error) {
        console.error('Erreur récupération ventes par commercial:', error.message);
        res.status(500).json(BaseResponseDTO.error('Erreur lors de la récupération des ventes par commercial'));
      }
    }
  );

  return router;
}

module.exports = { createCommercialReportRouter };
