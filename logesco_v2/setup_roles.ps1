#!/usr/bin/env pwsh

# Script pour configurer les rôles de base dans la base de données
# Usage: ./setup_roles.ps1

Write-Host "🔧 Configuration des rôles de base dans la base de données..." -ForegroundColor Cyan

# Chemin vers la base de données SQLite
$DB_PATH = "database/logesco.db"
$SQL_FILE = "database/insert_roles.sql"

# Vérifier que la base de données existe
if (-not (Test-Path $DB_PATH)) {
    Write-Host "❌ Base de données non trouvée: $DB_PATH" -ForegroundColor Red
    Write-Host "   Assurez-vous que la base de données a été créée." -ForegroundColor Red
    exit 1
}

# Vérifier que le fichier SQL existe
if (-not (Test-Path $SQL_FILE)) {
    Write-Host "❌ Fichier SQL non trouvé: $SQL_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Base de données trouvée: $DB_PATH" -ForegroundColor Green
Write-Host "✅ Script SQL trouvé: $SQL_FILE" -ForegroundColor Green

# Vérifier si sqlite3 est disponible
try {
    $null = Get-Command sqlite3 -ErrorAction Stop
    Write-Host "✅ SQLite3 disponible" -ForegroundColor Green
} catch {
    Write-Host "❌ SQLite3 non trouvé dans le PATH" -ForegroundColor Red
    Write-Host "   Installez SQLite3 ou utilisez un autre outil pour exécuter le script SQL." -ForegroundColor Red
    Write-Host "   Vous pouvez aussi exécuter manuellement le contenu de $SQL_FILE" -ForegroundColor Yellow
    exit 1
}

# Exécuter le script SQL
Write-Host "🔄 Exécution du script SQL..." -ForegroundColor Yellow
try {
    $result = sqlite3 $DB_PATH ".read $SQL_FILE" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Script SQL exécuté avec succès" -ForegroundColor Green
        
        # Afficher les rôles créés
        Write-Host "📋 Rôles dans la base de données:" -ForegroundColor Cyan
        $roles = sqlite3 $DB_PATH "SELECT id, nom, displayName, isAdmin FROM roles ORDER BY id;" -separator " | "
        if ($roles) {
            Write-Host "ID | Nom | Nom d'affichage | Admin" -ForegroundColor White
            Write-Host "---|-----|-----------------|------" -ForegroundColor White
            $roles | ForEach-Object { Write-Host $_ -ForegroundColor White }
        } else {
            Write-Host "⚠️ Aucun rôle trouvé dans la base" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Erreur lors de l'exécution du script SQL" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Configuration des rôles terminée avec succès!" -ForegroundColor Green
Write-Host "   Vous pouvez maintenant utiliser l'application avec les rôles de base." -ForegroundColor Green
Write-Host ""
Write-Host "📝 Rôles configurés:" -ForegroundColor Cyan
Write-Host "   - admin: Administrateur (accès complet)" -ForegroundColor White
Write-Host "   - manager: Gestionnaire (gestion produits, ventes, inventaire)" -ForegroundColor White
Write-Host "   - cashier: Caissi