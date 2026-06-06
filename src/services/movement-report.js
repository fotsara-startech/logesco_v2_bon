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
   * Converts any date value to a comparable string for SQLite
   * SQLite stores dates inconsistently — this normalizes for raw SQL comparison
   */
  _toSqliteDate(dateInput) {
    const d = new Date(dateInput);
    return d.toISOString();
  }

  /**
   * Génère un résumé des mouvements pour une période
   */
  async getSummary(startDate, endDate, boutiqueId = null) {
    try {
      const start = this._toSqliteDate(startDate);
      const end = this._toSqliteDate(endDate);

      // Use raw SQL to handle both ISO and non-ISO date formats in SQLite
      const boutiqueFilter = boutiqueId ? `AND boutique_id = ${parseInt(boutiqueId)}` : '';
      const rows = await this.prisma.$queryRawUnsafe(
        `SELECT montant, date FROM financial_movements 
         WHERE datetime(date) >= datetime(?) AND datetime(date) <= datetime(?) ${boutiqueFilter}`,
        start, end
      );

      const totalAmount = rows.reduce((sum, r) => sum + (parseFloat(r.montant) || 0), 0);
      const totalCount = rows.length;
      const avgAmount = totalCount > 0 ? totalAmount / totalCount : 0;
      const amounts = rows.map(r => parseFloat(r.montant) || 0);
      const maxAmount = amounts.length > 0 ? Math.max(...amounts) : 0;
      const minAmount = amounts.length > 0 ? Math.min(...amounts) : 0;

      const lastRow = rows.length > 0
        ? rows.reduce((latest, r) => new Date(r.date) > new Date(latest.date) ? r : latest)
        : null;

      return {
        totalAmount,
        totalCount,
        averageAmount: avgAmount,
        maxAmount,
        minAmount,
        lastMovementDate: lastRow ? new Date(lastRow.date) : null
      };
    } catch (error) {
      console.error('❌ Erreur getSummary:', error.message);
      throw error;
    }
  }

  /**
   * Génère un résumé par catégorie
   */
  async getCategorySummary(startDate, endDate, boutiqueId = null) {
    try {
      const start = this._toSqliteDate(startDate);
      const end = this._toSqliteDate(endDate);
      const boutiqueFilter = boutiqueId ? `AND fm.boutique_id = ${parseInt(boutiqueId)}` : '';

      const rows = await this.prisma.$queryRawUnsafe(
        `SELECT fm.categorie_id, fm.montant, mc.nom, mc.display_name, mc.color, mc.icon
         FROM financial_movements fm
         LEFT JOIN movement_categories mc ON fm.categorie_id = mc.id
         WHERE datetime(fm.date) >= datetime(?) AND datetime(fm.date) <= datetime(?) ${boutiqueFilter}`,
        start, end
      );

      // Group by category
      const categoryMap = new Map();
      let totalAmount = 0;

      rows.forEach(r => {
        const catId = typeof r.categorie_id === 'bigint' ? Number(r.categorie_id) : r.categorie_id;
        const montant = parseFloat(r.montant) || 0;
        totalAmount += montant;

        if (!categoryMap.has(catId)) {
          categoryMap.set(catId, {
            categoryId: catId,
            categoryName: r.nom || 'Inconnue',
            categoryDisplayName: r.display_name || r.nom || 'Catégorie inconnue',
            categoryColor: r.color || '#6B7280',
            categoryIcon: r.icon || 'category',
            amount: 0,
            count: 0
          });
        }
        const cat = categoryMap.get(catId);
        cat.amount += montant;
        cat.count += 1;
      });

      const categorySummaries = Array.from(categoryMap.values()).map(cat => ({
        ...cat,
        percentage: totalAmount > 0 ? (cat.amount / totalAmount) * 100 : 0
      }));

      return categorySummaries.sort((a, b) => b.amount - a.amount);
    } catch (error) {
      console.error('❌ Erreur getCategorySummary:', error.message);
      throw error;
    }
  }

  /**
   * Génère un résumé quotidien
   */
  async getDailySummary(startDate, endDate, boutiqueId = null) {
    try {
      const start = this._toSqliteDate(startDate);
      const end = this._toSqliteDate(endDate);
      const boutiqueFilter = boutiqueId ? `AND boutique_id = ${parseInt(boutiqueId)}` : '';

      const rows = await this.prisma.$queryRawUnsafe(
        `SELECT date, montant FROM financial_movements
         WHERE datetime(date) >= datetime(?) AND datetime(date) <= datetime(?) ${boutiqueFilter}
         ORDER BY datetime(date) ASC`,
        start, end
      );

      const dailyMap = new Map();
      rows.forEach(r => {
        const d = new Date(r.date);
        const dateKey = isNaN(d.getTime()) ? r.date.substring(0, 10) : d.toISOString().split('T')[0];
        if (!dailyMap.has(dateKey)) dailyMap.set(dateKey, { amount: 0, count: 0 });
        const day = dailyMap.get(dateKey);
        day.amount += parseFloat(r.montant) || 0;
        day.count += 1;
      });

      return Array.from(dailyMap.entries()).map(([dateStr, data]) => ({
        date: dateStr,
        amount: data.amount,
        count: data.count
      }));
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