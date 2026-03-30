# Script PowerShell pour configurer l'adresse du serveur LOGESCO

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configuration du serveur LOGESCO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Demander l'adresse IP du serveur
$serverIp = Read-Host "Entrez l'adresse IP du serveur (ex: 192.168.100.101)"

# Demander le port (par défaut 8080)
$serverPort = Read-Host "Entrez le port du serveur (par défaut 8080)"
if ([string]::IsNullOrWhiteSpace($serverPort)) {
    $serverPort = "8080"
}

# Construire l'URL complète
$serverUrl = "http://$($serverIp):$($serverPort)/api/v1"

Write-Host ""
Write-Host "URL du serveur: $serverUrl" -ForegroundColor Yellow
Write-Host ""

# Créer le fichier de configuration dans le répertoire Documents
$configDir = [Environment]::GetFolderPath("MyDocuments")
$configFile = Join-Path $configDir "server_config.txt"

Write-Host "Création du fichier de configuration..."

try {
    $serverUrl | Out-File -FilePath $configFile -Encoding UTF8 -Force
    
    Write-Host ""
    Write-Host "✓ Configuration sauvegardée avec succès!" -ForegroundColor Green
    Write-Host "Fichier: $configFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "Redémarrez l'application LOGESCO pour appliquer les changements." -ForegroundColor Yellow
    Write-Host ""
} catch {
    Write-Host ""
    Write-Host "✗ Erreur lors de la création du fichier de configuration" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
    Write-Host ""
}

Read-Host "Appuyez sur Entrée pour fermer"
