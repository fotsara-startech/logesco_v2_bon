const axios = require('axios');

const API_URL = 'http://localhost:8080/api/v1';

async function testPayment() {
  try {
    // 1. Login
    console.log('🔐 Connexion...');
    const loginRes = await axios.post(`${API_URL}/auth/login`, {
      nomUtilisateur: 'admin',
      motDePasse: 'Admin@2024'
    });
    
    const token = loginRes.data.data.token;
    console.log('✅ Connecté\n');

    // 2. Récupérer les fournisseurs
    console.log('📋 Récupération des fournisseurs...');
    const suppliersRes = await axios.get(`${API_URL}/suppliers`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    const supplier = suppliersRes.data.data[0];
    console.log(`✅ Fournisseur: ${supplier.nom} (ID: ${supplier.id})\n`);

    // 3. Récupérer les commandes impayées
    console.log('📦 Récupération des commandes impayées...');
    const procurementsRes = await axios.get(`${API_URL}/procurement/unpaid/${supplier.id}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    if (procurementsRes.data.data.length === 0) {
      console.log('⚠️ Aucune commande impayée\n');
      return;
    }
    
    const procurement = procurementsRes.data.data[0];
    console.log(`✅ Commande: ${procurement.reference}`);
    console.log(`   Montant restant: ${procurement.montantRestant} FCFA\n`);

    // 4. Effectuer le paiement avec mouvement financier
    con