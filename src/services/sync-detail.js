/**
 * Détail lisible des éléments non synchronisés.
 *
 * L'écran de synchronisation ne montrait que « Stock boutiques : 2 élément(s) ».
 * Ce module décrit chaque élément en clair (quel produit, quelle boutique, quelle
 * quantité, quelle vente...) et traduit l'erreur technique en une explication
 * et une action, pour qu'un blocage se comprenne sans lire les journaux.
 */

// ── Libellés ────────────────────────────────────────────────────────────────

const TABLE_LABELS = {
  produits: 'Produit',
  categories: 'Catégorie',
  stock: 'Stock global',
  stock_boutiques: 'Stock boutique',
  mouvements_stock: 'Mouvement de stock',
  ventes: 'Vente',
  details_ventes: 'Ligne de vente',
  clients: 'Client',
  fournisseurs: 'Fournisseur',
  comptes_clients: 'Compte client',
  comptes_fournisseurs: 'Compte fournisseur',
  transactions_comptes: 'Écriture de compte',
  cash_registers: 'Caisse',
  cash_sessions: 'Session de caisse',
  cash_movements: 'Mouvement de caisse',
  financial_movements: 'Mouvement financier',
  commandes_approvisionnement: 'Commande fournisseur',
  details_commandes_approvisionnement: 'Ligne de commande',
  boutiques: 'Boutique',
  utilisateurs: 'Utilisateur',
  user_roles: 'Rôle',
  user_boutique_assignments: 'Affectation de boutique',
  historique_prix_achat: 'Historique de prix d\'achat',
  parametres_entreprise: 'Paramètres de l\'entreprise',
};

const OPERATION_LABELS = { INSERT: 'Création', UPDATE: 'Modification', DELETE: 'Suppression' };

// Noms de colonnes → mots courants (pour expliquer une contrainte d'unicité).
// [mot, féminin ?] : "la même boutique", "le même produit"
const COLUMN_WORDS = {
  boutique_id: ['boutique', true],
  produit_id: ['produit', false],
  client_id: ['client', false],
  fournisseur_id: ['fournisseur', false],
  nom: ['nom', false],
  nom_utilisateur: ["nom d'utilisateur", false],
  numero_vente: ['numéro de vente', false],
  numero_commande: ['numéro de commande', false],
  reference: ['référence', true],
  email: ['e-mail', false],
  code_barre: ['code-barres', false],
};

function tableLabel(table) {
  return TABLE_LABELS[table] || table;
}

// ── Description d'un enregistrement ────────────────────────────────────────

function fmtNumber(v) {
  const n = Number(v);
  if (!Number.isFinite(n)) return String(v);
  return Number.isInteger(n) ? String(n) : n.toFixed(2);
}

/**
 * Cherche une valeur dans la base locale (nom d'un produit, d'une boutique...).
 * Ne lève jamais : un enregistrement supprimé ou une table absente → null.
 */
async function lookup(localPrisma, table, id, columns) {
  if (id === null || id === undefined) return null;
  try {
    const rows = await localPrisma.$queryRawUnsafe(`SELECT ${columns.map((c) => `"${c}"`).join(', ')} FROM "${table}" WHERE id = ? LIMIT 1`, id);
    return rows[0] || null;
  } catch (_) {
    return null;
  }
}

async function nameOf(localPrisma, table, id, column = 'nom') {
  const row = await lookup(localPrisma, table, id, [column]);
  return row ? row[column] : null;
}

/**
 * Décrit en une ligne l'enregistrement concerné par une opération.
 * `data` est le contenu de l'opération (snake_case ou camelCase).
 */
async function describeRecord(localPrisma, table, data, recordId) {
  const d = data || {};
  const get = (...keys) => {
    for (const k of keys) {
      if (d[k] !== undefined && d[k] !== null && d[k] !== '') return d[k];
    }
    return null;
  };
  const camel = (s) => s.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
  const val = (snake) => get(snake, camel(snake));

  const produitId = val('produit_id');
  const boutiqueId = val('boutique_id');
  const clientId = val('client_id');

  const produitNom = produitId !== null ? await nameOf(localPrisma, 'produits', produitId) : null;
  const boutiqueNom = boutiqueId !== null ? await nameOf(localPrisma, 'boutiques', boutiqueId) : null;

  const parts = [];
  switch (table) {
    case 'produits':
      parts.push(val('nom') || `Produit n° ${recordId}`);
      if (val('reference')) parts.push(`réf. ${val('reference')}`);
      if (val('prix_unitaire') !== null) parts.push(`prix ${fmtNumber(val('prix_unitaire'))} FCFA`);
      break;
    case 'stock':
    case 'stock_boutiques':
      parts.push(produitNom || `Produit n° ${produitId}`);
      if (table === 'stock_boutiques') parts.push(boutiqueNom ? `boutique ${boutiqueNom}` : `boutique n° ${boutiqueId}`);
      if (val('quantite_disponible') !== null) parts.push(`quantité ${fmtNumber(val('quantite_disponible'))}`);
      break;
    case 'mouvements_stock':
      parts.push(produitNom || `Produit n° ${produitId}`);
      parts.push(`${val('type_mouvement') || 'mouvement'} ${val('changement_quantite') > 0 ? '+' : ''}${fmtNumber(val('changement_quantite') ?? 0)}`);
      if (val('stock_final') !== null) parts.push(`stock après : ${fmtNumber(val('stock_final'))}`);
      break;
    case 'ventes': {
      parts.push(val('numero_vente') || `Vente n° ${recordId}`);
      if (val('montant_total') !== null) parts.push(`${fmtNumber(val('montant_total'))} FCFA`);
      const nomClient = clientId !== null ? await nameOf(localPrisma, 'clients', clientId) : null;
      if (nomClient) parts.push(`client ${nomClient}`);
      break;
    }
    case 'details_ventes':
      parts.push(produitNom || `Produit n° ${produitId}`);
      if (val('quantite') !== null) parts.push(`quantité ${fmtNumber(val('quantite'))}`);
      if (val('prix_total') !== null) parts.push(`${fmtNumber(val('prix_total'))} FCFA`);
      if (val('vente_id') !== null) {
        const numero = await nameOf(localPrisma, 'ventes', val('vente_id'), 'numero_vente');
        if (numero) parts.push(`vente ${numero}`);
      }
      break;
    case 'clients':
    case 'fournisseurs':
      parts.push([val('nom'), val('prenom')].filter(Boolean).join(' ') || `${tableLabel(table)} n° ${recordId}`);
      break;
    case 'comptes_clients':
    case 'comptes_fournisseurs': {
      const ownerTable = table === 'comptes_clients' ? 'clients' : 'fournisseurs';
      const ownerId = table === 'comptes_clients' ? clientId : val('fournisseur_id');
      const owner = ownerId !== null ? await nameOf(localPrisma, ownerTable, ownerId) : null;
      parts.push(owner ? `Compte de ${owner}` : `Compte n° ${recordId}`);
      if (val('solde_actuel') !== null) parts.push(`solde ${fmtNumber(val('solde_actuel'))} FCFA`);
      break;
    }
    case 'transactions_comptes':
      parts.push(val('description') || val('type_transaction_detail') || val('type_transaction') || `Écriture n° ${recordId}`);
      if (val('montant') !== null) parts.push(`${fmtNumber(val('montant'))} FCFA`);
      break;
    case 'cash_movements':
      parts.push(`${val('type') || 'mouvement'} de caisse`);
      if (val('montant') !== null) parts.push(`${fmtNumber(val('montant'))} FCFA`);
      if (val('description')) parts.push(String(val('description')).slice(0, 60));
      break;
    case 'cash_sessions':
      parts.push(`Session de caisse n° ${recordId}`);
      if (val('solde_attendu') !== null) parts.push(`solde attendu ${fmtNumber(val('solde_attendu'))} FCFA`);
      break;
    case 'cash_registers':
      parts.push(val('nom') || `Caisse n° ${recordId}`);
      if (val('solde_actuel') !== null) parts.push(`solde ${fmtNumber(val('solde_actuel'))} FCFA`);
      break;
    case 'financial_movements':
      parts.push(val('description') || val('reference') || `Mouvement n° ${recordId}`);
      if (val('montant') !== null) parts.push(`${fmtNumber(val('montant'))} FCFA`);
      break;
    case 'commandes_approvisionnement':
      parts.push(val('numero_commande') || `Commande n° ${recordId}`);
      if (val('montant_total') !== null) parts.push(`${fmtNumber(val('montant_total'))} FCFA`);
      break;
    case 'boutiques':
    case 'categories':
    case 'user_roles':
      parts.push(val('nom') || `${tableLabel(table)} n° ${recordId}`);
      break;
    case 'utilisateurs':
      parts.push(val('nom_utilisateur') || `Utilisateur n° ${recordId}`);
      break;
    default:
      parts.push(val('nom') || val('numero_vente') || val('numero_commande') || val('reference') || val('description') || `${tableLabel(table)} n° ${recordId}`);
  }
  return parts.filter(Boolean).join(' — ');
}

// ── Explication des erreurs ────────────────────────────────────────────────

/** Extrait les colonnes d'un nom de contrainte `table_col1_col2_key`. */
function columnsFromConstraint(constraint, table) {
  if (!constraint) return [];
  let name = constraint.replace(/_(key|idx|unique)$/i, '');
  if (table && name.startsWith(`${table}_`)) name = name.slice(table.length + 1);
  const cols = [];
  let rest = name;
  // Reconnaît les colonnes connues les plus longues d'abord (boutique_id_produit_id → 2 colonnes)
  const known = Object.keys(COLUMN_WORDS).sort((a, b) => b.length - a.length);
  while (rest.length > 0) {
    const col = known.find((k) => rest === k || rest.startsWith(`${k}_`));
    if (!col) return cols.length ? cols : [rest];
    cols.push(col);
    rest = rest.slice(col.length).replace(/^_/, '');
  }
  return cols;
}

// Tables dont le doublon est fusionné automatiquement (voir sync-service : _reconcileCompositeKeyConflicts
// et _reconcileNaturalKeyDuplicates)
const AUTO_FUSION = new Set([
  'stock', 'stock_boutiques', 'user_boutique_assignments', 'villes', 'zones',
  'user_roles', 'categories', 'movement_categories',
]);

// Doublons qu'on NE fusionne volontairement PAS à l'aveugle : explication et marche à suivre dédiées
const DOUBLON_PAR_TABLE = {
  comptes_clients: {
    titre: 'Deux comptes pour le même client',
    explication: "Le compte de ce client a été créé sur deux postes. Les deux soldes doivent être additionnés, pas choisis l'un ou l'autre.",
    action: 'Ouvrez « Décisions à prendre » (bandeau du tableau de bord) : vous y choisissez, en voyant les deux fiches côte à côte, d\'additionner les soldes ou de garder l\'un des deux.',
  },
  comptes_fournisseurs: {
    titre: 'Deux comptes pour le même fournisseur',
    explication: "Le compte de ce fournisseur a été créé sur deux postes. Les deux soldes doivent être additionnés, pas choisis l'un ou l'autre.",
    action: 'Ouvrez « Décisions à prendre » (bandeau du tableau de bord) : vous y choisissez, en voyant les deux fiches côte à côte, d\'additionner les soldes ou de garder l\'un des deux.',
  },
  produits: {
    titre: 'Deux produits avec la même référence',
    explication: "Un produit portant cette référence existe déjà dans le cloud. Il peut s'agir du même produit saisi deux fois, ou de deux produits différents.",
    action: "Ouvrez « Décisions à prendre » (bandeau du tableau de bord) : vous y choisissez, en voyant les deux fiches côte à côte, si c'est le même produit (fusion) ou deux produits (nouvelle référence).",
  },
  utilisateurs: {
    titre: "Un utilisateur du même nom existe déjà dans le cloud",
    explication: "Deux postes ont créé un utilisateur portant le même nom. Les remplacer l'un par l'autre changerait un mot de passe ou des droits.",
    action: "Ouvrez « Décisions à prendre » (bandeau du tableau de bord) : vous y choisissez, en voyant les deux fiches côte à côte, si c'est la même personne ou deux personnes (nouveau nom).",
  },
  cash_registers: {
    titre: "Une caisse du même nom existe déjà dans le cloud",
    explication: "Deux postes ont chacun créé une caisse portant ce nom. Chacune a son propre solde d'argent, qu'on ne peut pas écraser sans vérification.",
    action: "Ouvrez « Décisions à prendre » (bandeau du tableau de bord) : vous y choisissez, en voyant les deux fiches côte à côte, de fusionner les deux caisses ou de renommer la vôtre.",
  },
  boutiques: {
    titre: "Une boutique du même nom existe déjà dans le cloud",
    explication: "Deux postes ont chacun créé une boutique portant ce nom : stocks et ventes sont rattachés à chacune.",
    action: "Ouvrez « Décisions à prendre » (bandeau du tableau de bord) : vous y choisissez, en voyant les deux fiches côte à côte, de fusionner les deux boutiques (stocks rattachés) ou de renommer la vôtre.",
  },
  stock_inventories: {
    titre: 'Deux inventaires avec le même nom',
    explication: 'Un inventaire portant ce nom existe déjà dans le cloud.',
    action: "Ouvrez « Décisions à prendre » (bandeau du tableau de bord) : vous y choisissez, en voyant les deux fiches côte à côte, le nouveau nom de votre inventaire.",
  },
  ventes: numeroDocument('de vente'),
  commandes_approvisionnement: numeroDocument('de commande'),
  ventes_proforma: numeroDocument('de proforma'),
  historique_recus: numeroDocument('de reçu'),
  financial_movements: numeroDocument('de mouvement financier'),
  transferts_stock: numeroDocument('de transfert'),
};

function numeroDocument(quoi) {
  return {
    titre: `Même numéro ${quoi} sur deux postes`,
    explication: `Deux postes ont généré le même numéro ${quoi} (anciens numéros sans identifiant de poste). Le cloud n'accepte qu'un seul exemplaire.`,
    action: "Ouvrez « Décisions à prendre » (bandeau du tableau de bord) : vous y choisissez, en voyant les deux fiches côte à côte, le nouveau numéro de votre document. Les nouveaux numéros portent un identifiant de poste et ne se répètent plus.",
  };
}

/**
 * Traduit une erreur technique en explication claire.
 * @returns {{code:string, titre:string, explication:string, action:string}}
 */
function classifyError(message, table) {
  const msg = String(message || '').replace(/\s+/g, ' ').trim();
  const low = msg.toLowerCase();

  if (!msg) {
    return { code: 'attente', titre: 'En attente d\'envoi', explication: 'Pas encore envoyé : il partira à la prochaine synchronisation.', action: 'Aucune action : vérifiez simplement que la connexion internet est active.' };
  }

  // Doublon : contrainte d'unicité (PostgreSQL ou SQLite)
  const pg = msg.match(/violates unique constraint "([^"]+)"/i);
  const lite = msg.match(/UNIQUE constraint failed: ([\w.,\s]+)/i);
  if (pg || lite || low.includes('duplicate key')) {
    let cols = [];
    if (pg) cols = columnsFromConstraint(pg[1], table);
    else if (lite) cols = lite[1].split(',').map((c) => c.trim().split('.').pop());
    const mots = cols.map((c) => {
      const [mot, feminin] = COLUMN_WORDS[c] || [c, false];
      return `${feminin ? 'la même' : 'le même'} ${mot}`;
    });
    const sur = mots.length ? ` pour ${mots.join(' et ')}` : '';
    const conseil = DOUBLON_PAR_TABLE[table];
    const auto = AUTO_FUSION.has(table);
    return {
      code: 'doublon',
      titre: conseil && conseil.titre ? conseil.titre : "Doublon : cet élément existe déjà de l'autre côté",
      explication: conseil && conseil.explication
        ? conseil.explication
        : `Une fiche existe déjà${sur} avec un autre identifiant (créée sur un autre poste, ou ici avant d'avoir reçu celle du cloud). Chaque côté attend que l'autre cède sa place.`,
      action: auto
        ? 'Corrigé automatiquement : les deux fiches sont fusionnées à la prochaine synchronisation, sans perte.'
        : (conseil && conseil.action) || 'Les deux fiches doivent être fusionnées. Si cela persiste après plusieurs synchronisations, transmettez ce détail au support.',
    };
  }

  if (low.includes('violates foreign key') || low.includes('foreign key constraint')) {
    return {
      code: 'dependance',
      titre: 'Dépend d\'un autre élément pas encore synchronisé',
      explication: 'Cet élément fait référence à un autre (produit, client, vente...) qui n\'est pas encore présent de l\'autre côté.',
      action: 'Se résout en général tout seul, une fois l\'élément parent synchronisé. Si cela dure, cherchez l\'élément parent dans la liste.',
    };
  }

  if (/(connection|timeout|timed out|socket|econn|enotfound|eai_again|network)/i.test(msg)) {
    return { code: 'reseau', titre: 'Connexion internet instable', explication: 'La liaison avec le cloud a été coupée pendant l\'envoi.', action: 'Aucune action : l\'envoi reprendra tout seul dès que la connexion est stable.' };
  }

  if (/(column .* does not exist|relation .* does not exist|no such column|no such table)/i.test(msg)) {
    return { code: 'schema', titre: 'Le cloud n\'a pas la structure attendue', explication: 'Une colonne ou une table manque côté cloud : la mise à jour du cloud n\'est pas terminée.', action: 'Mettre à jour le cloud (déploiement du serveur), puis relancer la synchronisation.' };
  }

  if (/(null value in column|violates not-null|invalid input syntax|out of range|check constraint)/i.test(msg)) {
    return { code: 'donnee', titre: 'Donnée incomplète ou invalide', explication: 'Le cloud refuse cette donnée (champ obligatoire vide ou valeur incorrecte).', action: 'Corriger la fiche concernée dans l\'application, puis relancer la synchronisation.' };
  }

  return { code: 'inconnue', titre: 'Erreur de synchronisation', explication: 'Le cloud a refusé cet élément pour une raison non reconnue.', action: 'Transmettez le message technique ci-dessous au support.' };
}

// ── Assemblage ──────────────────────────────────────────────────────────────

/** Retire le bruit de Prisma (« Invalid ... invocation: Raw query failed. Code: ... Message: `...` »). */
function cleanTechnical(message) {
  const flat = String(message || '').replace(/\s+/g, ' ').trim();
  const m = flat.match(/Message: `(.*)`\.?$/);
  return (m ? m[1] : flat).slice(0, 400);
}

function safeParse(data) {
  if (data && typeof data === 'object') return data;
  try { return JSON.parse(data); } catch (_) { return null; }
}

/** Convertit une date SQLite (« 2026-10-03 08:55:12 », UTC) en ISO. */
function toIso(v) {
  if (!v) return null;
  if (typeof v === 'number' || typeof v === 'bigint') return new Date(Number(v)).toISOString();
  const s = String(v);
  const d = new Date(s.includes('T') ? s : `${s.replace(' ', 'T')}Z`);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

/**
 * Liste détaillée de ce qui n'est pas synchronisé.
 * @param {*} localPrisma  client Prisma local
 * @param {{limit?:number}} [options]
 */
async function getSyncDetails(localPrisma, { limit = 200 } = {}) {
  const items = [];

  const ops = await localPrisma.$queryRawUnsafe(
    `SELECT id, operation_id, operation_type, table_name, record_id, data, timestamp, status, error_message
     FROM operation_log WHERE status IN ('pending', 'failed')
     ORDER BY (status = 'failed') DESC, timestamp ASC LIMIT ?`,
    limit
  );
  for (const op of ops) {
    const data = safeParse(op.data);
    const erreur = op.status === 'failed' ? classifyError(op.error_message, op.table_name) : classifyError('', op.table_name);
    items.push({
      source: 'envoi',
      id: String(op.operation_id || op.id),
      table: op.table_name,
      tableLabel: tableLabel(op.table_name),
      operation: op.operation_type,
      operationLabel: OPERATION_LABELS[op.operation_type] || op.operation_type,
      recordId: op.record_id === null || op.record_id === undefined ? null : Number(op.record_id),
      status: op.status,
      createdAt: toIso(op.timestamp),
      summary: await describeRecord(localPrisma, op.table_name, data, op.record_id),
      error: { ...erreur, technique: op.status === 'failed' ? cleanTechnical(op.error_message) : null },
    });
  }

  let retries = [];
  try {
    retries = await localPrisma.$queryRawUnsafe(
      `SELECT table_name, record_id, payload, attempts, last_error, created_at
       FROM sync_pull_retry ORDER BY attempts DESC, id ASC LIMIT ?`,
      limit
    );
  } catch (_) { /* table absente : rien à afficher */ }
  for (const r of retries) {
    // Déjà présente localement sous le même identifiant : la ligne a fini par être appliquée
    // (ou fusionnée) par un autre chemin ; l'entrée de reprise est périmée, on ne la montre pas.
    if (await lookup(localPrisma, r.table_name, Number(r.record_id), ['id'])) continue;
    const data = safeParse(r.payload);
    items.push({
      source: 'reception',
      id: `${r.table_name}:${r.record_id}`,
      table: r.table_name,
      tableLabel: tableLabel(r.table_name),
      operation: 'REÇU',
      operationLabel: 'Reçu du cloud, non appliqué',
      recordId: Number(r.record_id),
      status: 'failed',
      attempts: Number(r.attempts || 0),
      createdAt: toIso(r.created_at),
      summary: await describeRecord(localPrisma, r.table_name, data, r.record_id),
      error: { ...classifyError(r.last_error, r.table_name), technique: cleanTechnical(r.last_error) },
    });
  }

  return items;
}

module.exports = { getSyncDetails, describeRecord, classifyError, tableLabel, columnsFromConstraint, TABLE_LABELS, DOUBLON_PAR_TABLE };
