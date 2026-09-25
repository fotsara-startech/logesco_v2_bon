-- Ajoute la colonne "statut" à financial_movements.
-- Ce champ existe dans schema.prisma depuis un moment mais n'avait jamais été
-- capturé dans une migration formelle : seul un correctif ad-hoc au démarrage
-- (server.js) l'ajoutait. Migration ré-écrite ici pour devenir la source unique
-- de vérité utilisée par le migration-runner.

ALTER TABLE financial_movements ADD COLUMN statut TEXT NOT NULL DEFAULT 'actif';
