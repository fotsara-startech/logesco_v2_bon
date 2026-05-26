-- Migration: Ajout des champs logo et slogan aux paramètres d'entreprise
-- Date: 2026-02-28
-- Description: Ajoute les champs optionnels logo (chemin fichier) et slogan aux paramètres d'entreprise

-- Ajouter le champ logo (chemin vers le fichier logo)
ALTER TABLE parametres_entreprise ADD COLUMN logo TEXT;

-- Ajouter le champ slogan (slogan de l'entreprise)
ALTER TABLE parametres_entreprise ADD COLUMN slogan TEXT;

-- Les deux champs sont optionnels (NULL par défaut)
