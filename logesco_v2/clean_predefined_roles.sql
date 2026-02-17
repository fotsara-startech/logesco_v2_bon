-- Script pour supprimer les rôles prédéfinis de la base de données
-- Exécuter ce script pour nettoyer la base et permettre aux utilisateurs de créer leurs propres rôles

-- Supprimer tous les rôles prédéfinis
DELETE FROM roles WHERE nom IN ('ADMIN', 'MANAGER', 'EMPLOYEE', 'CASHIER', 'VIEWER');

-- Vérifier que les rôles ont été supprimés
SELECT COUNT(*) as remaining_roles FROM roles;

-- Afficher les rôles restants (devrait être vide)
SELECT id, nom, displayName FROM roles;