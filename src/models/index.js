/**
 * Modèles et services de données pour LOGESCO
 * Couche d'abstraction au-dessus de Prisma pour les opérations métier
 */

const { PrismaClient } = require('../config/prisma-client.js');
const bcrypt = require('bcryptjs');
const {
  generateSaleNumber,
  generateOrderNumber,
  calculateSaleTotals,
  calculateOrderTotals,
  validateStockAvailability
} = require('../utils/transformers');

class BaseModel {
  constructor(prisma) {
    this.prisma = prisma;
  }

  /**
   * Trouve un enregistrement par ID
   * @param {number} id - ID de l'enregistrement
   * @param {Object} options - Options Prisma (include, select, etc.)
   * @returns {Promise<Object|null>}
   */
  async findById(id, options = {}) {
    return await this.model.findUnique({
      where: { id },
      ...options
    });
  }

  /**
   * Trouve le premier enregistrement correspondant aux critères
   * @param {Object} options - Options de requête (where, include, select, etc.)
   * @returns {Promise<Object|null>}
   */
  async findFirst(options = {}) {
    return await this.model.findFirst(options);
  }

  /**
   * Trouve tous les enregistrements avec pagination
   * @param {Object} options - Options de requête
   * @returns {Promise<Array>}
   */
  async findMany(options = {}) {
    return await this.model.findMany(options);
  }

  /**
   * Compte le nombre d'enregistrements
   * @param {Object} where - Conditions de filtrage
   * @returns {Promise<number>}
   */
  async count(where = {}) {
    return await this.model.count({ where });
  }

  /**
   * Crée un nouvel enregistrement
   * @param {Object} data - Données à créer
   * @param {Object} options - Options Prisma
   * @returns {Promise<Object>}
   */
  async create(data, options = {}) {
    return await this.model.create({
      data,
      ...options
    });
  }

  /**
   * Met à jour un enregistrement
   * @param {number} id - ID de l'enregistrement
   * @param {Object} data - Données à mettre à jour
   * @param {Object} options - Options Prisma
   * @returns {Promise<Object>}
   */
  async update(id, data, options = {}) {
    return await this.model.update({
      where: { id },
      data,
      ...options
    });
  }

  /**
   * Supprime un enregistrement
   * @param {number} id - ID de l'enregistrement
   * @returns {Promise<Object>}
   */
  async delete(id) {
    return await this.model.delete({
      where: { id }
    });
  }
}

/**
 * Modèle pour les utilisateurs
 */
class UtilisateurModel extends BaseModel {
  constructor(prisma) {
    super(prisma);
    this.model = prisma.utilisateur;
  }

  /**
   * Crée un nouvel utilisateur avec mot de passe hashé
   * @param {Object} userData - Données utilisateur
   * @returns {Promise<Object>}
   */
  async createUser(userData) {
    const { motDePasse, ...otherData } = userData;
    const motDePasseHash = await bcrypt.hash(motDePasse, 12);

    return await this.create({
      ...otherData,
      motDePasseHash
    });
  }

  /**
   * Trouve un utilisateur par nom d'utilisateur
   * @param {string} nomUtilisateur - Nom d'utilisateur
   * @returns {Promise<Object|null>}
   */
  async findByUsername(nomUtilisateur) {
    return await this.model.findUnique({
      where: { nomUtilisateur },
      include: { role: true }
    });
  }

  /**
   * Trouve un utilisateur par email
   * @param {string} email - Email
   * @returns {Promise<Object|null>}
   */
  async findByEmail(email) {
    return await this.model.findUnique({
      where: { email }
    });
  }

  /**
   * Vérifie le mot de passe d'un utilisateur
   * @param {string} motDePasse - Mot de passe en clair
   * @param {string} hash - Hash stocké
   * @returns {Promise<boolean>}
   */
  async verifyPassword(motDePasse, hash) {
    return await bcrypt.compare(motDePasse, hash);
  }

  /**
   * Met à jour le mot de passe d'un utilisateur
   * @param {number} id - ID utilisateur
   * @param {string} nouveauMotDePasse - Nouveau mot de passe
   * @returns {Promise<Object>}
   */
  async updatePassword(id, nouveauMotDePasse) {
    const motDePasseHash = await bcrypt.hash(nouveauMotDePasse, 12);
    return await this.update(id, { motDePasseHash });
  }
}

/**
 * Modèle pour les produits
 */
class ProduitModel extends BaseModel {
  constructor(prisma) {
    super(prisma);
    this.model = prisma.produit;
  }

  /**
   * Crée un produit avec son stock initial
   * @param {Object} produitData - Données du produit
   * @returns {Promise<Object>}
   */
  async createWithStock(produitData) {
    return await this.prisma.$transaction(async (tx) => {
      const produit = await tx.produit.create({
        data: produitData
      });

      await tx.stock.create({
        data: {
          produitId: produit.id,
          quantiteDisponible: 0,
          quantiteReservee: 0
        }
      });

      return await tx.produit.findUnique({
        where: { id: produit.id },
        include: { stock: true }
      });
    });
  }

  /**
   * Trouve les produits avec stock faible
   * @returns {Promise<Array>}
   */
  async findLowStock() {
    return await this.model.findMany({
      where: {
        estActif: true,
        stock: {
          quantiteDisponible: {
            lte: this.prisma.raw('produits.seuil_stock_minimum')
          }
        }
      },
      include: {
        stock: true
      }
    });
  }

  /**
   * Recherche de produits
   * @param {Object} searchParams - Paramètres de recherche
   * @param {Object} options - Options de pagination
   * @returns {Promise<Object>}
   */
  async search(searchParams, options = {}) {
    const where = {};

    if (searchParams.q) {
      where.OR = [
        { nom: { contains: searchParams.q } },
        { reference: { contains: searchParams.q } }
      ];
    }

    if (searchParams.categorie) {
      where.categorie = { 
        nom: { contains: searchParams.categorie }
      };
    }

    if (typeof searchParams.estActif === 'boolean') {
      where.estActif = searchParams.estActif;
    }

    const [produits, total] = await Promise.all([
      this.model.findMany({
        where,
        include: { 
          stock: true,
          categorie: true // Inclure les données de catégorie
        },
        ...options
      }),
      this.model.count({ where })
    ]);

    return { produits, total };
  }
}

/**
 * Modèle pour le stock
 */
class StockModel extends BaseModel {
  constructor(prisma) {
    super(prisma);
    this.model = prisma.stock;
  }

  /**
   * Ajuste le stock d'un produit
   * @param {number} produitId - ID du produit
   * @param {number} changement - Changement de quantité (+ ou -)
   * @param {string} typeReference - Type de référence
   * @param {number} referenceId - ID de référence
   * @param {string} notes - Notes optionnelles
   * @returns {Promise<Object>}
   */
  async adjustStock(produitId, changement, typeReference, referenceId = null, notes = null) {
    return await this.prisma.$transaction(async (tx) => {
      // Mettre à jour le stock
      const stock = await tx.stock.update({
        where: { produitId },
        data: {
          quantiteDisponible: {
            increment: changement
          }
        }
      });

      // Enregistrer le mouvement
      await tx.mouvementStock.create({
        data: {
          produitId,
          typeMouvement: changement > 0 ? 'achat' : 'vente',
          changementQuantite: changement,
          typeReference,
          referenceId,
          notes
        }
      });

      return stock;
    });
  }

  /**
   * Réserve du stock pour une vente
   * @param {Array} details - Détails de la vente
   * @returns {Promise<boolean>}
   */
  async reserveStock(details) {
    return await this.prisma.$transaction(async (tx) => {
      for (const detail of details) {
        await tx.stock.update({
          where: { produitId: detail.produitId },
          data: {
            quantiteDisponible: {
              decrement: detail.quantite
            },
            quantiteReservee: {
              increment: detail.quantite
            }
          }
        });
      }
      return true;
    });
  }

  /**
   * Confirme la vente et retire le stock réservé
   * @param {Array} details - Détails de la vente
   * @returns {Promise<boolean>}
   */
  async confirmSale(details) {
    return await this.prisma.$transaction(async (tx) => {
      for (const detail of details) {
        await tx.stock.update({
          where: { produitId: detail.produitId },
          data: {
            quantiteReservee: {
              decrement: detail.quantite
            }
          }
        });
      }
      return true;
    });
  }
}

/**
 * Modèle pour les ventes
 */
class VenteModel extends BaseModel {
  constructor(prisma) {
    super(prisma);
    this.model = prisma.vente;
  }

  /**
   * Crée une nouvelle vente avec ses détails
   * @param {Object} venteData - Données de la vente
   * @returns {Promise<Object>}
   */
  async createSale(venteData) {
    const { details, ...saleData } = venteData;
    
    return await this.prisma.$transaction(async (tx) => {
      // Calculer les totaux
      const { sousTotal } = calculateSaleTotals(details);
      const montantTotal = sousTotal - (saleData.montantRemise || 0);
      const montantRestant = montantTotal - (saleData.montantPaye || 0);

      // Créer la vente
      const vente = await tx.vente.create({
        data: {
          ...saleData,
          numeroVente: generateSaleNumber(),
          sousTotal,
          montantTotal,
          montantRestant
        }
      });

      // Créer les détails
      for (const detail of details) {
        await tx.detailVente.create({
          data: {
            venteId: vente.id,
            produitId: detail.produitId,
            quantite: detail.quantite,
            prixUnitaire: detail.prixUnitaire,
            prixTotal: detail.quantite * detail.prixUnitaire
          }
        });

        // Mettre à jour le stock
        await tx.stock.update({
          where: { produitId: detail.produitId },
          data: {
            quantiteDisponible: {
              decrement: detail.quantite
            }
          }
        });

        // Enregistrer le mouvement de stock
        await tx.mouvementStock.create({
          data: {
            produitId: detail.produitId,
            typeMouvement: 'vente',
            changementQuantite: -detail.quantite,
            typeReference: 'vente',
            referenceId: vente.id
          }
        });
      }

      // Mettre à jour le compte client si vente à crédit
      if (saleData.clientId && saleData.modePaiement === 'credit' && montantRestant > 0) {
        await this.updateClientAccount(tx, saleData.clientId, montantRestant, vente.id);
      }

      return await tx.vente.findUnique({
        where: { id: vente.id },
        include: {
          client: true,
          details: {
            include: { produit: true }
          }
        }
      });
    });
  }

  /**
   * Met à jour le compte client pour une vente à crédit
   * @param {Object} tx - Transaction Prisma
   * @param {number} clientId - ID du client
   * @param {number} montant - Montant à débiter
   * @param {number} venteId - ID de la vente
   */
  async updateClientAccount(tx, clientId, montant, venteId) {
    // Créer ou mettre à jour le compte client
    const compte = await tx.compteClient.upsert({
      where: { clientId },
      create: {
        clientId,
        soldeActuel: montant,
        limiteCredit: 0
      },
      update: {
        soldeActuel: {
          increment: montant
        }
      }
    });

    // Enregistrer la transaction
    await tx.transactionCompte.create({
      data: {
        typeCompte: 'client',
        compteId: compte.id,
        typeTransaction: 'debit',
        montant,
        description: `Vente à crédit`,
        referenceType: 'vente',
        referenceId: venteId,
        soldeApres: compte.soldeActuel + montant
      }
    });
  }
}

/**
 * Modèle pour les commandes d'approvisionnement
 */
class CommandeApprovisionnementModel extends BaseModel {
  constructor(prisma) {
    super(prisma);
    this.model = prisma.commandeApprovisionnement;
  }

  /**
   * Crée une nouvelle commande avec ses détails
   * @param {Object} commandeData - Données de la commande
   * @returns {Promise<Object>}
   */
  async createOrder(commandeData) {
    const { details, ...orderData } = commandeData;
    
    return await this.prisma.$transaction(async (tx) => {
      // Calculer le montant total
      const { montantTotal } = calculateOrderTotals(details);

      // Créer la commande
      const commande = await tx.commandeApprovisionnement.create({
        data: {
          ...orderData,
          numeroCommande: generateOrderNumber(),
          montantTotal
        }
      });

      // Créer les détails
      for (const detail of details) {
        await tx.detailCommandeApprovisionnement.create({
          data: {
            commandeId: commande.id,
            produitId: detail.produitId,
            quantiteCommandee: detail.quantiteCommandee,
            coutUnitaire: detail.coutUnitaire
          }
        });
      }

      return await tx.commandeApprovisionnement.findUnique({
        where: { id: commande.id },
        include: {
          fournisseur: true,
          details: {
            include: { produit: true }
          }
        }
      });
    });
  }

  /**
   * Réceptionne une commande (partiellement ou totalement)
   * @param {number} commandeId - ID de la commande
   * @param {Array} receptions - Détails des réceptions
   * @returns {Promise<Object>}
   */
  async receiveOrder(commandeId, receptions) {
    return await this.prisma.$transaction(async (tx) => {
      let commandeComplete = true;

      for (const reception of receptions) {
        // Mettre à jour le détail de commande
        const detail = await tx.detailCommandeApprovisionnement.update({
          where: { id: reception.detailId },
          data: {
            quantiteRecue: {
              increment: reception.quantiteRecue
            }
          }
        });

        // Vérifier si le détail est complet
        if (detail.quantiteRecue < detail.quantiteCommandee) {
          commandeComplete = false;
        }

        // Mettre à jour le stock
        await tx.stock.update({
          where: { produitId: detail.produitId },
          data: {
            quantiteDisponible: {
              increment: reception.quantiteRecue
            }
          }
        });

        // Enregistrer le mouvement de stock
        await tx.mouvementStock.create({
          data: {
            produitId: detail.produitId,
            typeMouvement: 'achat',
            changementQuantite: reception.quantiteRecue,
            typeReference: 'approvisionnement',
            referenceId: commandeId
          }
        });
      }

      // Mettre à jour le statut de la commande
      const nouveauStatut = commandeComplete ? 'terminee' : 'partielle';
      
      return await tx.commandeApprovisionnement.update({
        where: { id: commandeId },
        data: { statut: nouveauStatut },
        include: {
          fournisseur: true,
          details: {
            include: { produit: true }
          }
        }
      });
    });
  }
}

/**
 * Modèle pour les fournisseurs
 */
class FournisseurModel extends BaseModel {
  constructor(prisma) {
    super(prisma);
    this.model = prisma.fournisseur;
  }

  /**
   * Recherche de fournisseurs
   * @param {Object} searchParams - Paramètres de recherche
   * @param {Object} options - Options de pagination
   * @returns {Promise<Object>}
   */
  async search(searchParams, options = {}) {
    const where = {};

    if (searchParams.q) {
      where.OR = [
        { nom: { contains: searchParams.q } },
        { personneContact: { contains: searchParams.q } },
        { telephone: { contains: searchParams.q } },
        { email: { contains: searchParams.q } }
      ];
    }

    if (searchParams.telephone) {
      where.telephone = { contains: searchParams.telephone };
    }

    if (searchParams.email) {
      where.email = { contains: searchParams.email };
    }

    const [fournisseurs, total] = await Promise.all([
      this.model.findMany({
        where,
        include: { 
          compte: true,
          commandes: {
            take: 5,
            orderBy: { dateCommande: 'desc' }
          }
        },
        ...options
      }),
      this.model.count({ where })
    ]);

    return { fournisseurs, total };
  }

  /**
   * Vérifie si un fournisseur peut être supprimé
   * @param {number} id - ID du fournisseur
   * @returns {Promise<boolean>}
   */
  async canDelete(id) {
    const commandesCount = await this.prisma.commandeApprovisionnement.count({
      where: { fournisseurId: id }
    });

    return commandesCount === 0;
  }

  /**
   * Crée un fournisseur avec son compte
   * @param {Object} fournisseurData - Données du fournisseur
   * @returns {Promise<Object>}
   */
  async createWithAccount(fournisseurData) {
    return await this.prisma.$transaction(async (tx) => {
      const fournisseur = await tx.fournisseur.create({
        data: fournisseurData
      });

      await tx.compteFournisseur.create({
        data: {
          fournisseurId: fournisseur.id,
          soldeActuel: 0,
          limiteCredit: 0
        }
      });

      return await tx.fournisseur.findUnique({
        where: { id: fournisseur.id },
        include: { compte: true }
      });
    });
  }
}

/**
 * Modèle pour les clients
 */
class ClientModel extends BaseModel {
  constructor(prisma) {
    super(prisma);
    this.model = prisma.client;
  }

  /**
   * Recherche de clients
   * @param {Object} searchParams - Paramètres de recherche
   * @param {Object} options - Options de pagination
   * @returns {Promise<Object>}
   */
  async search(searchParams, options = {}) {
    const where = {};

    if (searchParams.q) {
      where.OR = [
        { nom: { contains: searchParams.q } },
        { prenom: { contains: searchParams.q } },
        { telephone: { contains: searchParams.q } },
        { email: { contains: searchParams.q } }
      ];
    }

    if (searchParams.telephone) {
      where.telephone = { contains: searchParams.telephone };
    }

    if (searchParams.email) {
      where.email = { contains: searchParams.email };
    }

    const [clients, total] = await Promise.all([
      this.model.findMany({
        where,
        include: { 
          compte: true,
          ventes: {
            take: 5,
            orderBy: { dateVente: 'desc' }
          }
        },
        ...options
      }),
      this.model.count({ where })
    ]);

    return { clients, total };
  }

  /**
   * Vérifie si un client peut être supprimé
   * @param {number} id - ID du client
   * @returns {Promise<boolean>}
   */
  async canDelete(id) {
    const ventesCount = await this.prisma.vente.count({
      where: { clientId: id }
    });

    return ventesCount === 0;
  }

  /**
   * Crée un client avec son compte
   * @param {Object} clientData - Données du client
   * @returns {Promise<Object>}
   */
  async createWithAccount(clientData) {
    return await this.prisma.$transaction(async (tx) => {
      const client = await tx.client.create({
        data: clientData
      });

      await tx.compteClient.create({
        data: {
          clientId: client.id,
          soldeActuel: 0,
          limiteCredit: 0
        }
      });

      return await tx.client.findUnique({
        where: { id: client.id },
        include: { compte: true }
      });
    });
  }
}

/**
 * Factory pour créer les modèles avec une instance Prisma partagée
 */
class ModelFactory {
  constructor(prisma) {
    this.prisma = prisma;
    this.utilisateur = new UtilisateurModel(prisma);
    this.produit = new ProduitModel(prisma);
    this.stock = new StockModel(prisma);
    this.vente = new VenteModel(prisma);
    this.commandeApprovisionnement = new CommandeApprovisionnementModel(prisma);
    this.fournisseur = new FournisseurModel(prisma);
    this.client = new ClientModel(prisma);
  }
}

module.exports = {
  BaseModel,
  UtilisateurModel,
  ProduitModel,
  StockModel,
  VenteModel,
  CommandeApprovisionnementModel,
  FournisseurModel,
  ClientModel,
  ModelFactory
};