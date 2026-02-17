const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function addTestTransactions() {
  try {
    console.log('🚀 Ajout de transactions de test...');

    // Vérifier s'il y a des clients
    const clients = await prisma.client.findMany();
    if (clients.length === 0) {
      console.log('❌ Aucun client trouvé. Créons d\'abord un client de test.');
      
      const testClient = await prisma.client.create({
        data: {
          nom: 'TCHIROMA',
          prenom: 'ISSA',
          telephone: '6845125720',
          email: 'issa@gmail.com',
          adresse: 'DOUALA'
        }
      });
      
      console.log(`✅ Client de test créé: ${testClient.nom} ${testClient.prenom}`);
      clients.push(testClient);
    }

    // Créer ou récupérer le compte client
    for (const client of clients) {
      let compte = await prisma.compteClient.findUnique({
        where: { clientId: client.id }
      });

      if (!compte) {
        compte = await prisma.compteClient.create({
          data: {
            clientId: client.id,
            soldeActuel: 0,
            limiteCredit: 100000
          }
        });
        console.log(`✅ Compte créé pour ${client.nom} ${client.prenom}`);
      }

      // Créer des transactions de test
      const transactions = [
        {
          typeCompte: 'client',
          compteId: client.id,
          typeTransaction: 'CREDIT',
          montant: 50000,
          description: 'Paiement initial',
          dateTransaction: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), // Il y a 10 jours
          soldeApres: 50000
        },
        {
          typeCompte: 'client',
          compteId: client.id,
          typeTransaction: 'DEBIT',
          montant: 25000,
          description: 'Achat de marchandises',
          referenceType: 'vente',
          referenceId: 1,
          dateTransaction: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // Il y a 7 jours
          soldeApres: 25000
        },
        {
          typeCompte: 'client',
          compteId: client.id,
          typeTransaction: 'CREDIT',
          montant: 30000,
          description: 'Paiement partiel',
          dateTransaction: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), // Il y a 3 jours
          soldeApres: 55000
        },
        {
          typeCompte: 'client',
          compteId: client.id,
          typeTransaction: 'DEBIT',
          montant: 15000,
          description: 'Nouvelle commande',
          referenceType: 'vente',
          referenceId: 2,
          dateTransaction: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // Hier
          soldeApres: 40000
        }
      ];

      for (const transaction of transactions) {
        await prisma.transactionCompte.create({
          data: transaction
        });
        console.log(`✅ Transaction créée: ${transaction.typeTransaction} ${transaction.montant} FCFA`);
      }

      // Mettre à jour le solde du compte
      await prisma.compteClient.update({
        where: { clientId: client.id },
        data: { soldeActuel: 40000 }
      });
    }

    console.log('🎉 Transactions de test ajoutées avec succès !');

  } catch (error) {
    console.error('❌ Erreur lors de l\'ajout des transactions:', error);
  } finally {
    await prisma.$disconnect();
  }
}

addTestTransactions();