-- Ajoute deux réglages d'entreprise configurables :
-- - separer_commande_encaissement : sépare la saisie de la commande de
--   l'encaissement (deux étapes, éventuellement deux personnes différentes).
-- - vendeurs_voient_toutes_ventes : si false (comportement historique), un
--   utilisateur non-admin ne voit que ses propres ventes.

ALTER TABLE parametres_entreprise ADD COLUMN separer_commande_encaissement BOOLEAN NOT NULL DEFAULT 0;
ALTER TABLE parametres_entreprise ADD COLUMN vendeurs_voient_toutes_ventes BOOLEAN NOT NULL DEFAULT 0;
