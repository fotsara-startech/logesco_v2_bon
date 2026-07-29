# Script pour déployer tous les clients configurés
# Usage: .\deploy-all-clients.ps1 [-Production]

param(
    [Parameter(Mandatory=$false)]
    [switch]$Production
)

# Charger la configuration des clients
$config = Get-Content -Path "clients-config.json" | ConvertFrom-Json

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DÉPLOIEMENT MULTI-CLIENTS LOGESCO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nombre de clients à déployer: $($config.clients.Count)" -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failCount = 0
$results = @()

foreach ($client in $config.clients) {
    Write-Host "---" -ForegroundColor Gray
    Write-Host "Déploiement: $($client.displayName)" -ForegroundColor Cyan
    
    try {
        if ($Production) {
            & .\deploy-client.ps1 `
                -ClientName $client.name `
                -BackendUrl $client.backendUrl `
                -ProjectName $client.projectName `
                -Production
        } else {
            & .\deploy-client.ps1 `
                -ClientName $client.name `
                -BackendUrl $client.backendUrl `
                -ProjectName $client.projectName
        }
        
        if ($LASTEXITCODE -eq 0) {
            $successCount++
            $results += [PSCustomObject]@{
                Client = $client.displayName
                Status = "✓ Succès"
                Project = $client.projectName
            }
        } else {
            $failCount++
            $results += [PSCustomObject]@{
                Client = $client.displayName
                Status = "✗ Échec"
                Project = $client.projectName
            }
        }
    }
    catch {
        $failCount++
        $results += [PSCustomObject]@{
            Client = $client.displayName
            Status = "✗ Erreur: $_"
            Project = $client.projectName
        }
    }
    
    Write-Host ""
}

# Résumé
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RÉSUMÉ DES DÉPLOIEMENTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$results | Format-Table -AutoSize

Write-Host ""
Write-Host "Succès: $successCount" -ForegroundColor Green
Write-Host "Échecs: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""
