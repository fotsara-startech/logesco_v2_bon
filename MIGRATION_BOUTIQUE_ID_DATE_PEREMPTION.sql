-- Migration pour ajouter le champ boutiqueId à la table DatePeremption
-- et mettre à jour les données existantes avec la boutique principale

-- 1. Ajouter la colonne boutiqueId à la table DatePeremption
ALTER TABLE DatePeremption 
ADD COLUMN boutiqueId INT;

-- 2. Créer un index sur boutiqueId pour optimiser les requêtes
CREATE INDEX idx_dateperemption_boutique_id ON DatePeremption(boutiqueId);

-- 3. Mettre à jour toutes les données existantes avec l'ID de la boutique principale
-- (Remplacer 1 par l'ID réel de votre boutique principale si différent)
UPDATE DatePeremption 
SET boutiqueId = (
    SELECT id 
    FROM Boutique 
    WHERE estPrincipale = 1 
    LIMIT 1
)
WHERE boutiqueId IS NULL;

-- 4. Rendre la colonne boutiqueId obligatoire après la mise à jour
ALTER TABLE DatePeremption 
MODIFY COLUMN boutiqueId INT NOT NULL;

-- 5. Ajouter une contrainte de clé étrangère vers la table Boutique
ALTER TABLE DatePeremption 
ADD CONSTRAINT fk_dateperemption_boutique 
FOREIGN KEY (boutiqueId) REFERENCES Boutique(id) 
ON DELETE CASCADE ON UPDATE CASCADE;

-- 6. Vérification : Afficher le nombre d'enregistrements mis à jour
SELECT 
    COUNT(*) as total_dates_peremption,
    COUNT(DISTINCT boutiqueId) as boutiques_distinctes,
    boutiqueId,
    (SELECT nom FROM Boutique WHERE id = DatePeremption.boutiqueId LIMIT 1) as nom_boutique
FROM DatePeremption 
GROUP BY boutiqueId;