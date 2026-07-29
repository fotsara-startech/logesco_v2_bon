#!/usr/bin/env node
/**
 * Vérifier les ventes dans la base embarquée
 */

const { PrismaClient } = require('@prisma/client');
const path = require('path');

const dbPath = path.join(
  process.env.LOCALAPPDATA || 'C:\\Users\\Default\\AppData\\Local',
  'LOGESCO',
  'backend',
  'database',
  'logesco.db'
);

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: `file:${dbPath.replace(/\\/g, '/')}`
    }
  }
});

async function main() {
  console.log(`📊 Vérification de la base: ${dbPath}\n`);

  const total = await prisma.vente.count();
  console.log(`Total ventes: ${total}`);

  const byBoutique = await prisma.vente.groupBy({
    by: ['boutiqueId'],
    _count: true
  });

  console.log('\nPar boutique:');
  byBoutique.forEach(b => {
    console.log(`  Boutique ${b.boutiqueId || 'NULL'}: ${b._count} ventes`);
  });

  const boutiques = await prisma.boutique.findMany({
    select: { id: true, nom: true }
  });

  console.log('\nBoutiques disponibles:');
  boutiques.forEach(b => {
    console.log(`  ${b.id}: ${b.nom}`);
  });

  const recentSales = await prisma.vente.findMany({
    take: 5,
    orderBy: { id: 'desc' },
    select: {
      id: true,
      numeroVente: true,
      boutiqueId: true,
      montantTotal: true,
      dateVente: true
    }
  });

  console.log('\n5 dernières ventes:');
  recentSales.forEach(s => {
    console.log(`  ${s.numeroVente} - Boutique ${s.boutiqueId} - ${s.montantTotal} FCFA`);
  });

  await prisma.$disconnect();
}

main().catch(console.error);
