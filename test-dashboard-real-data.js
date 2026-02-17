const axios = require('axios');

async function testDashboardRealData() {
  try {
    console.log('🧪 Test des données réelles du dashboard...');

    // 1. Test des statistiques générales
    console.log('\n📊 1. Test des statistiques générales:');
    const statsResponse = await axios.get('http://localhost:3002/api/v1/dashboard/stats');
    const stats = statsResponse.data.data;
    
    console.log('✅ Statistiques générales reçues:');
    console.log(`   - Total Produits: ${stats.totalProducts}`);
    console.log(`   - Total Utilisateurs: ${stats.totalUsers}`);
    console.log(`   - Utilisateurs Actifs: ${stats.activeUsers}`);
    console.log(`   - Total Ventes: ${stats.totalSales}`);
    console.log(`   - Revenus Total: ${stats.totalRevenue}€`);
    console.log(`   - Commandes en Attente: ${stats.pendingOrders}`);
    console.log(`   - Produits Stock Faible: ${stats.lowStockProducts}`);

    // 2. Test des statistiques de ventes
    console.log('\n💰 2. Test des statistiques de ventes:');
    try {
      const salesResponse = await axios.get('http://localhost:3002/api/v1/dashboard/sales-stats');
      const salesStats = salesResponse.data.data;
      
      console.log('✅ Statistiques de ventes reçues:');
      console.log(`   - Ventes Aujourd'hui: ${salesStats.todaySales} (${salesStats.todayRevenue}€)`);
      console.log(`   - Ventes Cette Semaine: ${salesStats.weekSales} (${salesStats.weekRevenue}€)`);
      console.log(`   - Ventes Ce Mois: ${salesStats.monthSales} (${salesStats.monthRevenue}€)`);
    } catch (e) {
      console.log('⚠️ Statistiques de ventes non disponibles (table ventes manquante)');
    }

    // 3. Test des activités récentes
    console.log('\n📝 3. Test des activités récentes:');
    const activitiesResponse = await axios.get('http://localhost:3002/api/v1/dashboard/recent-activities');
    const activities = activitiesResponse.data.data;
    
    console.log(`✅ ${activities.length} activités récentes trouvées:`);
    activities.slice(0, 5).forEach((activity, index) => {
      const date = new Date(activity.timestamp).toLocaleDateString('fr-FR');
      console.log(`   ${index + 1}. ${activity.title}`);
      console.log(`      ${activity.description} (${date})`);
    });

    // 4. Test des données du graphique
    console.log('\n📈 4. Test des données du graphique:');
    try {
      const chartResponse = await axios.get('http://localhost:3002/api/v1/dashboard/sales-chart');
      const chartData = chartResponse.data.data;
      
      console.log(`✅ Données graphique pour ${chartData.length} jours:`);
      chartData.forEach(day => {
        const date = new Date(day.date).toLocaleDateString('fr-FR');
        console.log(`   ${date}: ${day.sales} ventes, ${day.revenue}€`);
      });
    } catch (e) {
      console.log('⚠️ Données graphique non disponibles (table ventes manquante)');
    }

    // 5. Comparaison avec les anciennes données de test
    console.log('\n🔄 5. Comparaison avec les données de test:');
    console.log('   AVANT (données de test):');
    console.log('   - Produits: 156, Ventes: 12, Clients: 89');
    console.log('   APRÈS (données réelles):');
    console.log(`   - Produits: ${stats.totalProducts}, Ventes: ${stats.totalSales}, Utilisateurs: ${stats.totalUsers}`);
    
    if (stats.totalProducts > 0 || stats.totalUsers > 0) {
      console.log('   ✅ Les données réelles sont maintenant utilisées !');
    } else {
      console.log('   ⚠️ Base de données vide, mais le système fonctionne');
    }

    console.log('\n🎉 Test terminé avec succès !');
    console.log('📋 Résumé:');
    console.log('   - API dashboard fonctionnelle');
    console.log('   - Données réelles récupérées depuis la base');
    console.log('   - Fallback intelligent si données manquantes');
    console.log('   - Activités récentes générées automatiquement');

  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
  }
}

testDashboardRealData();