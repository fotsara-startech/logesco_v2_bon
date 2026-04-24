const express = require('express');
const { PrismaClient } = require('../config/prisma-client.js');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

/**
 * Crée le routeur pour la gestion des utilisateurs
 * @param {Object} dependencies - Les dépendances injectées
 * @returns {Router}
 */
function createUserRouter(dependencies) {
  const router = express.Router();
  const { authService } = dependencies;

  // GET /users - Récupérer tous les utilisateurs depuis la base de données
  router.get('/', async (req, res) => {
    try {
      console.log('🔍 [UserRouter] Récupération des utilisateurs depuis la base de données...');
      
      const users = await prisma.utilisateur.findMany({
        include: {
          role: true // Inclure les informations du rôle
        },
        orderBy: { id: 'asc' }
      });

      console.log(`✅ [UserRouter] ${users.length} utilisateurs trouvés`);
      
      // Transformer les données pour correspondre au format attendu par Flutter
      const transformedUsers = users.map(user => ({
        id: user.id,
        nomUtilisateur: user.nomUtilisateur,
        email: user.email,
        role: user.role ? {
          id: user.role.id,
          nom: user.role.nom,
          displayName: user.role.displayName,
          isAdmin: user.role.isAdmin,
          privileges: user.role.privileges ? JSON.parse(user.role.privileges) : {}
        } : null,
        isActive: user.isActive,
        dateCreation: user.dateCreation.toISOString(),
        dateModification: user.dateModification.toISOString(),
        dateDerniereConnexion: user.dateDerniereConnexion?.toISOString() || null
      }));
      
      res.json({
        success: true,
        data: transformedUsers
      });
    } catch (error) {
      console.error('❌ [UserRouter] Erreur lors de la récupération des utilisateurs:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération des utilisateurs',
          code: 'USERS_FETCH_ERROR'
        }
      });
    }
  });

  // GET /users/:id - Récupérer un utilisateur par ID depuis la base de données
  router.get('/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      
      if (isNaN(id)) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'ID d\'utilisateur invalide',
            code: 'INVALID_USER_ID'
          }
        });
      }

      console.log(`🔍 [UserRouter] Récupération de l'utilisateur ID: ${id}`);
      
      const user = await prisma.utilisateur.findUnique({
        where: { id: id },
        include: {
          role: true
        }
      });
      
      if (!user) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Utilisateur non trouvé',
            code: 'USER_NOT_FOUND'
          }
        });
      }
      
      console.log(`✅ [UserRouter] Utilisateur trouvé: ${user.nomUtilisateur}`);
      
      // Transformer les données
      const transformedUser = {
        id: user.id,
        nomUtilisateur: user.nomUtilisateur,
        email: user.email,
        role: user.role ? {
          id: user.role.id,
          nom: user.role.nom,
          displayName: user.role.displayName,
          isAdmin: user.role.isAdmin,
          privileges: user.role.privileges ? JSON.parse(user.role.privileges) : {}
        } : null,
        isActive: user.isActive,
        dateCreation: user.dateCreation.toISOString(),
        dateModification: user.dateModification.toISOString(),
        dateDerniereConnexion: user.dateDerniereConnexion?.toISOString() || null
      };
      
      res.json({
        success: true,
        data: transformedUser
      });
    } catch (error) {
      console.error('❌ [UserRouter] Erreur lors de la récupération de l\'utilisateur:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la récupération de l\'utilisateur',
          code: 'USER_FETCH_ERROR'
        }
      });
    }
  });

  // POST /users - Créer un nouvel utilisateur dans la base de données
  router.post('/', async (req, res) => {
    try {
      const { nomUtilisateur, email, motDePasse, role, isActive = true } = req.body;

      console.log('➕ [UserRouter] Création d\'un nouvel utilisateur:', { nomUtilisateur, email, roleId: role?.id });
      
      // Validation des données (email optionnel)
      if (!nomUtilisateur || !motDePasse || !role) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Données manquantes (nomUtilisateur, motDePasse, role requis)',
            code: 'MISSING_DATA'
          }
        });
      }
      
      // Vérifier si l'utilisateur existe déjà
      const whereConditions = [{ nomUtilisateur: nomUtilisateur }];
      if (email && email.trim() !== '') {
        whereConditions.push({ email: email });
      }
      
      const existingUser = await prisma.utilisateur.findFirst({
        where: {
          OR: whereConditions
        }
      });
      
      if (existingUser) {
        return res.status(409).json({
          success: false,
          error: {
            message: 'Un utilisateur avec ce nom ou cet email existe déjà',
            code: 'USER_EXISTS'
          }
        });
      }

      // Vérifier que le rôle existe
      const roleExists = await prisma.userRole.findUnique({
        where: { id: role.id }
      });

      if (!roleExists) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Le rôle spécifié n\'existe pas',
            code: 'ROLE_NOT_FOUND'
          }
        });
      }

      // Hasher le mot de passe
      const hashedPassword = await bcrypt.hash(motDePasse, 10);
      
      // Créer l'utilisateur
      const userData = {
        nomUtilisateur,
        motDePasseHash: hashedPassword,
        roleId: role.id,
        isActive
      };
      
      // N'ajouter l'email que s'il est fourni et non vide
      if (email && email.trim() !== '') {
        userData.email = email.trim();
      }
      
      const newUser = await prisma.utilisateur.create({
        data: userData,
        include: {
          role: true
        }
      });

      console.log(`✅ [UserRouter] Utilisateur créé: ${newUser.nomUtilisateur} (ID: ${newUser.id})`);

      // Transformer les données pour la réponse
      const transformedUser = {
        id: newUser.id,
        nomUtilisateur: newUser.nomUtilisateur,
        email: newUser.email,
        role: {
          id: newUser.role.id,
          nom: newUser.role.nom,
          displayName: newUser.role.displayName,
          isAdmin: newUser.role.isAdmin,
          privileges: newUser.role.privileges ? JSON.parse(newUser.role.privileges) : {}
        },
        isActive: newUser.isActive,
        dateCreation: newUser.dateCreation.toISOString(),
        dateModification: newUser.dateModification.toISOString(),
        dateDerniereConnexion: newUser.dateDerniereConnexion?.toISOString() || null
      };
      
      res.status(201).json({
        success: true,
        data: transformedUser
      });
    } catch (error) {
      console.error('❌ [UserRouter] Erreur lors de la création de l\'utilisateur:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la création de l\'utilisateur',
          code: 'USER_CREATE_ERROR'
        }
      });
    }
  });

  // PUT /users/:id - Mettre à jour un utilisateur dans la base de données
  router.put('/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const { nomUtilisateur, email, role, isActive, motDePasse } = req.body;

      if (isNaN(id)) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'ID d\'utilisateur invalide',
            code: 'INVALID_USER_ID'
          }
        });
      }

      console.log(`📝 [UserRouter] Mise à jour de l'utilisateur ID: ${id}`);
      
      // Vérifier si l'utilisateur existe
      const existingUser = await prisma.utilisateur.findUnique({
        where: { id: id },
        include: { role: true }
      });
      
      if (!existingUser) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Utilisateur non trouvé',
            code: 'USER_NOT_FOUND'
          }
        });
      }
      
      // Vérifier les conflits de nom/email (sauf pour l'utilisateur actuel)
      if (nomUtilisateur || (email && email.trim() !== '')) {
        const conflictConditions = [];
        if (nomUtilisateur) conflictConditions.push({ nomUtilisateur: nomUtilisateur });
        if (email && email.trim() !== '') conflictConditions.push({ email: email.trim() });
        
        if (conflictConditions.length > 0) {
          const conflictUser = await prisma.utilisateur.findFirst({
            where: {
              AND: [
                { id: { not: id } },
                { OR: conflictConditions }
              ]
            }
          });
          
          if (conflictUser) {
            return res.status(409).json({
              success: false,
              error: {
                message: 'Un autre utilisateur avec ce nom ou cet email existe déjà',
                code: 'USER_EXISTS'
              }
            });
          }
        }
      }

      // Vérifier que le nouveau rôle existe (si fourni)
      if (role && role.id) {
        const roleExists = await prisma.userRole.findUnique({
          where: { id: role.id }
        });

        if (!roleExists) {
          return res.status(400).json({
            success: false,
            error: {
              message: 'Le rôle spécifié n\'existe pas',
              code: 'ROLE_NOT_FOUND'
            }
          });
        }
      }

      // Préparer les données de mise à jour
      const updateData = {};
      if (nomUtilisateur) updateData.nomUtilisateur = nomUtilisateur;
      if (email !== undefined) {
        // Si email est fourni et non vide, l'utiliser, sinon le mettre à null
        updateData.email = (email && email.trim() !== '') ? email.trim() : null;
      }
      if (role && role.id) updateData.roleId = role.id;
      if (isActive !== undefined) updateData.isActive = isActive;
      if (motDePasse) {
        updateData.motDePasseHash = await bcrypt.hash(motDePasse, 10);
      }
      
      // Mettre à jour l'utilisateur
      const updatedUser = await prisma.utilisateur.update({
        where: { id: id },
        data: updateData,
        include: { role: true }
      });

      console.log(`✅ [UserRouter] Utilisateur mis à jour: ${updatedUser.nomUtilisateur}`);

      // Transformer les données pour la réponse
      const transformedUser = {
        id: updatedUser.id,
        nomUtilisateur: updatedUser.nomUtilisateur,
        email: updatedUser.email,
        role: {
          id: updatedUser.role.id,
          nom: updatedUser.role.nom,
          displayName: updatedUser.role.displayName,
          isAdmin: updatedUser.role.isAdmin,
          privileges: updatedUser.role.privileges ? JSON.parse(updatedUser.role.privileges) : {}
        },
        isActive: updatedUser.isActive,
        dateCreation: updatedUser.dateCreation.toISOString(),
        dateModification: updatedUser.dateModification.toISOString(),
        dateDerniereConnexion: updatedUser.dateDerniereConnexion?.toISOString() || null
      };
      
      res.json({
        success: true,
        data: transformedUser
      });
    } catch (error) {
      console.error('❌ [UserRouter] Erreur lors de la mise à jour de l\'utilisateur:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la mise à jour de l\'utilisateur',
          code: 'USER_UPDATE_ERROR'
        }
      });
    }
  });

  // DELETE /users/:id - Supprimer un utilisateur de la base de données
  router.delete('/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);

      if (isNaN(id)) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'ID d\'utilisateur invalide',
            code: 'INVALID_USER_ID'
          }
        });
      }

      console.log(`🗑️ [UserRouter] Suppression de l'utilisateur ID: ${id}`);
      
      // Vérifier si l'utilisateur existe
      const existingUser = await prisma.utilisateur.findUnique({
        where: { id: id },
        include: { role: true }
      });
      
      if (!existingUser) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Utilisateur non trouvé',
            code: 'USER_NOT_FOUND'
          }
        });
      }
      
      // Empêcher la suppression de l'admin principal (celui créé automatiquement)
      if (existingUser.role && existingUser.role.nom === 'admin' && existingUser.nomUtilisateur === 'admin') {
        return res.status(403).json({
          success: false,
          error: {
            message: 'Impossible de supprimer l\'administrateur principal',
            code: 'ADMIN_DELETE_FORBIDDEN'
          }
        });
      }
      
      // Supprimer l'utilisateur
      await prisma.utilisateur.delete({
        where: { id: id }
      });

      console.log(`✅ [UserRouter] Utilisateur supprimé: ${existingUser.nomUtilisateur}`);
      
      res.json({
        success: true,
        message: 'Utilisateur supprimé avec succès'
      });
    } catch (error) {
      console.error('❌ [UserRouter] Erreur lors de la suppression de l\'utilisateur:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la suppression de l\'utilisateur',
          code: 'USER_DELETE_ERROR'
        }
      });
    }
  });

  // PUT /users/:id/status - Activer/Désactiver un utilisateur dans la base de données
  router.put('/:id/status', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const { isActive } = req.body;

      if (isNaN(id)) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'ID d\'utilisateur invalide',
            code: 'INVALID_USER_ID'
          }
        });
      }
      
      if (isActive === undefined) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Le statut isActive est requis',
            code: 'MISSING_STATUS'
          }
        });
      }

      console.log(`🔄 [UserRouter] Modification du statut de l'utilisateur ID: ${id} -> ${isActive}`);
      
      // Vérifier si l'utilisateur existe
      const existingUser = await prisma.utilisateur.findUnique({
        where: { id: id },
        include: { role: true }
      });
      
      if (!existingUser) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Utilisateur non trouvé',
            code: 'USER_NOT_FOUND'
          }
        });
      }
      
      // Mettre à jour le statut
      const updatedUser = await prisma.utilisateur.update({
        where: { id: id },
        data: { isActive: isActive },
        include: { role: true }
      });

      console.log(`✅ [UserRouter] Statut mis à jour: ${updatedUser.nomUtilisateur} -> ${isActive ? 'Actif' : 'Inactif'}`);

      // Transformer les données pour la réponse
      const transformedUser = {
        id: updatedUser.id,
        nomUtilisateur: updatedUser.nomUtilisateur,
        email: updatedUser.email,
        role: {
          id: updatedUser.role.id,
          nom: updatedUser.role.nom,
          displayName: updatedUser.role.displayName,
          isAdmin: updatedUser.role.isAdmin,
          privileges: updatedUser.role.privileges ? JSON.parse(updatedUser.role.privileges) : {}
        },
        isActive: updatedUser.isActive,
        dateCreation: updatedUser.dateCreation.toISOString(),
        dateModification: updatedUser.dateModification.toISOString(),
        dateDerniereConnexion: updatedUser.dateDerniereConnexion?.toISOString() || null
      };
      
      res.json({
        success: true,
        data: transformedUser
      });
    } catch (error) {
      console.error('❌ [UserRouter] Erreur lors de la modification du statut:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors de la modification du statut',
          code: 'STATUS_UPDATE_ERROR'
        }
      });
    }
  });

  // PUT /users/:id/password - Changer le mot de passe dans la base de données
  router.put('/:id/password', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const { motDePasse } = req.body;

      if (isNaN(id)) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'ID d\'utilisateur invalide',
            code: 'INVALID_USER_ID'
          }
        });
      }
      
      if (!motDePasse) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Le nouveau mot de passe est requis',
            code: 'MISSING_PASSWORD'
          }
        });
      }

      console.log(`🔐 [UserRouter] Changement de mot de passe pour l'utilisateur ID: ${id}`);
      
      // Vérifier si l'utilisateur existe
      const existingUser = await prisma.utilisateur.findUnique({
        where: { id: id }
      });
      
      if (!existingUser) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Utilisateur non trouvé',
            code: 'USER_NOT_FOUND'
          }
        });
      }
      
      // Hasher le nouveau mot de passe
      const hashedPassword = await bcrypt.hash(motDePasse, 10);
      
      // Mettre à jour le mot de passe
      await prisma.utilisateur.update({
        where: { id: id },
        data: { motDePasseHash: hashedPassword }
      });

      console.log(`✅ [UserRouter] Mot de passe mis à jour pour: ${existingUser.nomUtilisateur}`);
      
      res.json({
        success: true,
        message: 'Mot de passe modifié avec succès'
      });
    } catch (error) {
      console.error('❌ [UserRouter] Erreur lors du changement de mot de passe:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur lors du changement de mot de passe',
          code: 'PASSWORD_UPDATE_ERROR'
        }
      });
    }
  });

  // GET /users/:id/boutiques — boutiques assignées à un utilisateur
  router.get('/:id/boutiques', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const assignments = await prisma.userBoutiqueAssignment.findMany({
        where: { utilisateurId: id, isActive: true },
        include: { boutique: true },
        orderBy: { boutique: { nom: 'asc' } }
      });
      res.json({
        success: true,
        data: assignments.map(a => ({
          boutiqueId: a.boutiqueId,
          nom: a.boutique.nom,
          adresse: a.boutique.adresse,
          estPrincipale: a.boutique.estPrincipale,
          isActive: a.boutique.isActive
        }))
      });
    } catch (error) {
      res.status(500).json({ success: false, error: { message: error.message, code: 'USER_BOUTIQUES_FETCH_ERROR' } });
    }
  });

  // PUT /users/:id/boutiques — remplacer toutes les assignations boutiques d'un utilisateur
  router.put('/:id/boutiques', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const { boutiqueIds } = req.body;

      if (!Array.isArray(boutiqueIds)) {
        return res.status(400).json({ success: false, error: { message: 'boutiqueIds doit être un tableau', code: 'VALIDATION_ERROR' } });
      }

      // Désactiver toutes les assignations existantes
      await prisma.userBoutiqueAssignment.updateMany({
        where: { utilisateurId: id },
        data: { isActive: false }
      });

      // Créer ou réactiver les nouvelles assignations
      for (const boutiqueId of boutiqueIds) {
        await prisma.userBoutiqueAssignment.upsert({
          where: { utilisateurId_boutiqueId: { utilisateurId: id, boutiqueId: parseInt(boutiqueId) } },
          update: { isActive: true },
          create: { utilisateurId: id, boutiqueId: parseInt(boutiqueId), isActive: true }
        });
      }

      res.json({ success: true, message: 'Assignations mises à jour avec succès' });
    } catch (error) {
      res.status(500).json({ success: false, error: { message: error.message, code: 'USER_BOUTIQUES_UPDATE_ERROR' } });
    }
  });

  return router;
}

module.exports = { createUserRouter };