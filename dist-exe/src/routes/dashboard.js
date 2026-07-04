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

      const totalProducts = await prisma.produit.count({
        where: {
          estActif: true,
          ...(boutiqueId ? { stocksBoutiques: { some: { boutiqueId } } } : {})
        }
      });
      const totalUsers = await prisma.utilisateur.count();
      const activeUsers = await prisma.utilisateur.count({ where: { isActive: true } });

      // Calculer les ventes totales (tous les temps, pas seulement ce mois)
      let totalSales = 0, totalRevenue = 0.0;
      try {
        totalSales = await prisma.vente.count({ where: venteWhere });
        const salesSum = await prisma.vente.aggregate({ where: venteWhere, _sum: { montantTotal: true } });
        totalRevenue = salesSum._sum.montantTotal || 0.0;
      } catch (e) {
        console.log('⚠️ [DashboardRouter] Erreur calcul ventes:', e.message);
      }

      let pendingOrders = 0;
      try { 
        pendingOrders = await prisma.commandeApprovisionnement.count({ 
          where: { 
            statut: 'EN_ATTENTE',
            ...(boutiqueId ? { boutiqueId } : {})
          } 
        }); 
      } catch (e) {
        console.log('⚠️ [DashboardRouter] Erreur calcul commandes:', e.message);
      }

      // Calculer les produits en stock faible (quantité < seuilAlerte)
      let lowStockProducts = 0;
      try {
        const stocks = await prisma.stockBoutique.findMany({
          where: boutiqueId ? { boutiqueId } : {},
          select: { quantiteDisponible: true, produit: { select: { seuilStockMinimum: true } } }
        });
        lowStockProducts = stocks.filter(s => s.quantiteDisponible < (s.produit?.seuilStockMinimum ?? 0)).length;
      } catch (e) {
        console.log('⚠️ [DashboardRouter] Erreur calcul stock faible:', e.message);
      }

      const stats = { 
        totalProducts, 
        totalUsers, 
        activeUsers, 
        totalSales, 
        totalRevenue, 
        pendingOrders, 
        lowStockProducts, 
        monthlyGrowth: 0.0 
      };
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

      // Créer les dates en utilisant le fuseau horaire local
      const now = new Date();
      // Aujourd'hui à 00:00:00
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
      
      // Début de la semaine (dimanche = 0, lundi = 1, etc.)
      const weekStart = new Date(today);
      const dayOfWeek = today.getDay(); // 0 = dimanche, 1 = lundi, ...
      weekStart.setDate(today.getDate() - dayOfWeek); // Revenir au dimanche
      weekStart.setHours(0, 0, 0, 0);
      
      // Début du mois
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);

      console.log('📅 [DashboardRouter] Plages de dates:', {
        today: today.toISOString(),
        weekStart: weekStart.toISOString(),
        monthStart: monthStart.toISOString(),
      });

      let salesStats = { 
        todaySales: 0, todayRevenue: 0.0, 
        weekSales: 0, weekRevenue: 0.0, 
        monthSales: 0, monthRevenue: 0.0, 
        topProducts: [] 
      };

      try {
        const [todayStats, weekStats, monthStats] = await Promise.all([
          prisma.vente.aggregate({ 
            where: { ...baseWhere, dateVente: { gte: today } }, 
            _count: { id: true }, 
            _sum: { montantTotal: true } 
          }),
          prisma.vente.aggregate({ 
            where: { ...baseWhere, dateVente: { gte: weekStart } }, 
            _count: { id: true }, 
            _sum: { montantTotal: true } 
          }),
          prisma.vente.aggregate({ 
            where: { ...baseWhere, dateVente: { gte: monthStart } }, 
            _count: { id: true }, 
            _sum: { montantTotal: true } 
          }),
        ]);
        
        salesStats = {
          todaySales: todayStats._count.id || 0, 
          todayRevenue: todayStats._sum.montantTotal || 0.0,
          weekSales: weekStats._count.id || 0, 
          weekRevenue: weekStats._sum.montantTotal || 0.0,
          monthSales: monthStats._count.id || 0, 
          monthRevenue: monthStats._sum.montantTotal || 0.0,
          topProducts: []
        };

        console.log('✅ [DashboardRouter] Stats calculées:', salesStats);
      } catch (e) {
        console.log('⚠️ [DashboardRouter] Erreur calcul stats ventes:', e.message);
      }

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

      // Générer les 7 derniers jours
      for (let i = 6; i >= 0; i--) {
        const date = new Date(now);
        date.setDate(now.getDate() - i);
        // Début du jour à 00:00:00
        const dayStart = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0, 0);
        // Fin du jour à 23:59:59.999
        const dayEnd = new Date(dayStart);
        dayEnd.setDate(dayStart.getDate() + 1);
        dayEnd.setMilliseconds(dayEnd.getMilliseconds() - 1);

        let sales = 0, revenue = 0.0;
        try {
          const dayStats = await prisma.vente.aggregate({
            where: { 
              ...baseWhere, 
              dateVente: { 
                gte: dayStart, 
                lt: dayEnd 
              } 
            },
            _count: { id: true }, 
            _sum: { montantTotal: true }
          });
          sales = dayStats._count.id || 0;
          revenue = dayStats._sum.montantTotal || 0.0;
        } catch (e) {
          console.log(`⚠️ [DashboardRouter] Erreur calcul jour ${dayStart.toISOString().split('T')[0]}:`, e.message);
        }

        chartData.push({ 
          date: dayStart.toISOString().split('T')[0], 
          sales, 
          revenue 
        });
      }

      console.log(`✅ [DashboardRouter] Données graphique générées pour ${chartData.length} jours`);
      res.json({ success: true, data: chartData });
    } catch (error) {
      console.error('❌ [DashboardRouter] Erreur données graphique:', error);
      res.status(500).json({ success: false, error: { message: 'Erreur lors de la récupération des données du graphique', code: 'CHART_DATA_FETCH_ERROR' } });
    }
  });

  // GET /dashboard/category-sales - Répartition des ventes par catégories
  router.get('/category-sales', async (req, res) => {
    try {
      console.log('📊 [DashboardRouter] Récupération répartition par catégories...');
      const boutiqueId = req.query.boutiqueId ? parseInt(req.query.boutiqueId) : null;

      // Récupérer toutes les ventes non annulées avec leurs détails
      const ventes = await prisma.vente.findMany({
        where: {
          statut: { not: 'annulee' },
          ...(boutiqueId ? { boutiqueId } : {})
        },
        include: {
          details: {
            include: {
              produit: {
                include: {
                  categorie: true
                }
              }
            }
          }
        }
      });

      console.log(`📋 [DashboardRouter] ${ventes.length} ventes trouvées`);

      // Agréger les données par catégorie
      const categoryMap = new Map();

      for (const vente of ventes) {
        for (const detail of vente.details) {
          const produit = detail.produit;
          if (!produit) continue;

          const categorie = produit.categorie;
          const categoryId = categorie?.id || 0;
          const categoryName = categorie?.nom || 'Sans catégorie';

          if (!categoryMap.has(categoryId)) {
            categoryMap.set(categoryId, {
              categoryId,
              categoryName,
              revenue: 0.0,
              quantity: 0
            });
          }

          const entry = categoryMap.get(categoryId);
          entry.revenue += detail.prixUnitaire * detail.quantite;
          entry.quantity += detail.quantite;
        }
      }

      // Convertir en tableau et trier par chiffre d'affaires décroissant
      const categoryData = Array.from(categoryMap.values())
        .sort((a, b) => b.revenue - a.revenue);

      console.log(`✅ [DashboardRouter] ${categoryData.length} catégories trouvées`);
      res.json({ success: true, data: categoryData });
    } catch (error) {
      console.error('❌ [DashboardRouter] Erreur répartition catégories:', error);
      res.status(500).json({ 
        success: false, 
        error: { 
          message: 'Erreur lors de la récupération de la répartition par catégories', 
          code: 'CATEGORY_SALES_FETCH_ERROR' 
        } 
      });
    }
  });

  return router;
}

module.exports = { createDashboardRouter };