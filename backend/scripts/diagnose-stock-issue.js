/**
 * Script de diagnostic pour identifier les problèmes de stock après réception
 */

require('dotenv').config();
const { PrismaClient } = require('../src/config/prisma-client');

async function diagnoseStockIssue() {
  const prisma = new PrismaClient();

  try {
    console.log('🔍 Diagnostic des problèmes de stock\n');
    console.log('═'.repeat(60));

    // 1. Vérifier les dernières commandes reçues
    console.log('\n📋 Dernières commandes d\'approvisionnement');
    console.log('─'.repeat(60));
    
    const commandes = await prisma.commandeApprovisionnement.findMany({
      where: {
        statut: { in: ['partielle', 'terminee'] }
      },
      include: {
        details: {
          include: {
            produit: {
              select: { id: true, nom: true, reference: true }
            }
          }
        }
      },
      orderBy: { dateCommande: 'desc' },
      take: 5
    });

    for (const commande of commandes) {
      console.log(`\n📦 Commande ${commande.numeroCommande} (${commande.statut})`);
      console.log(`   Date: ${commande.dateCommande.toISOString().split('T')[0]}`);
      console.log(`   Boutique ID: ${commande.boutiqueId || 'Global'}`);
      
      for (const detail of commande.details) {
        console.log(`   - Produit: ${detail.produit.nom} (ID: ${detail.produitId})`);
        console.log(`     Commandé: ${detail.quantiteCommandee}, Reçu: ${detail.quantiteRecue}`);
      }
    }

    // 2. Vérifier les mouvements de stock correspondants
    console.log('\n\n📊 Mouvements de stock récents (type: achat)');
    console.log('─'.repeat(60));
    
    const mouvements = await prisma.mouvementStock.findMany({
      where: {
        typeMouvement: 'achat',
        typeReference: 'approvisionnement'
      },
      include: {
        produit: {
          select: { id: true, nom: true, reference: true }
        }
      },
      orderBy: { dateMouvement: 'desc' },
      take: 10
    });

    if (mouvements.length === 0) {
      console.log('⚠️  Aucun mouvement de stock de type "achat" trouvé !');
      console.log('   Cela explique pourquoi les stocks ne sont pas mis à jour.');
    } else {
      for (const mvt of mouvements) {
        console.log(`\n📝 Mouvement ID ${mvt.id}`);
        console.log(`   Produit: ${mvt.produit.nom} (ID: ${mvt.produitId})`);
        console.log(`   Boutique ID: ${mvt.boutiqueId || 'Global'}`);
        console.log(`   Quantité: +${mvt.changementQuantite}`);
        console.log(`   Date: ${mvt.dateMouvement.toISOString()}`);
        console.log(`   Référence: ${mvt.typeReference} #${mvt.referenceId}`);
      }
    }

    // 3. Vérifier l'état actuel des stocks
    console.log('\n\n💾 État actuel des stocks');
    console.log('─'.repeat(60));

    // Récupérer les produits des dernières commandes
    const produitIds = [...new Set(commandes.flatMap(c => c.details.map(d => d.produitId)))];
    
    for (const produitId of produitIds.slice(0, 5)) {
      const produit = await prisma.produit.findUnique({
        where: { id: produitId },
        include: {
          stock: true,
          stocksBoutiques: true
        }
      });

      if (!produit) continue;

      console.log(`\n📦 ${produit.nom} (ID: ${produitId})`);
      
      // Stock global
      if (produit.stock) {
        console.log(`   Stock global: ${produit.stock.quantiteDisponible} disponible, ${produit.stock.quantiteReservee} réservé`);
      } else {
        console.log(`   ⚠️  Pas de stock global`);
      }

      // Stocks par boutique
      if (produit.stocksBoutiques.length > 0) {
        console.log(`   Stocks par boutique:`);
        for (const sb of produit.stocksBoutiques) {
          console.log(`     - Boutique ${sb.boutiqueId}: ${sb.quantiteDisponible} disponible, ${sb.quantiteReservee} réservé`);
        }
      } else {
        console.log(`   ⚠️  Pas de stock boutique`);
      }

      // Calculer le total des mouvements pour ce produit
      const totalMouvements = await prisma.mouvementStock.aggregate({
        where: {
          produitId: produitId,
          typeMouvement: 'achat'
        },
        _sum: {
          changementQuantite: true
        }
      });

      const totalAchats = totalMouvements._sum.changementQuantite || 0;
      console.log(`   Total achats (mouvements): ${totalAchats}`);

      // Vérifier la cohérence
      const stockTotal = (produit.stock?.quantiteDisponible || 0) + 
                        produit.stocksBoutiques.reduce((sum, sb) => sum + sb.quantiteDisponible, 0);
      
      if (totalAchats > 0 && stockTotal === 0) {
        console.log(`   ❌ INCOHÉRENCE: ${totalAchats} achats enregistrés mais stock = 0`);
      } else if (totalAchats !== stockTotal) {
        console.log(`   ⚠️  Différence: Achats=${totalAchats}, Stock=${stockTotal}`);
      } else {
        console.log(`   ✅ Cohérent`);
      }
    }

    // 4. Vérifier l'historique des prix d'achat
    console.log('\n\n💰 Historique des prix d\'achat récents');
    console.log('─'.repeat(60));
    
    const historique = await prisma.historiquePrixAchat.findMany({
      where: {
        source: 'approvisionnement'
      },
      include: {
        produit: {
          select: { id: true, nom: true, cump: true }
        }
      },
      orderBy: { dateCreation: 'desc' },
      take: 5
    });

    if (historique.length === 0) {
      console.log('⚠️  Aucun historique de prix d\'achat trouvé');
    } else {
      for (const h of historique) {
        console.log(`\n💵 ${h.produit.nom} (ID: ${h.produitId})`);
        console.log(`   Prix d'achat: ${h.prixAchat} FCFA`);
        console.log(`   Quantité: ${h.quantite}`);
        console.log(`   CUMP actuel: ${h.produit.cump || 'Non calculé'} FCFA`);
        console.log(`   Date: ${h.dateCreation.toISOString().split('T')[0]}`);
      }
    }

    console.log('\n' + '═'.repeat(60));
    console.log('\n💡 Recommandations:');
    console.log('─'.repeat(60));

    if (mouvements.length === 0) {
      console.log('❌ PROBLÈME IDENTIFIÉ: Les mouvements de stock ne sont pas créés');
      console.log('   → Vérifiez les logs du serveur lors de la réception');
      console.log('   → Vérifiez que la transaction se termine correctement');
      console.log('   → Redémarrez le serveur et réessayez');
    } else {
      console.log('✅ Les mouvements de stock sont créés correctement');
      console.log('   → Vérifiez que les hooks Prisma sont actifs');
      console.log('   → Vérifiez les logs de synchronisation');
    }

  } catch (error) {
    console.error('\n❌ Erreur lors du diagnostic:', error.message);
    console.error(error.stack);
  } finally {
    await prisma.$disconnect();
  }
}

diagnoseStockIssue();
