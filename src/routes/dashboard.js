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

      // Compter les produits
      const totalProducts = await prisma.produit.count();

      // Compter les utilisateurs
      const totalUsers = await prisma.utilisateur.count();
      const activeUsers = await prisma.utilisateur.count({
        where: { isActive: true }
      });

      // Compter les ventes (si la table existe)
      let totalSales = 0;
      let totalRevenue = 0.0;
      try {
        // Adapter selon votre schéma de ventes - CORRECTION: Exclure les ventes annulées
        totalSales = await prisma.vente.count({
          where: { statut: { not: 'annulee' } }
        });
        const salesSum = await prisma.vente.aggregate({
          where: { statut: { not: 'annulee' } },
          _sum: { montantTotal: true }
        });
        totalRevenue = salesSum._sum.montantTotal || 0.0;
      } catch (e) {
        console.log('⚠️ Table ventes non disponible, utilisation de valeurs par défaut');
      }

      // Compter les commandes en attente
      let pendingOrders = 0;
      try {
        pendingOrders = await prisma.commandeApprovisionnement.count({
          where: { statut: 'EN_ATTENTE' }
        });
      } catch (e) {
        console.log('⚠️ Table commandes non disponible');
      }

      // Produits en stock faible (exemple)
      let lowStockProducts = 0;
      try {
        lowStockProducts = await prisma.produit.count({
          where: { quantiteStock: { lt: 10 } }
        });
      } catch (e) {
        console.log('⚠️ Champ quantiteStock non disponible');
      }

      const stats = {
        totalProducts,
        totalUsers,
        activeUsers,
        totalSales,
        totalRevenue,
        pendingOrders,
        lowStockProducts,
        monthlyGrowth: 0.0, // À calculer selon vos besoins
      };

      console.log('✅ [DashboardRouter] Statistiques calculées:', stats);

      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('❌ [DashboardRouter] Erreur statistiques générales:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération des statistiques',
          code: 'STATS_FETCH_ERROR'
        }
      });
    }
  });

  // GET /dashboard/sales-stats - Statistiques de ventes
  router.get('/sales-stats', async (req, res) => {
    try {
      console.log('💰 [DashboardRouter] Récupération des statistiques de ventes...');

      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const weekStart = new Date(today);
      weekStart.setDate(today.getDate() - today.getDay());
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

      let salesStats = {
        todaySales: 0,
        todayRevenue: 0.0,
        weekSales: 0,
        weekRevenue: 0.0,
        monthSales: 0,
        monthRevenue: 0.0,
        topProducts: []
      };

      try {
        // Ventes d'aujourd'hui - CORRECTION: Exclure les ventes annulées
        const todayStats = await prisma.vente.aggregate({
          where: {
            dateCreation: { gte: today },
            statut: { not: 'annulee' }
          },
          _count: { id: true },
          _sum: { montantTotal: true }
        });

        // Ventes de la semaine - CORRECTION: Exclure les ventes annulées
        const weekStats = await prisma.vente.aggregate({
          where: {
            dateCreation: { gte: weekStart },
            statut: { not: 'annulee' }
          },
          _count: { id: true },
          _sum: { montantTotal: true }
        });

        // Ventes du mois - CORRECTION: Exclure les ventes annulées
        const monthStats = await prisma.vente.aggregate({
          where: {
            dateCreation: { gte: monthStart },
            statut: { not: 'annulee' }
          },
          _count: { id: true },
          _sum: { montantTotal: true }
        });

        salesStats = {
          todaySales: todayStats._count.id || 0,
          todayRevenue: todayStats._sum.montantTotal || 0.0,
          weekSales: weekStats._count.id || 0,
          weekRevenue: weekStats._sum.montantTotal || 0.0,
          monthSales: monthStats._count.id || 0,
          monthRevenue: monthStats._sum.montantTotal || 0.0,
          topProducts: [] // À implémenter selon vos besoins
        };
      } catch (e) {
        console.log('⚠️ Table ventes non disponible, utilisation de valeurs par défaut');
      }

      console.log('✅ [DashboardRouter] Statistiques de ventes calculées:', salesStats);

      res.json({
        success: true,
        data: salesStats
      });
    } catch (error) {
      console.error('❌ [DashboardRouter] Erreur statistiques de ventes:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération des statistiques de ventes',
          code: 'SALES_STATS_FETCH_ERROR'
        }
      });
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
            title: 'Nouvel utilisateur créé',
            description: `${user.nomUtilisateur} (${user.role?.displayName || 'Sans rôle'})`,
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
            title: 'Nouveau produit ajouté',
            description: `${product.nom} - ${product.prix}€`,
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

      const chartData = [];
      const now = new Date();

      // Générer les données pour les 7 derniers jours
      for (let i = 6; i >= 0; i--) {
        const date = new Date(now);
        date.setDate(now.getDate() - i);
        const dayStart = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        const dayEnd = new Date(dayStart);
        dayEnd.setDate(dayStart.getDate() + 1);

        let sales = 0;
        let revenue = 0.0;

        try {
          const dayStats = await prisma.vente.aggregate({
            where: {
              dateCreation: {
                gte: dayStart,
                lt: dayEnd
              },
              statut: { not: 'annulee' }
            },
            _count: { id: true },
            _sum: { montantTotal: true }
          });

          sales = dayStats._count.id || 0;
          revenue = dayStats._sum.montantTotal || 0.0;
        } catch (e) {
          // Garder les valeurs par défaut (0)
        }

        chartData.push({
          date: dayStart.toISOString().split('T')[0],
          sales,
          revenue
        });
      }

      console.log(`✅ [DashboardRouter] Données graphique générées pour ${chartData.length} jours`);

      res.json({
        success: true,
        data: chartData
      });
    } catch (error) {
      console.error('❌ [DashboardRouter] Erreur données graphique:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération des données du graphique',
          code: 'CHART_DATA_FETCH_ERROR'
        }
      });
    }
  });

  return router;
}

module.exports = { createDashboardRouter };