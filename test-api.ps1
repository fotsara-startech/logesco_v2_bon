# Test de l'API des rapports de remises

# 1. Authentification
$loginBody = @{
    nomUtilisateur = "admin"
    motDePasse = "admin123"
} | ConvertTo-Json

$authResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $authResponse.data.accessToken

Write-Host "✅ Authentification réussie"

# 2. Test du résumé des remises
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "🔍 Test du résumé des remises..."
$summaryResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/discount-reports/summary" -Method GET -Headers $headers

Write-Host "📊 Résultats du résumé:"
Write-Host "- Groupement: $($summaryResponse.data.groupBy)"
Write-Host "- Nombre de groupes: $($summaryResponse.data.groupes.Count)"
Write-Host "- Total des remises: $($summaryResponse.data.totaux.totalRemises) FCFA"
Write-Host "- Nombre de remises: $($summaryResponse.data.totaux.nombreRemises)"
Write-Host "- Remise moyenne: $($summaryResponse.data.totaux.remiseMoyenneGlobale) FCFA"

if ($summaryResponse.data.groupes.Count -gt 0) {
    Write-Host "📋 Groupes trouvés:"
    foreach ($groupe in $summaryResponse.data.groupes) {
        Write-Host "  - $($groupe.groupe): $($groupe.totalRemises) FCFA ($($groupe.nombreRemises) remises)"
    }
}

# 3. Test du rapport par vendeur
Write-Host "`n🔍 Test du rapport par vendeur..."
$vendorResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/discount-reports/by-vendor" -Method GET -Headers $headers

Write-Host "👥 Résultats par vendeur:"
Write-Host "- Nombre de ventes: $($vendorResponse.data.ventes.Count)"
Write-Host "- Nombre de statistiques vendeur: $($vendorResponse.data.statistiques.Count)"

if ($vendorResponse.data.statistiques.Count -gt 0) {
    Write-Host "📊 Statistiques par vendeur:"
    foreach ($stat in $vendorResponse.data.statistiques) {
        Write-Host "  - $($stat.vendeur.nomUtilisateur): $($stat.totalRemises) FCFA ($($stat.nombreVentes) ventes)"
    }
}

Write-Host "`n🎉 Tests terminés avec succès !"