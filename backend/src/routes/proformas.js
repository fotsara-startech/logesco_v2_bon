/**
 * Routes pour la gestion des ventes proforma
 * Pas de mouvement de stock ni financier — simple enregistrement
 */

const express = require('express');
const { authenticateToken } = require('../middleware/auth');

function createProformaRouter({ prisma, authService, syncService }) {
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
      const { page = 1, limit = 20, statut, clientId, vendeurId, boutiqueId, dateDebut, dateFin } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      const where = {};
      if (statut) where.statut = statut;
      if (clientId) where.clientId = parseInt(clientId);
      if (vendeurId) where.vendeurId = parseInt(vendeurId);
      if (boutiqueId) where.boutiqueId = parseInt(boutiqueId);
      // Filtre par période — même convention que /sales (dateDebut/dateFin en
      // heure locale, sans suffixe 'Z') ; filtré sur dateCreation, la date
      // affichée/triée dans le listing des proformas.
      if (dateDebut || dateFin) {
        where.dateCreation = {};
        if (dateDebut) where.dateCreation.gte = new Date(dateDebut);
        if (dateFin) where.dateCreation.lte = new Date(dateFin);
      }

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
      const { clientId, modePaiement, montantRemise, montantTva, tauxTva, dateVente, details, boutiqueId } = req.body;

      if (!details || details.length === 0) {
        return res.status(400).json({ success: false, message: 'Au moins un article est requis' });
      }

      // Déterminer la boutique à utiliser
      let activeBoutiqueId = boutiqueId;
      if (!activeBoutiqueId) {
        // Récupérer la boutique principale par défaut
        const boutiquePrincipale = await prisma.boutique.findFirst({
          where: { estPrincipale: true }
        });
        
        if (boutiquePrincipale) {
          activeBoutiqueId = boutiquePrincipale.id;
        }
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
          boutiqueId: activeBoutiqueId,
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

      // Enqueue pour sync vers Neon
      if (syncService) {
        await syncService.enqueue('ventes_proforma', 'INSERT', proforma);
        // Sync des détails
        if (proforma.details) {
          for (const detail of proforma.details) {
            await syncService.enqueue('details_ventes_proforma', 'INSERT', detail);
          }
        }
      }

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

      const { clientId, modePaiement, montantRemise, montantTva, tauxTva, dateVente, details, boutiqueId } = req.body;

      if (!details || details.length === 0) {
        return res.status(400).json({ success: false, message: 'Au moins un article est requis' });
      }

      // Déterminer la boutique à utiliser
      let activeBoutiqueId = boutiqueId;
      if (!activeBoutiqueId) {
        // Garder la boutique existante ou utiliser la boutique principale
        activeBoutiqueId = existing.boutiqueId;
        if (!activeBoutiqueId) {
          const boutiquePrincipale = await prisma.boutique.findFirst({
            where: { estPrincipale: true }
          });
          if (boutiquePrincipale) {
            activeBoutiqueId = boutiquePrincipale.id;
          }
        }
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
          boutiqueId: activeBoutiqueId,
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

      // Enqueue pour sync vers Neon
      if (syncService) {
        await syncService.enqueue('ventes_proforma', 'UPDATE', updated);
        // Sync des nouveaux détails
        if (updated.details) {
          for (const detail of updated.details) {
            await syncService.enqueue('details_ventes_proforma', 'INSERT', detail);
          }
        }
      }

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
      const { modePaiement, montantPaye, dateVente, montantTva, tauxTva } = req.body;

      const proforma = await prisma.venteProforma.findUnique({ where: { id }, include });
      if (!proforma) return res.status(404).json({ success: false, message: 'Proforma introuvable' });
      if (proforma.statut !== 'brouillon') {
        return res.status(400).json({ success: false, message: 'Cette proforma a déjà été traitée' });
      }

      console.log(`✅ [PROFORMA VALIDATION] Validation proforma ${id} pour boutique ${proforma.boutiqueId}`);

      // Vérifier le stock pour chaque article
      for (const detail of proforma.details) {
        const produit = await prisma.produit.findUnique({ where: { id: detail.produitId } });
        
        // Ignorer la vérification pour les services
        if (produit?.estService) {
          continue;
        }

        let stock;
        let stockDisponible = 0;

        // Vérifier le stock selon la boutique de la proforma
        if (proforma.boutiqueId) {
          // Vérifier le stock spécifique à la boutique
          stock = await prisma.stockBoutique.findUnique({
            where: { 
              boutiqueId_produitId: { 
                boutiqueId: proforma.boutiqueId, 
                produitId: detail.produitId 
              } 
            },
            include: { produit: { select: { nom: true, reference: true } } }
          });
          
          stockDisponible = stock?.quantiteDisponible || 0;
          
        } else {
          // Fallback sur le stock global si pas de boutique
          stock = await prisma.stock.findUnique({ where: { produitId: detail.produitId } });
          stockDisponible = stock?.quantiteDisponible || 0;
        }

        // Vérifier si le stock est suffisant
        if (stockDisponible < detail.quantite) {
          return res.status(400).json({
            success: false,
            message: `Stock insuffisant pour ${detail.produit?.nom || produit?.nom || 'produit ' + detail.produitId}. Disponible: ${stockDisponible}, Requis: ${detail.quantite}`,
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

      // Recalculer les montants TVA si le client a modifié la TVA depuis le dialog
      const finalMontantTva = montantTva !== undefined ? Number(montantTva) : proforma.montantTva;
      const finalTauxTva = tauxTva !== undefined ? Number(tauxTva) : proforma.tauxTva;
      const finalMontantTotal = proforma.sousTotal - proforma.montantRemise + finalMontantTva;
      const restant = Math.max(0, finalMontantTotal - paye);

      // Créer la vente dans une transaction
      const vente = await prisma.$transaction(async (tx) => {
        // Récupérer la session active de l'utilisateur connecté (filtrée par boutique)
        const sessionWhere = {
          utilisateurId: req.user.id,
          isActive: true,
          dateFermeture: null,
        };
        if (proforma.boutiqueId) sessionWhere.boutiqueId = proforma.boutiqueId;

        const activeSession = await tx.cashSession.findFirst({ where: sessionWhere });
        const sessionId = activeSession ? activeSession.id : null;

        if (!activeSession) {
          console.log('⚠️ [PROFORMA VALIDATION] Aucune session active trouvée - vente créée sans session');
        } else {
          console.log(`✅ [PROFORMA VALIDATION] Session active trouvée: ID ${activeSession.id}`);
        }

        // 1. Créer la vente
        const newVente = await tx.vente.create({
          data: {
            numeroVente,
            clientId: proforma.clientId,
            vendeurId: proforma.vendeurId,
            boutiqueId: proforma.boutiqueId,
            ...(sessionId ? { sessionId } : {}),
            dateVente: dateVente ? new Date(dateVente) : proforma.dateVente || now,
            sousTotal: proforma.sousTotal,
            montantRemise: proforma.montantRemise,
            montantTva: finalMontantTva,
            tauxTva: finalTauxTva,
            montantTotal: finalMontantTotal,
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
            // Décrémenter le stock selon la boutique de la proforma
            if (proforma.boutiqueId) {
              // Décrémenter le stock spécifique à la boutique
              await tx.stockBoutique.update({
                where: { 
                  boutiqueId_produitId: { 
                    boutiqueId: proforma.boutiqueId, 
                    produitId: detail.produitId 
                  } 
                },
                data: { quantiteDisponible: { decrement: detail.quantite } },
              });
            } else {
              // Fallback sur le stock global si pas de boutique
              await tx.stock.update({
                where: { produitId: detail.produitId },
                data: { quantiteDisponible: { decrement: detail.quantite } },
              });
            }

            // Créer le mouvement de stock avec boutiqueId
            await tx.mouvementStock.create({
              data: {
                produitId: detail.produitId,
                boutiqueId: proforma.boutiqueId || null,
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
          const compteExistant = await tx.compteClient.findUnique({
            where: { clientId: proforma.clientId }
          });

          if (compteExistant) {
            await tx.compteClient.update({
              where: { clientId: proforma.clientId },
              data: { soldeActuel: { decrement: restant } }
            });
          } else {
            await tx.compteClient.create({
              data: {
                clientId: proforma.clientId,
                soldeActuel: -restant,
                limiteCredit: 0
              }
            });
          }
        }

        // 4. Marquer la proforma comme validée
        await tx.venteProforma.update({
          where: { id },
          data: { statut: 'validee' },
        });

        return newVente;
      });

      res.status(201).json({ success: true, data: vente, message: `Vente ${numeroVente} créée depuis la proforma ${proforma.numeroProforma}` });

      // ─── Synchroniser vers Neon (asynchrone) ───────────────────────────────────
      if (process.env.CLOUD_DB_URL) {
        setImmediate(async () => {
          try {
            console.log('🔧 [Sync] Synchronisation proforma → vente...');
            
            // 1. Sync vente principale
            try {
              await syncService.enqueue('ventes', 'INSERT', {
                id: vente.id,
                numero_vente: vente.numeroVente,
                client_id: vente.clientId,
                sous_total: vente.sousTotal,
                montant_remise: vente.montantRemise,
                montant_tva: vente.montantTva,
                taux_tva: vente.tauxTva,
                montant_total: vente.montantTotal,
                montant_paye: vente.montantPaye,
                montant_restant: vente.montantRestant,
                statut: vente.statut,
                date_vente: vente.dateVente,
                boutique_id: vente.boutiqueId,
                vendeur_id: vente.vendeurId,
                mode_paiement: vente.modePaiement,
                session_id: vente.sessionId || null,
              });
              console.log(`✅ [Sync] Vente synchronisée: ${vente.id}`);
            } catch (syncErr) {
              console.error('❌ Erreur sync vente:', syncErr.message);
            }

            // 2. Sync détails de vente
            try {
              for (const detail of vente.details) {
                await syncService.enqueue('details_ventes', 'INSERT', {
                  id: detail.id,
                  vente_id: detail.venteId,
                  produit_id: detail.produitId,
                  quantite: detail.quantite,
                  prix_unitaire: detail.prixUnitaire,
                  prix_affiche: detail.prixAffiche,
                  remise_appliquee: detail.remiseAppliquee,
                  justification_remise: detail.justificationRemise,
                  prix_total: detail.prixTotal,
                });
              }
              console.log(`✅ [Sync] Détails synchronisés: ${vente.details.length} lignes`);
            } catch (syncErr) {
              console.error('❌ Erreur sync détails:', syncErr.message);
            }

            // 3. Sync mouvements de stock
            try {
              for (const detail of vente.details) {
                const mouvement = await prisma.mouvementStock.findFirst({
                  where: {
                    produitId: detail.produitId,
                    referenceId: vente.id,
                    typeReference: 'vente'
                  },
                  orderBy: { id: 'desc' }
                });
                
                if (mouvement) {
                  await syncService.enqueue('mouvements_stock', 'INSERT', {
                    id: mouvement.id,
                    produit_id: mouvement.produitId,
                    boutique_id: mouvement.boutiqueId,
                    type_mouvement: mouvement.typeMouvement,
                    changement_quantite: mouvement.changementQuantite,
                    reference_id: mouvement.referenceId,
                    type_reference: mouvement.typeReference,
                    date_mouvement: mouvement.dateMouvement,
                    notes: mouvement.notes
                  });
                }
              }
              console.log(`✅ [Sync] Mouvements de stock synchronisés`);
            } catch (syncErr) {
              console.error('❌ Erreur sync mouvements:', syncErr.message);
            }

            // 4. Sync proforma comme validée
            try {
              await syncService.enqueue('ventes_proforma', 'UPDATE', {
                id: proforma.id,
                statut: 'validee',
              });
              console.log(`✅ [Sync] Proforma marquée comme validée: ${proforma.id}`);
            } catch (syncErr) {
              console.error('❌ Erreur sync proforma:', syncErr.message);
            }

            console.log('✅ [Sync] Synchronisation proforma → vente terminée');
          } catch (error) {
            console.error('❌ Erreur sync global:', error.message);
          }
        });
      }
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
