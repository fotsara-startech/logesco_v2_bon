/**
 * Middleware de validation pour l'API LOGESCO
 * Utilise les schémas Joi pour valider les données d'entrée
 */

const { BaseResponseDTO } = require('../dto');

/**
 * Middleware de validation générique
 * @param {Object} schema - Schéma Joi à utiliser pour la validation
 * @param {string} source - Source des données ('body', 'query', 'params')
 * @returns {Function} Middleware Express
 */
function validate(schema, source = 'body') {
  return (req, res, next) => {
    const data = req[source];
    
    const { error, value } = schema.validate(data, {
      abortEarly: false, // Retourner toutes les erreurs
      stripUnknown: true, // Supprimer les champs non définis
      convert: true // Convertir les types automatiquement
    });

    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message,
        value: detail.context?.value
      }));

      return res.status(400).json(
        BaseResponseDTO.error('Données de validation invalides', errors)
      );
    }

    // Remplacer les données originales par les données validées et nettoyées
    req[source] = value;
    next();
  };
}

/**
 * Middleware de validation pour les paramètres d'ID
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {Function} next - Fonction next
 */
function validateId(req, res, next) {
  const id = parseInt(req.params.id);
  
  if (isNaN(id) || id <= 0) {
    return res.status(400).json(
      BaseResponseDTO.error('ID invalide', [
        {
          field: 'id',
          message: 'L\'ID doit être un nombre entier positif',
          value: req.params.id
        }
      ])
    );
  }

  req.params.id = id;
  next();
}

/**
 * Middleware de validation pour les paramètres de pagination
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {Function} next - Fonction next
 */
function validatePagination(req, res, next) {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;

  // Limites de sécurité
  if (page < 1) {
    return res.status(400).json(
      BaseResponseDTO.error('Paramètre de pagination invalide', [
        {
          field: 'page',
          message: 'La page doit être supérieure à 0',
          value: req.query.page
        }
      ])
    );
  }

  if (limit < 1 || limit > 100) {
    return res.status(400).json(
      BaseResponseDTO.error('Paramètre de pagination invalide', [
        {
          field: 'limit',
          message: 'La limite doit être entre 1 et 100',
          value: req.query.limit
        }
      ])
    );
  }

  req.query.page = page;
  req.query.limit = limit;
  next();
}

/**
 * Middleware de validation pour les dates
 * @param {Array} dateFields - Champs de date à valider
 * @returns {Function} Middleware Express
 */
function validateDates(dateFields = []) {
  return (req, res, next) => {
    const errors = [];

    for (const field of dateFields) {
      const value = req.body[field] || req.query[field];
      
      if (value) {
        const date = new Date(value);
        
        if (isNaN(date.getTime())) {
          errors.push({
            field,
            message: 'Format de date invalide (utilisez ISO 8601)',
            value
          });
        } else {
          // Remplacer par l'objet Date validé
          if (req.body[field]) req.body[field] = date;
          if (req.query[field]) req.query[field] = date;
        }
      }
    }

    if (errors.length > 0) {
      return res.status(400).json(
        BaseResponseDTO.error('Dates invalides', errors)
      );
    }

    next();
  };
}

/**
 * Middleware de validation pour les montants
 * @param {Array} amountFields - Champs de montant à valider
 * @returns {Function} Middleware Express
 */
function validateAmounts(amountFields = []) {
  return (req, res, next) => {
    const errors = [];

    for (const field of amountFields) {
      const value = req.body[field];
      
      if (value !== undefined && value !== null) {
        const amount = parseFloat(value);
        
        if (isNaN(amount) || amount < 0) {
          errors.push({
            field,
            message: 'Le montant doit être un nombre positif',
            value
          });
        } else {
          // Arrondir à 2 décimales
          req.body[field] = Math.round(amount * 100) / 100;
        }
      }
    }

    if (errors.length > 0) {
      return res.status(400).json(
        BaseResponseDTO.error('Montants invalides', errors)
      );
    }

    next();
  };
}

/**
 * Middleware de validation pour les quantités
 * @param {Array} quantityFields - Champs de quantité à valider
 * @returns {Function} Middleware Express
 */
function validateQuantities(quantityFields = []) {
  return (req, res, next) => {
    const errors = [];

    for (const field of quantityFields) {
      const value = req.body[field];
      
      if (value !== undefined && value !== null) {
        const quantity = parseInt(value);
        
        if (isNaN(quantity) || quantity < 0) {
          errors.push({
            field,
            message: 'La quantité doit être un nombre entier positif',
            value
          });
        } else {
          req.body[field] = quantity;
        }
      }
    }

    if (errors.length > 0) {
      return res.status(400).json(
        BaseResponseDTO.error('Quantités invalides', errors)
      );
    }

    next();
  };
}

/**
 * Middleware de validation pour les références uniques
 * @param {Function} checkFunction - Fonction pour vérifier l'unicité
 * @param {string} field - Champ à vérifier
 * @param {string} message - Message d'erreur personnalisé
 * @returns {Function} Middleware Express
 */
function validateUnique(checkFunction, field, message) {
  return async (req, res, next) => {
    try {
      const value = req.body[field];
      
      if (value) {
        const exists = await checkFunction(value, req.params.id);
        
        if (exists) {
          return res.status(409).json(
            BaseResponseDTO.error(message || `${field} déjà utilisé`, [
              {
                field,
                message: message || `Cette valeur de ${field} est déjà utilisée`,
                value
              }
            ])
          );
        }
      }

      next();
    } catch (error) {
      console.error('Erreur validation unicité:', error);
      return res.status(500).json(
        BaseResponseDTO.error('Erreur lors de la validation')
      );
    }
  };
}

/**
 * Middleware de validation pour les tableaux non vides
 * @param {Array} arrayFields - Champs tableau à valider
 * @returns {Function} Middleware Express
 */
function validateNonEmptyArrays(arrayFields = []) {
  return (req, res, next) => {
    const errors = [];

    for (const field of arrayFields) {
      const value = req.body[field];
      
      if (!Array.isArray(value) || value.length === 0) {
        errors.push({
          field,
          message: `${field} doit être un tableau non vide`,
          value
        });
      }
    }

    if (errors.length > 0) {
      return res.status(400).json(
        BaseResponseDTO.error('Tableaux invalides', errors)
      );
    }

    next();
  };
}

/**
 * Middleware de nettoyage des données d'entrée
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {Function} next - Fonction next
 */
function sanitizeInput(req, res, next) {
  // Nettoyer les chaînes de caractères dans le body
  if (req.body && typeof req.body === 'object') {
    req.body = cleanObject(req.body);
  }

  // Nettoyer les paramètres de requête
  if (req.query && typeof req.query === 'object') {
    req.query = cleanObject(req.query);
  }

  next();
}

/**
 * Nettoie récursivement un objet
 * @param {Object} obj - Objet à nettoyer
 * @returns {Object} Objet nettoyé
 */
function cleanObject(obj) {
  const cleaned = {};
  
  for (const [key, value] of Object.entries(obj)) {
    if (value === null || value === undefined) {
      cleaned[key] = null;
    } else if (typeof value === 'string') {
      const trimmed = value.trim();
      cleaned[key] = trimmed === '' ? null : trimmed;
    } else if (Array.isArray(value)) {
      cleaned[key] = value.map(item => 
        typeof item === 'object' ? cleanObject(item) : item
      );
    } else if (typeof value === 'object') {
      cleaned[key] = cleanObject(value);
    } else {
      cleaned[key] = value;
    }
  }
  
  return cleaned;
}

module.exports = {
  validate,
  validateId,
  validatePagination,
  validateDates,
  validateAmounts,
  validateQuantities,
  validateUnique,
  validateNonEmptyArrays,
  sanitizeInput
};