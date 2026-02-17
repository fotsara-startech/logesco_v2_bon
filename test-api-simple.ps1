# Test simple de l'API des rapports de remises

$loginBody = @{
    nomUtilisateur = "admin"
    motDePasse = "admin123"
} | ConvertTo-Json

$authResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
$token = $authResponse.data.accessToken

Write-Host "Authentification reussie"

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "Test du resume des remises..."
$summaryResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/discount-reports/summary" -Method GET -Headers $headers

Write-Host "Resultats:"
Write-Host "- Total des remises: $($summaryResponse.data.totaux.totalRemises) FCFA"
Write-Host "- Nombre de remises: $($summaryResponse.data.totaux.nombreRemises)"
Write-Host "- Nombre de groupes: $($summaryResponse.data.groupes.Count)"

$summaryResponse.data | ConvertTo-Json -Depth 10