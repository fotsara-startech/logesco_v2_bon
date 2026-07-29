#!/usr/bin/env node
/**
 * Script pour vérifier la cohérence du schéma entre SQLite et Neon
 */

const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

async function verifySchema() {
  console.log('🔍 Vérification de la cohérence du schéma SQLite vs Neon...\n');

  // Créer deux clients Prisma - un pour SQLite, un pour Neon
  const localPrisma = new PrismaClient({
    datasources: {
      db: {
        url: process.env.DATABASE_URL || 'file:./database/logesco.db'
      }
    }
  });

  let cloudPrisma = null;
  if (process.env.CLOUD_DB_URL) {
    cloudPrisma = new PrismaClient({
      datasources: {
        db: {
          url: process.env.CLOUD_DB_URL
        }
      }
    });
  }

  try {
    // 1. Vérifier la table Ventes localement
    console.log('📦 VENTES TABLE SCHEMA:');
    const localVentes = await localPrisma.vente.findMany({
      take: 1,
      include: {
        client: true,
        vendeur: true,
        details: { include: { produit: true } }
      }
    });

    if (localVentes.length > 0) {
      console.log('✅ Sample vente locale:');
      console.log(JSON.stringify(localVentes[0], null, 2));
    } else {
      console.log('⚠️ Aucune vente trouvée localement');
    }

    // 2. Vérifier le schéma brut (colonnes)
    console.log('\n📋 COLONNES DE LA TABLE VENTES (SQLite):');
    const columns = await localPrisma.$queryRaw`
      PRAGMA table_info(ventes)
    `;
    columns.forEach(col => {
      console.log(`  - ${col.name}: ${col.type}`);
    });

    // 3. Vérifier sur Neon si disponible
    if (cloudPrisma) {
      console.log('\n☁️  VENTES TABLE SCHEMA (NEON):');
      const cloudVentes = await cloudPrisma.vente.findMany({
        take: 1,
        include: {
          client: true,
          vendeur: true,
          details: { include: { produit: true } }
        }
      });

      if (cloudVentes.length > 0) {
        console.log('✅ Sample vente cloud:');
        console.log(JSON.stringify(cloudVentes[0], null, 2));
      } else {
        console.log('⚠️ Aucune vente trouvée dans le cloud');
      }

      console.log('\n📋 COLONNES DE LA TABLE VENTES (PostgreSQL):');
      const pgColumns = await cloudPrisma.$queryRaw`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'ventes'
        ORDER BY ordinal_position
      `;
      pgColumns.forEach(col => {
        console.log(`  - ${col.column_name}: ${col.data_type}`);
      });

      // 4. Comparer les colonnes
      console.log('\n🔄 COMPARAISON:');
      const localColNames = new Set(columns.map(c => c.name));
      const cloudColNames = new Set(pgColumns.map(c => c.column_name));

      const missingInCloud = [...localColNames].filter(c => !cloudColNames.has(c));
      const missingInLocal = [...cloudColNames].filter(c => !localColNames.has(c));

      if (missingInCloud.length > 0) {
        console.log('❌ COLONNES MANQUANTES DANS NEON:', missingInCloud);
      }
      if (missingInLocal.length > 0) {
        console.log('❌ COLONNES MANQUANTES LOCALEMENT:', missingInLocal);
      }
      if (missingInCloud.length === 0 && missingInLocal.length === 0) {
        console.log('✅ Les schémas sont identiques!');
      }
    } else {
      console.log('\n⚠️ CLOUD_DB_URL non configurée, impossible de comparer');
    }

    // 5. Vérifier le nombre total de ventes
    console.log('\n📊 STATISTIQUES:');
    const localCount = await localPrisma.vente.count();
    console.log(`  Ventes locales: ${localCount}`);

    if (cloudPrisma) {
      const cloudCount = await cloudPrisma.vente.count();
      console.log(`  Ventes cloud: ${cloudCount}`);
    }

  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await localPrisma.$disconnect();
    if (cloudPrisma) await cloudPrisma.$disconnect();
  }
}

verifySchema();
