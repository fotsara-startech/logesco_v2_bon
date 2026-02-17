/**
 * Service pour la génération de rapports des mouvements financiers
 * Gère l'export PDF et Excel des données financières
 */

const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

class MovementReportService {
  constructor(prisma, financialMovementService) {
    this.prisma = prisma;
    this.financialMovementService = financialMovementService;
  }

  /**
   * Génère un résumé des mouvements pour une période
   */
  async getSummary(startDate, endDate) {
    try {
      const where = {
        date: {
          gte: new Date(startDate),
          lte: new Date(endDate)
        }
      };

      const [movements, aggregates] = await Promise.all([
        this.prisma.financialMovement.findMany({
          where,
          select: {
            montant: true,
            date: true
          }
        }),
        this.prisma.financialMovement.aggregate({
          where,
          _sum: { montant: true },
          _avg: { montant: true },
          _max: { montant: true },
          _min: { montant: true },
          _count: true
        })
      ]);

      const lastMovement = await this.prisma.financialMovement.findFirst({
        where,
        orderBy: { date: 'desc' },
        select: { date: true }
      });

      return {
        totalAmount: aggregates._sum.montant || 0,
        totalCount: aggregates._count || 0,
        averageAmount: aggregates._avg.montant || 0,
        maxAmount: aggregates._max.montant || 0,
        minAmount: aggregates._min.montant || 0,
        lastMovementDate: lastMovement?.date || null
      };
    } catch (error) {
      console.error('❌ Erreur getSummary:', error.message);
      throw error;
    }
  }

  /**
   * Génère un résumé par catégorie
   */
  async getCategorySummary(startDate, endDate) {
    try {
      const where = {
        date: {
          gte: new Date(startDate),
          lte: new Date(endDate)
        }
      };

      // Récupérer le total pour calculer les pourcentages
      const totalAggregate = await this.prisma.financialMovement.aggregate({
        where,
        _sum: { montant: true }
      });
      const totalAmount = totalAggregate._sum.montant || 0;

      // Grouper par catégorie
      const categoryGroups = await this.prisma.financialMovement.groupBy({
        by: ['categorieId'],
        where,
        _sum: { montant: true },
        _count: true
      });

      // Enrichir avec les détails des catégories
      const categorySummaries = await Promise.all(
        categoryGroups.map(async (group) => {
          const category = await this.prisma.movementCategory.findUnique({
            where: { id: group.categorieId }
          });

          const amount = group._sum.montant || 0;
          const percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0;

          return {
            categoryId: group.categorieId,
            categoryName: category?.name || 'Inconnue',
            categoryDisplayName: category?.displayName || 'Catégorie inconnue',
            categoryColor: category?.color || '#6B7280',
            categoryIcon: category?.icon || 'category',
            amount,
            count: group._count,
            percentage
          };
        })
      );

      return categorySummaries.sort((a, b) => b.amount - a.amount);
    } catch (error) {
      console.error('❌ Erreur getCategorySummary:', error.message);
      throw error;
    }
  }

  /**
   * Génère un résumé quotidien
   */
  async getDailySummary(startDate, endDate) {
    try {
      const movements = await this.prisma.financialMovement.findMany({
        where: {
          date: {
            gte: new Date(startDate),
            lte: new Date(endDate)
          }
        },
        select: {
          date: true,
          montant: true
        },
        orderBy: { date: 'asc' }
      });

      // Grouper par jour
      const dailyMap = new Map();
      
      movements.forEach(movement => {
        const dateKey = movement.date.toISOString().split('T')[0];
        if (!dailyMap.has(dateKey)) {
          dailyMap.set(dateKey, { amount: 0, count: 0 });
        }
        const day = dailyMap.get(dateKey);
        day.amount += movement.montant;
        day.count += 1;
      });

      // Convertir en tableau
      const dailySummaries = Array.from(dailyMap.entries()).map(([dateStr, data]) => ({
        date: dateStr,
        amount: data.amount,
        count: data.count
      }));

      return dailySummaries;
    } catch (error) {
      console.error('❌ Erreur getDailySummary:', error.message);
      throw error;
    }
  }

  /**
   * Exporte un rapport au format PDF
   */
  async exportToPdf(request) {
    try {
      const { startDate, endDate, title, categoryIds, includeDetails } = request;

      // Récupérer les données
      const [summary, categorySummary, movements] = await Promise.all([
        this.getSummary(startDate, endDate),
        this.getCategorySummary(startDate, endDate),
        includeDetails ? this.getDetailedMovements(startDate, endDate, categoryIds) : Promise.resolve([])
      ]);

      // Créer le document PDF
      const doc = new PDFDocument({ margin: 50 });
      
      // Créer le fichier temporaire
      const fileName = `rapport_mouvements_${Date.now()}.pdf`;
      const filePath = path.join(__dirname, '../../uploads', fileName);
      
      // Assurer que le dossier existe
      const uploadsDir = path.dirname(filePath);
      if (!fs.existsSync(uploadsDir)) {
        fs.mkdirSync(uploadsDir, { recursive: true });
      }

      const stream = fs.createWriteStream(filePath);
      doc.pipe(stream);

      // En-tête du rapport
      doc.fontSize(20).text(title, { align: 'center' });
      doc.moveDown();
      
      const startDateFormatted = new Date(startDate).toLocaleDateString('fr-FR');
      const endDateFormatted = new Date(endDate).toLocaleDateString('fr-FR');
      doc.fontSize(12).text(`Période: ${startDateFormatted} - ${endDateFormatted}`, { align: 'center' });
      doc.text(`Généré le: ${new Date().toLocaleDateString('fr-FR')} à ${new Date().toLocaleTimeString('fr-FR')}`, { align: 'center' });
      doc.moveDown(2);

      // Résumé général
      doc.fontSize(16).text('Résumé général', { underline: true });
      doc.moveDown();
      doc.fontSize(12);
      doc.text(`Nombre total de mouvements: ${summary.totalCount}`);
      doc.text(`Montant total: ${summary.totalAmount.toFixed(2)} FCFA`);
      doc.text(`Montant moyen: ${summary.averageAmount.toFixed(2)} FCFA`);
      doc.text(`Montant maximum: ${summary.maxAmount.toFixed(2)} FCFA`);
      doc.text(`Montant minimum: ${summary.minAmount.toFixed(2)} FCFA`);
      doc.moveDown(2);

      // Répartition par catégorie
      if (categorySummary.length > 0) {
        doc.fontSize(16).text('Répartition par catégorie', { underline: true });
        doc.moveDown();
        
        categorySummary.forEach(category => {
          doc.fontSize(12);
          doc.text(`${category.categoryDisplayName}:`);
          doc.text(`  Montant: ${category.amount.toFixed(2)} FCFA (${category.percentage.toFixed(1)}%)`);
          doc.text(`  Nombre: ${category.count} mouvements`);
          doc.moveDown(0.5);
        });
        doc.moveDown();
      }

      // Détails des mouvements si demandés
      if (includeDetails && movements.length > 0) {
        doc.addPage();
        doc.fontSize(16).text('Détail des mouvements', { underline: true });
        doc.moveDown();

        movements.forEach((movement, index) => {
          if (index > 0 && index % 15 === 0) {
            doc.addPage();
          }
          
          doc.fontSize(10);
          doc.text(`${movement.reference} - ${new Date(movement.date).toLocaleDateString('fr-FR')}`);
          doc.text(`${movement.description}`);
          doc.text(`Catégorie: ${movement.categorie?.displayName || 'N/A'}`);
          doc.text(`Montant: ${movement.montant.toFixed(2)} FCFA`);
          doc.text(`Utilisateur: ${movement.utilisateur?.nomUtilisateur || 'N/A'}`);
          doc.moveDown(0.5);
        });
      }

      doc.end();

      // Attendre que le fichier soit écrit
      await new Promise((resolve, reject) => {
        stream.on('finish', resolve);
        stream.on('error', reject);
      });

      return {
        filePath,
        fileName,
        downloadUrl: `/uploads/${fileName}`
      };

    } catch (error) {
      console.error('❌ Erreur exportToPdf:', error.message);
      throw error;
    }
  }

  /**
   * Exporte un rapport au format Excel
   */
  async exportToExcel(request) {
    try {
      const { startDate, endDate, title, categoryIds, includeDetails } = request;

      // Récupérer les données
      const [summary, categorySummary, movements] = await Promise.all([
        this.getSummary(startDate, endDate),
        this.getCategorySummary(startDate, endDate),
        includeDetails ? this.getDetailedMovements(startDate, endDate, categoryIds) : Promise.resolve([])
      ]);

      // Créer le classeur Excel
      const workbook = new ExcelJS.Workbook();
      workbook.creator = 'LOGESCO v2';
      workbook.created = new Date();

      // Feuille de résumé
      const summarySheet = workbook.addWorksheet('Résumé');
      
      // En-tête
      summarySheet.addRow([title]);
      summarySheet.getRow(1).font = { size: 16, bold: true };
      summarySheet.addRow([]);
      
      const startDateFormatted = new Date(startDate).toLocaleDateString('fr-FR');
      const endDateFormatted = new Date(endDate).toLocaleDateString('fr-FR');
      summarySheet.addRow([`Période: ${startDateFormatted} - ${endDateFormatted}`]);
      summarySheet.addRow([`Généré le: ${new Date().toLocaleDateString('fr-FR')} à ${new Date().toLocaleTimeString('fr-FR')}`]);
      summarySheet.addRow([]);

      // Résumé général
      summarySheet.addRow(['Résumé général']);
      summarySheet.getRow(6).font = { bold: true };
      summarySheet.addRow(['Nombre total de mouvements', summary.totalCount]);
      summarySheet.addRow(['Montant total (FCFA)', summary.totalAmount]);
      summarySheet.addRow(['Montant moyen (FCFA)', summary.averageAmount]);
      summarySheet.addRow(['Montant maximum (FCFA)', summary.maxAmount]);
      summarySheet.addRow(['Montant minimum (FCFA)', summary.minAmount]);
      summarySheet.addRow([]);

      // Répartition par catégorie
      if (categorySummary.length > 0) {
        summarySheet.addRow(['Répartition par catégorie']);
        summarySheet.getRow(summarySheet.rowCount).font = { bold: true };
        summarySheet.addRow(['Catégorie', 'Montant (FCFA)', 'Pourcentage (%)', 'Nombre de mouvements']);
        
        const headerRow = summarySheet.getRow(summarySheet.rowCount);
        headerRow.font = { bold: true };
        headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE6E6FA' } };

        categorySummary.forEach(category => {
          summarySheet.addRow([
            category.categoryDisplayName,
            category.amount,
            category.percentage,
            category.count
          ]);
        });
      }

      // Ajuster les largeurs des colonnes
      summarySheet.columns = [
        { width: 30 },
        { width: 20 },
        { width: 15 },
        { width: 20 }
      ];

      // Feuille de détails si demandée
      if (includeDetails && movements.length > 0) {
        const detailSheet = workbook.addWorksheet('Détail des mouvements');
        
        // En-têtes
        detailSheet.addRow([
          'Référence',
          'Date',
          'Description',
          'Catégorie',
          'Montant (FCFA)',
          'Utilisateur',
          'Notes'
        ]);
        
        const headerRow = detailSheet.getRow(1);
        headerRow.font = { bold: true };
        headerRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE6E6FA' } };

        // Données
        movements.forEach(movement => {
          detailSheet.addRow([
            movement.reference,
            new Date(movement.date).toLocaleDateString('fr-FR'),
            movement.description,
            movement.categorie?.displayName || 'N/A',
            movement.montant,
            movement.utilisateur?.nomUtilisateur || 'N/A',
            movement.notes || ''
          ]);
        });

        // Ajuster les largeurs des colonnes
        detailSheet.columns = [
          { width: 20 },
          { width: 12 },
          { width: 30 },
          { width: 20 },
          { width: 15 },
          { width: 20 },
          { width: 30 }
        ];
      }

      // Sauvegarder le fichier
      const fileName = `rapport_mouvements_${Date.now()}.xlsx`;
      const filePath = path.join(__dirname, '../../uploads', fileName);
      
      // Assurer que le dossier existe
      const uploadsDir = path.dirname(filePath);
      if (!fs.existsSync(uploadsDir)) {
        fs.mkdirSync(uploadsDir, { recursive: true });
      }

      await workbook.xlsx.writeFile(filePath);

      return {
        filePath,
        fileName,
        downloadUrl: `/uploads/${fileName}`
      };

    } catch (error) {
      console.error('❌ Erreur exportToExcel:', error.message);
      throw error;
    }
  }

  /**
   * Récupère les mouvements détaillés pour l'export
   */
  async getDetailedMovements(startDate, endDate, categoryIds = null) {
    try {
      const where = {
        date: {
          gte: new Date(startDate),
          lte: new Date(endDate)
        }
      };

      if (categoryIds && categoryIds.length > 0) {
        where.categorieId = { in: categoryIds };
      }

      const movements = await this.prisma.financialMovement.findMany({
        where,
        include: {
          categorie: true,
          utilisateur: {
            select: {
              id: true,
              nomUtilisateur: true,
              email: true
            }
          }
        },
        orderBy: { date: 'desc' }
      });

      return movements;
    } catch (error) {
      console.error('❌ Erreur getDetailedMovements:', error.message);
      throw error;
    }
  }
}

module.exports = MovementReportService;