#!/usr/bin/env pwsh

# Script pour supprimer TOUS les rôles de la base de données via l'API
# Usage: ./delete_all_roles.ps1

Write-Host "🗑️ Suppression de TOUS les rôles de la base de données..." -ForegroundColor Red

# URL de l'API
$API_BASE_URL = "http://localhost:3002/api/v1"
$ROLES_ENDPOINT = "$API_BASE_URL/roles"

function Test-ApiConnection {
    try {
        $response = Invoke-RestMethod -Uri "$API_BASE_URL/health" -Method GET -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Get-AllRoles {
    try {
        $response = Invoke-RestMethod -Uri $ROLES_ENDPOINT -Method GET -ErrorAction Stop
        if ($response.data) {
            return $response.data
        }
        return @()
    }
    catch {
        Write-Host "⚠️ Erreur lors de la récupération des rôles: $($_.Exception.Message)" -ForegroundColor Yellow
        return @()
    }
}

function Delete-Role {
    param($roleId, $roleName)
    
    try {
        $deleteUrl = "$ROLES_ENDPOINT/$roleId"
        Invoke-RestMethod -Uri $deleteUrl -Method DELETE -ErrorAction Stop
        Write-Host "✅ Rôle supprimé: $roleName (ID: $roleId)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Erreur lors de la suppression du rôle $roleName : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Vérifier la connexion à l'API
Write-Host "🔍 Vérification de la connexion à l'API..." -ForegroundColor Yellow
if (-not (Test-ApiConnection)) {
    Write-Host "❌ Impossible de se connecter à l'API sur $API_BASE_URL" -ForegroundColor Red
    Write-Host "   Assurez-vous que le serveur backend est démarré." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Connexion à l'API établie" -ForegroundColor Green

# Récupérer tous les rôles
Write-Host "📋 Récupération de tous les rôles..." -ForegroundColor Yellow
$allRoles = Get-AllRoles

if (-not $allRoles -or $allRoles.Count -eq 0) {
    Write-Host "✅ Aucun rôle trouvé en base de données" -ForegroundColor Green
    Write-Host "   La base est déjà vide !" -ForegroundColor Green
    exit 0
}

Write-Host "   Rôles trouvés: $($allRoles.Count)" -ForegroundColor Cyan
foreach ($role in $allRoles) {
    Write-Host "   - $($role.nom) ($($role.displayName))" -ForegroundColor White
}

# Demander confirmation
Write-Host ""
Write-Host "⚠️  ATTENTION: Vous allez supprimer TOUS les $($allRoles.Count) rôles" -ForegroundColor Red
Write-Host "   Cette action est IRRÉVERSIBLE !" -ForegroundColor Red
Write-Host "   Tous les utilisateurs perdront leurs rôles !" -ForegroundColor Red
Write-Host ""

$confirmation = Read-Host "Êtes-vous ABSOLUMENT sûr ? Tapez 'SUPPRIMER TOUT' pour confirmer"

if ($confirmation -ne "SUPPRIMER TOUT") {
    Write-Host "❌ Opération annulée" -ForegroundColor Yellow
    Write-Host "   Pour confirmer, vous devez taper exactement: SUPPRIMER TOUT" -ForegroundColor Yellow
    exit 0
}

# Supprimer tous les rôles
Write-Host ""
Write-Host "🗑️ Suppression de tous les rôles..." -ForegroundColor Red
$deletedCount = 0

foreach ($role in $allRoles) {
    if (Delete-Role -roleId $role.id -roleName $role.nom) {
        $deletedCount++
    }
    Start-Sleep -Milliseconds 200  # Pause entre les suppressions
}

# Résumé final
Write-Host ""
if ($deletedCount -gt 0) {
    Write-Host "🎉 Nettoyage terminé: $deletedCount rôles supprimés" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Prochaines étapes:" -ForegroundColor Cyan
    Write-Host "   1. Redémarrez l'application Flutter" -ForegroundColor White
    Write-Host "   2. L'interface devrait maintenant afficher 'Aucun rôle configuré'" -ForegroundColor White
    Write-Host "   3. Créez vos propres rôles via l'interface" -ForegroundColor White
} else {
    Write-Host "❌ Aucun rôle n'a pu être supprimé" -ForegroundColor Red
}

# Vérification finale
Write-Host ""
Write-Host "🔍 Vérification finale..." -ForegroundColor Yellow
$remainingRoles = Get-AllRoles
Write-Host "   Rôles restants: $($remainingRoles.Count)" -ForegroundColor Cyan

if ($remainingRoles.Count -eq 0) {
    Write-Host "✅ Base de données complètement nettoyée !" -ForegroundColor Green
    Write-Host "   Vous pouvez maintenant créer vos propres rôles" -ForegroundColor Green
} else {
    Write-Host "⚠️ Il reste encore $($remainingRoles.Count) rôles:" -ForegroundColor Yellow
    foreach ($role in $remainingRoles) {
        Write-Host "   - $($role.nom) ($($role.displayName))" -ForegroundColor Gray
    }
}