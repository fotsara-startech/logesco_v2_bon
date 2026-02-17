-- Migration: Ajouter les colonnes venteId et venteReference à TransactionCompte
-- Date: 2026-02-11
-- Description: Permet de lier chaque transaction à une vente spécifique pour un meilleur suivi

-- Ajouter les nouvelles colonnes
ALTER TABLE TransactionCompte 
ADD COLUMN venteId INTEGER NULL,
ADD COLUMN venteReference VARCHAR(50) NULL,
ADD COLUMN typeTransactionDetail VARCHAR(50) NULL;

-- Ajouter une clé étrangère vers la table Vente
ALTER TABLE TransactionCompte
ADD CONSTRAINT fk_transaction_vente
FOREIGN KEY (venteId) REFERENCES Vente(id)
ON DELETE SET NULL;

-- Créer un index pour améliorer les performances
CREATE INDEX idx_transaction_vente ON TransactionCompte(venteId);
CREATE INDEX idx_transaction_type_detail ON TransactionCompte(typeTransactionDetail);

-- Mettre à jour les anciennes transactions pour avoir un typeTransactionDetail
UPDATE TransactionCompte
SET typeTransactionDetail = CASE
    WHEN typeTransaction = 'paiement' THEN 'paiement_manuel'
    WHEN typeTransaction = 'credit' THEN 'credit_manuel'
    WHEN typeTransaction = 'debit' THEN 'debit_manuel'
    WHEN typeTransaction = 'achat' THEN 'achat_manuel'
    ELSE typeTransaction
END
WHERE typeTransactionDetail IS NULL;

-- Commentaires sur les colonnes
COMMENT ON COLUMN TransactionCompte.venteId IS 'ID de la vente associée à cette transaction';
COMMENT ON COLUMN TransactionCompte.venteReference IS 'Numéro de référence de la vente (ex: VTE-20260210-180642)';
COMMENT ON COLUMN TransactionCompte.typeTransactionDetail IS 'Type détaillé: vente_comptant, vente_credit, paiement_vente, paiement_dette, ajustement';

-- Afficher un résumé
SELECT 
    'Migration terminée' as status,
    COUNT(*) as total_transactions,
    COUNT(venteId) as transactions_avec_vente
FROM TransactionCompte;
