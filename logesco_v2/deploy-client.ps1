# Script de déploiement personnalisé par client sur Vercel
# Usage: .\deploy-client.ps1 -ClientName "nom-client" -BackendUrl "https://api-client.example.com" -ProjectName "logesco-client"

param(
    [Parameter(Mandatory=$true)]
    [string]$ClientName,
    
    [Parameter(Mandatory=$true)]
    [string]$BackendUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [switch]$Production
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Déploiement LOGESCO pour: $ClientName" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Build Flutter avec la configuration client
Write-Host "[1/3] Building Flutter Web avec URL backend: $BackendUrl" -ForegroundColor Yellow
flutter build web --release `
    --dart-define=IS_CLIENT_MODE=true `
    --dart-define=BASE_URL=$BackendUrl `
    --dart-define=ENABLE_LICENSE_CONTROL=false `
    --web-renderer canvaskit

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du build Flutter" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Build Flutter terminé" -ForegroundColor Green
Write-Host ""

# 2. Créer/Mettre à jour vercel.json dans build/web
Write-Host "[2/3] Configuration Vercel" -ForegroundColor Yellow

$vercelConfig = @{
    name = $ProjectName
    version = 2
    routes = @(
        @{
            src = "/(.*)"
            dest = "/index.html"
        }
    )
    headers = @(
        @{
            source = "/(.*)"
            headers = @(
                @{
                    key = "X-Client-Name"
                    value = $ClientName
                },
                @{
                    key = "X-Content-Type-Options"
                    value = "nosniff"
                },
                @{
                    key = "X-Frame-Options"
                    value = "DENY"
                },
                @{
                    key = "X-XSS-Protection"
                    value = "1; mode=block"
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

Set-Content -Path "build/web/vercel.json" -Value $vercelConfig
Write-Host "✓ Configuration Vercel créée" -ForegroundColor Green
Write-Host ""

# 3. Déployer sur Vercel
Write-Host "[3/3] Déploiement sur Vercel" -ForegroundColor Yellow
Set-Location build/web

if ($Production) {
    Write-Host "Déploiement en PRODUCTION..." -ForegroundColor Magenta
    vercel --prod --name $ProjectName --yes
} else {
    Write-Host "Déploiement en PREVIEW..." -ForegroundColor Yellow
    vercel --name $ProjectName --yes
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du déploiement Vercel" -ForegroundColor Red
    Set-Location ../..
    exit 1
}

Set-Location ../..

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Déploiement réussi pour $ClientName!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:"
Write-Host "  - Client: $ClientName"
Write-Host "  - Backend: $BackendUrl"
Write-Host "  - Projet: $ProjectName"
Write-Host ""
Write-Host "Pour voir le déploiement: https://vercel.com/black-tech-corps/$ProjectName"
