/**
 * Schémas de validation Joi pour toutes les entités LOGESCO
 * Validation des données d'entrée pour l'API REST
 */

const Joi = require('joi');

// Schémas de base réutilisables
const baseSchemas = {
  id: Joi.number().integer().positive(),
  email: Joi.string().email().max(100),
  telephone: Joi.string().max(50), // Accepte n'importe quel texte, max 50 caractères
  montant: Joi.number().precision(2).min(0),
  date: Joi.date().iso(),
  statut: Joi.string().valid('en_attente', 'partielle', 'terminee', 'annulee'),
  modePaiement: Joi.string().valid('comptant', 'credit')
};

// Validation des utilisateurs
const utilisateurSchemas = {
  create: Joi.object({
    nomUtilisateur: Joi.string().alphanum().min(3).max(50).required(),
    email: baseSchemas.email.required(),
    motDePasse: Joi.string().min(6).max(100).required()
  }),

  update: Joi.object({
    nomUtilisateur: Joi.string().alphanum().min(3).max(50),
    email: baseSchemas.email,
    motDePasse: Joi.string().min(6).max(100)
  }).min(1),

  login: Joi.object({
    nomUtilisateur: Joi.string().required(),
    motDePasse: Joi.string().required()
  })
};

// Validation des produits
const produitSchemas = {
  create: Joi.object({
    reference: Joi.string().pattern(/^[A-Z0-9]+$/).min(1).max(50).required(),
    nom: Joi.string().min(1).max(100).required(),
    description: Joi.string().max(500).allow('', null),
    prixUnitaire: baseSchemas.montant.required(),
    prixAchat: baseSchemas.montant.allow(null),
    codeBarre: Joi.string().max(50).allow('', null),
    categorie: Joi.string().max(50).allow('', null),
    seuilStockMinimum: Joi.number().integer().min(0).default(0),
    remiseMaxAutorisee: baseSchemas.montant.default(0),
    estActif: Joi.boolean().default(true),
    estService: Joi.boolean().default(false),
    gestionPeremption: Joi.boolean().default(false)
  }),

  update: Joi.object({
    reference: Joi.string().pattern(/^[A-Z0-9]+$/).min(1).max(50),
    nom: Joi.string().min(1).max(100),
    description: Joi.string().max(500).allow('', null),
    prixUnitaire: baseSchemas.montant,
    prixAchat: baseSchemas.montant.allow(null),
    codeBarre: Joi.string().max(50).allow('', null),
    categorie: Joi.string().max(50).allow('', null),
    seuilStockMinimum: Joi.number().integer().min(0),
    remiseMaxAutorisee: baseSchemas.montant,
    estActif: Joi.boolean(),
    estService: Joi.boolean(),
    gestionPeremption: Joi.boolean()
  }).min(1),

  search: Joi.object({
    q: Joi.string().max(100),
    categorie: Joi.string().max(50),
    estActif: Joi.boolean(),
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  }),

  checkReference: Joi.object({
    reference: Joi.string().alphanum().min(1).max(50).required(),
    exclude_id: Joi.number().integer().min(1)
  })
};

// Validation des clients
const clientSchemas = {
  create: Joi.object({
    nom: Joi.string().min(1).max(100).required(),
    prenom: Joi.string().max(100).allow('', null),
    telephone: baseSchemas.telephone.allow('', null),
    email: baseSchemas.email.allow('', null),
    adresse: Joi.string().max(500).allow('', null)
  }),

  update: Joi.object({
    nom: Joi.string().min(1).max(100),
    prenom: Joi.string().max(100).allow('', null),
    telephone: baseSchemas.telephone.allow('', null),
    email: baseSchemas.email.allow('', null),
    adresse: Joi.string().max(500).allow('', null)
  }).min(1),

  search: Joi.object({
    q: Joi.string().max(100),
    telephone: baseSchemas.telephone,
    email: baseSchemas.email,
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  })
};

// Validation des fournisseurs
const fournisseurSchemas = {
  create: Joi.object({
    nom: Joi.string().min(1).max(100).required(),
    personneContact: Joi.string().max(100).allow('', null),
    telephone: baseSchemas.telephone.allow('', null),
    email: baseSchemas.email.allow('', null),
    adresse: Joi.string().max(500).allow('', null)
  }),

  update: Joi.object({
    nom: Joi.string().min(1).max(100),
    personneContact: Joi.string().max(100).allow('', null),
    telephone: baseSchemas.telephone.allow('', null),
    email: baseSchemas.email.allow('', null),
    adresse: Joi.string().max(500).allow('', null)
  }).min(1),

  search: Joi.object({
    q: Joi.string().max(100),
    telephone: baseSchemas.telephone,
    email: baseSchemas.email,
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  })
};

// Validation des comptes
const compteSchemas = {
  updateSolde: Joi.object({
    montant: baseSchemas.montant.required(),
    typeTransaction: Joi.string().valid('debit', 'credit', 'paiement', 'achat').required(),
    description: Joi.string().max(500).allow('', null),
    referenceType: Joi.string().max(50).allow(null).optional(),
    referenceId: Joi.number().integer().positive().allow(null).optional(),
    createFinancialMovement: Joi.boolean().optional()
  }),

  updateLimite: Joi.object({
    limiteCredit: baseSchemas.montant.required()
  }),

  search: Joi.object({
    q: Joi.string().max(100),
    soldeMin: baseSchemas.montant,
    soldeMax: baseSchemas.montant,
    enDepassement: Joi.boolean(),
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  })
};

// Validation du stock
const stockSchemas = {
  create: Joi.object({
    produitId: baseSchemas.id.required(),
    quantiteInitiale: Joi.number().integer().min(0).default(0)
  }),

  ajustement: Joi.object({
    produitId: baseSchemas.id.required(),
    changementQuantite: Joi.number().integer().required(),
    notes: Joi.string().max(500).allow('', null)
  }),

  search: Joi.object({
    alerteStock: Joi.boolean(),
    produitId: baseSchemas.id,
    search: Joi.string().max(100).allow('', null),
    category: Joi.string().max(50).allow('', null),
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  }),

  mouvements: Joi.object({
    q: Joi.string().max(100).allow(''),
    produitId: baseSchemas.id,
    typeMouvement: Joi.string().valid('achat', 'vente', 'ajustement', 'retour'),
    dateDebut: baseSchemas.date,
    dateFin: baseSchemas.date,
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  }),

  bulkAdjust: Joi.object({
    ajustements: Joi.array().items(
      Joi.object({
        produitId: baseSchemas.id.required(),
        changementQuantite: Joi.number().integer().required(),
        notes: Joi.string().max(500).allow('', null)
      })
    ).min(1).max(50).required(),
    notes: Joi.string().max(500).allow('', null)
  }),

  createMouvement: Joi.object({
    produitId: baseSchemas.id.required(),
    typeMouvement: Joi.string().valid('achat', 'vente', 'ajustement', 'retour', 'transfert', 'perte', 'correction').required(),
    changementQuantite: Joi.number().integer().required(),
    notes: Joi.string().max(500).allow('', null),
    referenceId: baseSchemas.id.allow(null),
    typeReference: Joi.string().max(50).allow('', null)
  })
};

// Validation des commandes d'approvisionnement
const commandeApprovisionnementSchemas = {
  create: Joi.object({
    fournisseurId: baseSchemas.id.required(),
    dateLivraisonPrevue: baseSchemas.date.allow(null),
    modePaiement: baseSchemas.modePaiement.default('credit'),
    notes: Joi.string().max(500).allow('', null),
    details: Joi.array().items(
      Joi.object({
        produitId: baseSchemas.id.required(),
        quantiteCommandee: Joi.number().integer().min(1).required(),
        coutUnitaire: baseSchemas.montant.required()
      })
    ).min(1).required()
  }),

  update: Joi.object({
    dateLivraisonPrevue: baseSchemas.date.allow(null),
    modePaiement: baseSchemas.modePaiement,
    notes: Joi.string().max(500).allow('', null),
    statut: baseSchemas.statut
  }).min(1),

  reception: Joi.object({
    details: Joi.array().items(
      Joi.object({
        detailId: baseSchemas.id.required(),
        quantiteRecue: Joi.number().integer().min(0).required()
      })
    ).min(1).required()
  }),

  search: Joi.object({
    fournisseurId: baseSchemas.id,
    statut: baseSchemas.statut,
    dateDebut: baseSchemas.date,
    dateFin: baseSchemas.date,
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  })
};

// Validation des ventes
const venteSchemas = {
  create: Joi.object({
    clientId: baseSchemas.id.allow(null),
    vendeurId: baseSchemas.id.allow(null),
    modePaiement: baseSchemas.modePaiement.default('comptant'),
    montantRemise: baseSchemas.montant.default(0),
    montantPaye: baseSchemas.montant.default(0),
    dateVente: baseSchemas.date.allow(null), // Date personnalisée pour l'antidatage
    details: Joi.array().items(
      Joi.object({
        produitId: baseSchemas.id.required(),
        quantite: Joi.number().integer().min(1).required(),
        prixUnitaire: baseSchemas.montant.required(),
        prixAffiche: baseSchemas.montant.required(),
        remiseAppliquee: baseSchemas.montant.default(0),
        justificationRemise: Joi.string().max(500).allow('', null)
      })
    ).min(1).required()
  }),

  // Validation spécifique pour les remises
  validateDiscount: Joi.object({
    produitId: baseSchemas.id.required(),
    remiseAppliquee: baseSchemas.montant.required(),
    justificationRemise: Joi.string().max(500).allow('', null)
  }),

  update: Joi.object({
    clientId: baseSchemas.id.allow(null),
    modePaiement: baseSchemas.modePaiement,
    montantRemise: baseSchemas.montant,
    montantPaye: baseSchemas.montant,
    statut: Joi.string().valid('terminee', 'annulee')
  }).min(1),

  paiement: Joi.object({
    montantPaye: baseSchemas.montant.min(0.01).required(),
    description: Joi.string().max(500).allow('', null)
  }),

  search: Joi.object({
    clientId: baseSchemas.id,
    statut: Joi.string().valid('terminee', 'annulee'),
    modePaiement: baseSchemas.modePaiement,
    dateDebut: baseSchemas.date,
    dateFin: baseSchemas.date,
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  }),

  analyticsProducts: Joi.object({
    dateDebut: baseSchemas.date,
    dateFin: baseSchemas.date,
    categorieId: baseSchemas.id,
    limit: Joi.number().integer().min(1).max(200).default(50),
    includeServices: Joi.string().valid('true', 'false').default('true')
  })
};

// Validation des paramètres de pagination
const paginationSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  sortBy: Joi.string().max(50),
  sortOrder: Joi.string().valid('asc', 'desc').default('asc')
});

// Validation des paramètres d'entreprise
const parametresEntrepriseSchemas = {
  create: Joi.object({
    nomEntreprise: Joi.string().min(1).max(100).required(),
    adresse: Joi.string().min(1).max(500).required(),
    localisation: Joi.string().max(100).allow('', null),
    telephone: baseSchemas.telephone.allow('', null),
    email: baseSchemas.email.allow('', null),
    nuiRccm: Joi.string().max(50).allow('', null),
    logo: Joi.string().max(500).allow('', null), // Chemin vers le fichier logo
    slogan: Joi.string().max(200).allow('', null), // Slogan de l'entreprise
    langueFacture: Joi.string().valid('fr', 'en', 'es').default('fr') // Langue des factures: fr, en, es
  }),

  update: Joi.object({
    nomEntreprise: Joi.string().min(1).max(100),
    adresse: Joi.string().min(1).max(500),
    localisation: Joi.string().max(100).allow('', null),
    telephone: baseSchemas.telephone.allow('', null),
    email: baseSchemas.email.allow('', null),
    nuiRccm: Joi.string().max(50).allow('', null),
    logo: Joi.string().max(500).allow('', null), // Chemin vers le fichier logo
    slogan: Joi.string().max(200).allow('', null), // Slogan de l'entreprise
    langueFacture: Joi.string().valid('fr', 'en', 'es').default('fr') // Langue des factures: fr, en, es
  }).min(1)
};

// Validation du système d'impression
const printingSchemas = {
  generateReceipt: Joi.object({
    venteId: baseSchemas.id.required(),
    formatImpression: Joi.string().valid('thermal', 'a4', 'a5').default('thermal'),
    utilisateurId: baseSchemas.id.allow(null)
  }),

  reprint: Joi.object({
    formatImpression: Joi.string().valid('thermal', 'a4', 'a5').default('thermal'),
    motifReimpression: Joi.string().max(500).allow('', null),
    utilisateurId: baseSchemas.id.allow(null)
  }),

  searchReceipts: Joi.object({
    venteId: baseSchemas.id,
    numeroVente: Joi.string().max(50),
    numeroRecu: Joi.string().max(50),
    clientNom: Joi.string().max(100),
    formatImpression: Joi.string().valid('thermal', 'a4', 'a5'),
    dateDebut: baseSchemas.date,
    dateFin: baseSchemas.date,
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  }),

  stats: Joi.object({
    dateDebut: baseSchemas.date,
    dateFin: baseSchemas.date
  })
};

// Validation des dates de péremption
const datePeremptionSchemas = {
  create: Joi.object({
    produitId: baseSchemas.id.required(),
    datePeremption: baseSchemas.date.required(),
    quantite: Joi.number().integer().min(0).required(),
    numeroLot: Joi.string().max(50).allow('', null),
    notes: Joi.string().max(500).allow('', null)
  }),

  update: Joi.object({
    datePeremption: baseSchemas.date,
    quantite: Joi.number().integer().min(0),
    numeroLot: Joi.string().max(50).allow('', null),
    notes: Joi.string().max(500).allow('', null),
    estEpuise: Joi.boolean()
  }).min(1),

  search: Joi.object({
    produitId: baseSchemas.id,
    estPerime: Joi.boolean(),
    joursRestants: Joi.number().integer(),
    estEpuise: Joi.boolean(),
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  }),

  alertes: Joi.object({
    niveauAlerte: Joi.string().valid('perime', 'critique', 'avertissement', 'attention', 'normal'),
    joursMax: Joi.number().integer().min(0).max(365).default(30),
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20)
  })
};

// Validation des paramètres d'ID
const idParamSchema = Joi.object({
  id: baseSchemas.id.required()
});

module.exports = {
  baseSchemas,
  utilisateurSchemas,
  produitSchemas,
  clientSchemas,
  fournisseurSchemas,
  compteSchemas,
  stockSchemas,
  commandeApprovisionnementSchemas,
  venteSchemas,
  parametresEntrepriseSchemas,
  printingSchemas,
  paginationSchema,
  idParamSchema,
  datePeremptionSchemas
};