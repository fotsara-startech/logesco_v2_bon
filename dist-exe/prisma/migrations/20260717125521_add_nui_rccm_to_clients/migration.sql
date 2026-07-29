-- Migration pour ajouter les champs NUI et RCCM aux clients
-- Ces champs sont optionnels et destinés aux clients entreprises

-- Ajouter la colonne NUI (Numéro d'Identification Unique)
ALTER TABLE clients ADD COLUMN nui VARCHAR(255) NULL;

-- Ajouter la colonne RCCM (Registre du Commerce et du Crédit Mobilier)
ALTER TABLE clients ADD COLUMN rccm VARCHAR(255) NULL;

-- Créer un index sur NUI pour faciliter les recherches (optionnel)
CREATE INDEX idx_clients_nui ON clients(nui) WHERE nui IS NOT NULL;

-- Créer un index sur RCCM pour faciliter les recherches (optionnel)
CREATE INDEX idx_clients_rccm ON clients(rccm) WHERE rccm IS NOT NULL;
