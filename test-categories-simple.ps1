# Test simple des categories de depenses

# 1. Authentification
$loginBody = @{
    nomUtilisateur = "admin"
    motDePasse = "admin123"
} | ConvertTo-Json

$authResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $authResponse.data.accessToken

Write-Host "Authentification reussie"

# 2. Headers pour les requetes
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 3. Creer une categorie de test
Write-Host "Creation d'une categorie de test..."
$categoryBody = @{
    nom = "Fournitures de bureau"
    couleur = "#4CAF50"
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/expense-categories" -Method POST -Body $categoryBody -Headers $headers
    Write-Host "Categorie creee: $($createResponse.data.displayName)"
} catch {
    Write-Host "Erreur creation: $($_.Exception.Message)"
}

# 4. Lister toutes les categories
Write-Host "Liste des categories..."
$listResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/expense-categories" -Method GET -Headers $headers

Write-Host "Nombre de categories: $($listResponse.data.Count)"
foreach ($category in $listResponse.data) {
    Write-Host "  - $($category.displayName) (Couleur: $($category.color))"
}

Write-Host "Test termine avec succes !"