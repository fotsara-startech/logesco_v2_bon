# Test simple des catégories de dépenses

# 1. Authentification
$loginBody = @{
    nomUtilisateur = "admin"
    motDePasse = "admin123"
} | ConvertTo-Json

$authResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $authResponse.data.accessToken

Write-Host "✅ Authentification réussie"

# 2. Headers pour les requêtes
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 3. Créer une catégorie de test
Write-Host "🔍 Création d'une catégorie de test..."
$categoryBody = @{
    nom = "Fournitures de bureau"
    description = "Papeterie, stylos, et autres fournitures"
    couleur = "#4CAF50"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/expense-categories" -Method POST -Body $categoryBody -Headers $headers
    Write-Host "✅ Catégorie créée: $($createResponse.data.nom)"
} catch {
    Write-Host "⚠️ Erreur création (peut-être déjà existante): $($_.Exception.Message)"
}

# 4. Lister toutes les catégories
Write-Host "📋 Liste des catégories..."
$listResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/expense-categories" -Method GET -Headers $headers

Write-Host "📊 Nombre de catégories: $($listResponse.data.Count)"
foreach ($category in $listResponse.data) {
    Write-Host "  - $($category.nom) (Couleur: $($category.couleur))"
}

Write-Host "🎉 Test terminé avec succès !"