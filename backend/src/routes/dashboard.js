const express = require('express');
const { PrismaClient } = require('../config/prisma-client.js');

const prisma = new PrismaClient();

/**
 * Crée le routeur pour les statistiques du dashboard
 * @param {Object} dependencies - Les dépendances injectées
 * @returns {Router}
 */
function createDashboardRouter(dependencies) {
  const router = express.Router();

  // GET /dashboard/stats - Statistiques générales
  router.get('/stats', async (req, res) => {
    try {
      console.log('📊 [DashboardRouter] Récupération des statistiques générales...');
      const boutiqueId = req.query.boutiqueId ? parseInt(req.query.boutiqueId) : null;
      const venteWhere = { statut: { not: 'annulee' }, ...(boutiqueId ? { boutiqueId } : {}) };

      const totalProducts = await prisma.produit.count();
      const totalUsers = await prisma.utilisateur.count();
      const activeUsers = await prisma.utilisateur.count({ where: { isActive: true } });

      let totalSales = 0, totalRevenue = 0.0;
      try {
        totalSales = await prisma.vente.count({ where: venteWhere });
        const salesSum = await prisma.vente.aggregate({ where: venteWhere, _sum: { montantTotal: true } });
        totalRevenue = salesSum._sum.montantTotal || 0.0;
      } catch (e) {}

      let pendingOrders = 0;
      try { pendingOrders = await prisma.commandeApprovisionnement.count({ where: { statut: 'EN_ATTENTE' } }); } catch (e) {}

      const stats = { totalProducts, totalUsers, activeUsers, totalSales, totalRevenue, pendingOrders, lowStockProducts: 0, monthlyGrowth: 0.0 };
      console.log('✅ [DashboardRouter] Statistiques calculées:', stats);
      res.json({ success: true, data: stats });
    } catch (error) {
      console.error('❌ [DashboardRouter] Erreur statistiques générales:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur lors de la récupération des statistiques', code: 'STATS_FETCH_ERROR' } });
    }
  });

  // GET /dashboard/sales-stats - Statistiques de ventes
  router.get('/sales-stats', async (req, res) => {
    try {
      console.log('💰 [DashboardRouter] Récupération des statistiques de ventes...');
      const boutiqueId = req.query.boutiqueId ? parseInt(req.query.boutiqueId) : null;
      const baseWhere = { statut: { not: 'annulee' }, ...(boutiqueId ? { boutiqueId } : {}) };

      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const weekStart = new Date(today); weekStart.setDate(today.getDate() - today.getDay());
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

      let salesStats = { todaySales: 0, todayRevenue: 0.0, weekSales: 0, weekRevenue: 0.0, monthSales: 0, monthRevenue: 0.0, topProducts: [] };

      try {
        const [todayStats, weekStats, monthStats] = await Promise.all([
          prisma.vente.aggregate({ where: { ...baseWhere, dateVente: { gte: today } }, _count: { id: true }, _sum: { montantTotal: true } }),
          prisma.vente.aggregate({ where: { ...baseWhere, dateVente: { gte: weekStart } }, _count: { id: true }, _sum: { montantTotal: true } }),
          prisma.vente.aggregate({ where: { ...baseWhere, dateVente: { gte: monthStart } }, _count: { id: true }, _sum: { montantTotal: true } }),
        ]);
        salesStats = {
          todaySales: todayStats._count.id || 0, todayRevenue: todayStats._sum.montantTotal || 0.0,
          weekSales: weekStats._count.id || 0, weekRevenue: weekStats._sum.montantTotal || 0.0,
          monthSales: monthStats._count.id || 0, monthRevenue: monthStats._sum.montantTotal || 0.0,
          topProducts: []
        };
      } catch (e) {}

      console.log('✅ [DashboardRouter] Statistiques de ventes calculées:', salesStats);
      res.json({ success: true, data: salesStats });
    } catch (error) {
      console.error('❌ [DashboardRouter] Erreur statistiques de ventes:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur lors de la récupération des statistiques de ventes', code: 'SALES_STATS_FETCH_ERROR' } });
    }
  });

  // GET /dashboard/recent-activities - Activités récentes
  router.get('/recent-activities', async (req, res) => {
    try {
      console.log('📝 [DashboardRouter] Récupération des activités récentes...');

      const activities = [];

      // Récupérer les derniers utilisateurs créés
      try {
        const recentUsers = await prisma.utilisateur.findMany({
          take: 3,
          orderBy: { dateCreation: 'desc' },
          include: { role: true }
        });

        recentUsers.forEach(user => {
          activities.push({
            id: `user_${user.id}`,
            type: 'user',
            title: 'activity_new_user',
            description: `${user.nomUtilisateur} (${user.role?.displayName || ''})`,
            timestamp: user.dateCreation.toISOString(),
            icon: 'user',
            color: 'blue'
          });
        });
      } catch (e) {
        console.log('⚠️ Erreur récupération utilisateurs récents');
      }

      // Récupérer les derniers produits créés
      try {
        const recentProducts = await prisma.produit.findMany({
          take: 3,
          orderBy: { dateCreation: 'desc' }
        });

        recentProducts.forEach(product => {
          activities.push({
            id: `product_${product.id}`,
            type: 'product',
            title: 'activity_new_product',
            description: `${product.nom} - ${product.prixUnitaire ?? 0} FCFA`,
            timestamp: product.dateCreation.toISOString(),
            icon: 'product',
            color: 'green'
          });
        });
      } catch (e) {
        console.log('⚠️ Erreur récupération produits récents');
      }

      // Trier par date décroissante
      activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

      // Limiter à 10 activités
      const limitedActivities = activities.slice(0, 10);

      console.log(`✅ [DashboardRouter] ${limitedActivities.length} activités récentes trouvées`);

      res.json({
        success: true,
        data: limitedActivities
      });
    } catch (error) {
      console.error('❌ [DashboardRouter] Erreur activités récentes:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération des activités récentes',
          code: 'ACTIVITIES_FETCH_ERROR'
        }
      });
    }
  });

  // GET /dashboard/sales-chart - Données du graphique des ventes
  router.get('/sales-chart', async (req, res) => {
    try {
      console.log('📈 [DashboardRouter] Récupération des données du graphique...');
      const boutiqueId = req.query.boutiqueId ? parseInt(req.query.boutiqueId) : null;
      const baseWhere = { statut: { not: 'annulee' }, ...(boutiqueId ? { boutiqueId } : {}) };

      const chartData = [];
      const now = new Date();

      for (let i = 6; i >= 0; i--) {
        const date = new Date(now);
        date.setDate(now.getDate() - i);
        const dayStart = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        const dayEnd = new Date(dayStart); dayEnd.setDate(dayStart.getDate() + 1);

        let sales = 0, revenue = 0.0;
        try {
          const dayStats = await prisma.vente.aggregate({
            where: { ...baseWhere, dateVente: { gte: dayStart, lt: dayEnd } },
            _count: { id: true }, _sum: { montantTotal: true }
          });
          sales = dayStats._count.id || 0;
          revenue = dayStats._sum.montantTotal || 0.0;
        } catch (e) {}

        chartData.push({ date: dayStart.toISOString().split('T')[0], sales, revenue });
      }

      console.log(`✅ [DashboardRouter] Données graphique générées pour ${chartData.length} jours`);
      res.json({ success: true, data: chartData });
    } catch (error) {
      console.error('❌ [DashboardRouter] Erreur données graphique:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur lors de la récupération des données du graphique', code: 'CHART_DATA_FETCH_ERROR' } });
    }
  });

  return router;
}

module.exports = { createDashboardRouter };