param(
    [Parameter(Mandatory=$true)]
    [string]$client
)

Write-Host "========================================"
Write-Host " SWITCH -> BASE CLIENT: $client"
Write-Host "========================================"

$envFile = ".env.client-$client"
if (-not (Test-Path $envFile)) {
    Write-Host "ERREUR: $envFile introuvable" -ForegroundColor Red
    Write-Host ""
    Write-Host "Clients disponibles:"
    Get-ChildItem ".env.client-*" | ForEach-Object { Write-Host "  - $($_.Name -replace '.env.client-','')" }
    exit 1
}

$dbFiles = @("prisma\database\logesco.db", "database\logesco.db")
foreach ($f in $dbFiles) {
    if (Test-Path $f) {
        Write-Host "Sauvegarde BD dev..."
        Copy-Item $f "$f.dev-backup" -Force -ErrorAction SilentlyContinue
        Remove-Item $f -Force -ErrorAction SilentlyContinue
        if (Test-Path $f) {
            Write-Host "[WARN] Impossible de supprimer $f - backend encore actif?" -ForegroundColor Yellow
        }
    }
}

Copy-Item $envFile ".env" -Force
Write-Host ""
Write-Host "[OK] .env pointe vers la BD client: $client" -ForegroundColor Green
Write-Host "[OK] Demarre le backend avec: npm start" -ForegroundColor Green
Write-Host "========================================"
