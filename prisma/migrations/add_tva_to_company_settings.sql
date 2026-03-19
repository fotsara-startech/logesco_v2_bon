-- Migration: Ajout du taux de TVA dans les paramètres d'entreprise
-- Ce champ est optionnel (nullable) et représente le taux de TVA en pourcentage

ALTER TABLE parametres_entreprise ADD COLUMN taux_tva REAL;
