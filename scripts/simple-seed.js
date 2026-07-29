#!/usr/bin/env node
/**
 * Seed simple pour créer une boutique et quelques ventes de test
 * Pas de dépendances externes, juste Prisma
 */

const { PrismaClient } = require('@prisma/client');

async function main() {
  const prisma = new PrismaClient();

  try {
    console.log('🌱 Création des données de test...\n');

    // 1. Créer une boutique
    const boutique = await prisma.boutique.create({
      data: {
        nom: 'Boutique Test',
        adresse: 'Rue Test, 123',
        telephone: '+226 12345678',
        email: 'boutique@test.com',
        isActive: true,
        dateCreation: new Date(),
      },
    });
    console.log('✅ Boutique créée:', boutique.nom);

    // 2. Créer un utilisateur/vendeur
    const vendeur = await prisma.utilisateur.create({
      data: {
        nomUtilisateur: 'vendeur_test',
        email: 'vendeur@test.com',
        motDePasse: 'hashedPassword123',
        role: 'vendeur',
        prenomNom: 'Vendeur Test',
        isActive: true,
        dateCreation: new Date(),
      },
    });
    console.log('✅ Vendeur créé:', vendeur.nomUtilisateur);

    // 3. Créer un client
    const client = await prisma.client.create({
      data: {
        nom: 'Client Test',
        prenom: 'Jean',
        telephone: '+226 98765432',
        adresse: 'Adresse Client',
        isActive: true,
        dateCreation: new Date(),
      },
    });
    console.log('✅ Client créé:', client.nom);

    // 4. Créer un produit
    const produit = await prisma.produit.create({
      data: {
        reference: 'PROD001',
        nom: 'Produit Test',
        description: 'Description du produit test',
        prixUnitaire: 5000,
        prixAchat: 3000,
        codeBarre: 'BAR001',
        estService: false,
        remiseMaxAutorisee: 1000,
        seuiStockMinimum: 5,
  