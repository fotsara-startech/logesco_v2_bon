const express = require('express');

/**
 * Créer le routeur pour la gestion des caisses
 * @param {Object} dependencies - Dépendances injectées
 * @returns {Router}
 */
function createCashRegistersRouter({ prisma, authService }) {
  const router = express.Router();

  // GET /api/v1/cash-registers - Récupérer toutes les caisses
  router.get('/', async (req, res) => {
    try {
      const cashRegisters = await prisma.cashRegister.findMany({
        include: {
          utilisateur: true
        },
        orderBy: {
          dateCreation: 'desc'
        }
      });
      
      const formattedCashRegisters = cashRegisters.map(cashRegister => ({
        id: cashRegister.id,
        nom: cashRegister.nom,
        description: cashRegister.description,
        soldeInitial: parseFloat(cashRegister.soldeInitial),
        soldeActuel: parseFloat(cashRegister.soldeActuel),
        isActive: Boolean(cashRegister.isActive),
        utilisateurId: cashRegister.utilisateurId,
        nomUtilisateur: cashRegister.utilisateur?.nomUtilisateur,
        dateCreation: cashRegister.dateCreation,
        dateModification: cashRegister.dateModification,
        dateOuverture: cashRegister.dateOuverture,
        dateFermeture: cashRegister.dateFermeture
      }));
      
      res.json({
        success: true,
        data: formattedCashRegisters
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des caisses:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'CASH_REGISTERS_FETCH_ERROR'
        }
      });
    }
  });

  // POST /api/v1/cash-registers - Créer une nouvelle caisse
  router.post('/', async (req, res) => {
    try {
      const { nom, description, soldeInitial = 0, isActive = true } = req.body;
      
      // Validation
      if (!nom) {
        return res.status(400).json({ 
          success: false,
          error: {
            message: 'Le nom de la caisse est requis',
            code: 'VALIDATION_ERROR'
          }
        });
      }
      
      // Vérifier si le nom existe déjà
      const existingCashRegister = await prisma.cashRegister.findFirst({
        where: { nom }
      });
      
      if (existingCashRegister) {
        return res.status(400).json({ 
          success: false,
          error: {
            message: 'Une caisse avec ce nom existe déjà',
            code: 'DUPLICATE_NAME'
          }
        });
      }
      
      const newCashRegister = await prisma.cashRegister.create({
        data: {
          nom,
          description: description || '',
          soldeInitial: parseFloat(soldeInitial),
          soldeActuel: parseFloat(soldeInitial),
          isActive
        },
        include: {
          utilisateur: true
        }
      });
      
      const formattedCashRegister = {
        id: newCashRegister.id,
        nom: newCashRegister.nom,
        description: newCashRegister.description,
        soldeInitial: parseFloat(newCashRegister.soldeInitial),
        soldeActuel: parseFloat(newCashRegister.soldeActuel),
        isActive: Boolean(newCashRegister.isActive),
        utilisateurId: newCashRegister.utilisateurId,
        nomUtilisateur: newCashRegister.utilisateur?.nomUtilisateur,
        dateCreation: newCashRegister.dateCreation,
        dateModification: newCashRegister.dateModification,
        dateOuverture: newCashRegister.dateOuverture,
        dateFermeture: newCashRegister.dateFermeture
      };
      
      res.status(201).json({
        success: true,
        data: formattedCashRegister
      });
    } catch (error) {
      console.error('Erreur lors de la création de la caisse:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'CASH_REGISTER_CREATE_ERROR'
        }
      });
    }
  });

  // PUT /api/v1/cash-registers/:id - Mettre à jour une caisse
  router.put('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const { nom, description, isActive } = req.body;
      
      // Vérifier si la caisse existe
      const existingCashRegister = await prisma.cashRegister.findUnique({
        where: { id: parseInt(id) }
      });
      
      if (!existingCashRegister) {
        return res.status(404).json({ 
          success: false,
          error: {
            message: 'Caisse non trouvée',
            code: 'CASH_REGISTER_NOT_FOUND'
          }
        });
      }
      
      // Vérifier les doublons de nom (sauf pour la caisse actuelle)
      if (nom !== existingCashRegister.nom) {
        const duplicateName = await prisma.cashRegister.findFirst({
          where: { 
            nom,
            id: { not: parseInt(id) }
          }
        });
        
        if (duplicateName) {
          return res.status(400).json({ 
            success: false,
            error: {
              message: 'Une caisse avec ce nom existe déjà',
              code: 'DUPLICATE_NAME'
            }
          });
        }
      }
      
      const updatedCashRegister = await prisma.cashRegister.update({
        where: { id: parseInt(id) },
        data: {
          nom,
          description: description || '',
          isActive
        },
        include: {
          utilisateur: true
        }
      });
      
      const formattedCashRegister = {
        id: updatedCashRegister.id,
        nom: updatedCashRegister.nom,
        description: updatedCashRegister.description,
        soldeInitial: parseFloat(updatedCashRegister.soldeInitial),
        soldeActuel: parseFloat(updatedCashRegister.soldeActuel),
        isActive: Boolean(updatedCashRegister.isActive),
        utilisateurId: updatedCashRegister.utilisateurId,
        nomUtilisateur: updatedCashRegister.utilisateur?.nomUtilisateur,
        dateCreation: updatedCashRegister.dateCreation,
        dateModification: updatedCashRegister.dateModification,
        dateOuverture: updatedCashRegister.dateOuverture,
        dateFermeture: updatedCashRegister.dateFermeture
      };
      
      res.json({
        success: true,
        data: formattedCashRegister
      });
    } catch (error) {
      console.error('Erreur lors de la mise à jour de la caisse:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'CASH_REGISTER_UPDATE_ERROR'
        }
      });
    }
  });

  // DELETE /api/v1/cash-registers/:id - Supprimer une caisse
  router.delete('/:id', async (req, res) => {
    try {
      const { id } = req.params;
      
      // Vérifier si la caisse existe
      const cashRegister = await prisma.cashRegister.findUnique({
        where: { id: parseInt(id) }
      });
      
      if (!cashRegister) {
        return res.status(404).json({ 
          success: false,
          error: {
            message: 'Caisse non trouvée',
            code: 'CASH_REGISTER_NOT_FOUND'
          }
        });
      }
      
      // Vérifier si la caisse est ouverte
      if (cashRegister.dateOuverture && !cashRegister.dateFermeture) {
        return res.status(400).json({ 
          success: false,
          error: {
            message: 'Impossible de supprimer une caisse ouverte',
            code: 'CASH_REGISTER_OPEN'
          }
        });
      }
      
      await prisma.cashRegister.delete({
        where: { id: parseInt(id) }
      });
      
      res.status(204).send();
    } catch (error) {
      console.error('Erreur lors de la suppression de la caisse:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'CASH_REGISTER_DELETE_ERROR'
        }
      });
    }
  });

  // PATCH /api/v1/cash-registers/:id/status - Ouvrir/Fermer une caisse
  router.patch('/:id/status', async (req, res) => {
    try {
      const { id } = req.params;
      const { action, soldeInitial } = req.body;
      
      // Vérifier si la caisse existe
      const cashRegister = await prisma.cashRegister.findUnique({
        where: { id: parseInt(id) }
      });
      
      if (!cashRegister) {
        return res.status(404).json({ 
          success: false,
          error: {
            message: 'Caisse non trouvée',
            code: 'CASH_REGISTER_NOT_FOUND'
          }
        });
      }
      
      let updateData = {};
      let movementType = '';
      let movementAmount = 0;
      
      if (action === 'open') {
        if (cashRegister.dateOuverture && !cashRegister.dateFermeture) {
          return res.status(400).json({ 
            success: false,
            error: {
              message: 'La caisse est déjà ouverte',
              code: 'CASH_REGISTER_ALREADY_OPEN'
            }
          });
        }
        
        updateData = {
          dateOuverture: new Date(),
          dateFermeture: null,
          soldeActuel: parseFloat(soldeInitial || cashRegister.soldeInitial)
        };
        movementType = 'ouverture';
        movementAmount = parseFloat(soldeInitial || cashRegister.soldeInitial);
        
      } else if (action === 'close') {
        if (!cashRegister.dateOuverture || cashRegister.dateFermeture) {
          return res.status(400).json({ 
            success: false,
            error: {
              message: 'La caisse n\'est pas ouverte',
              code: 'CASH_REGISTER_NOT_OPEN'
            }
          });
        }
        
        updateData = {
          dateFermeture: new Date()
        };
        movementType = 'fermeture';
        movementAmount = parseFloat(cashRegister.soldeActuel);
      }
      
      // Mettre à jour la caisse
      const updatedCashRegister = await prisma.cashRegister.update({
        where: { id: parseInt(id) },
        data: updateData,
        include: {
          utilisateur: true
        }
      });
      
      // Créer un mouvement de caisse
      await prisma.cashMovement.create({
        data: {
          caisseId: parseInt(id),
          type: movementType,
          montant: movementAmount,
          description: `${action === 'open' ? 'Ouverture' : 'Fermeture'} de caisse`,
          utilisateurId: 1 // TODO: Récupérer l'utilisateur connecté
        }
      });
      
      const formattedCashRegister = {
        id: updatedCashRegister.id,
        nom: updatedCashRegister.nom,
        description: updatedCashRegister.description,
        soldeInitial: parseFloat(updatedCashRegister.soldeInitial),
        soldeActuel: parseFloat(updatedCashRegister.soldeActuel),
        isActive: Boolean(updatedCashRegister.isActive),
        utilisateurId: updatedCashRegister.utilisateurId,
        nomUtilisateur: updatedCashRegister.utilisateur?.nomUtilisateur,
        dateCreation: updatedCashRegister.dateCreation,
        dateModification: updatedCashRegister.dateModification,
        dateOuverture: updatedCashRegister.dateOuverture,
        dateFermeture: updatedCashRegister.dateFermeture
      };
      
      res.json({
        success: true,
        data: formattedCashRegister
      });
    } catch (error) {
      console.error('Erreur lors de la modification du statut de la caisse:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'CASH_REGISTER_STATUS_ERROR'
        }
      });
    }
  });

  // GET /api/v1/cash-registers/:id/movements - Récupérer les mouvements d'une caisse
  router.get('/:id/movements', async (req, res) => {
    try {
      const { id } = req.params;
      
      const movements = await prisma.cashMovement.findMany({
        where: { caisseId: parseInt(id) },
        include: {
          utilisateur: true
        },
        orderBy: {
          dateCreation: 'desc'
        }
      });
      
      const formattedMovements = movements.map(movement => ({
        id: movement.id,
        caisseId: movement.caisseId,
        type: movement.type,
        montant: parseFloat(movement.montant),
        description: movement.description,
        dateCreation: movement.dateCreation,
        utilisateurId: movement.utilisateurId,
        nomUtilisateur: movement.utilisateur?.nomUtilisateur,
        metadata: movement.metadata ? JSON.parse(movement.metadata) : null
      }));
      
      res.json({
        success: true,
        data: formattedMovements
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des mouvements:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'CASH_MOVEMENTS_FETCH_ERROR'
        }
      });
    }
  });

  // POST /api/v1/cash-registers/:id/movements - Ajouter un mouvement de caisse
  router.post('/:id/movements', async (req, res) => {
    try {
      const { id } = req.params;
      const { type, montant, description } = req.body;
      
      // Validation
      if (!type || montant === undefined) {
        return res.status(400).json({ 
          success: false,
          error: {
            message: 'Le type et le montant sont requis',
            code: 'VALIDATION_ERROR'
          }
        });
      }
      
      // Vérifier si la caisse existe et est ouverte
      const cashRegister = await prisma.cashRegister.findUnique({
        where: { id: parseInt(id) }
      });
      
      if (!cashRegister) {
        return res.status(404).json({ 
          success: false,
          error: {
            message: 'Caisse non trouvée',
            code: 'CASH_REGISTER_NOT_FOUND'
          }
        });
      }
      
      if (!cashRegister.dateOuverture || cashRegister.dateFermeture) {
        return res.status(400).json({ 
          success: false,
          error: {
            message: 'La caisse doit être ouverte pour ajouter un mouvement',
            code: 'CASH_REGISTER_NOT_OPEN'
          }
        });
      }
      
      // Créer le mouvement
      const movement = await prisma.cashMovement.create({
        data: {
          caisseId: parseInt(id),
          type,
          montant: parseFloat(montant),
          description: description || '',
          utilisateurId: 1 // TODO: Récupérer l'utilisateur connecté
        },
        include: {
          utilisateur: true
        }
      });
      
      // Mettre à jour le solde de la caisse
      const newBalance = type === 'entree' 
        ? parseFloat(cashRegister.soldeActuel) + parseFloat(montant)
        : parseFloat(cashRegister.soldeActuel) - parseFloat(montant);
      
      await prisma.cashRegister.update({
        where: { id: parseInt(id) },
        data: { soldeActuel: newBalance }
      });
      
      const formattedMovement = {
        id: movement.id,
        caisseId: movement.caisseId,
        type: movement.type,
        montant: parseFloat(movement.montant),
        description: movement.description,
        dateCreation: movement.dateCreation,
        utilisateurId: movement.utilisateurId,
        nomUtilisateur: movement.utilisateur?.nomUtilisateur,
        metadata: movement.metadata ? JSON.parse(movement.metadata) : null
      };
      
      res.status(201).json({
        success: true,
        data: formattedMovement
      });
    } catch (error) {
      console.error('Erreur lors de l\'ajout du mouvement:', error);
      res.status(500).json({ 
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'CASH_MOVEMENT_CREATE_ERROR'
        }
      });
    }
  });

  return router;
}

module.exports = { createCashRegistersRouter };