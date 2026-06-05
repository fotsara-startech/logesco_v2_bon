Write-Host "========================================"
Write-Host " SWITCH -> BASE DE DEV"
Write-Host "========================================"

# Arreter le backend si en cours (optionnel)
$dbFiles = @("prisma\database\logesco.db", "database\logesco.db")
foreach ($f in $dbFiles) {
    if (Test-Path $f) {
        Write-Host "Sauvegarde BD client..."
        Copy-Item $f "$f.client-backup" -Force -ErrorAction SilentlyContinue
        Remove-Item $f -Force -ErrorAction SilentlyContinue
        if (Test-Path $f) {
            Write-Host "[WARN] Impossible de supprimer $f - backend encore actif?" -ForegroundColor Yellow
        }
    }
}

Copy-Item ".env.dev" ".env" -Force
Write-Host ""
Write-Host "[OK] .env pointe vers la BD de DEV" -ForegroundColor Green
Write-Host "[OK] Demarre le backend avec: npm start" -ForegroundColor Green
Write-Host "========================================"
