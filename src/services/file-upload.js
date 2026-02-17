/**
 * Service pour l'upload et la gestion des fichiers justificatifs
 */

const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

class FileUploadService {
  constructor(prisma) {
    this.prisma = prisma;
    this.uploadDir = path.join(process.cwd(), 'uploads', 'movements');
    this.maxFileSize = 5 * 1024 * 1024; // 5MB
    this.allowedMimeTypes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'application/pdf',
      'image/webp'
    ];
    
    // Créer le dossier d'upload s'il n'existe pas
    this.ensureUploadDir();
  }

  /**
   * S'assure que le dossier d'upload existe
   */
  async ensureUploadDir() {
    try {
      await fs.access(this.uploadDir);
    } catch (error) {
      // Le dossier n'existe pas, le créer
      await fs.mkdir(this.uploadDir, { recursive: true });
      console.log(`📁 Dossier d'upload créé: ${this.uploadDir}`);
    }
  }

  /**
   * Génère un nom de fichier unique
   * @param {string} originalName - Nom original du fichier
   * @returns {string} Nom de fichier unique
   */
  generateUniqueFileName(originalName) {
    const ext = path.extname(originalName);
    const hash = crypto.randomBytes(16).toString('hex');
    const timestamp = Date.now();
    return `${timestamp}-${hash}${ext}`;
  }

  /**
   * Valide un fichier uploadé
   * @param {Object} file - Fichier à valider
   * @returns {boolean} Validation réussie
   */
  validateFile(file) {
    // Vérifier la taille
    if (file.size > this.maxFileSize) {
      throw new Error(`Fichier trop volumineux. Taille maximum: ${this.maxFileSize / 1024 / 1024}MB`);
    }

    // Vérifier le type MIME
    if (!this.allowedMimeTypes.includes(file.mimetype)) {
      throw new Error(`Type de fichier non autorisé. Types acceptés: ${this.allowedMimeTypes.join(', ')}`);
    }

    return true;
  }

  /**
   * Upload un fichier justificatif pour un mouvement
   * @param {number} movementId - ID du mouvement
   * @param {Object} file - Fichier à uploader
   * @returns {Promise<Object>} Attachment créé
   */
  async uploadAttachment(movementId, file) {
    try {
      // Vérifier que le mouvement existe
      const movement = await this.prisma.financialMovement.findUnique({
        where: { id: parseInt(movementId) }
      });

      if (!movement) {
        throw new Error('Mouvement financier non trouvé');
      }

      // Valider le fichier
      this.validateFile(file);

      // Générer un nom de fichier unique
      const fileName = this.generateUniqueFileName(file.originalname);
      const filePath = path.join(this.uploadDir, fileName);

      // Sauvegarder le fichier
      await fs.writeFile(filePath, file.buffer);

      // Créer l'enregistrement en base
      const attachment = await this.prisma.movementAttachment.create({
        data: {
          mouvementId: parseInt(movementId),
          fileName,
          originalName: file.originalname,
          mimeType: file.mimetype,
          fileSize: file.size,
          filePath: path.relative(process.cwd(), filePath)
        }
      });

      console.log(`✅ Fichier uploadé: ${file.originalname} -> ${fileName}`);
      return attachment;

    } catch (error) {
      console.error('❌ Erreur lors de l\'upload du fichier:', error.message);
      throw error;
    }
  }

  /**
   * Récupère un fichier justificatif
   * @param {number} attachmentId - ID de l'attachment
   * @returns {Promise<Object>} Informations du fichier
   */
  async getAttachment(attachmentId) {
    try {
      const attachment = await this.prisma.movementAttachment.findUnique({
        where: { id: parseInt(attachmentId) },
        include: {
          mouvement: {
            select: {
              id: true,
              reference: true,
              description: true
            }
          }
        }
      });

      if (!attachment) {
        throw new Error('Fichier justificatif non trouvé');
      }

      // Vérifier que le fichier existe sur le disque
      const fullPath = path.resolve(attachment.filePath);
      try {
        await fs.access(fullPath);
      } catch (error) {
        throw new Error('Fichier physique non trouvé sur le disque');
      }

      return {
        ...attachment,
        fullPath
      };

    } catch (error) {
      console.error('❌ Erreur lors de la récupération du fichier:', error.message);
      throw error;
    }
  }

  /**
   * Supprime un fichier justificatif
   * @param {number} attachmentId - ID de l'attachment
   * @returns {Promise<boolean>} Succès de la suppression
   */
  async deleteAttachment(attachmentId) {
    try {
      // Récupérer les informations du fichier
      const attachment = await this.getAttachment(attachmentId);

      // Supprimer le fichier physique
      try {
        await fs.unlink(attachment.fullPath);
        console.log(`🗑️ Fichier physique supprimé: ${attachment.fileName}`);
      } catch (error) {
        console.warn(`⚠️ Impossible de supprimer le fichier physique: ${error.message}`);
      }

      // Supprimer l'enregistrement en base
      await this.prisma.movementAttachment.delete({
        where: { id: parseInt(attachmentId) }
      });

      console.log(`✅ Fichier justificatif supprimé: ${attachment.originalName}`);
      return true;

    } catch (error) {
      console.error('❌ Erreur lors de la suppression du fichier:', error.message);
      throw error;
    }
  }

  /**
   * Récupère tous les attachments d'un mouvement
   * @param {number} movementId - ID du mouvement
   * @returns {Promise<Array>} Liste des attachments
   */
  async getMovementAttachments(movementId) {
    try {
      const attachments = await this.prisma.movementAttachment.findMany({
        where: { mouvementId: parseInt(movementId) },
        orderBy: { uploadedAt: 'desc' }
      });

      return attachments;

    } catch (error) {
      console.error('❌ Erreur lors de la récupération des attachments:', error.message);
      throw error;
    }
  }

  /**
   * Nettoie les fichiers orphelins (sans enregistrement en base)
   * @returns {Promise<Object>} Résultat du nettoyage
   */
  async cleanupOrphanedFiles() {
    try {
      // Lister tous les fichiers dans le dossier d'upload
      const files = await fs.readdir(this.uploadDir);
      
      // Récupérer tous les noms de fichiers en base
      const attachments = await this.prisma.movementAttachment.findMany({
        select: { fileName: true }
      });
      
      const dbFileNames = new Set(attachments.map(a => a.fileName));
      
      // Identifier les fichiers orphelins
      const orphanedFiles = files.filter(file => !dbFileNames.has(file));
      
      let deletedCount = 0;
      let errors = [];

      // Supprimer les fichiers orphelins
      for (const file of orphanedFiles) {
        try {
          await fs.unlink(path.join(this.uploadDir, file));
          deletedCount++;
          console.log(`🗑️ Fichier orphelin supprimé: ${file}`);
        } catch (error) {
          errors.push({ file, error: error.message });
          console.error(`❌ Erreur lors de la suppression de ${file}:`, error.message);
        }
      }

      return {
        totalFiles: files.length,
        orphanedFiles: orphanedFiles.length,
        deletedCount,
        errors
      };

    } catch (error) {
      console.error('❌ Erreur lors du nettoyage des fichiers:', error.message);
      throw error;
    }
  }

  /**
   * Calcule les statistiques de stockage
   * @returns {Promise<Object>} Statistiques de stockage
   */
  async getStorageStatistics() {
    try {
      // Statistiques de la base de données
      const [totalAttachments, totalSize] = await Promise.all([
        this.prisma.movementAttachment.count(),
        this.prisma.movementAttachment.aggregate({
          _sum: { fileSize: true }
        })
      ]);

      // Statistiques par type de fichier
      const typeStats = await this.prisma.movementAttachment.groupBy({
        by: ['mimeType'],
        _count: true,
        _sum: { fileSize: true }
      });

      return {
        totalAttachments,
        totalSize: totalSize._sum.fileSize || 0,
        averageSize: totalAttachments > 0 ? (totalSize._sum.fileSize || 0) / totalAttachments : 0,
        typeBreakdown: typeStats
      };

    } catch (error) {
      console.error('❌ Erreur lors du calcul des statistiques de stockage:', error.message);
      throw error;
    }
  }
}

module.exports = FileUploadService;