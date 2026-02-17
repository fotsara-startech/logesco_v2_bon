# Script PowerShell pour créer la table categories via l'API backend
# Ce script utilise l'API du backend pour créer la table et insérer les données

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   CREATION TABLE CATEGORIES VIA API" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$backendUrl = "http://localhost:3002"
$apiUrl = "$backendUrl/api/v1"

# Fonction pour tester la connexion au backend
function Test-BackendConnection {
    try {
        Write-Host "🔍 Test de connexion au backend..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "$backendUrl/health" -Method GET -TimeoutSec 5
        Write-Host "✅ Backend accessible" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Backend non accessible sur $backendUrl" -ForegroundColor Red
        Write-Host "   Erreur: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour créer les catégories par défaut
function Create-DefaultCategories {
    $categories = @(
        @{ nom = "Smartphones"; description = "Téléphones intelligents et accessoires mobiles" },
        @{ nom = "Ordinateurs"; description = "PC, laptops et composants informatiques" },
        @{ nom = "Accessoires"; description = "Câbles, chargeurs et autres accessoires électroniques" },
        @{ nom = "Écrans"; description = "Moniteurs et écrans pour ordinateurs" },
        @{ nom = "Audio"; description = "Casques, écouteurs et équipements audio" }
    )

    Write-Host "📝 Création des catégories par défaut..." -ForegroundColor Yellow
    $created = 0
    
    foreach ($category in $categories) {
        try {
            $body = $category | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "$apiUrl/categories" -Method POST -Body $body -ContentType "application/json"
            Write-Host "✅ Catégorie créée: $($category.nom)" -ForegroundColor Green
            $created++
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 409) {
                Write-Host "ℹ️  Catégorie existe déjà: $($category.nom)" -ForegroundColor Blue
            }
            else {
                Write-Host "❌ Erreur création $($category.nom): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    return $created
}

# Fonction pour lister les catégories existantes
function Get-Categories {
    try {
        Write-Host "📊 Récupération des catégories..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri "$apiUrl/categories" -Method GET
        
        if ($response.success -and $response.data) {
            Write-Host "✅ Catégories trouvées:" -ForegroundColor Green
            $response.data | ForEach-Object {
                Write-Host "   - ID: $($_.id) | Nom: $($_.nom) | Description: $($_.description)" -ForegroundColor White
            }
            return $response.data.Count
        }
        else {
            Write-Host "⚠️  Aucune catégorie trouvée" -ForegroundColor Yellow
            return 0
        }
    }
    catch {
        Write-Host "❌ Erreur récupération: $($_.Exception.Message)" -ForegroundColor Red
        return -1
    }
}

# Exécution principale
Write-Host "🚀 Démarrage de la configuration des catégories..." -ForegroundColor Cyan
Write-Host ""

# Test de connexion
if (-not (Test-BackendConnection)) {
    Write-Host ""
    Write-Host "💡 Solutions possibles:" -ForegroundColor Yellow
    Write-Host "   1. Démarrer le serveur backend sur http://localhost:3002" -ForegroundColor White
    Write-Host "   2. Vérifier que l'API est accessible" -ForegroundColor White
    Write-Host "   3. Modifier l'URL dans ce script si nécessaire" -ForegroundColor White
    Write-Host ""
    Read-Host "Appuyez sur Entrée pour continuer..."
    exit 1
}

Write-Host ""

# Vérifier les catégories existantes
$existingCount = Get-Categories

Write-Host ""

if ($existingCount -eq 0) {
    # Créer les catégories par défaut
    $createdCount = Create-DefaultCategories
    
    Write-Host ""
    Write-Host "📈 Résumé:" -ForegroundColor Cyan
    Write-Host "   - Catégories créées: $createdCount" -ForegroundColor Green
    
    # Vérification finale
    Write-Host ""
    $finalCount = Get-Categories
}
elseif ($existingCount -gt 0) {
    Write-Host "ℹ️  $existingCount catégorie(s) déjà présente(s)" -ForegroundColor Blue
    
    $response = Read-Host "Voulez-vous ajouter les catégories manquantes? (o/N)"
    if ($response -eq "o" -or $response -eq "O") {
        $createdCount = Create-DefaultCategories
        Write-Host ""
        Write-Host "📈 Catégories ajoutées: $createdCount" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🎯 Configuration terminée!" -ForegroundColor Green
Write-Host "   Les catégories sont prêtes à être utilisées dans l'application Flutter." -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Read-Host "Appuyez sur Entrée pour continuer..."