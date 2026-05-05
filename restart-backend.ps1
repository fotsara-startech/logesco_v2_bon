# Script PowerShell pour redémarrer proprement le backend
# Usage: .\restart-backend.ps1

Write-Host "=== Redémarrage du Backend LOGESCO ===" -ForegroundColor Cyan
Write-Host ""

# 1. Arrêter tous les processus Node.js
Write-Host "1. Arrêt des processus Node.js..." -ForegroundColor Yellow
$nodeProcesses = Get-Process node -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "   Processus Node trouvés: $($nodeProcesses.Count)" -ForegroundColor Gray
    Stop-Process -Name node -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "   ✅ Processus Node arrêtés" -ForegroundColor Green
} else {
    Write-Host "   ℹ️  Aucun processus Node en cours" -ForegroundColor Gray
}
Write-Host ""

# 2. Vérifier qu'aucun processus ne tourne
Write-Host "2. Vérification..." -ForegroundColor Yellow
$remainingProcesses = Get-Process node -ErrorAction SilentlyContinue
if ($remainingProcesses) {
    Write-Host "   ⚠️  Certains processus Node sont encore actifs" -ForegroundColor Red
    Write-Host "   Veuillez les fermer manuellement" -ForegroundColor Red
    exit 1
} else {
    Write-Host "   ✅ Aucun processus Node actif" -ForegroundColor Green
}
Write-Host ""

# 3. Démarrer le backend
Write-Host "3. Démarrage du backend..." -ForegroundColor Yellow
Write-Host "   Commande: npm start" -ForegroundColor Gray
Write-Host ""
Write-Host "=== Logs du Backend ===" -ForegroundColor Cyan
Write-Host ""

npm start
