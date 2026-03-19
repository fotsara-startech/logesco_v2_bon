/**
 * Classes d'exception métier personnalisées pour LOGESCO
 * Chaque erreur a un code spécifique et un message en français
 */

/**
 * Classe de base pour toutes les erreurs métier
 */
class BusinessError extends Error {
  constructor(message, code, status = 400, details = {}) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    this.status = status;
    this.details = details;
    this.timestamp = new Date().toISOString();
    
    // Capture la stack trace
    Error.captureStackTrace(this, this.constructor);
  }

  /**
   * Convertit l'erreur en format JSON pour l'API
   */
  toJSON() {
    return {
      success: false,
      error: {
        message: this.message,
        code: this.code,
        status: this.status,
        timestamp: this.timestamp,
        details: this.details
      }
    };
  }
}

/**
 * Erreur de validation des données
 */
class ValidationError extends BusinessError {
  constructor(message, field = null, value = null) {
    super(message, 'VALIDATION_ERROR', 400, { field, value });
  }
}

/**
 * Erreur de ressource non trouvée
 */
class NotFoundError extends BusinessError {
  constructor(resource, id = null) {
    const message = id 
      ? `${resource} avec l'ID ${id} non trouvé(e)`
      : `${resource} non trouvé(e)`;
    
    super(message, 'RESOURCE_NOT_FOUND', 404, { resource, id });
  }
}

/**
 * Erreur d'authentification
 */
class AuthenticationError extends BusinessError {
  constructor(message = 'Authentification requise') {
    super(message, 'AUTHENTICATION_REQUIRED', 401);
  }
}

/**
 * Erreur d'autorisation
 */
class AuthorizationError extends BusinessError {
  constructor(message = 'Accès non autorisé') {
    super(message, 'ACCESS_DENIED', 403);
  }
}

/**
 * Erreur de conflit (ressource déjà existante)
 */
class ConflictError extends BusinessError {
  constructor(message, field = null, value = null) {
    super(message, 'RESOURCE_CONFLICT', 409, { field, value });
  }
}

/**
 * Erreur de stock insuffisant
 */
class InsufficientStockError extends BusinessError {
  constructor(productName, available, requested) {
    const message = `Stock insuffisant pour ${productName}. Disponible: ${available}, Demandé: ${requested}`;
    super(message, 'INSUFFICIENT_STOCK', 400, {
      productName,
      available,
      requested
    });
  }
}

/**
 * Erreur de limite de crédit dépassée
 */
class CreditLimitExceededError extends BusinessError {
  constructor(clientName, currentBalance, creditLimit, requestedAmount) {
    const message = `Limite de crédit dépassée pour ${clientName}. Solde actuel: ${currentBalance}, Limite: ${creditLimit}, Montant demandé: ${requestedAmount}`;
    super(message, 'CREDIT_LIMIT_EXCEEDED', 400, {
      clientName,
      currentBalance,
      creditLimit,
      requestedAmount
    });
  }
}

/**
 * Erreur de référence produit déjà existante
 */
class DuplicateProductReferenceError extends ConflictError {
  constructor(reference) {
    super(`La référence produit '${reference}' existe déjà`, 'reference', reference);
    this.code = 'DUPLICATE_PRODUCT_REFERENCE';
  }
}

/**
 * Erreur de suppression impossible (ressource liée)
 */
class DeleteConstraintError extends BusinessError {
  constructor(resource, reason) {
    const message = `Impossible de supprimer ${resource}: ${reason}`;
    super(message, 'DELETE_CONSTRAINT_VIOLATION', 409, { resource, reason });
  }
}

/**
 * Erreur de transaction invalide
 */
class InvalidTransactionError extends BusinessError {
  constructor(message, transactionType = null) {
    super(message, 'INVALID_TRANSACTION', 400, { transactionType });
  }
}

/**
 * Erreur de prix invalide
 */
class InvalidPriceError extends ValidationError {
  constructor(price, field = 'prix') {
    super(`Le prix doit être positif et supérieur à 0. Valeur reçue: ${price}`, field, price);
    this.code = 'INVALID_PRICE';
  }
}

/**
 * Erreur de quantité invalide
 */
class InvalidQuantityError extends ValidationError {
  constructor(quantity, field = 'quantite') {
    super(`La quantité doit être un nombre entier positif. Valeur reçue: ${quantity}`, field, quantity);
    this.code = 'INVALID_QUANTITY';
  }
}

/**
 * Erreur de commande déjà traitée
 */
class OrderAlreadyProcessedError extends BusinessError {
  constructor(orderNumber, currentStatus) {
    const message = `La commande ${orderNumber} a déjà été traitée (statut: ${currentStatus})`;
    super(message, 'ORDER_ALREADY_PROCESSED', 409, { orderNumber, currentStatus });
  }
}

/**
 * Erreur de vente déjà annulée
 */
class SaleAlreadyCancelledError extends BusinessError {
  constructor(saleNumber) {
    const message = `La vente ${saleNumber} a déjà été annulée`;
    super(message, 'SALE_ALREADY_CANCELLED', 409, { saleNumber });
  }
}

/**
 * Erreur de base de données
 */
class DatabaseError extends BusinessError {
  constructor(message, operation = null) {
    super(message, 'DATABASE_ERROR', 500, { operation });
  }
}

/**
 * Erreur de configuration
 */
class ConfigurationError extends BusinessError {
  constructor(message, configKey = null) {
    super(message, 'CONFIGURATION_ERROR', 500, { configKey });
  }
}

/**
 * Factory pour créer des erreurs métier à partir d'erreurs Prisma
 */
class ErrorFactory {
  /**
   * Convertit une erreur Prisma en erreur métier
   */
  static fromPrismaError(error) {
    if (error.code === 'P2002') {
      // Contrainte unique violée
      const field = error.meta?.target?.[0] || 'champ';
      return new ConflictError(`Une entrée avec cette valeur de ${field} existe déjà`, field);
    }

    if (error.code === 'P2025') {
      // Enregistrement non trouvé
      return new NotFoundError('Ressource');
    }

    if (error.code === 'P2003') {
      // Contrainte de clé étrangère violée
      return new DeleteConstraintError('la ressource', 'elle est liée à d\'autres données');
    }

    // Erreur de base de données générique
    return new DatabaseError(error.message, 'prisma_operation');
  }

  /**
   * Crée une erreur de validation à partir d'un schéma Joi
   */
  static fromJoiError(joiError) {
    const details = joiError.details.map(detail => ({
      field: detail.path.join('.'),
      message: detail.message,
      value: detail.context?.value
    }));

    const firstDetail = details[0];
    const error = new ValidationError(firstDetail.message, firstDetail.field, firstDetail.value);
    error.details.validationErrors = details;
    
    return error;
  }
}

module.exports = {
  BusinessError,
  ValidationError,
  NotFoundError,
  AuthenticationError,
  AuthorizationError,
  ConflictError,
  InsufficientStockError,
  CreditLimitExceededError,
  DuplicateProductReferenceError,
  DeleteConstraintError,
  InvalidTransactionError,
  InvalidPriceError,
  InvalidQuantityError,
  OrderAlreadyProcessedError,
  SaleAlreadyCancelledError,
  DatabaseError,
  ConfigurationError,
  ErrorFactory
};