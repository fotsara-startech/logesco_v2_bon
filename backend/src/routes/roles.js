const express = require('express');
const { PrismaClient } = require('../config/prisma-client.js');

const prisma = new PrismaClient();

/**
 * Crée le routeur pour la gestion des rôles
 * @param {Object} dependencies - Les dépendances injectées
 * @returns {Router}
 */
function createRoleRouter(dependencies) {
  const router = express.Router();

  // GET /roles - Récupérer tous les rôles depuis la base de données
  router.get('/', async (req, res) => {
    try {
      console.log('🔍 [RoleRouter] Récupération des rôles depuis la base de données...');
      
      const roles = await prisma.userRole.findMany({
        orderBy: { id: 'asc' }
      });

      console.log(`✅ [RoleRouter] ${roles.length} rôles trouvés`);
      
      // Parser les privilèges pour chaque rôle
      const rolesWithParsedPrivileges = roles.map(role => {
        let privileges = role.privileges;
        if (typeof privileges === 'string') {
          try {
            privileges = JSON.parse(privileges);
          } catch (e) {
            console.error(`❌ [RoleRouter] Erreur parsing privilèges pour rôle ${role.nom}:`, e);
            privileges = {};
          }
        }
        return {
          ...role,
          privileges: privileges || {}
        };
      });
      
      res.json({
        success: true,
        data: rolesWithParsedPrivileges
      });
    } catch (error) {
      console.error('❌ [RoleRouter] Erreur lors de la récupération des rôles:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération des rôles',
          code: 'ROLES_FETCH_ERROR'
        }
      });
    }
  });

  // GET /roles/:id - Récupérer un rôle par ID depuis la base de données
  router.get('/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      
      if (isNaN(id)) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'ID de rôle invalide',
            code: 'INVALID_ROLE_ID'
          }
        });
      }

      console.log(`🔍 [RoleRouter] Récupération du rôle ID: ${id}`);
      
      const role = await prisma.userRole.findUnique({
        where: { id: id }
      });
      
      if (!role) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Rôle non trouvé',
            code: 'ROLE_NOT_FOUND'
          }
        });
      }
      
      console.log(`✅ [RoleRouter] Rôle trouvé: ${role.displayName}`);
      
      // Parser les privilèges
      let privileges = role.privileges;
      if (typeof privileges === 'string') {
        try {
          privileges = JSON.parse(privileges);
        } catch (e) {
          console.error(`❌ [RoleRouter] Erreur parsing privilèges pour rôle ${role.nom}:`, e);
          privileges = {};
        }
      }
      
      res.json({
        success: true,
        data: {
          ...role,
          privileges: privileges || {}
        }
      });
    } catch (error) {
      console.error('❌ [RoleRouter] Erreur lors de la récupération du rôle:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération du rôle',
          code: 'ROLE_FETCH_ERROR'
        }
      });
    }
  });

  // POST /roles - Créer un nouveau rôle
  router.post('/', async (req, res) => {
    try {
      const { nom, displayName, isAdmin, privileges } = req.body;

      console.log('➕ [RoleRouter] Création d\'un nouveau rôle:', { nom, displayName, isAdmin });
      console.log('🔍 [RoleRouter] Privilèges reçus:', privileges);
      console.log('🔍 [RoleRouter] Type des privilèges:', typeof privileges);
      console.log('🔍 [RoleRouter] Body complet:', JSON.stringify(req.body, null, 2));

      // Validation des données
      if (!nom || !displayName) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Le nom et le nom d\'affichage sont requis',
            code: 'MISSING_REQUIRED_FIELDS'
          }
        });
      }

      // Vérifier si le nom existe déjà
      const existingRole = await prisma.userRole.findUnique({
        where: { nom: nom }
      });

      if (existingRole) {
        return res.status(409).json({
          success: false,
          error: {
            message: 'Un rôle avec ce nom existe déjà',
            code: 'ROLE_NAME_EXISTS'
          }
        });
      }

      // Préparer les privilèges pour la base de données
      let privilegesString = null;
      if (privileges) {
        if (typeof privileges === 'string') {
          // Les privilèges sont déjà une chaîne JSON (venant de Flutter)
          privilegesString = privileges;
          console.log('📝 [RoleRouter] Privilèges déjà en string, utilisation directe');
        } else if (typeof privileges === 'object') {
          // Les privilèges sont un objet, on les encode
          privilegesString = JSON.stringify(privileges);
          console.log('📝 [RoleRouter] Privilèges objet, encodage JSON');
        }
      }

      console.log('💾 [RoleRouter] Privilèges à sauvegarder:', privilegesString);

      // Créer le rôle
      const newRole = await prisma.userRole.create({
        data: {
          nom,
          displayName,
          isAdmin: isAdmin || false,
          privileges: privilegesString
        }
      });

      console.log(`✅ [RoleRouter] Rôle créé: ${newRole.displayName} (ID: ${newRole.id})`);
      console.log('💾 [RoleRouter] Privilèges sauvegardés:', newRole.privileges);

      res.status(201).json({
        success: true,
        data: newRole
      });
    } catch (error) {
      console.error('❌ [RoleRouter] Erreur lors de la création du rôle:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la création du rôle',
          code: 'ROLE_CREATE_ERROR'
        }
      });
    }
  });

  // PUT /roles/:id - Mettre à jour un rôle
  router.put('/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const { nom, displayName, isAdmin, privileges } = req.body;

      if (isNaN(id)) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'ID de rôle invalide',
            code: 'INVALID_ROLE_ID'
          }
        });
      }

      console.log(`📝 [RoleRouter] Mise à jour du rôle ID: ${id}`);

      // Vérifier si le rôle existe
      const existingRole = await prisma.userRole.findUnique({
        where: { id: id }
      });

      if (!existingRole) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Rôle non trouvé',
            code: 'ROLE_NOT_FOUND'
          }
        });
      }

      // Vérifier si le nouveau nom existe déjà (sauf pour le rôle actuel)
      if (nom && nom !== existingRole.nom) {
        const nameExists = await prisma.userRole.findUnique({
          where: { nom: nom }
        });

        if (nameExists) {
          return res.status(409).json({
            success: false,
            error: {
              message: 'Un rôle avec ce nom existe déjà',
              code: 'ROLE_NAME_EXISTS'
            }
          });
        }
      }

      // Mettre à jour le rôle
      const updatedRole = await prisma.userRole.update({
        where: { id: id },
        data: {
          ...(nom && { nom }),
          ...(displayName && { displayName }),
          ...(isAdmin !== undefined && { isAdmin }),
          ...(privileges && { privileges: JSON.stringify(privileges) })
        }
      });

      console.log(`✅ [RoleRouter] Rôle mis à jour: ${updatedRole.displayName}`);

      res.json({
        success: true,
        data: updatedRole
      });
    } catch (error) {
      console.error('❌ [RoleRouter] Erreur lors de la mise à jour du rôle:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la mise à jour du rôle',
          code: 'ROLE_UPDATE_ERROR'
        }
      });
    }
  });

  // DELETE /roles/:id - Supprimer un rôle
  router.delete('/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);

      if (isNaN(id)) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'ID de rôle invalide',
            code: 'INVALID_ROLE_ID'
          }
        });
      }

      console.log(`🗑️ [RoleRouter] Suppression du rôle ID: ${id}`);

      // Vérifier si le rôle existe
      const existingRole = await prisma.userRole.findUnique({
        where: { id: id }
      });

      if (!existingRole) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Rôle non trouvé',
            code: 'ROLE_NOT_FOUND'
          }
        });
      }

      // Vérifier si des utilisateurs utilisent ce rôle
      const usersWithRole = await prisma.utilisateur.findMany({
        where: { roleId: id }
      });

      if (usersWithRole.length > 0) {
        return res.status(409).json({
          success: false,
          error: {
            message: `Impossible de supprimer ce rôle car ${usersWithRole.length} utilisateur(s) l'utilisent`,
            code: 'ROLE_IN_USE'
          }
        });
      }

      // Supprimer le rôle
      await prisma.userRole.delete({
        where: { id: id }
      });

      console.log(`✅ [RoleRouter] Rôle supprimé: ${existingRole.displayName}`);

      res.json({
        success: true,
        message: 'Rôle supprimé avec succès'
      });
    } catch (error) {
      console.error('❌ [RoleRouter] Erreur lors de la suppression du rôle:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la suppression du rôle',
          code: 'ROLE_DELETE_ERROR'
        }
      });
    }
  });

  return router;
}

module.exports = { createRoleRouter };