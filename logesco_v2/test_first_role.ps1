$body = @{
    nom = "ADMIN"
    displayName = "Administrateur"
    isAdmin = $true
    privileges = @{}
} | ConvertTo-Json -Depth 3

$response = Invoke-WebRequest -Uri "http://localhost:3002/api/v1/roles" -Method POST -Body $body -ContentType "application/json"

Write-Host "Status: $($response.StatusCode)"
Write-Host "Response: $($response.Content)"