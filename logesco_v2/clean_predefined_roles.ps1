#!/usr/bin/env pwsh

# Script pour supprimer les rôles prédéfinis via l'API
# Usage: ./clean_predefined_roles.ps1

Write-Host "🧹 Nettoyage des rôles prédéfinis..." -ForegroundColor Cyan

# URL de l'API (ajustez selon votre configuration)
$API_BASE_URL = "http://localhost:3002/api/v1"
$ROLES_ENDPOINT = "$API_BASE_URL/roles"

# Rôles prédéfinis à supprimer
$predefinedRoleNames = @("ADMIN", "MANAGER", "EMPLOYEE", "CASHIER", "VIEWER")

function Test-ApiConnection {
    try {
        $response = Invoke-RestMethod -Uri "$API_BASE_URL/health" -Method GET -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Get-ExistingRoles {
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

# Récupérer les rôles existants
Write-Host "📋 Récupération des rôles existants..." -ForegroundColor Yellow
$existingRoles = Get-ExistingRoles

if (-not $existingRoles -or $existingRoles.Count -eq 0) {
    Write-Host "✅ Aucun rôle trouvé en base de données" -ForegroundColor Green
    Write-Host "   La base est déjà propre !" -ForegroundColor Green
    exit 0
}

Write-Host "   Rôles trouvés: $($existingRoles.Count)" -ForegroundColor Cyan

# Identifier les rôles prédéfinis à supprimer
$rolesToDelete = @()
foreach ($role in $existingRoles) {
    if ($predefinedRoleNames -contains $role.nom) {
        $rolesToDelete += $role
        Write-Host "🎯 Rôle prédéfini identifié: $($role.nom) - $($role.displayName)" -ForegroundColor Yellow
    }
}

if ($rolesToDelete.Count -eq 0) {
    Write-Host "✅ Aucun rôle prédéfini trouvé" -ForegroundColor Green
    Write-Host "   Tous les rôles semblent être créés par les utilisateurs" -ForegroundColor Green
    exit 0
}

# Demander confirmation
Write-Host ""
Write-Host "⚠️  ATTENTION: Vous allez supprimer $($rolesToDelete.Count) rôles prédéfinis" -ForegroundColor Red
Write-Host "   Cette action est irréversible !" -ForegroundColor Red
Write-Host ""

foreach ($role in $rolesToDelete) {
    Write-Host "   - $($role.nom) ($($role.displayName))" -ForegroundColor White
}

Write-Host ""
$confirmation = Read-Host "Voulez-vous continuer ? (oui/non)"

if ($confirmation -ne "oui" -and $confirmation -ne "o" -and $confirmation -ne "y" -and $confirmation -ne "yes") {
    Write-Host "❌ Opération annulée par l'utilisateur" -ForegroundColor Yellow
    exit 0
}

# Supprimer les rôles prédéfinis
Write-Host ""
Write-Host "🗑️ Suppression des rôles prédéfinis..." -ForegroundColor Red
$deletedCount = 0

foreach ($role in $rolesToDelete) {
    if (Delete-Role -roleId $role.id -roleName $role.nom) {
        $deletedCount++
    }
    Start-Sleep -Milliseconds 100  # Petite pause entre les suppressions
}

# Résumé final
Write-Host ""
if ($deletedCount -gt 0) {
    Write-Host "🎉 Nettoyage terminé: $deletedCount rôles supprimés" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Prochaines étapes:" -ForegroundColor Cyan
    Write-Host "   1. Redémarrez l'application Flutter" -ForegroundColor White
    Write-Host "   2. Créez vos propres rôles via l'interface" -ForegroundColor White
    Write-Host "   3. Assignez les rôles aux utilisateurs" -ForegroundColor White
} else {
    Write-Host "❌ Aucun rôle n'a pu être supprimé" -ForegroundColor Red
}

# Vérification finale
Write-Host ""
Write-Host "🔍 Vérification finale..." -ForegroundColor Yellow
$remainingRoles = Get-ExistingRoles
Write-Host "   Rôles restants: $($remainingRoles.Count)" -ForegroundColor Cyan

if ($remainingRoles.Count -gt 0) {
    Write-Host "   Rôles encore présents:" -ForegroundColor White
    foreach ($role in $remainingRoles) {
        Write-Host "   - $($role.nom) ($($role.displayName))" -ForegroundColor Gray
    }
} else {
    Write-Host "✅ Base de données complètement nettoyée !" -ForegroundColor Green
}