/**
 * Module à précharger (node -r) pour un poste 100 % local.
 *
 * Pourquoi : `src/server.js` charge `backend/.env` (dotenv) au démarrage. Le harnais retire CLOUD_DB_URL de
 * l'environnement d'un poste « sans cloud », mais dotenv la RÉINJECTE alors depuis `.env` : le poste se relie
 * silencieusement à la base Neon de développement (et y écrit). Définir la variable à une chaîne VIDE avant le
 * chargement de dotenv l'en empêche (dotenv n'écrase jamais une variable déjà présente) ; le service de
 * synchronisation lit alors une valeur vide = mode 100 % local.
 */
if (process.env.CLOUD_DB_URL === undefined) process.env.CLOUD_DB_URL = '';
