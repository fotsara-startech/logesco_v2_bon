/**
 * Middleware de synchronisation automatique
 * Intercepte les réponses d'écriture réussies et enqueue vers Neon
 * Lit les données directement depuis la BD locale (sans relations imbriquées)
 */

const syncService = require('../services/sync-service');

// Mapping route → modèle Prisma + colonnes autorisées (celles qui existent vraiment en BD)
const ROUTE_MODEL_MAP = {
  '/sales':               {
    table: 'ventes', model: 'vente',
    allowedColumns: [
      'id','numeroVente','clientId','vendeurId','sessionId','boutiqueId',
      'dateVente','sousTotal','montantRemise','montantTva','tauxTva',
      'montantTotal','statut','modePaiement','montantPaye','montantRestant'
    ]
  },
  '/products':            { 
    table: 'produits', model: 'produit',
    allowedColumns: [
      'id','reference','nom','description','prixUnitaire','prixAchat','codeBarre',
      'categorieId','seuilStockMinimum','remiseMaxAutorisee','estActif','estService',
      'gestionPeremption','dateCreation','dateModification'
    ]
  },
  '/customers':           { 
    table: 'clients', model: 'client',
    allowedColumns: [
      'id','nom','prenom','telephone','email','adresse',
      'date_creation','date_modification'
    ]
  },
  '/suppliers':           { 
    table: 'fournisseurs', model: 'fournisseur',
    allowedColumns: [
      'id','nom','personne_contact','telephone','email','adresse',
      'date_creation','date_modification'
    ]
  },
  '/procurement':         { 
    table: 'commandes_approvisionnement', model: 'commandeApprovisionnement',
    allowedColumns: [
      'id','numero_commande','fournisseur_id','boutique_id','date_commande',
      'date_livraison_prevue','date_livraison_reelle','montant_total',
      'statut','notes','date_creation','date_modification'
    ]
  },
  '/cash-sessions':       {
    table: 'cash_sessions', model: 'cashSession',
    allowedColumns: [
      'id','caisse_id','utilisateur_id','boutique_id','solde_ouverture',
      'solde_fermeture','date_ouverture','date_fermeture','is_active',
      'metadata','solde_attendu','ecart'
    ]
  },
  '/cash-registers':      { 
    table: 'cash_registers', model: 'cashRegister',
    allowedColumns: [
      'id','nom','description','solde_initial','solde_actuel','is_active',
      'utilisateur_id','boutique_id','date_creation','date_modification',
      'date_ouverture','date_fermeture'
    ]
  },
  '/financial-movements': { 
    table: 'financial_movements', model: 'financialMovement',
    allowedColumns: [
      'id','reference','sessionId','boutiqueId','montant','categorieId',
      'description','date','utilisateurId','notes','dateCreation','dateModification'
    ]
  },
  '/categories':          { 
    table: 'categories', model: 'category',
    allowedColumns: [
      'id','nom','description','date_creation','date_modification'
    ]
  },
  '/boutiques':           { 
    table: 'boutiques', model: 'boutique',
    allowedColumns: [
      'id','nom','adresse','telephone','email','description',
      'est_principale','is_active','date_creation','date_modification'
    ]
  },
  '/users':               { 
    table: 'utilisateurs', model: 'utilisateur',
    fetchFromDb: true,  // mot_de_passe_hash n'est pas dans la réponse API
    allowedColumns: [
      'id','nom_utilisateur','email','mot_de_passe_hash','role_id',
      'is_active','date_creation','date_modification','date_derniere_connexion'
    ]
  },
  '/roles':               { 
    table: 'user_roles', model: 'userRole',
    allowedColumns: [
      'id','nom','display_name','is_admin','privileges',
      'date_creation','date_modification'
    ]
  },
  '/stock-inventory':     { 
    table: 'stock_inventories', model: 'stockInventory',
    allowedColumns: [
      'id','nom','boutique_id','date_inventaire','notes',
      'date_creation','date_modification'
    ]
  },
  '/expiration-dates':    { 
    table: 'dates_peremption', model: 'datePeremption',
    allowedColumns: [
      'id','produit_id','boutique_id','date_peremption','quantite',
      'date_creation','date_modification'
    ]
  },
};

function getConfigFromPath(path) {
  for (const [route, config] of Object.entries(ROUTE_MODEL_MAP)) {
    if (path.includes(route)) return config;
  }
  return null;
}

/**
 * Convertit snake_case en camelCase pour la recherche
 */
function snakeToCamel(str) {
  return str.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
}

/**
 * Middleware principal
 */
function syncMiddleware(prisma) {
  return function(req, res, next) {
    if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) return next();
    if (!process.env.CLOUD_DB_URL) return next();

    const config = getConfigFromPath(req.path);
    if (!config || config.skip) return next();

    const originalJson = res.json.bind(res);
    res.json = function(body) {
      originalJson(body);

      if (body && body.success && body.data) {
        const operation = req.method === 'POST' ? 'INSERT'
          : req.method === 'DELETE' ? 'DELETE'
          : 'UPDATE';

        const responseData = Array.isArray(body.data) ? body.data[0] : body.data;
        const recordId = responseData?.id;
        if (!recordId) return;

        // Si fetchFromDb est activé, récupérer les données directement depuis la BD locale
        if (config.fetchFromDb && prisma) {
          const modelName = config.model;
          prisma[modelName].findUnique({ where: { id: recordId } })
            .then(dbRecord => {
              if (!dbRecord) return;
              syncService.enqueue(config.table, operation, dbRecord).catch(() => {});
            })
            .catch(() => {});
          return;
        }

        // Filtre les colonnes autorisées AVANT d'enqueuer
        let dataToSync = responseData;
        if (config.allowedColumns) {
          dataToSync = {};
          for (const col of config.allowedColumns) {
            const camelCol = snakeToCamel(col);
            
            // Inclure la valeur même si null (null est une valeur valide en BD)
            if (responseData[camelCol] !== undefined) {
              dataToSync[camelCol] = responseData[camelCol];
            } 
            else if (responseData[col] !== undefined) {
              dataToSync[col] = responseData[col];
            }
          }
          if (!dataToSync.id) dataToSync.id = recordId;
        }

        if (process.env.DEBUG_SYNC || config.table === 'cash_sessions' || config.table === 'ventes') {
          console.log(`🔍 Sync ${config.table} (${operation}): ${Object.keys(dataToSync).length} fields`);
          if (process.env.DEBUG_SYNC) {
            console.log(`   Data:`, JSON.stringify(dataToSync).substring(0, 300));
          }
        }

        syncService.enqueue(config.table, operation, dataToSync).catch(() => {});
      }
    };

    next();
  };
}

module.exports = syncMiddleware;
