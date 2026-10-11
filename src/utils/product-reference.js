/**
 * Référence automatique des produits : PRD + année + séquence sur 4 chiffres (+ identifiant de poste).
 *
 * Chaque poste calcule la séquence à partir de SES produits. Deux postes qui n'ont pas encore synchronisé
 * produisent donc le même numéro pour deux produits différents (cas réel : PRD20260097 donné au « Système
 * d'alarme » sur un poste et à un lustre sur un autre). La référence est unique côté Neon : le second produit n'est
 * jamais synchronisé. Comme pour les numéros de documents, on ajoute l'identifiant du poste (-P15) : le poste 1
 * (poste historique) garde le format d'origine.
 */

/**
 * @param {{annee:number|string, references:string[], suffixe?:string}} p
 *   references : références déjà connues (au minimum celles qui commencent par PRD<année>)
 *   suffixe    : suffixe de poste (installation.documentSuffix())
 * @returns {string} ex. « PRD20260100 » (poste 1) ou « PRD20260100-P15 »
 */
function prochaineReferenceProduit({ annee, references = [], suffixe = '' }) {
  const prefixe = `PRD${annee}`;
  const motif = new RegExp(`^PRD${annee}(\\d+)(?:-P\\d+)?$`);
  const connues = new Set(references);

  // La séquence continue au plus grand numéro connu, tous postes confondus (le suffixe n'y compte pas)
  let max = 0;
  for (const ref of references) {
    const m = motif.exec(ref);
    if (m) max = Math.max(max, parseInt(m[1], 10));
  }

  let numero = max + 1;
  let candidate = `${prefixe}${String(numero).padStart(4, '0')}${suffixe}`;
  // Une référence saisie à la main peut déjà occuper ce numéro : on passe au suivant
  while (connues.has(candidate)) {
    numero++;
    candidate = `${prefixe}${String(numero).padStart(4, '0')}${suffixe}`;
  }
  return candidate;
}

module.exports = { prochaineReferenceProduit };
