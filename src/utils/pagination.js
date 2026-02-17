/**
 * Utilitaires de pagination pour les API LOGESCO
 * Support pour pagination, tri et filtrage
 */

/**
 * Classe pour gérer la pagination des résultats
 */
class PaginationHelper {
  /**
   * Crée les paramètres de pagination pour Prisma
   * @param {Object} query - Paramètres de requête
   * @param {Object} options - Options de pagination
   * @returns {Object} Paramètres Prisma
   */
  static createPrismaParams(query = {}, options = {}) {
    const {
      page = 1,
      limit = 20,
      sortBy = 'id',
      sortOrder = 'desc',
      search = '',
      ...filters
    } = query;

    // Validation des paramètres
    const validatedPage = Math.max(1, parseInt(page) || 1);
    const validatedLimit = Math.min(100, Math.max(1, parseInt(limit) || 20));
    const validatedSortOrder = ['asc', 'desc'].includes(sortOrder) ? sortOrder : 'desc';

    // Calcul de l'offset
    const skip = (validatedPage - 1) * validatedLimit;

    // Construction des paramètres Prisma
    const prismaParams = {
      skip,
      take: validatedLimit,
      orderBy: {
        [sortBy]: validatedSortOrder
      }
    };

    // Ajout des filtres de recherche si spécifiés
    if (search && options.searchFields) {
      prismaParams.where = {
        OR: options.searchFields.map(field => ({
          [field]: {
            contains: search,
            mode: 'insensitive'
          }
        }))
      };
    }

    // Ajout des filtres personnalisés
    if (Object.keys(filters).length > 0 && options.filterFields) {
      const customFilters = {};
      
      Object.entries(filters).forEach(([key, value]) => {
        if (options.filterFields.includes(key) && value !== undefined && value !== '') {
          // Gestion des différents types de filtres
          if (typeof value === 'string' && value.includes(',')) {
            // Filtre multiple (ex: "1,2,3")
            customFilters[key] = {
              in: value.split(',').map(v => v.trim())
            };
          } else if (key.endsWith('_min') || key.endsWith('_max')) {
            // Filtres de plage
            const baseField = key.replace(/_min|_max$/, '');
            if (!customFilters[baseField]) {
              customFilters[baseField] = {};
            }
            
            if (key.endsWith('_min')) {
              customFilters[baseField].gte = parseFloat(value) || 0;
            } else {
              customFilters[baseField].lte = parseFloat(value) || 0;
            }
          } else {
            // Filtre exact
            customFilters[key] = value;
          }
        }
      });

      // Combiner avec les filtres de recherche
      if (prismaParams.where) {
        prismaParams.where = {
          AND: [
            prismaParams.where,
            customFilters
          ]
        };
      } else {
        prismaParams.where = customFilters;
      }
    }

    return {
      prismaParams,
      pagination: {
        page: validatedPage,
        limit: validatedLimit,
        sortBy,
        sortOrder: validatedSortOrder
      }
    };
  }

  /**
   * Crée la réponse paginée standardisée
   * @param {Array} data - Données récupérées
   * @param {number} total - Nombre total d'éléments
   * @param {Object} pagination - Paramètres de pagination
   * @returns {Object} Réponse paginée
   */
  static createPaginatedResponse(data, total, pagination) {
    const { page, limit } = pagination;
    const totalPages = Math.ceil(total / limit);
    const hasNext = page < totalPages;
    const hasPrev = page > 1;

    return {
      success: true,
      data,
      pagination: {
        page,
        limit,
        total,
        pages: totalPages,
        hasNext,
        hasPrev,
        from: total > 0 ? (page - 1) * limit + 1 : 0,
        to: Math.min(page * limit, total)
      },
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Middleware pour valider les paramètres de pagination
   * @param {Object} options - Options de validation
   * @returns {Function} Middleware Express
   */
  static validatePaginationMiddleware(options = {}) {
    const {
      maxLimit = 100,
      defaultLimit = 20,
      allowedSortFields = ['id', 'createdAt', 'updatedAt'],
      allowedFilterFields = []
    } = options;

    return (req, res, next) => {
      try {
        // Validation de la page
        if (req.query.page && (isNaN(req.query.page) || parseInt(req.query.page) < 1)) {
          return res.status(400).json({
            success: false,
            error: {
              message: 'Le numéro de page doit être un entier positif',
              code: 'INVALID_PAGE',
              field: 'page'
            }
          });
        }

        // Validation de la limite
        if (req.query.limit) {
          const limit = parseInt(req.query.limit);
          if (isNaN(limit) || limit < 1 || limit > maxLimit) {
            return res.status(400).json({
              success: false,
              error: {
                message: `La limite doit être entre 1 et ${maxLimit}`,
                code: 'INVALID_LIMIT',
                field: 'limit'
              }
            });
          }
        }

        // Validation du champ de tri
        if (req.query.sortBy && !allowedSortFields.includes(req.query.sortBy)) {
          return res.status(400).json({
            success: false,
            error: {
              message: `Champ de tri invalide. Champs autorisés: ${allowedSortFields.join(', ')}`,
              code: 'INVALID_SORT_FIELD',
              field: 'sortBy'
            }
          });
        }

        // Validation de l'ordre de tri
        if (req.query.sortOrder && !['asc', 'desc'].includes(req.query.sortOrder)) {
          return res.status(400).json({
            success: false,
            error: {
              message: 'L\'ordre de tri doit être "asc" ou "desc"',
              code: 'INVALID_SORT_ORDER',
              field: 'sortOrder'
            }
          });
        }

        // Validation des filtres
        if (allowedFilterFields.length > 0) {
          const invalidFilters = Object.keys(req.query).filter(key => 
            !['page', 'limit', 'sortBy', 'sortOrder', 'search'].includes(key) &&
            !allowedFilterFields.includes(key) &&
            !allowedFilterFields.some(field => key.startsWith(field + '_'))
          );

          if (invalidFilters.length > 0) {
            return res.status(400).json({
              success: false,
              error: {
                message: `Filtres invalides: ${invalidFilters.join(', ')}`,
                code: 'INVALID_FILTERS',
                field: 'filters'
              }
            });
          }
        }

        // Définir les valeurs par défaut
        req.query.limit = req.query.limit || defaultLimit;
        req.query.page = req.query.page || 1;
        req.query.sortBy = req.query.sortBy || allowedSortFields[0];
        req.query.sortOrder = req.query.sortOrder || 'desc';

        next();
      } catch (error) {
        return res.status(500).json({
          success: false,
          error: {
            message: 'Erreur lors de la validation des paramètres de pagination',
            code: 'PAGINATION_VALIDATION_ERROR'
          }
        });
      }
    };
  }

  /**
   * Crée un cache key pour la pagination
   * @param {string} baseKey - Clé de base
   * @param {Object} params - Paramètres de pagination
   * @returns {string} Clé de cache
   */
  static createCacheKey(baseKey, params) {
    const { page, limit, sortBy, sortOrder, search, ...filters } = params;
    
    const keyParts = [
      baseKey,
      `page:${page}`,
      `limit:${limit}`,
      `sort:${sortBy}:${sortOrder}`
    ];

    if (search) {
      keyParts.push(`search:${search}`);
    }

    // Ajouter les filtres triés pour une clé cohérente
    const sortedFilters = Object.keys(filters).sort().map(key => `${key}:${filters[key]}`);
    if (sortedFilters.length > 0) {
      keyParts.push(`filters:${sortedFilters.join(',')}`);
    }

    return keyParts.join('|');
  }

  /**
   * Optimise une requête Prisma pour de meilleures performances
   * @param {Object} prismaParams - Paramètres Prisma
   * @param {Object} options - Options d'optimisation
   * @returns {Object} Paramètres optimisés
   */
  static optimizePrismaQuery(prismaParams, options = {}) {
    const optimized = { ...prismaParams };

    // Sélection des champs spécifiques pour réduire la taille des données
    if (options.selectFields) {
      optimized.select = options.selectFields.reduce((acc, field) => {
        acc[field] = true;
        return acc;
      }, {});
    }

    // Inclusion des relations nécessaires uniquement
    if (options.includeRelations) {
      optimized.include = options.includeRelations;
    }

    // Optimisation des index pour les requêtes de recherche
    if (optimized.where && options.indexHints) {
      // Réorganiser les conditions WHERE pour utiliser les index efficacement
      const { OR, AND, ...directConditions } = optimized.where;
      
      if (Object.keys(directConditions).length > 0) {
        optimized.where = {
          ...directConditions,
          ...(AND && { AND }),
          ...(OR && { OR })
        };
      }
    }

    return optimized;
  }
}

module.exports = PaginationHelper;