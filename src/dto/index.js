/**
 * Data Transfer Objects (DTOs) pour l'API LOGESCO
 * Transformation et formatage des données pour les réponses API
 */

/**
 * DTO de base pour les réponses API
 */
class BaseResponseDTO {
  constructor(success = true, data = null, message = null, errors = null) {
    this.success = success;
    this.timestamp = new Date().toISOString();
    
    if (data !== null) this.data = data;
    if (message !== null) this.message = message;
    if (errors !== null) this.errors = errors;
  }

  static success(data, message = null) {
    return new BaseResponseDTO(true, data, message);
  }

  static error(message, errors = null) {
    return new BaseResponseDTO(false, null, message, errors);
  }
}

/**
 * DTO pour les réponses paginées
 */
class PaginatedResponseDTO extends BaseResponseDTO {
  constructor(data, pagination, message = null) {
    super(true, data, message);
    this.pagination = {
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: Math.ceil(pagination.total / pagination.limit),
      hasNext: pagination.page < Math.ceil(pagination.total / pagination.limit),
      hasPrev: pagination.page > 1
    };
  }
}

/**
 * DTO pour les utilisateurs (sans mot de passe)
 */
class UtilisateurDTO {
  constructor(utilisateur) {
    this.id = utilisateur.id;
    this.nomUtilisateur = utilisateur.nomUtilisateur;
    this.email = utilisateur.email;
    this.dateCreation = utilisateur.dateCreation;
    this.dateModification = utilisateur.dateModification;
    
    // Inclure les informations de rôle si disponibles
    if (utilisateur.role) {
      // Parser les privilèges si c'est une string JSON
      let privileges = utilisateur.role.privileges;
      if (typeof privileges === 'string') {
        try {
          privileges = JSON.parse(privileges);
        } catch (e) {
          console.error('❌ [UtilisateurDTO] Erreur parsing privilèges:', e);
          privileges = {};
        }
      }
      
      this.role = {
        id: utilisateur.role.id,
        nom: utilisateur.role.nom,
        displayName: utilisateur.role.displayName,
        isAdmin: utilisateur.role.isAdmin,
        privileges: privileges || {}
      };
    }
  }

  static fromEntity(utilisateur) {
    return new UtilisateurDTO(utilisateur);
  }

  static fromEntities(utilisateurs) {
    return utilisateurs.map(u => new UtilisateurDTO(u));
  }
}

/**
 * DTO pour les produits
 */
class ProduitDTO {
  constructor(produit) {
    this.id = produit.id;
    this.reference = produit.reference;
    this.nom = produit.nom;
    this.description = produit.description;
    this.prixUnitaire = parseFloat(produit.prixUnitaire);
    this.prixAchat = produit.prixAchat ? parseFloat(produit.prixAchat) : null;
    this.codeBarre = produit.codeBarre;
    // Gérer la catégorie depuis la relation ou l'ancien champ
    this.categorieId = produit.categorieId;
    this.categorie = produit.categorie ? produit.categorie.nom : null;
    this.seuilStockMinimum = produit.seuilStockMinimum;
    this.remiseMaxAutorisee = parseFloat(produit.remiseMaxAutorisee || 0);
    this.estActif = produit.estActif;
    this.estService = produit.estService;
    this.gestionPeremption = produit.gestionPeremption || false;
    this.dateCreation = produit.dateCreation;
    this.dateModification = produit.dateModification;

    // Inclure les informations de stock si disponibles
    if (produit.stock) {
      this.stock = new StockDTO(produit.stock);
    }

    // Inclure les dates de péremption si disponibles
    if (produit.datesPeremption) {
      this.datesPeremption = DatePeremptionDTO.fromEntities(produit.datesPeremption);
    }
  }

  static fromEntity(produit) {
    return new ProduitDTO(produit);
  }

  static fromEntities(produits) {
    return produits.map(p => new ProduitDTO(p));
  }
}

/**
 * DTO pour le stock
 */
class StockDTO {
  constructor(stock) {
    this.id = stock.id;
    this.produitId = stock.produitId;
    this.quantiteDisponible = stock.quantiteDisponible;
    this.quantiteReservee = stock.quantiteReservee;
    this.quantiteTotale = stock.quantiteDisponible + stock.quantiteReservee;
    this.derniereMaj = stock.derniereMaj;

    // Inclure les informations du produit si disponibles
    if (stock.produit) {
      this.produit = {
        id: stock.produit.id,
        reference: stock.produit.reference,
        nom: stock.produit.nom,
        seuilStockMinimum: stock.produit.seuilStockMinimum
      };
      this.stockFaible = stock.quantiteDisponible <= stock.produit.seuilStockMinimum;
    }
  }

  static fromEntity(stock) {
    return new StockDTO(stock);
  }

  static fromEntities(stocks) {
    return stocks.map(s => new StockDTO(s));
  }
}

/**
 * DTO pour les clients
 */
class ClientDTO {
  constructor(client) {
    this.id = client.id;
    this.nom = client.nom;
    this.prenom = client.prenom;
    this.nomComplet = client.prenom ? `${client.nom} ${client.prenom}` : client.nom;
    this.telephone = client.telephone;
    this.email = client.email;
    this.adresse = client.adresse;
    this.dateCreation = client.dateCreation;
    this.dateModification = client.dateModification;

    // Inclure le solde directement depuis le compte
    if (client.compte) {
      this.solde = parseFloat(client.compte.soldeActuel);
      this.compte = new CompteClientDTO(client.compte);
    } else {
      // Si pas de compte, solde = 0
      this.solde = 0;
    }
  }

  static fromEntity(client) {
    return new ClientDTO(client);
  }

  static fromEntities(clients) {
    return clients.map(c => new ClientDTO(c));
  }
}

/**
 * DTO pour les fournisseurs
 */
class FournisseurDTO {
  constructor(fournisseur) {
    this.id = fournisseur.id;
    this.nom = fournisseur.nom;
    this.personneContact = fournisseur.personneContact;
    this.telephone = fournisseur.telephone;
    this.email = fournisseur.email;
    this.adresse = fournisseur.adresse;
    this.dateCreation = fournisseur.dateCreation;
    this.dateModification = fournisseur.dateModification;

    // Inclure les informations de compte si disponibles
    if (fournisseur.compte) {
      this.compte = new CompteFournisseurDTO(fournisseur.compte);
    }
  }

  static fromEntity(fournisseur) {
    return new FournisseurDTO(fournisseur);
  }

  static fromEntities(fournisseurs) {
    return fournisseurs.map(f => new FournisseurDTO(f));
  }
}

/**
 * DTO pour les comptes clients
 */
class CompteClientDTO {
  constructor(compte) {
    this.id = compte.id;
    this.clientId = compte.clientId;
    this.soldeActuel = parseFloat(compte.soldeActuel);
    this.limiteCredit = parseFloat(compte.limiteCredit);
    this.creditDisponible = parseFloat(compte.limiteCredit) - parseFloat(compte.soldeActuel);
    this.estEnDepassement = parseFloat(compte.soldeActuel) > parseFloat(compte.limiteCredit);
    this.dateDerniereMaj = compte.dateDerniereMaj;

    // Inclure les informations du client si disponibles
    if (compte.client) {
      this.client = {
        id: compte.client.id,
        nom: compte.client.nom,
        prenom: compte.client.prenom,
        nomComplet: compte.client.prenom ? `${compte.client.nom} ${compte.client.prenom}` : compte.client.nom
      };
    }
  }

  static fromEntity(compte) {
    return new CompteClientDTO(compte);
  }

  static fromEntities(comptes) {
    return comptes.map(c => new CompteClientDTO(c));
  }
}

/**
 * DTO pour les comptes fournisseurs
 */
class CompteFournisseurDTO {
  constructor(compte) {
    this.id = compte.id;
    this.fournisseurId = compte.fournisseurId;
    this.soldeActuel = parseFloat(compte.soldeActuel);
    this.limiteCredit = parseFloat(compte.limiteCredit);
    this.creditDisponible = parseFloat(compte.limiteCredit) - parseFloat(compte.soldeActuel);
    this.estEnDepassement = parseFloat(compte.soldeActuel) > parseFloat(compte.limiteCredit);
    this.dateDerniereMaj = compte.dateDerniereMaj;

    // Inclure les informations du fournisseur si disponibles
    if (compte.fournisseur) {
      this.fournisseur = {
        id: compte.fournisseur.id,
        nom: compte.fournisseur.nom,
        personneContact: compte.fournisseur.personneContact
      };
    }
  }

  static fromEntity(compte) {
    return new CompteFournisseurDTO(compte);
  }

  static fromEntities(comptes) {
    return comptes.map(c => new CompteFournisseurDTO(c));
  }
}

/**
 * DTO pour les ventes
 */
class VenteDTO {
  constructor(vente) {
    this.id = vente.id;
    this.numeroVente = vente.numeroVente;
    this.clientId = vente.clientId;
    this.vendeurId = vente.vendeurId;
    this.dateVente = vente.dateVente;
    this.sousTotal = parseFloat(vente.sousTotal);
    this.montantRemise = parseFloat(vente.montantRemise);
    this.montantTotal = parseFloat(vente.montantTotal);
    this.statut = vente.statut;
    this.modePaiement = vente.modePaiement;
    this.montantPaye = parseFloat(vente.montantPaye);
    this.montantRestant = parseFloat(vente.montantRestant);
    this.estACredit = vente.modePaiement === 'credit';
    this.estSoldee = parseFloat(vente.montantRestant) <= 0;

    // Inclure les informations du client si disponibles
    if (vente.client) {
      this.client = {
        id: vente.client.id,
        nom: vente.client.nom,
        prenom: vente.client.prenom,
        nomComplet: vente.client.prenom ? `${vente.client.nom} ${vente.client.prenom}` : vente.client.nom
      };
    }

    // Inclure les informations du vendeur si disponibles
    if (vente.vendeur) {
      this.vendeur = {
        id: vente.vendeur.id,
        nomUtilisateur: vente.vendeur.nomUtilisateur,
        email: vente.vendeur.email
      };
    }

    // Inclure les détails si disponibles
    if (vente.details) {
      this.details = vente.details.map(d => new DetailVenteDTO(d));
      
      // Calculer les statistiques de remises
      this.statistiquesRemises = this.calculerStatistiquesRemises(this.details);
    }
  }

  calculerStatistiquesRemises(details) {
    const detailsAvecRemise = details.filter(d => d.remiseAppliquee > 0);
    
    if (detailsAvecRemise.length === 0) {
      return {
        nombreProduitsAvecRemise: 0,
        totalRemises: 0,
        remiseMoyenne: 0,
        remiseMax: 0,
        economieClientTotale: 0
      };
    }

    const totalRemises = detailsAvecRemise.reduce((sum, d) => sum + d.remiseAppliquee, 0);
    const economieClientTotale = detailsAvecRemise.reduce((sum, d) => sum + d.economieTotale, 0);
    const remiseMax = Math.max(...detailsAvecRemise.map(d => d.remiseAppliquee));

    return {
      nombreProduitsAvecRemise: detailsAvecRemise.length,
      totalRemises,
      remiseMoyenne: totalRemises / detailsAvecRemise.length,
      remiseMax,
      economieClientTotale
    };
  }

  static fromEntity(vente) {
    return new VenteDTO(vente);
  }

  static fromEntities(ventes) {
    return ventes.map(v => new VenteDTO(v));
  }
}

/**
 * DTO pour les détails de vente
 */
class DetailVenteDTO {
  constructor(detail) {
    this.id = detail.id;
    this.venteId = detail.venteId;
    this.produitId = detail.produitId;
    this.quantite = detail.quantite;
    this.prixUnitaire = parseFloat(detail.prixUnitaire);
    this.prixAffiche = parseFloat(detail.prixAffiche || detail.prixUnitaire);
    this.remiseAppliquee = parseFloat(detail.remiseAppliquee || 0);
    this.justificationRemise = detail.justificationRemise;
    this.prixTotal = parseFloat(detail.prixTotal);
    
    // Calculs dérivés
    this.economieUnitaire = this.prixAffiche - this.prixUnitaire;
    this.economieTotale = this.economieUnitaire * this.quantite;
    this.pourcentageRemise = this.prixAffiche > 0 ? (this.remiseAppliquee / this.prixAffiche * 100) : 0;

    // Inclure les informations du produit si disponibles
    if (detail.produit) {
      this.produit = {
        id: detail.produit.id,
        reference: detail.produit.reference,
        nom: detail.produit.nom,
        remiseMaxAutorisee: detail.produit.remiseMaxAutorisee || 0
      };
      
      // Vérifier si la remise est dans les limites autorisées
      this.remiseAutorisee = this.remiseAppliquee <= (detail.produit.remiseMaxAutorisee || 0);
    }
  }

  static fromEntity(detail) {
    return new DetailVenteDTO(detail);
  }

  static fromEntities(details) {
    return details.map(d => new DetailVenteDTO(d));
  }
}

/**
 * DTO pour les commandes d'approvisionnement
 */
class CommandeApprovisionnementDTO {
  constructor(commande) {
    this.id = commande.id;
    this.numeroCommande = commande.numeroCommande;
    this.fournisseurId = commande.fournisseurId;
    this.statut = commande.statut;
    this.dateCommande = commande.dateCommande;
    this.dateLivraisonPrevue = commande.dateLivraisonPrevue;
    this.montantTotal = commande.montantTotal ? parseFloat(commande.montantTotal) : null;
    this.modePaiement = commande.modePaiement;
    this.notes = commande.notes;

    // Inclure les informations du fournisseur si disponibles
    if (commande.fournisseur) {
      this.fournisseur = {
        id: commande.fournisseur.id,
        nom: commande.fournisseur.nom,
        personneContact: commande.fournisseur.personneContact
      };
    }

    // Inclure les détails si disponibles
    if (commande.details) {
      this.details = commande.details.map(d => new DetailCommandeApprovisionnementDTO(d));
    }
  }

  static fromEntity(commande) {
    return new CommandeApprovisionnementDTO(commande);
  }

  static fromEntities(commandes) {
    return commandes.map(c => new CommandeApprovisionnementDTO(c));
  }
}

/**
 * DTO pour les détails de commande d'approvisionnement
 */
class DetailCommandeApprovisionnementDTO {
  constructor(detail) {
    this.id = detail.id;
    this.commandeId = detail.commandeId;
    this.produitId = detail.produitId;
    this.quantiteCommandee = detail.quantiteCommandee;
    this.quantiteRecue = detail.quantiteRecue;
    this.quantiteRestante = detail.quantiteCommandee - detail.quantiteRecue;
    this.coutUnitaire = parseFloat(detail.coutUnitaire);
    this.coutTotal = parseFloat(detail.coutUnitaire) * detail.quantiteCommandee;
    this.estComplet = detail.quantiteRecue >= detail.quantiteCommandee;

    // Inclure les informations du produit si disponibles
    if (detail.produit) {
      this.produit = {
        id: detail.produit.id,
        reference: detail.produit.reference,
        nom: detail.produit.nom
      };
    }
  }

  static fromEntity(detail) {
    return new DetailCommandeApprovisionnementDTO(detail);
  }

  static fromEntities(details) {
    return details.map(d => new DetailCommandeApprovisionnementDTO(d));
  }
}

/**
 * DTO pour les transactions de compte
 */
class TransactionCompteDTO {
  constructor(transaction) {
    this.id = transaction.id;
    this.typeCompte = transaction.typeCompte;
    this.compteId = transaction.compteId;
    this.typeTransaction = transaction.typeTransaction;
    this.montant = parseFloat(transaction.montant);
    this.description = transaction.description;
    this.referenceId = transaction.referenceId;
    this.referenceType = transaction.referenceType;
    this.dateTransaction = transaction.dateTransaction;
    this.soldeApres = parseFloat(transaction.soldeApres);
  }

  static fromEntity(transaction) {
    return new TransactionCompteDTO(transaction);
  }

  static fromEntities(transactions) {
    return transactions.map(t => new TransactionCompteDTO(t));
  }
}

/**
 * DTO pour les mouvements de stock
 */
class MouvementStockDTO {
  constructor(mouvement) {
    this.id = mouvement.id;
    this.produitId = mouvement.produitId;
    this.typeMouvement = mouvement.typeMouvement;
    this.changementQuantite = mouvement.changementQuantite;
    this.referenceId = mouvement.referenceId;
    this.typeReference = mouvement.typeReference;
    this.dateMouvement = mouvement.dateMouvement;
    this.notes = mouvement.notes;

    // Inclure les informations du produit si disponibles
    if (mouvement.produit) {
      this.produit = {
        id: mouvement.produit.id,
        reference: mouvement.produit.reference,
        nom: mouvement.produit.nom,
        // Inclure le stock actuel pour calculer le stock initial
        stockActuel: mouvement.produit.stock?.quantiteDisponible
      };
    }
  }

  static fromEntity(mouvement) {
    return new MouvementStockDTO(mouvement);
  }

  static fromEntities(mouvements) {
    return mouvements.map(m => new MouvementStockDTO(m));
  }
}

/**
 * DTO pour les catégories de mouvements financiers
 */
class MovementCategoryDTO {
  constructor(category) {
    this.id = category.id;
    this.nom = category.nom;
    this.displayName = category.displayName;
    this.color = category.color;
    this.icon = category.icon;
    this.isDefault = category.isDefault;
    this.isActive = category.isActive;
    this.dateCreation = category.dateCreation;
    this.dateModification = category.dateModification;
  }

  static fromEntity(category) {
    return new MovementCategoryDTO(category);
  }

  static fromEntities(categories) {
    return categories.map(c => new MovementCategoryDTO(c));
  }
}

/**
 * DTO pour les attachments de mouvements financiers
 */
class MovementAttachmentDTO {
  constructor(attachment) {
    this.id = attachment.id;
    this.mouvementId = attachment.mouvementId;
    this.fileName = attachment.fileName;
    this.originalName = attachment.originalName;
    this.mimeType = attachment.mimeType;
    this.fileSize = attachment.fileSize;
    this.filePath = attachment.filePath;
    this.uploadedAt = attachment.uploadedAt;
    
    // Informations dérivées
    this.isImage = attachment.mimeType.startsWith('image/');
    this.isPdf = attachment.mimeType === 'application/pdf';
    this.fileSizeFormatted = this.formatFileSize(attachment.fileSize);
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  static fromEntity(attachment) {
    return new MovementAttachmentDTO(attachment);
  }

  static fromEntities(attachments) {
    return attachments.map(a => new MovementAttachmentDTO(a));
  }
}

/**
 * DTO pour les mouvements financiers
 */
class FinancialMovementDTO {
  constructor(movement) {
    this.id = movement.id;
    this.reference = movement.reference;
    this.montant = parseFloat(movement.montant);
    this.categorieId = movement.categorieId;
    this.description = movement.description;
    this.date = movement.date;
    this.utilisateurId = movement.utilisateurId;
    this.dateCreation = movement.dateCreation;
    this.dateModification = movement.dateModification;
    this.notes = movement.notes;

    // Inclure les informations de la catégorie si disponibles
    if (movement.categorie) {
      this.categorie = new MovementCategoryDTO(movement.categorie);
    }

    // Inclure les informations de l'utilisateur si disponibles
    if (movement.utilisateur) {
      this.utilisateur = {
        id: movement.utilisateur.id,
        nomUtilisateur: movement.utilisateur.nomUtilisateur,
        email: movement.utilisateur.email
      };
    }

    // Inclure les attachments si disponibles
    if (movement.attachments) {
      this.attachments = MovementAttachmentDTO.fromEntities(movement.attachments);
      this.hasAttachments = movement.attachments.length > 0;
      this.attachmentCount = movement.attachments.length;
    }

    // Informations dérivées
    this.montantFormate = this.formatAmount(movement.montant);
    this.dateFormatee = this.formatDate(movement.date);
  }

  formatAmount(amount) {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
      maximumFractionDigits: 2
    }).format(amount);
  }

  formatDate(date) {
    return new Intl.DateTimeFormat('fr-FR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(new Date(date));
  }

  static fromEntity(movement) {
    return new FinancialMovementDTO(movement);
  }

  static fromEntities(movements) {
    return movements.map(m => new FinancialMovementDTO(m));
  }
}

/**
 * DTO pour les statistiques de mouvements financiers
 */
class MovementStatisticsDTO {
  constructor(stats) {
    // Helper pour parser les nombres de manière sûre
    const safeParseFloat = (value, defaultValue = 0) => {
      if (value == null || value === undefined) return defaultValue;
      const parsed = parseFloat(value);
      return isNaN(parsed) || !isFinite(parsed) ? defaultValue : parsed;
    };

    const safeParseInt = (value, defaultValue = 0) => {
      if (value == null || value === undefined) return defaultValue;
      const parsed = parseInt(value);
      return isNaN(parsed) ? defaultValue : parsed;
    };

    this.totalMovements = safeParseInt(stats.totalMovements);
    this.totalAmount = safeParseFloat(stats.totalAmount);
    this.averageAmount = safeParseFloat(stats.averageAmount);
    
    // Formatage des montants
    this.totalAmountFormatted = this.formatAmount(this.totalAmount);
    this.averageAmountFormatted = this.formatAmount(this.averageAmount);

    // Répartition par catégorie
    if (stats.categoryBreakdown && Array.isArray(stats.categoryBreakdown)) {
      this.categoryBreakdown = stats.categoryBreakdown.map(item => {
        const itemAmount = safeParseFloat(item._sum?.montant);
        const itemCount = safeParseInt(item._count);
        const percentage = this.totalAmount > 0 ? 
          safeParseFloat((itemAmount / this.totalAmount * 100).toFixed(1)) : 0;

        return {
          categoryId: safeParseInt(item.categorieId),
          categoryName: item.categorie?.nom || `Catégorie ${item.categorieId}`,
          categorie: item.categorie ? new MovementCategoryDTO(item.categorie) : null,
          count: itemCount,
          amount: itemAmount,
          totalAmount: itemAmount, // Alias pour compatibilité
          totalAmountFormatted: this.formatAmount(itemAmount),
          percentage: percentage
        };
      });
    } else {
      this.categoryBreakdown = [];
    }

    // Répartition quotidienne (si disponible)
    if (stats.dailyBreakdown && Array.isArray(stats.dailyBreakdown)) {
      this.dailyBreakdown = stats.dailyBreakdown.map(item => ({
        date: item.date || new Date().toISOString(),
        amount: safeParseFloat(item.amount),
        count: safeParseInt(item.count)
      }));
    } else {
      this.dailyBreakdown = [];
    }
  }

  formatAmount(amount) {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'XOF',
      minimumFractionDigits: 0,
      maximumFractionDigits: 2
    }).format(amount || 0);
  }

  static fromEntity(stats) {
    return new MovementStatisticsDTO(stats);
  }
}

/**
 * DTO pour les dates de péremption
 */
class DatePeremptionDTO {
  constructor(datePeremption) {
    this.id = datePeremption.id;
    this.produitId = datePeremption.produitId;
    this.datePeremption = datePeremption.datePeremption;
    this.quantite = datePeremption.quantite;
    this.numeroLot = datePeremption.numeroLot;
    this.dateEntree = datePeremption.dateEntree;
    this.notes = datePeremption.notes;
    this.estEpuise = datePeremption.estEpuise;
    this.dateCreation = datePeremption.dateCreation;
    this.dateModification = datePeremption.dateModification;

    // Calculer le statut de péremption
    const now = new Date();
    const datePerem = new Date(datePeremption.datePeremption);
    const joursRestants = Math.ceil((datePerem - now) / (1000 * 60 * 60 * 24));

    this.joursRestants = joursRestants;
    this.estPerime = joursRestants < 0;
    this.estProcheDeLaPeremption = joursRestants >= 0 && joursRestants <= 30;
    this.niveauAlerte = this.getNiveauAlerte(joursRestants);

    // Inclure les informations du produit si disponibles
    if (datePeremption.produit) {
      this.produit = {
        id: datePeremption.produit.id,
        reference: datePeremption.produit.reference,
        nom: datePeremption.produit.nom
      };
    }
  }

  getNiveauAlerte(joursRestants) {
    if (joursRestants < 0) return 'perime'; // Rouge
    if (joursRestants <= 7) return 'critique'; // Rouge
    if (joursRestants <= 30) return 'avertissement'; // Orange
    if (joursRestants <= 90) return 'attention'; // Jaune
    return 'normal'; // Vert
  }

  static fromEntity(datePeremption) {
    return new DatePeremptionDTO(datePeremption);
  }

  static fromEntities(datesPeremption) {
    return datesPeremption.map(d => new DatePeremptionDTO(d));
  }
}

module.exports = {
  BaseResponseDTO,
  PaginatedResponseDTO,
  UtilisateurDTO,
  ProduitDTO,
  StockDTO,
  ClientDTO,
  FournisseurDTO,
  CompteClientDTO,
  CompteFournisseurDTO,
  VenteDTO,
  DetailVenteDTO,
  CommandeApprovisionnementDTO,
  DetailCommandeApprovisionnementDTO,
  TransactionCompteDTO,
  MouvementStockDTO,
  MovementCategoryDTO,
  MovementAttachmentDTO,
  FinancialMovementDTO,
  MovementStatisticsDTO,
  DatePeremptionDTO
};