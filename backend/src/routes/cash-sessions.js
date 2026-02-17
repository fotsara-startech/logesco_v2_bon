const express = require('express');

/**
 * Créer le routeur pour la gestion des sessions de caisse
 * @param {Object} dependencies - Dépendances injectées
 * @returns {Router}
 */
function createCashSessionsRouter({ prisma, authService }) {
  const router = express.Router();

  // GET /api/v1/cash-sessions/active - Récupérer la session active de l'utilisateur
  router.get('/active', async (req, res) => {
    try {
      // TODO: Récupérer l'utilisateur connecté depuis le token
      const userId = 1; // Temporaire
      
      const activeSession = await prisma.cashSession.findFirst({
        where: {
          utilisateurId: userId,
          isActive: true,
          dateFermeture: null
        },
        include: {
          caisse: true,
          utilisateur: true
        }
      });
      
      if (!activeSession) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Aucune session active trouvée',
            code: 'NO_ACTIVE_SESSION'
          }
        });
      }
      
      const formattedSession = {
        id: activeSession.id,
        caisseId: activeSession.caisseId,
        nomCaisse: activeSession.caisse.nom,
        utilisateurId: activeSession.utilisateurId,
        nomUtilisateur: activeSession.utilisateur.nomUtilisateur,
        soldeOuverture: parseFloat(activeSession.soldeOuverture),
        soldeFermeture: activeSession.soldeFermeture ? parseFloat(activeSession.soldeFermeture) : null,
        soldeAttendu: activeSession.soldeAttendu ? parseFloat(activeSession.soldeAttendu) : null,
        ecart: activeSession.ecart ? parseFloat(activeSession.ecart) : null,
        dateOuverture: activeSession.dateOuverture,
        dateFermeture: activeSession.dateFermeture,
        isActive: Boolean(activeSession.isActive),
        metadata: activeSession.metadata ? JSON.parse(activeSession.metadata) : null
      };
      
      res.json({
        success: true,
        data: formattedSession
      });
    } catch (error) {
      console.error('Erreur lors de la récupération de la session active:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'ACTIVE_SESSION_FETCH_ERROR'
        }
      });
    }
  });

  // GET /api/v1/cash-sessions/available-cash-registers - Récupérer les caisses disponibles
  router.get('/available-cash-registers', async (req, res) => {
    try {
      // Récupérer les caisses actives qui ne sont pas utilisées par d'autres utilisateurs
      const availableCashRegisters = await prisma.cashRegister.findMany({
        where: {
          isActive: true,
          NOT: {
            sessions: {
              some: {
                isActive: true,
                dateFermeture: null
              }
            }
          }
        },
        orderBy: {
          nom: 'asc'
        }
      });
      
      const formattedCashRegisters = availableCashRegisters.map(cashRegister => ({
        id: cashRegister.id,
        nom: cashRegister.nom,
        description: cashRegister.description,
        soldeInitial: parseFloat(cashRegister.soldeInitial),
        soldeActuel: parseFloat(cashRegister.soldeActuel),
        isActive: Boolean(cashRegister.isActive),
        dateCreation: cashRegister.dateCreation,
        dateModification: cashRegister.dateModification
      }));
      
      res.json({
        success: true,
        data: formattedCashRegisters
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des caisses disponibles:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'AVAILABLE_CASH_REGISTERS_FETCH_ERROR'
        }
      });
    }
  });

  // POST /api/v1/cash-sessions/connect - Se connecter à une caisse
  router.post('/connect', async (req, res) => {
    try {
      const { cashRegisterId, soldeInitial } = req.body;
      // TODO: Récupérer l'utilisateur connecté depuis le token
      const userId = 1; // Temporaire
      
      // Validation
      if (!cashRegisterId || soldeInitial === undefined) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'L\'ID de la caisse et le solde initial sont requis',
            code: 'VALIDATION_ERROR'
          }
        });
      }
      
      // Vérifier si l'utilisateur a déjà une session active
      const existingSession = await prisma.cashSession.findFirst({
        where: {
          utilisateurId: userId,
          isActive: true,
          dateFermeture: null
        }
      });
      
      if (existingSession) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Vous avez déjà une session active',
            code: 'ACTIVE_SESSION_EXISTS'
          }
        });
      }
      
      // Vérifier si la caisse existe et est disponible
      const cashRegister = await prisma.cashRegister.findUnique({
        where: { id: parseInt(cashRegisterId) },
        include: {
          sessions: {
            where: {
              isActive: true,
              dateFermeture: null
            }
          }
        }
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
      
      if (!cashRegister.isActive) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Cette caisse n\'est pas active',
            code: 'CASH_REGISTER_INACTIVE'
          }
        });
      }
      
      if (cashRegister.sessions.length > 0) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Cette caisse est déjà utilisée par un autre utilisateur',
            code: 'CASH_REGISTER_IN_USE'
          }
        });
      }
      
      // Créer la session
      const newSession = await prisma.cashSession.create({
        data: {
          caisseId: parseInt(cashRegisterId),
          utilisateurId: userId,
          soldeOuverture: parseFloat(soldeInitial),
          soldeAttendu: parseFloat(soldeInitial), // Initialiser avec le solde d'ouverture
          dateOuverture: new Date(),
          isActive: true
        },
        include: {
          caisse: true,
          utilisateur: true
        }
      });
      
      // Mettre à jour la caisse (marquer comme ouverte)
      await prisma.cashRegister.update({
        where: { id: parseInt(cashRegisterId) },
        data: {
          dateOuverture: new Date(),
          dateFermeture: null,
          soldeActuel: parseFloat(soldeInitial),
          utilisateurId: userId
        }
      });
      
      // Créer un mouvement de caisse
      await prisma.cashMovement.create({
        data: {
          caisseId: parseInt(cashRegisterId),
          type: 'ouverture_session',
          montant: parseFloat(soldeInitial),
          description: 'Ouverture de session utilisateur',
          utilisateurId: userId,
          metadata: JSON.stringify({ sessionId: newSession.id })
        }
      });
      
      const formattedSession = {
        id: newSession.id,
        caisseId: newSession.caisseId,
        nomCaisse: newSession.caisse.nom,
        utilisateurId: newSession.utilisateurId,
        nomUtilisateur: newSession.utilisateur.nomUtilisateur,
        soldeOuverture: parseFloat(newSession.soldeOuverture),
        soldeFermeture: null,
        soldeAttendu: parseFloat(newSession.soldeOuverture), // Initialement égal au solde d'ouverture
        ecart: null,
        dateOuverture: newSession.dateOuverture,
        dateFermeture: null,
        isActive: Boolean(newSession.isActive),
        metadata: newSession.metadata ? JSON.parse(newSession.metadata) : null
      };
      
      res.status(201).json({
        success: true,
        data: formattedSession
      });
    } catch (error) {
      console.error('Erreur lors de la connexion à la caisse:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'CASH_SESSION_CONNECT_ERROR'
        }
      });
    }
  });

  // POST /api/v1/cash-sessions/disconnect - Se déconnecter de la caisse
  router.post('/disconnect', async (req, res) => {
    try {
      const { soldeFermeture } = req.body;
      // TODO: Récupérer l'utilisateur connecté depuis le token
      const userId = 1; // Temporaire
      
      // Validation
      if (soldeFermeture === undefined || soldeFermeture === null) {
        return res.status(400).json({
          success: false,
          error: {
            message: 'Le solde de fermeture est requis',
            code: 'VALIDATION_ERROR'
          }
        });
      }
      
      // Récupérer la session active
      const activeSession = await prisma.cashSession.findFirst({
        where: {
          utilisateurId: userId,
          isActive: true,
          dateFermeture: null
        },
        include: {
          caisse: true,
          utilisateur: true
        }
      });
      
      if (!activeSession) {
        return res.status(404).json({
          success: false,
          error: {
            message: 'Aucune session active trouvée',
            code: 'NO_ACTIVE_SESSION'
          }
        });
      }
      
      // CALCUL DU SOLDE ATTENDU ET DE L'ÉCART
      // Le solde attendu doit être calculé à partir du soldeAttendu actuel de la session
      // (qui est mis à jour à chaque vente et dépense)
      
      console.log('═══════════════════════════════════════════════════════════');
      console.log('🔍 DÉBUT CLÔTURE DE CAISSE - DEBUG DÉTAILLÉ');
      console.log('═══════════════════════════════════════════════════════════');
      console.log(`📌 Session ID: ${activeSession.id}`);
      console.log(`📌 Caisse: ${activeSession.caisse.nom}`);
      console.log(`📌 Utilisateur: ${activeSession.utilisateur.nomUtilisateur}`);
      console.log('');
      
      console.log('📊 VALEURS BRUTES DE LA SESSION:');
      console.log(`   activeSession.soldeOuverture = ${activeSession.soldeOuverture} (type: ${typeof activeSession.soldeOuverture})`);
      console.log(`   activeSession.soldeAttendu = ${activeSession.soldeAttendu} (type: ${typeof activeSession.soldeAttendu})`);
      console.log(`   activeSession.soldeFermeture = ${activeSession.soldeFermeture} (type: ${typeof activeSession.soldeFermeture})`);
      console.log(`   activeSession.ecart = ${activeSession.ecart} (type: ${typeof activeSession.ecart})`);
      console.log('');
      
      console.log('📊 VALEUR REÇUE DU CLIENT:');
      console.log(`   soldeFermeture (req.body) = ${soldeFermeture} (type: ${typeof soldeFermeture})`);
      console.log('');
      
      const soldeAttendu = activeSession.soldeAttendu ? parseFloat(activeSession.soldeAttendu) : parseFloat(activeSession.soldeOuverture);
      const soldeFermetureFloat = parseFloat(soldeFermeture);
      const ecart = soldeFermetureFloat - soldeAttendu;
      
      console.log('📊 CALCULS:');
      console.log(`   soldeAttendu (calculé) = ${soldeAttendu} FCFA`);
      console.log(`   soldeFermetureFloat = ${soldeFermetureFloat} FCFA`);
      console.log(`   ecart = ${soldeFermetureFloat} - ${soldeAttendu} = ${ecart} FCFA`);
      console.log('');
      
      console.log(`📊 RÉSUMÉ CLÔTURE caisse ${activeSession.caisse.nom}:`);
      console.log(`   ✓ Solde ouverture: ${activeSession.soldeOuverture} FCFA`);
      console.log(`   ✓ Solde attendu: ${soldeAttendu} FCFA`);
      console.log(`   ✓ Solde déclaré: ${soldeFermetureFloat} FCFA`);
      console.log(`   ${ecart >= 0 ? '✓' : '✗'} Écart: ${ecart >= 0 ? '+' : ''}${ecart} FCFA`);
      console.log('');
      
      console.log('💾 DONNÉES QUI SERONT ENREGISTRÉES:');
      console.log(`   soldeFermeture: ${soldeFermetureFloat}`);
      console.log(`   soldeAttendu: ${soldeAttendu}`);
      console.log(`   ecart: ${ecart}`);
      console.log(`   dateFermeture: ${new Date()}`);
      console.log(`   isActive: false`);
      console.log('');
      
      // Fermer la session avec tous les calculs
      const closedSession = await prisma.cashSession.update({
        where: { id: activeSession.id },
        data: {
          soldeFermeture: soldeFermetureFloat,
          soldeAttendu: soldeAttendu,
          ecart: ecart,
          dateFermeture: new Date(),
          isActive: false
        },
        include: {
          caisse: true,
          utilisateur: true
        }
      });
      
      console.log('✅ SESSION ENREGISTRÉE DANS LA BASE:');
      console.log(`   ID: ${closedSession.id}`);
      console.log(`   soldeFermeture: ${closedSession.soldeFermeture}`);
      console.log(`   soldeAttendu: ${closedSession.soldeAttendu}`);
      console.log(`   ecart: ${closedSession.ecart}`);
      console.log(`   isActive: ${closedSession.isActive}`);
      console.log('═══════════════════════════════════════════════════════════');
      console.log('');
      
      // Mettre à jour la caisse
      await prisma.cashRegister.update({
        where: { id: activeSession.caisseId },
        data: {
          dateFermeture: new Date(),
          soldeActuel: soldeFermetureFloat, // Mettre le solde déclaré
          utilisateurId: null
        }
      });
      
      // Créer un mouvement de caisse pour tracer la fermeture
      await prisma.cashMovement.create({
        data: {
          caisseId: activeSession.caisseId,
          type: 'fermeture_session',
          montant: soldeFermetureFloat,
          description: `Clôture session - Écart: ${ecart >= 0 ? '+' : ''}${ecart} FCFA`,
          utilisateurId: userId,
          dateCreation: new Date(),
          metadata: JSON.stringify({ 
            sessionId: activeSession.id,
            soldeOuverture: parseFloat(activeSession.soldeOuverture),
            soldeAttendu: soldeAttendu,
            soldeFermeture: soldeFermetureFloat,
            ecart: ecart
          })
        }
      });
      
      const formattedSession = {
        id: closedSession.id,
        caisseId: closedSession.caisseId,
        nomCaisse: closedSession.caisse.nom,
        utilisateurId: closedSession.utilisateurId,
        nomUtilisateur: closedSession.utilisateur.nomUtilisateur,
        soldeOuverture: parseFloat(closedSession.soldeOuverture),
        soldeFermeture: parseFloat(closedSession.soldeFermeture),
        soldeAttendu: parseFloat(closedSession.soldeAttendu),
        ecart: parseFloat(closedSession.ecart),
        dateOuverture: closedSession.dateOuverture,
        dateFermeture: closedSession.dateFermeture,
        isActive: Boolean(closedSession.isActive),
        metadata: closedSession.metadata ? JSON.parse(closedSession.metadata) : null
      };
      
      res.json({
        success: true,
        data: formattedSession,
        message: 'Session clôturée avec succès'
      });
    } catch (error) {
      console.error('Erreur lors de la déconnexion de la caisse:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'CASH_SESSION_DISCONNECT_ERROR'
        }
      });
    }
  });

  // GET /api/v1/cash-sessions/history - Récupérer l'historique des sessions
  router.get('/history', async (req, res) => {
    try {
      const { limit = 10 } = req.query;
      // TODO: Récupérer l'utilisateur connecté depuis le token
      const userId = 1; // Temporaire
      
      const sessions = await prisma.cashSession.findMany({
        where: {
          utilisateurId: userId
        },
        include: {
          caisse: true,
          utilisateur: true
        },
        orderBy: {
          dateOuverture: 'desc'
        },
        take: parseInt(limit)
      });
      
      const formattedSessions = sessions.map(session => ({
        id: session.id,
        caisseId: session.caisseId,
        nomCaisse: session.caisse.nom,
        utilisateurId: session.utilisateurId,
        nomUtilisateur: session.utilisateur.nomUtilisateur,
        soldeOuverture: parseFloat(session.soldeOuverture),
        soldeFermeture: session.soldeFermeture ? parseFloat(session.soldeFermeture) : null,
        soldeAttendu: session.soldeAttendu ? parseFloat(session.soldeAttendu) : null,
        ecart: session.ecart ? parseFloat(session.ecart) : null,
        dateOuverture: session.dateOuverture,
        dateFermeture: session.dateFermeture,
        isActive: Boolean(session.isActive),
        metadata: session.metadata ? JSON.parse(session.metadata) : null
      }));
      
      res.json({
        success: true,
        data: formattedSessions
      });
    } catch (error) {
      console.error('Erreur lors de la récupération de l\'historique:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'SESSION_HISTORY_FETCH_ERROR'
        }
      });
    }
  });

  // GET /api/v1/cash-sessions/stats - Récupérer les statistiques des sessions
  router.get('/stats', async (req, res) => {
    try {
      // TODO: Récupérer l'utilisateur connecté depuis le token
      const userId = 1; // Temporaire
      
      const [totalSessions, activeSessions, recentSessions] = await Promise.all([
        prisma.cashSession.count({
          where: { utilisateurId: userId }
        }),
        prisma.cashSession.count({
          where: { 
            utilisateurId: userId,
            isActive: true,
            dateFermeture: null
          }
        }),
        prisma.cashSession.findMany({
          where: { utilisateurId: userId },
          include: {
            caisse: true,
            utilisateur: true
          },
          orderBy: {
            dateOuverture: 'desc'
          },
          take: 5
        })
      ]);
      
      // Calculer le chiffre d'affaires total (approximatif)
      const totalRevenue = await prisma.cashSession.aggregate({
        where: {
          utilisateurId: userId,
          soldeFermeture: { not: null }
        },
        _sum: {
          soldeFermeture: true
        }
      });
      
      const formattedRecentSessions = recentSessions.map(session => ({
        id: session.id,
        caisseId: session.caisseId,
        nomCaisse: session.caisse.nom,
        utilisateurId: session.utilisateurId,
        nomUtilisateur: session.utilisateur.nomUtilisateur,
        soldeOuverture: parseFloat(session.soldeOuverture),
        soldeFermeture: session.soldeFermeture ? parseFloat(session.soldeFermeture) : null,
        dateOuverture: session.dateOuverture,
        dateFermeture: session.dateFermeture,
        isActive: Boolean(session.isActive),
        metadata: session.metadata ? JSON.parse(session.metadata) : null
      }));
      
      const stats = {
        totalSessions,
        activeSessions,
        totalRevenue: parseFloat(totalRevenue._sum.soldeFermeture || 0),
        averageSessionDuration: 0, // TODO: Calculer la durée moyenne
        recentSessions: formattedRecentSessions
      };
      
      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Erreur lors de la récupération des statistiques:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'SESSION_STATS_FETCH_ERROR'
        }
      });
    }
  });

  // GET /api/v1/cash-sessions/check-availability/:id - Vérifier la disponibilité d'une caisse
  router.get('/check-availability/:id', async (req, res) => {
    try {
      const { id } = req.params;
      
      const cashRegister = await prisma.cashRegister.findUnique({
        where: { id: parseInt(id) },
        include: {
          sessions: {
            where: {
              isActive: true,
              dateFermeture: null
            }
          }
        }
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
      
      const available = cashRegister.isActive && cashRegister.sessions.length === 0;
      
      res.json({
        success: true,
        data: {
          available,
          cashRegister: {
            id: cashRegister.id,
            nom: cashRegister.nom,
            isActive: cashRegister.isActive
          },
          activeSessions: cashRegister.sessions.length
        }
      });
    } catch (error) {
      console.error('Erreur lors de la vérification de disponibilité:', error);
      res.status(500).json({
        success: false,
        error: {
          message: 'Erreur serveur',
          code: 'AVAILABILITY_CHECK_ERROR'
        }
      });
    }
  });

  return router;
}

module.exports = { createCashSessionsRouter };