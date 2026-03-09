# Test API Simple - PowerShell
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TEST API BACKEND SIMPLE" -ForegroundColor Cyan
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

# Tests
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TESTS API" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Test Health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get
    Write-Host "✅ Backend repond" -ForegroundColor Green
    Write-Host ($health | ConvertTo-Json)
} catch {
    Write-Host "❌ Backend ne repond pas" -ForegroundColor Red
}
Write-Host ""

Write-Host "[2/3] Test Users..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8080/api/users" -Method Get
    if ($users.Count -gt 0) {
        Write-Host "✅ $($users.Count) utilisateurs trouves" -ForegroundColor Green
        Write-Host "Exemple:" -ForegroundColor Cyan
        Write-Host ($users[0] | ConvertTo-Json)
    } else {
        Write-Host "⚠️  API retourne tableau vide" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur API Users: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "[3/3] Test Products..." -ForegroundColor Yellow
try {
    $products = Invoke-RestMethod -Uri "http://localhost:8080/api/products" -Method Get
    if ($products.Count -gt 0) {
        Write-Host "✅ $($products.Count) produits trouves" -ForegroundColor Green
        Write-Host "Exemple:" -ForegroundColor Cyan
        Write-Host ($products[0] | ConvertTo-Json)
    } else {
        Write-Host "⚠️  API retourne tableau vide" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erreur API Products: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Arrêter backend
Write-Host "Arret backend..." -ForegroundColor Yellow
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  INTERPRETATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Si API retourne des donnees:" -ForegroundColor Green
Write-Host "  → Backend fonctionne correctement" -ForegroundColor White
Write-Host "  → Le probleme est dans l'application Flutter" -ForegroundColor White
Write-Host ""

Write-Host "Si API retourne tableau vide []:" -ForegroundColor Yellow
Write-Host "  → Prisma ne lit pas les donnees" -ForegroundColor White
Write-Host "  → Verifier schema.prisma" -ForegroundColor White
Write-Host ""

Write-Host "Si erreurs:" -ForegroundColor Red
Write-Host "  → Verifier backend\logs\error.log" -ForegroundColor White
Write-Host ""

Write-Host "Appuyez sur une touche pour continuer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
