/**
 * Routes multi-boutique — LOGESCO
 * CRUD boutiques, assignations utilisateurs, transferts de stock, dashboard consolidé
 */

const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const { BaseResponseDTO } = require('../dto');

function createBoutiquesRouter({ prisma, authService }) {
  const router = express.Router();
  const auth = authenticateToken(authService);

  // ─── Helpers ────────────────────────────────────────────────────────────────

  function generateTransfertRef() {
    const ts = Date.now().toString(36).toUpperCase();
    const rand = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `TRF-${ts}-${rand}`;
  }

  async function getUserWithRole(prisma, userId) {
    return prisma.utilisateur.findUnique({
      where: { id: userId },
      include: { role: true }
    });
  }

  async function isAdminUser(prisma, userId) {
    const user = await getUserWithRole(prisma, userId);
    return user?.role?.isAdmin === true;
  }

  // ─── BOUTIQUES ───────────────────────────────────────────────────────────────

  // GET /boutiques — liste toutes les boutiques (admin) ou celles de l'user
  router.get('/', auth, async (req, res) => {
    try {
      const isAdmin = await isAdminUser(prisma, req.user.id);
      let boutiques;

      if (isAdmin) {
        boutiques = await prisma.boutique.findMany({
          orderBy: [{ estPrincipale: 'desc' }, { nom: 'asc' }],
          include: {
            _count: { select: { utilisateurs: true, ventes: true } }
          }
        });
      } else {
        const assignments = await prisma.userBoutiqueAssignment.findMany({
          where: { utilisateurId: req.user.id, isActive: true },
          include: {
            boutique: {
              include: { _count: { select: { utilisateurs: true, ventes: true } } }
            },
            role: true
          }
        });
        boutiques = assignments.map(a => ({ ...a.boutique, roleAssigne: a.role }));
      }

      res.json(BaseResponseDTO.success(boutiques));
    } catch (err) {
      console.error('GET /boutiques error:', err);
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // GET /boutiques/:id
  router.get('/:id', auth, async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const boutique = await prisma.boutique.findUnique({
        where: { id },
        include: {
          utilisateurs: {
            include: { utilisateur: { select: { id: true, nomUtilisateur: true, email: true } }, role: true }
          },
          caisses: { select: { id: true, nom: true, soldeActuel: true, isActive: true } }
        }
      });
      if (!boutique) return res.status(404).json(BaseResponseDTO.error('Boutique introuvable'));
      res.json(BaseResponseDTO.success(boutique));
    } catch (err) {
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // POST /boutiques — créer une boutique (admin seulement)
  router.post('/', auth, async (req, res) => {
    try {
      const isAdmin = await isAdminUser(prisma, req.user.id);
      if (!isAdmin) return res.status(403).json(BaseResponseDTO.error('Accès réservé aux administrateurs'));

      const { nom, adresse, telephone, email, description } = req.body;
      if (!nom) return res.status(400).json(BaseResponseDTO.error('Le nom est requis'));

      const boutique = await prisma.boutique.create({
        data: { nom, adresse, telephone, email, description, estPrincipale: false, isActive: true }
      });

      res.status(201).json(BaseResponseDTO.success(boutique, 'Boutique créée avec succès'));
    } catch (err) {
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // PUT /boutiques/:id
  router.put('/:id', auth, async (req, res) => {
    try {
      const isAdmin = await isAdminUser(prisma, req.user.id);
      if (!isAdmin) return res.status(403).json(BaseResponseDTO.error('Accès réservé aux administrateurs'));

      const id = parseInt(req.params.id);
      const { nom, adresse, telephone, email, description, isActive } = req.body;

      const boutique = await prisma.boutique.update({
        where: { id },
        data: { nom, adresse, telephone, email, description, isActive }
      });

      res.json(BaseResponseDTO.success(boutique, 'Boutique mise à jour'));
    } catch (err) {
      if (err.code === 'P2025') return res.status(404).json(BaseResponseDTO.error('Boutique introuvable'));
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // DELETE /boutiques/:id (ne pas supprimer la boutique principale)
  router.delete('/:id', auth, async (req, res) => {
    try {
      const isAdmin = await isAdminUser(prisma, req.user.id);
      if (!isAdmin) return res.status(403).json(BaseResponseDTO.error('Accès réservé aux administrateurs'));

      const id = parseInt(req.params.id);
      const boutique = await prisma.boutique.findUnique({ where: { id } });
      if (!boutique) return res.status(404).json(BaseResponseDTO.error('Boutique introuvable'));
      if (boutique.estPrincipale) return res.status(400).json(BaseResponseDTO.error('Impossible de supprimer la boutique principale'));

      await prisma.boutique.update({ where: { id }, data: { isActive: false } });
      res.json(BaseResponseDTO.success(null, 'Boutique désactivée'));
    } catch (err) {
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // ─── ASSIGNATIONS UTILISATEURS ───────────────────────────────────────────────

  // GET /boutiques/:id/users
  router.get('/:id/users', auth, async (req, res) => {
    try {
      const boutiqueId = parseInt(req.params.id);
      const assignments = await prisma.userBoutiqueAssignment.findMany({
        where: { boutiqueId },
        include: {
          utilisateur: { select: { id: true, nomUtilisateur: true, email: true, isActive: true } },
          role: true
        }
      });
      res.json(BaseResponseDTO.success(assignments));
    } catch (err) {
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // POST /boutiques/:id/users — assigner un utilisateur à une boutique
  router.post('/:id/users', auth, async (req, res) => {
    try {
      const isAdmin = await isAdminUser(prisma, req.user.id);
      if (!isAdmin) return res.status(403).json(BaseResponseDTO.error('Accès réservé aux administrateurs'));

      const boutiqueId = parseInt(req.params.id);
      const { utilisateurId, roleId } = req.body;
      if (!utilisateurId) return res.status(400).json(BaseResponseDTO.error('utilisateurId requis'));

      const assignment = await prisma.userBoutiqueAssignment.upsert({
        where: { utilisateurId_boutiqueId: { utilisateurId: parseInt(utilisateurId), boutiqueId } },
        update: { roleId: roleId ? parseInt(roleId) : null, isActive: true },
        create: { utilisateurId: parseInt(utilisateurId), boutiqueId, roleId: roleId ? parseInt(roleId) : null, isActive: true },
        include: {
          utilisateur: { select: { id: true, nomUtilisateur: true, email: true } },
          role: true
        }
      });

      res.status(201).json(BaseResponseDTO.success(assignment, 'Utilisateur assigné à la boutique'));
    } catch (err) {
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // DELETE /boutiques/:id/users/:userId — retirer un utilisateur d'une boutique
  router.delete('/:id/users/:userId', auth, async (req, res) => {
    try {
      const isAdmin = await isAdminUser(prisma, req.user.id);
      if (!isAdmin) return res.status(403).json(BaseResponseDTO.error('Accès réservé aux administrateurs'));

      const boutiqueId = parseInt(req.params.id);
      const utilisateurId = parseInt(req.params.userId);

      await prisma.userBoutiqueAssignment.update({
        where: { utilisateurId_boutiqueId: { utilisateurId, boutiqueId } },
        data: { isActive: false }
      });

      res.json(BaseResponseDTO.success(null, 'Utilisateur retiré de la boutique'));
    } catch (err) {
      if (err.code === 'P2025') return res.status(404).json(BaseResponseDTO.error('Assignation introuvable'));
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // ─── STOCK PAR BOUTIQUE ──────────────────────────────────────────────────────

  // GET /boutiques/:id/stock
  router.get('/:id/stock', auth, async (req, res) => {
    try {
      const boutiqueId = parseInt(req.params.id);
      const { search, page = 1, limit = 50 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);

      const where = { boutiqueId };
      if (search) {
        where.produit = { nom: { contains: search } };
      }

      const [stocks, total] = await Promise.all([
        prisma.stockBoutique.findMany({
          where,
          include: { produit: { include: { categorie: true } } },
          skip,
          take: parseInt(limit),
          orderBy: { produit: { nom: 'asc' } }
        }),
        prisma.stockBoutique.count({ where })
      ]);

      res.json(BaseResponseDTO.success({ stocks, total, page: parseInt(page), limit: parseInt(limit) }));
    } catch (err) {
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // ─── TRANSFERTS DE STOCK ─────────────────────────────────────────────────────

  // GET /boutiques/transferts — liste tous les transferts (admin) ou ceux des boutiques de l'user
  router.get('/transferts/list', auth, async (req, res) => {
    try {
      const { boutiqueId, page = 1, limit = 50 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      const where = {};
      if (boutiqueId) {
        where.OR = [
          { sourceBoutiqueId: parseInt(boutiqueId) },
          { destBoutiqueId: parseInt(boutiqueId) }
        ];
      }

      const [transferts, total] = await Promise.all([
        prisma.transfertStock.findMany({
          where,
          include: {
            sourceBoutique: { select: { id: true, nom: true } },
            destBoutique: { select: { id: true, nom: true } },
            produit: { select: { id: true, nom: true, reference: true } },
            utilisateur: { select: { id: true, nomUtilisateur: true } }
          },
          skip,
          take: parseInt(limit),
          orderBy: { dateTransfert: 'desc' }
        }),
        prisma.transfertStock.count({ where })
      ]);

      res.json(BaseResponseDTO.success({ transferts, total, page: parseInt(page), limit: parseInt(limit) }));
    } catch (err) {
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // POST /boutiques/transferts — créer un transfert de stock
  router.post('/transferts', auth, async (req, res) => {
    try {
      const { sourceBoutiqueId, destBoutiqueId, produitId, quantite, notes } = req.body;

      if (!sourceBoutiqueId || !destBoutiqueId || !produitId || !quantite) {
        return res.status(400).json(BaseResponseDTO.error('sourceBoutiqueId, destBoutiqueId, produitId et quantite sont requis'));
      }
      if (sourceBoutiqueId === destBoutiqueId) {
        return res.status(400).json(BaseResponseDTO.error('La boutique source et destination doivent être différentes'));
      }
      if (quantite <= 0) {
        return res.status(400).json(BaseResponseDTO.error('La quantité doit être positive'));
      }

      const srcId = parseInt(sourceBoutiqueId);
      const dstId = parseInt(destBoutiqueId);
      const prdId = parseInt(produitId);
      const qty = parseInt(quantite);

      // Vérifier le stock source
      const stockSource = await prisma.stockBoutique.findUnique({
        where: { boutiqueId_produitId: { boutiqueId: srcId, produitId: prdId } }
      });

      if (!stockSource || stockSource.quantiteDisponible < qty) {
        return res.status(400).json(BaseResponseDTO.error(
          `Stock insuffisant. Disponible: ${stockSource?.quantiteDisponible ?? 0}, Demandé: ${qty}`
        ));
      }

      // Transaction atomique
      const result = await prisma.$transaction(async (tx) => {
        // Décrémenter stock source
        await tx.stockBoutique.update({
          where: { boutiqueId_produitId: { boutiqueId: srcId, produitId: prdId } },
          data: { quantiteDisponible: { decrement: qty } }
        });

        // Incrémenter stock destination (upsert)
        await tx.stockBoutique.upsert({
          where: { boutiqueId_produitId: { boutiqueId: dstId, produitId: prdId } },
          update: { quantiteDisponible: { increment: qty } },
          create: { boutiqueId: dstId, produitId: prdId, quantiteDisponible: qty, quantiteReservee: 0 }
        });

        // Mouvement stock sortie (source)
        await tx.mouvementStock.create({
          data: {
            produitId: prdId,
            boutiqueId: srcId,
            typeMouvement: 'TRANSFERT_SORTIE',
            changementQuantite: -qty,
            typeReference: 'transfert',
            notes: `Transfert vers boutique #${dstId}${notes ? ' - ' + notes : ''}`
          }
        });

        // Mouvement stock entrée (destination)
        await tx.mouvementStock.create({
          data: {
            produitId: prdId,
            boutiqueId: dstId,
            typeMouvement: 'TRANSFERT_ENTREE',
            changementQuantite: qty,
            typeReference: 'transfert',
            notes: `Transfert depuis boutique #${srcId}${notes ? ' - ' + notes : ''}`
          }
        });

        // Créer le transfert
        return tx.transfertStock.create({
          data: {
            reference: generateTransfertRef(),
            sourceBoutiqueId: srcId,
            destBoutiqueId: dstId,
            produitId: prdId,
            quantite: qty,
            notes,
            utilisateurId: req.user.id
          },
          include: {
            sourceBoutique: { select: { id: true, nom: true } },
            destBoutique: { select: { id: true, nom: true } },
            produit: { select: { id: true, nom: true, reference: true } },
            utilisateur: { select: { id: true, nomUtilisateur: true } }
          }
        });
      });

      res.status(201).json(BaseResponseDTO.success(result, 'Transfert effectué avec succès'));
    } catch (err) {
      console.error('POST /transferts error:', err);
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // ─── DASHBOARD CONSOLIDÉ ─────────────────────────────────────────────────────

  // GET /boutiques/dashboard/consolidated — stats globales toutes boutiques
  router.get('/dashboard/consolidated', auth, async (req, res) => {
    try {
      const isAdmin = await isAdminUser(prisma, req.user.id);
      if (!isAdmin) return res.status(403).json(BaseResponseDTO.error('Accès réservé aux administrateurs'));

      const { dateDebut, dateFin } = req.query;
      const where = {};
      if (dateDebut || dateFin) {
        where.dateVente = {};
        if (dateDebut) where.dateVente.gte = new Date(dateDebut);
        if (dateFin) where.dateVente.lte = new Date(dateFin);
      }

      const boutiques = await prisma.boutique.findMany({
        where: { isActive: true },
        orderBy: [{ estPrincipale: 'desc' }, { nom: 'asc' }]
      });

      const statsBoutiques = await Promise.all(boutiques.map(async (b) => {
        const venteWhere = { ...where, boutiqueId: b.id, statut: { not: 'annulee' } };

        const [ventesAgg, nbVentes, mouvementsAgg, caisses] = await Promise.all([
          prisma.vente.aggregate({
            where: venteWhere,
            _sum: { montantTotal: true, montantPaye: true }
          }),
          prisma.vente.count({ where: venteWhere }),
          prisma.financialMovement.aggregate({
            where: { boutiqueId: b.id, ...(where.dateVente ? { date: where.dateVente } : {}) },
            _sum: { montant: true }
          }),
          prisma.cashRegister.findMany({
            where: { boutiqueId: b.id, isActive: true },
            select: { id: true, nom: true, soldeActuel: true }
          })
        ]);

        return {
          boutique: { id: b.id, nom: b.nom, estPrincipale: b.estPrincipale },
          chiffreAffaires: ventesAgg._sum.montantTotal ?? 0,
          montantEncaisse: ventesAgg._sum.montantPaye ?? 0,
          nbVentes,
          totalMouvementsFinanciers: mouvementsAgg._sum.montant ?? 0,
          caisses
        };
      }));

      const totaux = {
        chiffreAffaires: statsBoutiques.reduce((s, b) => s + b.chiffreAffaires, 0),
        montantEncaisse: statsBoutiques.reduce((s, b) => s + b.montantEncaisse, 0),
        nbVentes: statsBoutiques.reduce((s, b) => s + b.nbVentes, 0),
        totalMouvementsFinanciers: statsBoutiques.reduce((s, b) => s + b.totalMouvementsFinanciers, 0)
      };

      res.json(BaseResponseDTO.success({ boutiques: statsBoutiques, totaux }));
    } catch (err) {
      console.error('GET /dashboard/consolidated error:', err);
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  // GET /boutiques/:id/dashboard — stats d'une boutique spécifique
  router.get('/:id/dashboard', auth, async (req, res) => {
    try {
      const boutiqueId = parseInt(req.params.id);
      const { dateDebut, dateFin } = req.query;

      const venteWhere = { boutiqueId, statut: { not: 'annulee' } };
      if (dateDebut || dateFin) {
        venteWhere.dateVente = {};
        if (dateDebut) venteWhere.dateVente.gte = new Date(dateDebut);
        if (dateFin) venteWhere.dateVente.lte = new Date(dateFin);
      }

      const [boutique, ventesAgg, nbVentes, mouvementsAgg, stockFaible, caisses] = await Promise.all([
        prisma.boutique.findUnique({ where: { id: boutiqueId } }),
        prisma.vente.aggregate({ where: venteWhere, _sum: { montantTotal: true, montantPaye: true } }),
        prisma.vente.count({ where: venteWhere }),
        prisma.financialMovement.aggregate({
          where: { boutiqueId, ...(venteWhere.dateVente ? { date: venteWhere.dateVente } : {}) },
          _sum: { montant: true }
        }),
        prisma.stockBoutique.count({
          where: {
            boutiqueId,
            produit: { seuilStockMinimum: { gt: 0 } },
            quantiteDisponible: { lte: prisma.stockBoutique.fields.produit }
          }
        }).catch(() => 0),
        prisma.cashRegister.findMany({
          where: { boutiqueId, isActive: true },
          select: { id: true, nom: true, soldeActuel: true }
        })
      ]);

      if (!boutique) return res.status(404).json(BaseResponseDTO.error('Boutique introuvable'));

      res.json(BaseResponseDTO.success({
        boutique,
        chiffreAffaires: ventesAgg._sum.montantTotal ?? 0,
        montantEncaisse: ventesAgg._sum.montantPaye ?? 0,
        nbVentes,
        totalMouvementsFinanciers: mouvementsAgg._sum.montant ?? 0,
        caisses
      }));
    } catch (err) {
      res.status(500).json(BaseResponseDTO.error(err.message));
    }
  });

  return router;
}

module.exports = { createBoutiquesRouter };
