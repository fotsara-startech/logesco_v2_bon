# Script pour tuer le process sur le port 8080 et redémarrer le backend
# Usage: .\kill-port-and-start.ps1

$PORT = 8080

Write-Host "=== Redémarrage Backend LOGESCO (port $PORT) ===" -ForegroundColor Cyan

# Trouver et tuer le process qui utilise le port 8080
$connections = netstat -aon | Select-String ":$PORT\s"
$pids = @()
foreach ($line in $connections) {
    if ($line -match '\s+(\d+)\s*$') {
        $pids += [int]$Matches[1]
    }
}
$pids = $pids | Sort-Object -Unique | Where-Object { $_ -gt 0 }

if ($pids.Count -gt 0) {
    Write-Host "Process occupant le port $PORT : $($pids -join ', ')" -ForegroundColor Yellow
    foreach ($pid in $pids) {
        try {
            Stop-Process -Id $pid -Force -ErrorAction Stop
            Write-Host "  ✅ Process $pid tué" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Impossible de tuer le process $pid : $_" -ForegroundColor Red
        }
    }
    Start-Sleep -Seconds 1
} else {
    Write-Host "Port $PORT libre" -ForegroundColor Green
}

Write-Host "Démarrage du backend..." -ForegroundColor Cyan
npm start
