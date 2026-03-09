# Test API avec version v1
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TEST API BACKEND (v1)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Arrêter processus existants
Write-Host "Arret processus..." -ForegroundColor Yellow
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Démarrer backend
Write-Host "Demarrage backend..." -ForegroundColor Yellow
Set-Location backend
Start-Process -FilePath "node" -ArgumentList "src/server.js" -WindowStyle Hidden
Set-Location ..

Write-Host "Attente 15 secondes..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
Write-Host ""

# Tests avec /api/v1/
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TESTS API v1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Test Health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get
    Write-Host "✅ Backend repond" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend ne repond pas" -ForegroundColor Red
}
Write-Host ""

Write-Host "[2/4] Test Users (v1)..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users" -Method Get
    if ($users.Count -gt 0) {
        Write-Host "✅ $($users.Count) utilisateurs trouves" -ForegroundColor Green
        Write-Host "Premier utilisateur:" -ForegroundColor Cyan
        Write-Host ($users[0] | ConvertTo-Json -Depth 2)
    } else {
        Write-Host "⚠️  API retourne tableau vide" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Essai sans authentification..." -ForegroundColor Yellow
}
Write-Host ""

Write-Host "[3/4] Test Products (v1)..." -ForegroundColor Yellow
try {
    $products = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/products" -Method Get
    if ($products.Count -gt 0) {
        Write-Host "✅ $($products.Count) produits trouves" -ForegroundColor Green
        Write-Host "Premier produit:" -ForegroundColor Cyan
        Write-Host ($products[0] | ConvertTo-Json -Depth 2)
    } else {
        Write-Host "⚠️  API retourne tableau vide" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "[4/4] Test Categories (v1)..." -ForegroundColor Yellow
try {
    $categories = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/categories" -Method Get
    if ($categories.Count -gt 0) {
        Write-Host "✅ $($categories.Count) categories trouvees" -ForegroundColor Green
    } else {
        Write-Host "⚠️  API retourne tableau vide" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Arrêter backend
Write-Host "Arret backend..." -ForegroundColor Yellow
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "PROBLEME IDENTIFIE:" -ForegroundColor Yellow
Write-Host "  Les routes utilisent /api/v1/ et non /api/" -ForegroundColor White
Write-Host ""

Write-Host "Si les tests ci-dessus montrent des donnees:" -ForegroundColor Green
Write-Host "  ✅ Backend fonctionne correctement" -ForegroundColor White
Write-Host "  ✅ Prisma lit les donnees" -ForegroundColor White
Write-Host "  → Le probleme est dans l'application Flutter" -ForegroundColor White
Write-Host "  → L'app utilise probablement /api/ au lieu de /api/v1/" -ForegroundColor White
Write-Host ""

Write-Host "SOLUTION:" -ForegroundColor Cyan
Write-Host "  Verifier l'URL dans l'application Flutter" -ForegroundColor White
Write-Host "  Doit etre: http://localhost:8080/api/v1/" -ForegroundColor White
Write-Host ""

Write-Host "Appuyez sur une touche pour continuer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
