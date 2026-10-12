/**
 * Module préchargé dans le poste (node -r) : dévie les connexions TCP sortantes vers le port 5432 (PostgreSQL / Neon)
 * vers le banc de pannes local (LOGESCO_FAULT_PROXY_PORT). Le nom d'hôte d'origine reste intact dans l'appelant : la
 * bibliothèque pg l'utilise comme SNI pour le TLS, qui reste donc de bout en bout avec Neon.
 */
const net = require('node:net');

const PORT_BANC = parseInt(process.env.LOGESCO_FAULT_PROXY_PORT, 10);
const PORT_CIBLE = 5432;

if (PORT_BANC) {
  const estLocal = (h) => !h || h === 'localhost' || h === '127.0.0.1' || h === '::1';
  const devie = (o) => (o && typeof o === 'object' && Number(o.port) === PORT_CIBLE && !estLocal(o.host) ? { ...o, host: '127.0.0.1', port: PORT_BANC } : o);
  const original = net.Socket.prototype.connect;

  net.Socket.prototype.connect = function connecteDevie(...args) {
    const a0 = args[0];
    if (Array.isArray(a0)) {
      // forme normalisée interne de net.connect() : on remplace l'élément en place (le tableau garde son marqueur)
      a0[0] = devie(a0[0]);
    } else if (a0 && typeof a0 === 'object') {
      args[0] = devie(a0);
    } else if (Number(a0) === PORT_CIBLE && typeof args[1] === 'string' && !estLocal(args[1])) {
      args[0] = PORT_BANC;
      args[1] = '127.0.0.1';
    }
    return original.apply(this, args);
  };
}
