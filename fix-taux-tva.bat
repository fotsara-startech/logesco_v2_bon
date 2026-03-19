@echo off
echo ========================================
echo  Correction du taux TVA en base de donnees
echo  19 -> 19.25
echo ========================================
echo.

cd /d "%~dp0backend"

node -e "
const { PrismaClient } = require('./src/config/prisma-client.js');
const prisma = new PrismaClient();

async function fix() {
  const settings = await prisma.parametresEntreprise.findFirst();
  if (!settings) { console.log('Aucun parametre trouve'); return; }
  
  console.log('Valeur actuelle tauxTva:', settings.tauxTva);
  
  if (settings.tauxTva === 19 || settings.tauxTva === 19.0) {
    const updated = await prisma.parametresEntreprise.update({
      where: { id: settings.id },
      data: { tauxTva: 19.25 }
    });
    console.log('Corrige! Nouvelle valeur:', updated.tauxTva);
  } else {
    console.log('Valeur OK, pas de correction necessaire:', settings.tauxTva);
  }
  
  await prisma.$disconnect();
}

fix().catch(e => { console.error(e); process.exit(1); });
"

echo.
echo Termine. Redemarrez le backend.
pause
