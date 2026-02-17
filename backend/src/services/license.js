const { PrismaClient } = require('../config/prisma-client.js');
const crypto = require('crypto');

/**
 * Service de gestion des licences
 */
class LicenseService {
  constructor(prisma) {
    this.prisma = prisma || new PrismaClient();
  }

  /**
   * Génère une nouvelle licence
   */
  async generateLicense(data) {
    const {
      userId,
      subscriptionType,
      deviceFingerprint,
      expiresAt,
      metadata = {}
    } = data;

    const licenseKey = this.generateLicenseKey();
    const signature = this.createSignature(licenseKey, userId, subscriptionType);

    const license = await this.prisma.license.create({
      data: {
        licenseKey,
        userId,
        subscriptionType,
        deviceFingerprint,
        expiresAt: new Date(expiresAt),
        signature,
        metadata: JSON.stringify(metadata)
      },
      include: {
        activations: true,
        auditLogs: true
      }
    });

    await this.createAuditLog(license.id, 'GENERATED', {
      subscriptionType,
      expiresAt,
      deviceFingerprint
    });

    return license;
  }

  /**
   * Valide une licence
   */
  async validateLicense(licenseKey, deviceFingerprint) {
    const license = await this.prisma.license.findUnique({
      where: { licenseKey },
      include: {
        activations: true,
        auditLogs: true
      }
    });

    if (!license) {
      throw new Error('Licence non trouvée');
    }

    const validationResult = {
      isValid: false,
      license,
      errors: []
    };

    if (license.isRevoked) {
      validationResult.errors.push('Licence révoquée');
    }

    if (!license.isActive) {
      validationResult.errors.push('Licence inactive');
    }

    if (new Date() > license.expiresAt) {
      validationResult.errors.push('Licence expirée');
    }

    if (deviceFingerprint && license.deviceFingerprint && 
        license.deviceFingerprint !== deviceFingerprint) {
      validationResult.errors.push('Appareil non autorisé');
    }

    validationResult.isValid = validationResult.errors.length === 0;

    if (validationResult.isValid) {
      await this.prisma.license.update({
        where: { id: license.id },
        data: {
          lastValidatedAt: new Date(),
          validationCount: { increment: 1 }
        }
      });

      await this.createAuditLog(license.id, 'VALIDATED', {
        deviceFingerprint,
        validationCount: license.validationCount + 1
      });
    }

    return validationResult;
  }

  /**
   * Révoque une licence
   */
  async revokeLicense(licenseKey, reason, performedBy) {
    const license = await this.prisma.license.update({
      where: { licenseKey },
      data: {
        isRevoked: true,
        revokedAt: new Date(),
        revokedReason: reason
      }
    });

    await this.createAuditLog(license.id, 'REVOKED', {
      reason,
      performedBy
    }, performedBy);

    return license;
  }

  /**
   * Génère une clé de licence unique (16 caractères)
   */
  generateLicenseKey() {
    // CORRECTION: Réduction de la longueur des clés à 16 caractères
    // 4 segments de 2 bytes chacun = 16 caractères hex au total
    const segments = [];
    for (let i = 0; i < 4; i++) {
      segments.push(crypto.randomBytes(2).toString('hex').toUpperCase());
    }
    return segments.join('-');
  }

  /**
   * Crée une signature cryptographique
   */
  createSignature(licenseKey, userId, subscriptionType) {
    const data = `${licenseKey}:${userId}:${subscriptionType}`;
    return crypto.createHash('sha256').update(data).digest('hex');
  }

  /**
   * Crée un log d'audit
   */
  async createAuditLog(licenseId, action, details, performedBy = 'SYSTEM') {
    return await this.prisma.licenseAuditLog.create({
      data: {
        licenseId,
        action,
        details: JSON.stringify(details),
        performedBy
      }
    });
  }

  /**
   * Récupère toutes les licences avec filtres
   */
  async getLicenses(filters = {}) {
    const {
      userId,
      subscriptionType,
      isActive,
      isRevoked,
      page = 1,
      limit = 50
    } = filters;

    const where = {};
    
    if (userId) where.userId = userId;
    if (subscriptionType) where.subscriptionType = subscriptionType;
    if (isActive !== undefined) where.isActive = isActive;
    if (isRevoked !== undefined) where.isRevoked = isRevoked;

    const [licenses, total] = await Promise.all([
      this.prisma.license.findMany({
        where,
        include: {
          activations: {
            orderBy: { activatedAt: 'desc' },
            take: 5
          },
          auditLogs: {
            orderBy: { timestamp: 'desc' },
            take: 10
          },
          _count: {
            select: {
              activations: true,
              auditLogs: true
            }
          }
        },
        orderBy: { dateCreation: 'desc' },
        skip: (page - 1) * limit,
        take: limit
      }),
      this.prisma.license.count({ where })
    ]);

    return {
      licenses,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    };
  }

  /**
   * Récupère les statistiques des licences
   */
  async getLicenseStats() {
    const [
      totalLicenses,
      activeLicenses,
      revokedLicenses,
      expiredLicenses,
      subscriptionStats
    ] = await Promise.all([
      this.prisma.license.count(),
      this.prisma.license.count({ where: { isActive: true, isRevoked: false } }),
      this.prisma.license.count({ where: { isRevoked: true } }),
      this.prisma.license.count({ 
        where: { 
          expiresAt: { lt: new Date() },
          isRevoked: false 
        } 
      }),
      this.prisma.license.groupBy({
        by: ['subscriptionType'],
        _count: { subscriptionType: true }
      })
    ]);

    return {
      total: totalLicenses,
      active: activeLicenses,
      revoked: revokedLicenses,
      expired: expiredLicenses,
      bySubscriptionType: subscriptionStats.reduce((acc, stat) => {
        acc[stat.subscriptionType] = stat._count.subscriptionType;
        return acc;
      }, {})
    };
  }
}

module.exports = LicenseService;
