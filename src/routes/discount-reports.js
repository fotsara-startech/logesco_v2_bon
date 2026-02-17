/**
 * Routes pour les rapports de remises
 * Analyse des remises accordées par vendeur
 */

const express = require('express');
const { validate, validatePagination } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const Joi = require('joi');

// Schémas de validation pour les rapports
const discountReportSchemas = {
    byVendor: Joi.object({
        vendeurId: Joi.number().integer().positive(),
        dateDebut: Joi.date().iso(),
        dateFin: Joi.date().iso(),
        page: Joi.number().integer().min(1).default(1),
        limit: Joi.number().integer().min(1).max(100).default(20)
    }),

    summary: Joi.object({
        dateDebut: Joi.date().iso(),
        dateFin: Joi.date().iso(),
        groupBy: Joi.string().valid('vendeur', 'produit', 'jour', 'mois').default('vendeur')
    })
};

function createDiscountReportsRouter({ prisma, authService }) {
    const router = express.Router();

    // Middleware d'authentification
    router.use(authenticateToken(authService));

    /**
     * GET /discount-reports/by-vendor
     * Rapport des remises par vendeur
     */
    router.get('/by-vendor',
        validate(discountReportSchemas.byVendor, 'query'),
        validatePagination,
        async (req, res) => {
            try {
                const {
                    vendeurId,
                    dateDebut,
                    dateFin,
                    page = 1,
                    limit = 20
                } = req.query;

                const skip = (page - 1) * limit;

                // Construire les conditions de recherche
                const whereConditions = {};

                if (vendeurId) {
                    whereConditions.vendeurId = parseInt(vendeurId);
                }

                if (dateDebut || dateFin) {
                    whereConditions.dateVente = {};
                    if (dateDebut) {
                        whereConditions.dateVente.gte = new Date(dateDebut);
                    }
                    if (dateFin) {
                        whereConditions.dateVente.lte = new Date(dateFin);
                    }
                }

                // Récupérer les ventes avec remises (globales ou par détail)
                const [ventes, total] = await Promise.all([
                    prisma.vente.findMany({
                        where: {
                            ...whereConditions,
                            OR: [
                                {
                                    montantRemise: {
                                        gt: 0
                                    }
                                },
                                {
                                    details: {
                                        some: {
                                            remiseAppliquee: {
                                                gt: 0
                                            }
                                        }
                                    }
                                }
                            ]
                        },
                        include: {
                            vendeur: {
                                select: {
                                    id: true,
                                    nomUtilisateur: true,
                                    email: true
                                }
                            },
                            client: {
                                select: {
                                    id: true,
                                    nom: true,
                                    prenom: true
                                }
                            },
                            details: {
                                include: {
                                    produit: {
                                        select: {
                                            id: true,
                                            nom: true,
                                            reference: true,
                                            remiseMaxAutorisee: true
                                        }
                                    }
                                }
                            }
                        },
                        orderBy: { dateVente: 'desc' },
                        skip,
                        take: parseInt(limit)
                    }),
                    prisma.vente.count({
                        where: {
                            ...whereConditions,
                            OR: [
                                {
                                    montantRemise: {
                                        gt: 0
                                    }
                                },
                                {
                                    details: {
                                        some: {
                                            remiseAppliquee: {
                                                gt: 0
                                            }
                                        }
                                    }
                                }
                            ]
                        }
                    })
                ]);

                // Calculer les statistiques
                const statistiques = ventes.reduce((stats, vente) => {
                    const vendeurId = vente.vendeurId;
                    const vendeurNom = vente.vendeur?.nomUtilisateur || 'Vendeur inconnu';

                    if (!stats[vendeurId]) {
                        stats[vendeurId] = {
                            vendeur: {
                                id: vendeurId,
                                nomUtilisateur: vendeurNom
                            },
                            totalRemises: 0,
                            nombreVentes: 0,
                            nombreProduits: 0,
                            remiseMoyenne: 0
                        };
                    }

                    stats[vendeurId].nombreVentes++;

                    // Ajouter la remise globale de la vente
                    if (vente.montantRemise > 0) {
                        stats[vendeurId].totalRemises += vente.montantRemise;
                    }

                    // Ajouter les remises par détail
                    vente.details.forEach(detail => {
                        if (detail.remiseAppliquee > 0) {
                            stats[vendeurId].totalRemises += detail.remiseAppliquee;
                        }
                        stats[vendeurId].nombreProduits++;
                    });

                    stats[vendeurId].remiseMoyenne =
                        stats[vendeurId].nombreVentes > 0 ? stats[vendeurId].totalRemises / stats[vendeurId].nombreVentes : 0;

                    return stats;
                }, {});

                res.json({
                    success: true,
                    data: {
                        ventes,
                        statistiques: Object.values(statistiques),
                        pagination: {
                            page: parseInt(page),
                            limit: parseInt(limit),
                            total,
                            pages: Math.ceil(total / limit)
                        }
                    },
                    message: 'Rapport des remises par vendeur récupéré avec succès'
                });

            } catch (error) {
                console.error('Erreur rapport remises par vendeur:', error);
                res.status(500).json({
                    success: false,
                    message: 'Erreur lors de la génération du rapport'
                });
            }
        }
    );

    /**
     * GET /discount-reports/summary
     * Résumé des remises avec groupement
     */
    router.get('/summary',
        validate(discountReportSchemas.summary, 'query'),
        async (req, res) => {
            try {
                const { dateDebut, dateFin, groupBy = 'vendeur' } = req.query;

                // Construire les conditions de recherche
                const whereConditions = {};

                if (dateDebut || dateFin) {
                    whereConditions.dateVente = {};
                    if (dateDebut) {
                        whereConditions.dateVente.gte = new Date(dateDebut);
                    }
                    if (dateFin) {
                        whereConditions.dateVente.lte = new Date(dateFin);
                    }
                }

                // Récupérer toutes les ventes avec remises (globales ou par détail)
                const ventes = await prisma.vente.findMany({
                    where: {
                        ...whereConditions,
                        OR: [
                            {
                                montantRemise: {
                                    gt: 0
                                }
                            },
                            {
                                details: {
                                    some: {
                                        remiseAppliquee: {
                                            gt: 0
                                        }
                                    }
                                }
                            }
                        ]
                    },
                    include: {
                        vendeur: {
                            select: {
                                id: true,
                                nomUtilisateur: true
                            }
                        },
                        details: {
                            include: {
                                produit: {
                                    select: {
                                        id: true,
                                        nom: true,
                                        reference: true
                                    }
                                }
                            }
                        }
                    }
                });

                // Grouper selon le critère demandé
                let groupedData = {};

                ventes.forEach(vente => {
                    // Traiter les remises globales de la vente
                    if (vente.montantRemise > 0) {
                        let groupKey;

                        switch (groupBy) {
                            case 'vendeur':
                                groupKey = vente.vendeur?.nomUtilisateur || 'Vendeur inconnu';
                                break;
                            case 'produit':
                                groupKey = 'Remise globale';
                                break;
                            case 'jour':
                                groupKey = vente.dateVente.toISOString().split('T')[0];
                                break;
                            case 'mois':
                                const date = new Date(vente.dateVente);
                                groupKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
                                break;
                            default:
                                groupKey = 'Tous';
                        }

                        if (!groupedData[groupKey]) {
                            groupedData[groupKey] = {
                                groupe: groupKey,
                                totalRemises: 0,
                                nombreRemises: 0,
                                remiseMoyenne: 0,
                                remiseMin: vente.montantRemise,
                                remiseMax: vente.montantRemise
                            };
                        }

                        const group = groupedData[groupKey];
                        group.totalRemises += vente.montantRemise;
                        group.nombreRemises++;
                        group.remiseMin = Math.min(group.remiseMin, vente.montantRemise);
                        group.remiseMax = Math.max(group.remiseMax, vente.montantRemise);
                        group.remiseMoyenne = group.totalRemises / group.nombreRemises;
                    }

                    // Traiter les remises par détail (si elles existent)
                    vente.details.forEach(detail => {
                        if (detail.remiseAppliquee > 0) {
                            let groupKey;

                            switch (groupBy) {
                                case 'vendeur':
                                    groupKey = vente.vendeur?.nomUtilisateur || 'Vendeur inconnu';
                                    break;
                                case 'produit':
                                    groupKey = `${detail.produit.nom} (${detail.produit.reference})`;
                                    break;
                                case 'jour':
                                    groupKey = vente.dateVente.toISOString().split('T')[0];
                                    break;
                                case 'mois':
                                    const date = new Date(vente.dateVente);
                                    groupKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
                                    break;
                                default:
                                    groupKey = 'Tous';
                            }

                            if (!groupedData[groupKey]) {
                                groupedData[groupKey] = {
                                    groupe: groupKey,
                                    totalRemises: 0,
                                    nombreRemises: 0,
                                    remiseMoyenne: 0,
                                    remiseMin: detail.remiseAppliquee,
                                    remiseMax: detail.remiseAppliquee
                                };
                            }

                            const group = groupedData[groupKey];
                            group.totalRemises += detail.remiseAppliquee;
                            group.nombreRemises++;
                            group.remiseMin = Math.min(group.remiseMin, detail.remiseAppliquee);
                            group.remiseMax = Math.max(group.remiseMax, detail.remiseAppliquee);
                            group.remiseMoyenne = group.totalRemises / group.nombreRemises;
                        }
                    });
                });

                // Calculer les totaux généraux
                const totaux = Object.values(groupedData).reduce((acc, group) => {
                    acc.totalRemises += group.totalRemises;
                    acc.nombreRemises += group.nombreRemises;
                    return acc;
                }, { totalRemises: 0, nombreRemises: 0 });

                totaux.remiseMoyenneGlobale = totaux.nombreRemises > 0
                    ? totaux.totalRemises / totaux.nombreRemises
                    : 0;

                res.json({
                    success: true,
                    data: {
                        groupBy,
                        periode: {
                            debut: dateDebut,
                            fin: dateFin
                        },
                        groupes: Object.values(groupedData).sort((a, b) => b.totalRemises - a.totalRemises),
                        totaux
                    },
                    message: 'Résumé des remises généré avec succès'
                });

            } catch (error) {
                console.error('Erreur résumé remises:', error);
                res.status(500).json({
                    success: false,
                    message: 'Erreur lors de la génération du résumé'
                });
            }
        }
    );

    /**
     * GET /discount-reports/top-discounts
     * Top des plus grosses remises accordées
     */
    router.get('/top-discounts',
        validatePagination,
        async (req, res) => {
            try {
                const { page = 1, limit = 10 } = req.query;
                const skip = (page - 1) * limit;

                // Récupérer les détails de vente avec les plus grosses remises
                const topDiscounts = await prisma.detailVente.findMany({
                    where: {
                        remiseAppliquee: {
                            gt: 0
                        }
                    },
                    include: {
                        produit: {
                            select: {
                                id: true,
                                nom: true,
                                reference: true,
                                remiseMaxAutorisee: true
                            }
                        },
                        vente: {
                            select: {
                                id: true,
                                numeroVente: true,
                                dateVente: true,
                                vendeur: {
                                    select: {
                                        id: true,
                                        nomUtilisateur: true
                                    }
                                },
                                client: {
                                    select: {
                                        id: true,
                                        nom: true,
                                        prenom: true
                                    }
                                }
                            }
                        }
                    },
                    orderBy: {
                        remiseAppliquee: 'desc'
                    },
                    skip,
                    take: parseInt(limit)
                });

                res.json({
                    success: true,
                    data: topDiscounts.map(detail => ({
                        id: detail.id,
                        remiseAppliquee: detail.remiseAppliquee,
                        remiseMaxAutorisee: detail.produit.remiseMaxAutorisee,
                        pourcentageUtilise: (detail.remiseAppliquee / detail.produit.remiseMaxAutorisee) * 100,
                        justification: detail.justificationRemise,
                        produit: detail.produit,
                        vente: detail.vente,
                        prixOriginal: detail.prixAffiche,
                        prixFinal: detail.prixUnitaire,
                        economieClient: detail.remiseAppliquee * detail.quantite
                    })),
                    pagination: {
                        page: parseInt(page),
                        limit: parseInt(limit)
                    },
                    message: 'Top des remises récupéré avec succès'
                });

            } catch (error) {
                console.error('Erreur top remises:', error);
                res.status(500).json({
                    success: false,
                    message: 'Erreur lors de la récupération du top des remises'
                });
            }
        }
    );

    return router;
}

module.exports = { createDiscountReportsRouter };