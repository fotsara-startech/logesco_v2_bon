/**
 * Hooks Prisma pour synchroniser automatiquement les tables modifiées
 * Utilise l'API $extends de Prisma v5+
 */

const syncService = require('../services/sync-service');

// Tables à synchroniser automatiquement avec leurs colonnes
const SYNC_TABLES = {
  mouvementStock: {
    table: 'mouvements_stock',
    columns: [
      'id', 'produit_id', 'boutique_id', 'type_mouvement', 'changement_quantite',
      'reference_id', 'type_reference', 'date_mouvement', 'notes'
      // Note: mouvements_stock n'a PAS de date_modification
    ]
  },
  stockBoutique: {
    table: 'stock_boutiques',
    columns: [
      'id', 'boutique_id', 'produit_id', 'quantite_disponible',
      'quantite_reservee', 'derniere_maj', 'date_modification'
    ]
  },
  stock: {
    table: 'stock',
    columns: [
      'id', 'produit_id', 'quantite_disponible', 'quantite_reservee',
      'derniere_maj', 'date_modification'
    ]
  }
};

/**
 * Filtre et convertit les données pour la synchronisation
 */
function prepareDataForSync(modelName, data, columns) {
  const syncData = {};
  
  for (const col of columns) {
    // Essayer d'abord avec le nom snake_case
    if (data[col] !== undefined) {
      syncData[col] = data[col];
    } else {
      // Essayer avec camelCase
      const camelCol = col.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
      if (data[camelCol] !== undefined) {
        syncData[col] = data[camelCol];
      }
    }
  }
  
  return syncData;
}

/**
 * Synchronise un enregistrement vers Neon (ASYNCHRONE - ne bloque pas)
 * Utilise setImmediate pour exécuter après la transaction
 */
function syncRecord(modelName, operation, recordId, prisma) {
  const syncConfig = SYNC_TABLES[modelName];
  if (!syncConfig) return;

  // Exécuter la synchronisation de manière asynchrone APRÈS la transaction
  // Ne pas utiliser await ici pour ne pas bloquer la transaction
  setImmediate(async () => {
    try {
      if (operation !== 'DELETE') {
        // Récupérer les données complètes depuis la BD
        const fullData = await prisma[modelName].findUnique({
          where: { id: recordId }
        });

        if (fullData) {
          const syncData = prepareDataForSync(modelName, fullData, syncConfig.columns);
          
          if (process.env.DEBUG_SYNC) {
            console.log(`🔄 [Prisma Extension] ${syncConfig.table} (${operation}):`, syncData);
          }
          
          await syncService.enqueue(syncConfig.table, operation, syncData);
        }
      } else {
        // Pour DELETE, utiliser l'ID
        await syncService.enqueue(syncConfig.table, 'DELETE', { id: recordId });
      }
    } catch (error) {
      // Ne pas bloquer l'opération principale en cas d'erreur de sync
      console.error(`❌ Erreur sync ${modelName}:`, error.message);
    }
  });
}

/**
 * Configure les hooks Prisma pour la synchronisation
 * Utilise l'API $extends de Prisma v5+
 */
function setupPrismaSyncHooks(prisma) {
  // Vérifications de sécurité
  if (!prisma) {
    console.error('❌ setupPrismaSyncHooks: Instance Prisma non fournie');
    return prisma;
  }

  if (!process.env.CLOUD_DB_URL) {
    console.log('ℹ️  setupPrismaSyncHooks: CLOUD_DB_URL non défini, hooks désactivés');
    return prisma;
  }

  // Vérifier que prisma a la méthode $extends (Prisma v5+)
  if (typeof prisma.$extends !== 'function') {
    console.error('❌ setupPrismaSyncHooks: Prisma.$extends non disponible');
    console.error('   Version Prisma incompatible (nécessite v5+)');
    return prisma;
  }

  console.log('🔧 setupPrismaSyncHooks: Configuration des extensions Prisma...');

  try {
    // Créer une extension Prisma pour intercepter les opérations
    const extendedPrisma = prisma.$extends({
      name: 'sync-extension',
      query: {
        // Hook pour mouvementStock
        mouvementStock: {
          async create({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('mouvementStock', 'INSERT', result.id, prisma);
            }
            return result;
          },
          async update({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('mouvementStock', 'UPDATE', result.id, prisma);
            }
            return result;
          },
          async delete({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('mouvementStock', 'DELETE', result.id, prisma);
            }
            return result;
          }
        },
        // Hook pour stockBoutique
        stockBoutique: {
          async create({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('stockBoutique', 'INSERT', result.id, prisma);
            }
            return result;
          },
          async update({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('stockBoutique', 'UPDATE', result.id, prisma);
            }
            return result;
          },
          async upsert({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('stockBoutique', 'UPDATE', result.id, prisma);
            }
            return result;
          },
          async delete({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('stockBoutique', 'DELETE', result.id, prisma);
            }
            return result;
          }
        },
        // Hook pour stock
        stock: {
          async create({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('stock', 'INSERT', result.id, prisma);
            }
            return result;
          },
          async update({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('stock', 'UPDATE', result.id, prisma);
            }
            return result;
          },
          async upsert({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('stock', 'UPDATE', result.id, prisma);
            }
            return result;
          },
          async delete({ args, query }) {
            const result = await query(args);
            if (result?.id) {
              syncRecord('stock', 'DELETE', result.id, prisma);
            }
            return result;
          }
        }
      }
    });

    console.log('✅ Hooks Prisma de synchronisation activés pour:', Object.keys(SYNC_TABLES).join(', '));
    console.log('   Tables surveillées:', Object.values(SYNC_TABLES).map(t => t.table).join(', '));
    console.log('   Extension Prisma appliquée avec succès');
    
    return extendedPrisma;
  } catch (error) {
    console.error('❌ Erreur lors de la configuration des hooks Prisma:', error.message);
    console.error('   Stack:', error.stack);
    return prisma;
  }
}

module.exports = { setupPrismaSyncHooks };
