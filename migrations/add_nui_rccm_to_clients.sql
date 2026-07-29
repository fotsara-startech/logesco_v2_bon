-- Migration: Ajouter les colonnes nui et rccm à la table clients
-- Date: 2026-07-17

-- Vérifier si les colonnes existent déjà dans Neon
-- Si nui_rccm existe, on va migrer les données vers nui et rccm séparés

DO $$ 
BEGIN
    -- Ajouter la colonne nui si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'nui'
    ) THEN
        ALTER TABLE clients ADD COLUMN nui TEXT;
        RAISE NOTICE 'Colonne nui ajoutée';
    ELSE
        RAISE NOTICE 'Colonne nui existe déjà';
    END IF;

    -- Ajouter la colonne rccm si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'rccm'
    ) THEN
        ALTER TABLE clients ADD COLUMN rccm TEXT;
        RAISE NOTICE 'Colonne rccm ajoutée';
    ELSE
        RAISE NOTICE 'Colonne rccm existe déjà';
    END IF;

    -- Si nui_rccm existe, migrer les données (optionnel)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'nui_rccm'
    ) THEN
        -- Ici vous pouvez ajouter une logique pour séparer nui_rccm en nui et rccm
        -- Par exemple: UPDATE clients SET nui = nui_rccm WHERE nui IS NULL;
        RAISE NOTICE 'Colonne nui_rccm existe, migration de données nécessaire';
    END IF;
END $$;
