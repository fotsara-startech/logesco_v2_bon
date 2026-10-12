/**
 * Rend les requêtes directes de vérification (cloud-admin.requete) tolérantes aux coupures réseau passagères du PC
 * de test (« Connection terminated due to connection timeout », ETIMEDOUT, ENOTFOUND) : jusqu'à 6 essais espacés.
 * À charger AVANT oracle.js et campagne.js (ils s'y raccrochent à leur chargement). N'altère pas cloud-admin.js.
 */
const admin = require('./cloud-admin');
const origine = admin.requete;
if (!origine.__avecReprises) {
  const reseau = /timeout|ETIMEDOUT|ENOTFOUND|ECONNRESET|terminated|EAI_AGAIN/i;
  const avec = async (...args) => {
    let derniere;
    for (let i = 0; i < 6; i++) {
      try { return await origine(...args); } catch (e) {
        derniere = e;
        if (!reseau.test(`${e.code || ''} ${e.message}`)) throw e;
        await new Promise((r) => setTimeout(r, 3000 * (i + 1)));
      }
    }
    throw derniere;
  };
  avec.__avecReprises = true;
  admin.requete = avec;
}
