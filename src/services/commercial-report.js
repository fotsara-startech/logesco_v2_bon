/**
 * Service de rapport « ventes par commercial / zone / ville ».
 *
 * Agrégation par [commercial, zone] côté backend, pas juste par commercial :
 * la zone/ville est celle FIGÉE sur la vente au moment où elle a été créée
 * (Vente.zoneId), pas celle actuelle du commercial. Un commercial réaffecté
 * en cours de période apparaît donc sur plusieurs lignes (une par zone où
 * il a réellement vendu), au lieu de voir tout son historique réécrit sous
 * sa zone du jour. Le regroupement par zone ou par ville se fait ensuite en
 * ré-agrégeant cette liste plate côté client.
 *
 * Implémenté en Prisma ORM (groupBy/findMany), pas en SQL brut : c'est le
 * choix qui évite le bug déjà rencontré dans movement-report.js, où
 * `datetime(date)` appliqué à la colonne entière (stockage epoch-ms de
 * Prisma en SQLite) renvoyait toujours NULL et cassait silencieusement tout
 * filtre de date. Le filtrage par date via l'ORM (`dateVente: { gte, lte }`)
 * n'a pas ce problème.
 */

class CommercialReportService {
  constructor(prisma) {
    this.prisma = prisma;
  }

  /**
   * Ventes agrégées par [commercial, zone-au-moment-de-la-vente] sur une
   * période, avec zone/ville jointes.
   */
  async getByCommercial(startDate, endDate, boutiqueId = null) {
    const where = {
      commercialId: { not: null },
      statut: { not: 'annulee' },
      dateVente: { gte: new Date(startDate), lte: new Date(endDate) },
      ...(boutiqueId ? { boutiqueId } : {}),
    };

    const rows = await this.prisma.vente.groupBy({
      by: ['commercialId', 'zoneId'],
      where,
      _sum: { montantTotal: true },
      _count: { _all: true },
    });

    if (rows.length === 0) return [];

    const commerciaux = await this.prisma.commercial.findMany({
      where: { id: { in: [...new Set(rows.map((r) => r.commercialId))] } },
      include: { zone: { include: { ville: true } } },
    });
    const commercialById = new Map(commerciaux.map((c) => [c.id, c]));

    // Zones figées sur les ventes elles-mêmes — peuvent différer de la zone
    // ACTUELLE du commercial s'il a été réaffecté depuis.
    const zoneIdsSnapshot = [...new Set(rows.map((r) => r.zoneId).filter(Boolean))];
    const zonesSnapshot = zoneIdsSnapshot.length
      ? await this.prisma.zone.findMany({
          where: { id: { in: zoneIdsSnapshot } },
          include: { ville: true },
        })
      : [];
    const zoneById = new Map(zonesSnapshot.map((z) => [z.id, z]));

    return rows
      .map((r) => {
        const commercial = commercialById.get(r.commercialId);
        if (!commercial) return null;

        // Ventes créées avant l'ajout du snapshot (zone_id NULL) : on
        // retombe sur la zone actuelle du commercial, faute de mieux.
        const zone = r.zoneId ? zoneById.get(r.zoneId) : commercial.zone;
        if (!zone) return null;

        return {
          commercialId: commercial.id,
          commercialNom: commercial.nom,
          commercialPrenom: commercial.prenom,
          zoneId: zone.id,
          zoneNom: zone.nom,
          villeId: zone.ville.id,
          villeNom: zone.ville.nom,
          montant: r._sum.montantTotal || 0,
          count: r._count._all,
        };
      })
      .filter(Boolean)
      .sort((a, b) => b.montant - a.montant);
  }

  /**
   * Résumé global (toutes ventes attribuées à un commercial confondues) —
   * sert de cartes de synthèse en tête du rapport.
   */
  async getSummary(startDate, endDate, boutiqueId = null) {
    const where = {
      commercialId: { not: null },
      statut: { not: 'annulee' },
      dateVente: { gte: new Date(startDate), lte: new Date(endDate) },
      ...(boutiqueId ? { boutiqueId } : {}),
    };

    const agg = await this.prisma.vente.aggregate({
      where,
      _sum: { montantTotal: true },
      _count: { _all: true },
    });

    const commerciauxActifs = await this.prisma.vente.groupBy({
      by: ['commercialId'],
      where,
    });

    return {
      totalAmount: agg._sum.montantTotal || 0,
      totalCount: agg._count._all || 0,
      commerciauxActifsCount: commerciauxActifs.length,
    };
  }
}

module.exports = CommercialReportService;
