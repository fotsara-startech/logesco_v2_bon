/**
 * Modèle pour les paramètres d'entreprise
 * Gestion des informations de base de l'entreprise
 */

const { PrismaClient } = require('../config/prisma-client.js');
const { BaseResponseDTO } = require('../dto');

class CompanySettingsModel {
  constructor() {
    this.prisma = new PrismaClient();
  }

  /**
   * Récupérer les paramètres d'entreprise
   * @returns {Promise<Object>} Paramètres d'entreprise ou null
   */
  async getSettings() {
    try {
      const settings = await this.prisma.parametresEntreprise.findFirst({
        orderBy: {
          dateCreation: 'desc'
        }
      });

      return settings;
    } catch (error) {
      console.error('Erreur lors de la récupération des paramètres:', error);
      throw new Error('Erreur lors de la récupération des paramètres d\'entreprise');
    }
  }

  /**
   * Créer ou mettre à jour les paramètres d'entreprise
   * @param {Object} data - Données des paramètres
   * @returns {Promise<Object>} Paramètres créés/mis à jour
   */
  async upsertSettings(data) {
    try {
      // Nettoyer le chemin du logo: extraire juste le nom du fichier
      let logoPath = data.logo || null;
      if (logoPath && logoPath.trim().length > 0) {
        // Extraire juste le nom du fichier du chemin complet
        // Gère les chemins Windows (C:\...\file.png) et Unix (/path/to/file.png)
        const fileName = logoPath.split(/[\\\/]/).pop();
        logoPath = fileName || logoPath;
        console.log(`📁 Logo path nettoyé: "${data.logo}" → "${logoPath}"`);
      }

      // Vérifier s'il existe déjà des paramètres
      const existingSettings = await this.prisma.parametresEntreprise.findFirst();

      if (existingSettings) {
        // Mettre à jour les paramètres existants
        return await this.prisma.parametresEntreprise.update({
          where: { id: existingSettings.id },
          data: {
            nomEntreprise: data.nomEntreprise,
            adresse: data.adresse,
            localisation: data.localisation || null,
            telephone: data.telephone || null,
            email: data.email || null,
            nuiRccm: data.nuiRccm || null,
            logo: logoPath,
            slogan: data.slogan || null,
            langueFacture: data.langueFacture || 'fr'
          }
        });
      } else {
        // Créer de nouveaux paramètres
        return await this.prisma.parametresEntreprise.create({
          data: {
            nomEntreprise: data.nomEntreprise,
            adresse: data.adresse,
            localisation: data.localisation || null,
            telephone: data.telephone || null,
            email: data.email || null,
            nuiRccm: data.nuiRccm || null,
            logo: logoPath,
            slogan: data.slogan || null,
            langueFacture: data.langueFacture || 'fr'
          }
        });
      }
    } catch (error) {
      console.error('Erreur lors de la sauvegarde des paramètres:', error);
      throw new Error('Erreur lors de la sauvegarde des paramètres d\'entreprise');
    }
  }

  /**
   * Valider les données des paramètres d'entreprise
   * @param {Object} data - Données à valider
   * @returns {Object} Résultat de validation
   */
  validateSettings(data) {
    const errors = [];

    // Validation du nom d'entreprise
    if (!data.nomEntreprise || data.nomEntreprise.trim().length === 0) {
      errors.push({
        field: 'nomEntreprise',
        message: 'Le nom de l\'entreprise est requis'
      });
    } else if (data.nomEntreprise.length > 100) {
      errors.push({
        field: 'nomEntreprise',
        message: 'Le nom de l\'entreprise ne peut pas dépasser 100 caractères'
      });
    }

    // Validation de l'adresse
    if (!data.adresse || data.adresse.trim().length === 0) {
      errors.push({
        field: 'adresse',
        message: 'L\'adresse est requise'
      });
    } else if (data.adresse.length > 500) {
      errors.push({
        field: 'adresse',
        message: 'L\'adresse ne peut pas dépasser 500 caractères'
      });
    }

    // Validation de l'email (optionnel)
    if (data.email && data.email.trim().length > 0) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(data.email)) {
        errors.push({
          field: 'email',
          message: 'Format d\'email invalide'
        });
      }
    }

    // Validation du téléphone (optionnel) - Accepte n'importe quel texte
    if (data.telephone && data.telephone.length > 50) {
      errors.push({
        field: 'telephone',
        message: 'Le téléphone ne peut pas dépasser 50 caractères'
      });
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Vérifier si les paramètres d'entreprise sont configurés
   * @returns {Promise<boolean>} True si configurés
   */
  async isConfigured() {
    try {
      const settings = await this.getSettings();
      return settings !== null;
    } catch (error) {
      console.error('Erreur lors de la vérification de configuration:', error);
      return false;
    }
  }

  /**
   * Fermer la connexion Prisma
   */
  async disconnect() {
    await this.prisma.$disconnect();
  }
}

module.exports = CompanySettingsModel;