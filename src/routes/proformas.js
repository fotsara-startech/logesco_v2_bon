/**
 * Routes pour la gestion des ventes proforma
 * Pas de mouvement de stock ni financier — simple enregistrement
 */

const express = require('express');
const { authenticateToken } = require('../middleware/auth');

function createProformaRouter({ prisma, authService }) {
  const router = express.Router();
  router.use(authenticateToken(authService));

  // ── Générer un numéro de proforma unique ──────────────────────────────────
  async function generateProformaNumber() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const prefix = `PRF-${year}${month}-`;

    const last = await prisma.venteProforma.findFirst({
      where: { numeroProforma: { startsWith: prefix } },
      orderBy: { id: 'desc' },
    });

    let seq = 1;
    if (last) {
      const parts = last.numeroProforma.split('-');
      seq = (parseInt(parts[parts.length - 1], 10) || 0) + 1;
    }
    return `${prefix}${String(seq).padStart(4, '0')}`;
  }

  // ── Inclusions communes ───────────────────────────────────────────────────
  const include = {
    client: { select: { id: true, nom: true, prenom: true, telephone: true } },
    vendeur: { select: { id: true, nomUtilisateur: true } },
    details: {
      include: {
        produit: { select: { id: true, nom: true, reference: true } },
      },
    },
  };

  // ── GET /proformas ────────────────────────────────────────────────────────
  router.get('/', async (req, res) => {
    try {
      const { page = 1, limit = 20, statut, clientId, vendeurId } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      const where = {};
      if (statut) where.statut = statut;
      if (clientId) where.clientId = parseInt(clientId);
      if (vendeurId) where.vendeurId = parseInt(vendeurId);

      const [total, proformas] = await Promise.all([
        prisma.venteProforma.count({ where }),
        prisma.venteProforma.findMany({
          where,
          include,
          orderBy: { dateCreation: 'desc' },
          skip,
          take: parseInt(limit),
        }),
      ]);

      res.json({
        success: true,
        data: proformas,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit)),
          hasNext: skip + proformas.length < total,
          hasPrev: parseInt(page) > 1,
        },
      });
    } catch (err) {
      console.error('GET /proformas error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  });

  // ── GET /proformas/:id ────────────────────────────────────────────────────
  router.get('/:id', async (req, res) => {
    try {
      const proforma = await prisma.venteProforma.findUnique({
        where: { id: parseInt(req.params.id) },
        include,
      });
      if (!proforma) return res.status(404).json({ success: false, message: 'Proforma introuvable' });
      res.json({ success: true, data: proforma });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  });

  // ── POST /proformas ───────────────────────────────────────────────────────
  router.post('/', async (req, res) => {
    try {
      const { clientId, modePaiement, montantRemise, montantTva, tauxTva, dateVente, details } = req.body;

      if (!details || details.length === 0) {
        return res.status(400).json({ success: false, message: 'Au moins un article est requis' });
      }

      // Calculer les totaux
      let sousTotal = 0;
      const detailsData = [];

      for (const d of details) {
        const produit = await prisma.produit.findUnique({ where: { id: d.produitId } });
        if (!produit) return res.status(404).json({ success: false, message: `Produit ${d.produitId} introuvable` });

        const prixTotal = d.prixUnitaire * d.quantite;
        sousTotal += prixTotal;
        detailsData.push({
          produitId: d.produitId,
          quantite: d.quantite,
          prixUnitaire: d.prixUnitaire,
          prixAffiche: d.prixAffiche || d.prixUnitaire,
          remiseAppliquee: d.remiseAppliquee || 0,
          justificationRemise: d.justificationRemise || null,
          prixTotal,
        });
      }

      const remise = montantRemise || 0;
      const tva = montantTva || 0;
      const montantTotal = sousTotal - remise + tva;
      const numeroProforma = await generateProformaNumber();

      const proforma = await prisma.venteProforma.create({
        data: {
          numeroProforma,
          clientId: clientId || null,
          vendeurId: req.user?.id || null,
          modePaiement: modePaiement || 'comptant',
          sousTotal,
          montantRemise: remise,
          montantTva: tva,
          tauxTva: tauxTva || null,
          montantTotal,
          statut: 'brouillon',
          dateVente: dateVente ? new Date(dateVente) : null,
          details: { create: detailsData },
        },
        include,
      });

      res.status(201).json({ success: true, data: proforma, message: `Proforma ${numeroProforma} créée` });
    } catch (err) {
      console.error('POST /proformas error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  });

  // ── PUT /proformas/:id ────────────────────────────────────────────────────
  router.put('/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const existing = await prisma.venteProforma.findUnique({ where: { id } });
      if (!existing) return res.status(404).json({ success: false, message: 'Proforma introuvable' });
      if (existing.statut !== 'brouillon') {
        return res.status(400).json({ success: false, message: 'Seules les proformas en brouillon peuvent être modifiées' });
      }

      const { clientId, modePaiement, montantRemise, montantTva, tauxTva, dateVente, details } = req.body;

      if (!details || details.length === 0) {
        return res.status(400).json({ success: false, message: 'Au moins un article est requis' });
      }

      let sousTotal = 0;
      const detailsData = [];

      for (const d of details) {
        const prixTotal = d.prixUnitaire * d.quantite;
        sousTotal += prixTotal;
        detailsData.push({
          produitId: d.produitId,
          quantite: d.quantite,
          prixUnitaire: d.prixUnitaire,
          prixAffiche: d.prixAffiche || d.prixUnitaire,
          remiseAppliquee: d.remiseAppliquee || 0,
          justificationRemise: d.justificationRemise || null,
          prixTotal,
        });
      }

      const remise = montantRemise || 0;
      const tva = montantTva || 0;
      const montantTotal = sousTotal - remise + tva;

      // Supprimer les anciens détails et recréer
      await prisma.detailVenteProforma.deleteMany({ where: { proformaId: id } });

      const updated = await prisma.venteProforma.update({
        where: { id },
        data: {
          clientId: clientId || null,
          modePaiement: modePaiement || 'comptant',
          sousTotal,
          montantRemise: remise,
          montantTva: tva,
          tauxTva: tauxTva || null,
          montantTotal,
          dateVente: dateVente ? new Date(dateVente) : null,
          details: { create: detailsData },
        },
        include,
      });

      res.json({ success: true, data: updated, message: 'Proforma mise à jour' });
    } catch (err) {
      console.error('PUT /proformas/:id error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  });

  // ── POST /proformas/:id/validate ──────────────────────────────────────────
  // Convertit la proforma en vente réelle (avec stock + financier)
  router.post('/:id/validate', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const { modePaiement, montantPaye, dateVente } = req.body;

      const proforma = await prisma.venteProforma.findUnique({ where: { id }, include });
      if (!proforma) return res.status(404).json({ success: false, message: 'Proforma introuvable' });
      if (proforma.statut !== 'brouillon') {
        return res.status(400).json({ success: false, message: 'Cette proforma a déjà été traitée' });
      }

      // Vérifier le stock pour chaque article
      for (const detail of proforma.details) {
        const stock = await prisma.stock.findUnique({ where: { produitId: detail.produitId } });
        const produit = await prisma.produit.findUnique({ where: { id: detail.produitId } });
        if (!produit?.estService && stock && stock.quantiteDisponible < detail.quantite) {
          return res.status(400).json({
            success: false,
            message: `Stock insuffisant pour ${detail.produit?.nom || 'produit ' + detail.produitId}. Disponible: ${stock.quantiteDisponible}, Requis: ${detail.quantite}`,
          });
        }
      }

      // Générer le numéro de vente
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      const lastVente = await prisma.vente.findFirst({ orderBy: { id: 'desc' } });
      const seq = (lastVente?.id || 0) + 1;
      const numeroVente = `VNT-${year}${month}${day}-${String(seq).padStart(4, '0')}`;

      const paye = montantPaye || proforma.montantTotal;
      const restant = Math.max(0, proforma.montantTotal - paye);

      // Créer la vente dans une transaction
      const vente = await prisma.$transaction(async (tx) => {
        // 1. Créer la vente
        const newVente = await tx.vente.create({
          data: {
            numeroVente,
            clientId: proforma.clientId,
            vendeurId: proforma.vendeurId,
            dateVente: dateVente ? new Date(dateVente) : proforma.dateVente || now,
            sousTotal: proforma.sousTotal,
            montantRemise: proforma.montantRemise,
            montantTva: proforma.montantTva,
            tauxTva: proforma.tauxTva,
            montantTotal: proforma.montantTotal,
            modePaiement: modePaiement || proforma.modePaiement,
            montantPaye: paye,
            montantRestant: restant,
            statut: 'terminee',
            details: {
              create: proforma.details.map((d) => ({
                produitId: d.produitId,
                quantite: d.quantite,
                prixUnitaire: d.prixUnitaire,
                prixAffiche: d.prixAffiche,
                remiseAppliquee: d.remiseAppliquee,
                justificationRemise: d.justificationRemise,
                prixTotal: d.prixTotal,
              })),
            },
          },
          include: {
            client: true,
            vendeur: { select: { id: true, nomUtilisateur: true } },
            details: { include: { produit: true } },
          },
        });

        // 2. Décrémenter le stock
        for (const detail of proforma.details) {
          const produit = await tx.produit.findUnique({ where: { id: detail.produitId } });
          if (!produit?.estService) {
            await tx.stock.update({
              where: { produitId: detail.produitId },
              data: { quantiteDisponible: { decrement: detail.quantite } },
            });
            await tx.mouvementStock.create({
              data: {
                produitId: detail.produitId,
                typeMouvement: 'sortie',
                changementQuantite: -detail.quantite,
                referenceId: newVente.id,
                typeReference: 'vente',
                notes: `Vente ${numeroVente} (depuis proforma ${proforma.numeroProforma})`,
              },
            });
          }
        }

        // 3. Mettre à jour le compte client si crédit
        if (proforma.clientId && restant > 0) {
          await tx.compteClient.upsert({
            where: { clientId: proforma.clientId },
            update: { soldeActuel: { decrement: restant } },
            create: { clientId: proforma.clientId, soldeActuel: -restant },
          });
        }

        // 4. Marquer la proforma comme validée
        await tx.venteProforma.update({
          where: { id },
          data: { statut: 'validee' },
        });

        return newVente;
      });

      res.status(201).json({ success: true, data: vente, message: `Vente ${numeroVente} créée depuis la proforma ${proforma.numeroProforma}` });
    } catch (err) {
      console.error('POST /proformas/:id/validate error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  });

  // ── DELETE /proformas/:id ─────────────────────────────────────────────────
  router.delete('/:id', async (req, res) => {
    try {
      const id = parseInt(req.params.id);
      const existing = await prisma.venteProforma.findUnique({ where: { id } });
      if (!existing) return res.status(404).json({ success: false, message: 'Proforma introuvable' });
      if (existing.statut === 'validee') {
        return res.status(400).json({ success: false, message: 'Une proforma validée ne peut pas être annulée' });
      }

      await prisma.venteProforma.update({ where: { id }, data: { statut: 'annulee' } });
      res.json({ success: true, message: 'Proforma annulée' });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  });

  return router;
}

module.exports = { createProformaRouter };
