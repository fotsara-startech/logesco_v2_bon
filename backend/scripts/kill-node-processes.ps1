# Script PowerShell pour arrêter tous les processus Node.js
# Utile quand Prisma est bloqué par un processus en cours

Write-Host "🔍 Recherche des processus Node.js en cours..." -ForegroundColor Cyan

$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue

if ($nodeProcesses) {
    Write-Host "`n📋 Processus Node.js trouvés:" -ForegroundColor Yellow
    $nodeProcesses | Format-Table Id, ProcessName, StartTime, @{Label="Memory (MB)"; Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}} -AutoSize
    
    Write-Host "`n⚠️  Voulez-vous arrêter tous ces processus? (O/N)" -ForegroundColor Yellow
    $confirmation = Read-Host
    
    if ($confirmation -eq 'O' -or $confirmation -eq 'o') {
        Write-Host "`n🛑 Arrêt des processus Node.js..." -ForegroundColor Red
        $nodeProcesses | ForEach-Object {
            try {
                Stop-Process -Id $_.Id -Force
                Write-Host "  ✅ Processus $($_.Id) arrêté" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Impossible d'arrêter le processus $($_.Id): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host "`n✅ Tous les processus Node.js ont été arrêtés" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Opération annulée" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n✅ Aucun processus Node.js en cours d'exécution" -ForegroundColor Green
}

Write-Host "`nAppuyez sur une touche pour continuer..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
