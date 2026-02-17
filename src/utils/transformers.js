/**
 * Utilitaires de transformation de données pour LOGESCO
 * Fonctions helper pour convertir et formater les données
 */

/**
 * Transforme les paramètres de requête en options Prisma
 * @param {Object} query - Paramètres de requête
 * @returns {Object} Options Prisma formatées
 */
function buildPrismaQuery(query) {
  const options = {};

  // Pagination
  if (query.page && query.limit) {
    const page = parseInt(query.page) || 1;
    const limit = parseInt(query.limit) || 20;
    options.skip = (page - 1) * limit;
    options.take = limit;
  }

  // Tri
  if (query.sortBy) {
    options.orderBy = {
      [query.sortBy]: query.sortOrder || 'asc'
    };
  }

  return options;
}

/**
 * Construit les conditions de recherche pour les produits
 * @param {Object} searchParams - Paramètres de recherche
 * @returns {Object} Conditions Prisma where
 */
function buildProductSearchConditions(searchParams) {
  const conditions = {};

  if (searchParams.q) {
    conditions.OR = [
      { nom: { contains: searchParams.q } },
      { reference: { contains: searchParams.q } },
      { description: { contains: searchParams.q } },
      { codeBarre: { contains: searchParams.q } }
    ];
  }

  if (searchParams.categorie) {
    conditions.categorie = { 
      nom: { contains: searchParams.categorie }
    };
  }

  if (typeof searchParams.estActif === 'boolean') {
    conditions.estActif = searchParams.estActif;
  }

  return conditions;
}

/**
 * Construit les conditions de recherche pour les clients
 * @param {Object} searchParams - Paramètres de recherche
 * @returns {Object} Conditions Prisma where
 */
function buildClientSearchConditions(searchParams) {
  const conditions = {};

  if (searchParams.q) {
    conditions.OR = [
      { nom: { contains: searchParams.q } },
      { prenom: { contains: searchParams.q } },
      { telephone: { contains: searchParams.q } },
      { email: { contains: searchParams.q } }
    ];
  }

  if (searchParams.telephone) {
    conditions.telephone = { contains: searchParams.telephone };
  }

  if (searchParams.email) {
    conditions.email = { contains: searchParams.email };
  }

  return conditions;
}

/**
 * Construit les conditions de recherche pour les fournisseurs
 * @param {Object} searchParams - Paramètres de recherche
 * @returns {Object} Conditions Prisma where
 */
function buildSupplierSearchConditions(searchParams) {
  const conditions = {};

  if (searchParams.q) {
    conditions.OR = [
      { nom: { contains: searchParams.q } },
      { personneContact: { contains: searchParams.q } },
      { telephone: { contains: searchParams.q } },
      { email: { contains: searchParams.q } }
    ];
  }

  if (searchParams.telephone) {
    conditions.telephone = { contains: searchParams.telephone };
  }

  if (searchParams.email) {
    conditions.email = { contains: searchParams.email };
  }

  return conditions;
}

/**
 * Construit les conditions de recherche pour les ventes
 * @param {Object} searchParams - Paramètres de recherche
 * @returns {Object} Conditions Prisma where
 */
function buildSalesSearchConditions(searchParams) {
  const conditions = {};

  if (searchParams.clientId) {
    conditions.clientId = parseInt(searchParams.clientId);
  }

  if (searchParams.statut) {
    conditions.statut = searchParams.statut;
  }

  if (searchParams.modePaiement) {
    conditions.modePaiement = searchParams.modePaiement;
  }

  if (searchParams.dateDebut || searchParams.dateFin) {
    conditions.dateVente = {};
    if (searchParams.dateDebut) {
      conditions.dateVente.gte = new Date(searchParams.dateDebut);
    }
    if (searchParams.dateFin) {
      conditions.dateVente.lte = new Date(searchParams.dateFin);
    }
  }

  return conditions;
}

/**
 * Construit les conditions de recherche pour les commandes d'approvisionnement
 * @param {Object} searchParams - Paramètres de recherche
 * @returns {Object} Conditions Prisma where
 */
function buildOrderSearchConditions(searchParams) {
  const conditions = {};

  if (searchParams.fournisseurId) {
    conditions.fournisseurId = parseInt(searchParams.fournisseurId);
  }

  if (searchParams.statut) {
    conditions.statut = searchParams.statut;
  }

  if (searchParams.dateDebut || searchParams.dateFin) {
    conditions.dateCommande = {};
    if (searchParams.dateDebut) {
      conditions.dateCommande.gte = new Date(searchParams.dateDebut);
    }
    if (searchParams.dateFin) {
      conditions.dateCommande.lte = new Date(searchParams.dateFin);
    }
  }

  return conditions;
}

/**
 * Génère un numéro de vente unique
 * @returns {string} Numéro de vente formaté
 */
function generateSaleNumber() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const time = String(now.getHours()).padStart(2, '0') + 
               String(now.getMinutes()).padStart(2, '0') + 
               String(now.getSeconds()).padStart(2, '0');
  
  return `VTE-${year}${month}${day}-${time}`;
}

/**
 * Génère un numéro de commande d'approvisionnement unique
 * @returns {string} Numéro de commande formaté
 */
function generateOrderNumber() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const time = String(now.getHours()).padStart(2, '0') + 
               String(now.getMinutes()).padStart(2, '0') + 
               String(now.getSeconds()).padStart(2, '0');
  
  return `CMD-${year}${month}${day}-${time}`;
}

/**
 * Génère un numéro de reçu unique
 * @param {Object} prisma - Instance Prisma
 * @returns {Promise<string>} Numéro de reçu formaté
 */
async function generateReceiptNumber(prisma) {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  
  // Compter les reçus du jour pour générer un numéro séquentiel
  const startOfDay = new Date(year, now.getMonth(), now.getDate());
  const endOfDay = new Date(year, now.getMonth(), now.getDate() + 1);
  
  const count = await prisma.historiqueRecu.count({
    where: {
      dateGeneration: {
        gte: startOfDay,
        lt: endOfDay
      }
    }
  });
  
  const sequence = String(count + 1).padStart(4, '0');
  return `RCU-${year}${month}${day}-${sequence}`;
}

/**
 * Construit les conditions de recherche pour les reçus
 * @param {Object} searchParams - Paramètres de recherche
 * @returns {Object} Conditions Prisma where
 */
function buildReceiptSearchConditions(searchParams) {
  const conditions = {};

  if (searchParams.venteId) {
    conditions.venteId = parseInt(searchParams.venteId);
  }

  if (searchParams.numeroRecu) {
    conditions.numeroRecu = {
      contains: searchParams.numeroRecu
    };
  }

  if (searchParams.formatImpression) {
    conditions.formatImpression = searchParams.formatImpression;
  }

  if (searchParams.dateDebut || searchParams.dateFin) {
    conditions.dateGeneration = {};
    if (searchParams.dateDebut) {
      conditions.dateGeneration.gte = new Date(searchParams.dateDebut);
    }
    if (searchParams.dateFin) {
      conditions.dateGeneration.lte = new Date(searchParams.dateFin);
    }
  }

  // Conditions pour la vente associée
  if (searchParams.numeroVente || searchParams.clientNom) {
    conditions.vente = {};
    
    if (searchParams.numeroVente) {
      conditions.vente.numeroVente = {
        contains: searchParams.numeroVente
      };
    }
    
    if (searchParams.clientNom) {
      conditions.vente.client = {
        OR: [
          { nom: { contains: searchParams.clientNom } },
          { prenom: { contains: searchParams.clientNom } }
        ]
      };
    }
  }

  return conditions;
}

/**
 * Calcule le total d'une vente à partir des détails
 * @param {Array} details - Détails de la vente
 * @returns {Object} Totaux calculés
 */
function calculateSaleTotals(details) {
  const sousTotal = details.reduce((sum, detail) => {
    return sum + (detail.quantite * detail.prixUnitaire);
  }, 0);

  return {
    sousTotal: parseFloat(sousTotal.toFixed(2))
  };
}

/**
 * Calcule le total d'une commande d'approvisionnement
 * @param {Array} details - Détails de la commande
 * @returns {Object} Totaux calculés
 */
function calculateOrderTotals(details) {
  const montantTotal = details.reduce((sum, detail) => {
    return sum + (detail.quantiteCommandee * detail.coutUnitaire);
  }, 0);

  return {
    montantTotal: parseFloat(montantTotal.toFixed(2))
  };
}

/**
 * Valide la disponibilité du stock pour une vente
 * @param {Array} details - Détails de la vente
 * @param {Array} stockItems - Items de stock disponibles
 * @returns {Object} Résultat de validation
 */
function validateStockAvailability(details, stockItems) {
  const errors = [];
  const stockMap = new Map(stockItems.map(item => [item.produitId, item]));

  for (const detail of details) {
    const stock = stockMap.get(detail.produitId);
    
    if (!stock) {
      errors.push({
        produitId: detail.produitId,
        message: 'Produit non trouvé en stock'
      });
      continue;
    }

    if (stock.quantiteDisponible < detail.quantite) {
      errors.push({
        produitId: detail.produitId,
        message: `Stock insuffisant. Disponible: ${stock.quantiteDisponible}, Demandé: ${detail.quantite}`
      });
    }
  }

  return {
    isValid: errors.length === 0,
    errors
  };
}

/**
 * Formate un montant pour l'affichage
 * @param {number} amount - Montant à formater
 * @param {string} currency - Devise (optionnel)
 * @returns {string} Montant formaté
 */
function formatCurrency(amount, currency = 'FCFA') {
  const formatted = parseFloat(amount).toLocaleString('fr-FR', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  });
  
  return `${formatted} ${currency}`;
}

/**
 * Formate une date pour l'affichage français
 * @param {Date|string} date - Date à formater
 * @returns {string} Date formatée
 */
function formatDate(date) {
  const d = new Date(date);
  return d.toLocaleDateString('fr-FR', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  });
}

/**
 * Formate une date et heure pour l'affichage français
 * @param {Date|string} date - Date à formater
 * @returns {string} Date et heure formatées
 */
function formatDateTime(date) {
  const d = new Date(date);
  return d.toLocaleString('fr-FR', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * Nettoie et normalise les données d'entrée
 * @param {Object} data - Données à nettoyer
 * @returns {Object} Données nettoyées
 */
function sanitizeInput(data) {
  const cleaned = {};
  
  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined) {
      cleaned[key] = null;
    } else if (typeof value === 'string') {
      cleaned[key] = value.trim() || null;
    } else {
      cleaned[key] = value;
    }
  }
  
  return cleaned;
}

/**
 * Construit les options d'inclusion Prisma pour les relations
 * @param {Array} includes - Liste des relations à inclure
 * @returns {Object} Options d'inclusion Prisma
 */
function buildIncludeOptions(includes = []) {
  const includeOptions = {};
  
  for (const include of includes) {
    switch (include) {
      case 'stock':
        includeOptions.stock = true;
        break;
      case 'compte':
        includeOptions.compte = true;
        break;
      case 'client':
        includeOptions.client = true;
        break;
      case 'fournisseur':
        includeOptions.fournisseur = true;
        break;
      case 'produit':
        includeOptions.produit = true;
        break;
      case 'details':
        includeOptions.details = {
          include: {
            produit: true
          }
        };
        break;
      default:
        includeOptions[include] = true;
    }
  }
  
  return includeOptions;
}

module.exports = {
  buildPrismaQuery,
  buildProductSearchConditions,
  buildClientSearchConditions,
  buildSupplierSearchConditions,
  buildSalesSearchConditions,
  buildOrderSearchConditions,
  buildReceiptSearchConditions,
  generateSaleNumber,
  generateOrderNumber,
  generateReceiptNumber,
  calculateSaleTotals,
  calculateOrderTotals,
  validateStockAvailability,
  formatCurrency,
  formatDate,
  formatDateTime,
  sanitizeInput,
  buildIncludeOptions
};
/**

 * Transformateurs pour les réponses API
 */

/**
 * Transforme un produit pour la réponse API
 * @param {Object} produit - Produit Prisma
 * @returns {Object} Produit transformé
 */
function produit(produit) {
  if (!produit) return null;
  
  return {
    id: produit.id,
    reference: produit.reference,
    nom: produit.nom,
    description: produit.description,
    prixUnitaire: produit.prixUnitaire,
    prixAchat: produit.prixAchat,
    codeBarre: produit.codeBarre,
    categorie: produit.categorie,
    seuilStockMinimum: produit.seuilStockMinimum,
    estActif: produit.estActif,
    estService: produit.estService,
    dateCreation: produit.dateCreation,
    dateModification: produit.dateModification,
    stock: produit.stock ? {
      quantiteDisponible: produit.stock.quantiteDisponible,
      quantiteReservee: produit.stock.quantiteReservee,
      derniereMaj: produit.stock.derniereMaj
    } : null
  };
}

/**
 * Transforme un client pour la réponse API
 * @param {Object} client - Client Prisma
 * @returns {Object} Client transformé
 */
function client(client) {
  if (!client) return null;
  
  return {
    id: client.id,
    nom: client.nom,
    prenom: client.prenom,
    telephone: client.telephone,
    email: client.email,
    adresse: client.adresse,
    dateCreation: client.dateCreation,
    dateModification: client.dateModification,
    compte: client.compte ? {
      id: client.compte.id,
      soldeActuel: client.compte.soldeActuel,
      limiteCredit: client.compte.limiteCredit,
      dateDerniereMaj: client.compte.dateDerniereMaj
    } : null
  };
}

/**
 * Transforme un fournisseur pour la réponse API
 * @param {Object} fournisseur - Fournisseur Prisma
 * @returns {Object} Fournisseur transformé
 */
function fournisseur(fournisseur) {
  if (!fournisseur) return null;
  
  return {
    id: fournisseur.id,
    nom: fournisseur.nom,
    personneContact: fournisseur.personneContact,
    telephone: fournisseur.telephone,
    email: fournisseur.email,
    adresse: fournisseur.adresse,
    dateCreation: fournisseur.dateCreation,
    dateModification: fournisseur.dateModification,
    compte: fournisseur.compte ? {
      id: fournisseur.compte.id,
      soldeActuel: fournisseur.compte.soldeActuel,
      limiteCredit: fournisseur.compte.limiteCredit,
      dateDerniereMaj: fournisseur.compte.dateDerniereMaj
    } : null
  };
}

/**
 * Transforme une commande d'approvisionnement pour la réponse API
 * @param {Object} commande - Commande Prisma
 * @returns {Object} Commande transformée
 */
function commandeApprovisionnement(commande) {
  if (!commande) return null;
  
  const details = commande.details ? commande.details.map(detail => ({
    id: detail.id,
    produitId: detail.produitId,
    produit: detail.produit ? produit(detail.produit) : null,
    quantiteCommandee: detail.quantiteCommandee,
    quantiteRecue: detail.quantiteRecue,
    quantiteRestante: detail.quantiteCommandee - detail.quantiteRecue,
    coutUnitaire: detail.coutUnitaire,
    coutTotal: detail.quantiteCommandee * detail.coutUnitaire,
    estComplete: detail.quantiteRecue >= detail.quantiteCommandee
  })) : [];

  // Calculer les statistiques de la commande
  const totalQuantiteCommandee = details.reduce((sum, d) => sum + d.quantiteCommandee, 0);
  const totalQuantiteRecue = details.reduce((sum, d) => sum + d.quantiteRecue, 0);
  const pourcentageReception = totalQuantiteCommandee > 0 ? 
    Math.round((totalQuantiteRecue / totalQuantiteCommandee) * 100) : 0;

  return {
    id: commande.id,
    numeroCommande: commande.numeroCommande,
    fournisseurId: commande.fournisseurId,
    fournisseur: commande.fournisseur ? fournisseur(commande.fournisseur) : null,
    statut: commande.statut,
    dateCommande: commande.dateCommande,
    dateLivraisonPrevue: commande.dateLivraisonPrevue,
    montantTotal: commande.montantTotal,
    modePaiement: commande.modePaiement,
    notes: commande.notes,
    details,
    statistiques: {
      totalQuantiteCommandee,
      totalQuantiteRecue,
      pourcentageReception,
      nombreProduits: details.length,
      produitsCompletsRecus: details.filter(d => d.estComplete).length
    }
  };
}

/**
 * Transforme une vente pour la réponse API
 * @param {Object} vente - Vente Prisma
 * @returns {Object} Vente transformée
 */
function vente(vente) {
  if (!vente) return null;
  
  const details = vente.details ? vente.details.map(detail => ({
    id: detail.id,
    produitId: detail.produitId,
    produit: detail.produit ? produit(detail.produit) : null,
    quantite: detail.quantite,
    prixUnitaire: detail.prixUnitaire,
    prixTotal: detail.prixTotal
  })) : [];

  return {
    id: vente.id,
    numeroVente: vente.numeroVente,
    clientId: vente.clientId,
    client: vente.client ? client(vente.client) : null,
    dateVente: vente.dateVente,
    sousTotal: vente.sousTotal,
    montantRemise: vente.montantRemise,
    montantTotal: vente.montantTotal,
    statut: vente.statut,
    modePaiement: vente.modePaiement,
    montantPaye: vente.montantPaye,
    montantRestant: vente.montantRestant,
    details,
    statistiques: {
      nombreProduits: details.length,
      quantiteTotale: details.reduce((sum, d) => sum + d.quantite, 0),
      estSoldee: vente.montantRestant <= 0,
      estACredit: vente.modePaiement === 'credit'
    }
  };
}

/**
 * Transforme un mouvement de stock pour la réponse API
 * @param {Object} mouvement - Mouvement Prisma
 * @returns {Object} Mouvement transformé
 */
function mouvementStock(mouvement) {
  if (!mouvement) return null;
  
  return {
    id: mouvement.id,
    produitId: mouvement.produitId,
    produit: mouvement.produit ? produit(mouvement.produit) : null,
    typeMouvement: mouvement.typeMouvement,
    changementQuantite: mouvement.changementQuantite,
    referenceId: mouvement.referenceId,
    typeReference: mouvement.typeReference,
    dateMouvement: mouvement.dateMouvement,
    notes: mouvement.notes
  };
}

module.exports = {
  buildPrismaQuery,
  buildProductSearchConditions,
  buildClientSearchConditions,
  buildSupplierSearchConditions,
  buildSalesSearchConditions,
  buildOrderSearchConditions,
  buildReceiptSearchConditions,
  generateSaleNumber,
  generateOrderNumber,
  generateReceiptNumber,
  calculateSaleTotals,
  calculateOrderTotals,
  validateStockAvailability,
  formatCurrency,
  formatDate,
  formatDateTime,
  sanitizeInput,
  buildIncludeOptions,
  // Transformateurs
  produit,
  client,
  fournisseur,
  commandeApprovisionnement,
  vente,
  mouvementStock
};