#!/usr/bin/env node

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const { PrismaClient } = require('@prisma/client');

async function testInventoryData() {
  const prisma = new PrismaClient();
  
  try {
    console.log('📊 TEST DIRECT PRISMA - Vérification des données\n');
    
    // Compter les produits actifs
    const totalActifs = await prisma.produit.count({
      where: { estActif: true }
    });
    
    // Compter avec stock inclus
    const produitsAvecStock = await prisma.produit.findMany({
      where: { estActif: true },
      include: { stock: true },
      take: 5
    });
    
    const avecStockCount = await prisma.produit.count({
      where: {
        estActif: true,
        stock: { isNot: null }
      }
    });
    
    console.log(`✅ Produits actifs total: ${totalActifs}`);
    console.log(`✅ Produits avec stock: ${avecStockCount}`);
    console.log(`\n📋 Premiers 5 produits avec leur stock:`);
    
    produitsAvecStock.forEach((prod, i) => {
      console.log(`\n${i+1}. ${prod.nom}`);
      console.log(`   - ID: ${prod.id}`);
      console.log(`   - Stock: ${prod.stock ? '✓ Initié' : '✗ Pas de stock'}`);
      if (prod.stock) {
        console.log(`   - Quantité: ${prod.stock.quantiteDisponible}`);
      }
    });
    
    // Test pagination comme dans le vrai endpoint
    const paginated = await prisma.produit.findMany({
      where: { estActif: true },
      include: { stock: true },
      take: 20,
      skip: 0
    });
    
    const totalCount = await prisma.produit.count({
      where: { estActif: true }
    });
    
    console.log(`\n\n📄 Résultat pagination (page 1, limit 20):`);
    console.log(`   - Total products: ${totalCount}`);
    console.log(`   - Page 1 results: ${paginated.length}`);
    console.log(`   - Expected pages: ${Math.ceil(totalCount / 20)}`);
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testInventoryData();
