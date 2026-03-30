# ============================================================
# LOGESCO v2 - Déploiement Client Réseau
# Script PowerShell pour déployer l'application sur plusieurs clients
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$InstallerPath,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientsFile,
    
    [string]$ServerAddress = "192.168.1.100",
    [int]$ServerPort = 3000,
    [switch]$Silent = $false,
    [switch]$NoRestart = $false
)

# Couleurs pour l'affichage
$colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = $colors[$Level]
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-ClientConnection {
    param(
        [string]$ComputerName
    )
    
    Write-Log "Test de connexion à $ComputerName..." "Info"
    
    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        Write-Log "✓ $ComputerName est accessible" "Success"
        return $true
    } else {
        Write-Log "✗ $ComputerName n'est pas accessible" "Error"
        return $false
    }
}

function Deploy-Installer {
    param(
        [string]$ComputerName,
        [string]$InstallerPath,
        [bool]$Silent,
        [bool]$NoRestart
    )
    
    Write-Log "Déploiement sur $ComputerName..." "Info"
    
    try {
        # Créer le chemin UNC
        $uncPath = "\\$ComputerName\c$\Temp"
        
        # Copier l'installeur
        Write-Log "Copie de l'installeur vers $ComputerName..." "Info"
        Copy-Item -Path $InstallerPath -Destination $uncPath -Force
        
        # Construire la ligne de commande
        $installerName = Split-Path -Leaf $InstallerPath
        $installerRemotePath = "C:\Temp\$installerName"
        
        $arguments = "/VERYSILENT"
        if ($NoRestart) {
            $arguments += " /NORESTART"
        }
        
        # Exécuter l'installeur
        Write-Log "Exécution de l'installeur sur $ComputerName..." "Info"
        
        $session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
        
        Invoke-Command -Session $session -ScriptBlock {
            param($path, $args)
            & $path $args
        } -ArgumentList $installerRemotePath, $arguments
        
        Remove-PSSession $session
        
        Write-Log "✓ Déploiement réussi sur $ComputerName" "Success"
        return $true
    }
    catch {
        Write-Log "✗ Erreur lors du déploiement sur $ComputerName : $_" "Error"
        return $false
    }
}

function Configure-ClientServer {
    param(
        [string]$ComputerName,
        [string]$ServerAddress,
        [int]$ServerPort
    )
    
    Write-Log "Configuration du serveur sur $ComputerName..." "Info"
    
    try {
        $session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
        
        $configPath = "$env:LOCALAPPDATA\LOGESCO\client\client-network-config.json"
        
        $configContent = @{
            serverConfig = @{
                host = $ServerAddress
                port = $ServerPort
                protocol = "http"
                baseUrl = "http://$($ServerAddress):$($ServerPort)"
            }
            clientInfo = @{
                clientId = "client-$ComputerName"
                clientName = $ComputerName
                version = "2.0.0"
            }
            features = @{
                offlineMode = $false
                localDatabase = $false
                requiresServerConnection = $true
            }
            ui = @{
                language = "fr"
                theme = "light"
            }
        } | ConvertTo-Json
        
        Invoke-Command -Session $session -ScriptBlock {
            param($path, $content)
            
            $dir = Split-Path -Parent $path
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            
            $content | Out-File -FilePath $path -Encoding UTF8 -Force
        } -ArgumentList $configPath, $configContent
        
        Remove-PSSession $session
        
        Write-Log "✓ Configuration appliquée sur $ComputerName" "Success"
        return $true
    }
    catch {
        Write-Log "✗ Erreur lors de la configuration de $ComputerName : $_" "Error"
        return $false
    }
}

# ============================================================
# Script principal
# ============================================================

Write-Log "========================================" "Info"
Write-Log "LOGESCO v2 - Déploiement Client Réseau" "Info"
Write-Log "========================================" "Info"
Write-Log ""

# Vérifier que l'installeur existe
if (-not (Test-Path $InstallerPath)) {
    Write-Log "ERREUR: L'installeur n'existe pas: $InstallerPath" "Error"
    exit 1
}

Write-Log "Installeur: $InstallerPath" "Info"
Write-Log "Serveur: $ServerAddress`:$ServerPort" "Info"
Write-Log ""

# Vérifier que le fichier clients existe
if (-not (Test-Path $ClientsFile)) {
    Write-Log "ERREUR: Le fichier clients n'existe pas: $ClientsFile" "Error"
    exit 1
}

# Lire la liste des clients
$clients = Get-Content $ClientsFile | Where-Object { $_ -and -not $_.StartsWith("#") }

if ($clients.Count -eq 0) {
    Write-Log "ERREUR: Aucun client trouvé dans $ClientsFile" "Error"
    exit 1
}

Write-Log "Nombre de clients: $($clients.Count)" "Info"
Write-Log ""

# Statistiques
$stats = @{
    Total = $clients.Count
    Success = 0
    Failed = 0
    Skipped = 0
}

# Déployer sur chaque client
foreach ($client in $clients) {
    $client = $client.Trim()
    
    Write-Log "---" "Info"
    Write-Log "Traitement de $client..." "Info"
    
    # Test de connexion
    if (-not (Test-ClientConnection $client)) {
        Write-Log "Client $client ignoré (non accessible)" "Warning"
        $stats.Skipped++
        continue
    }
    
    # Déploiement
    if (Deploy-Installer -ComputerName $client -InstallerPath $InstallerPath -Silent $Silent -NoRestart $NoRestart) {
        # Configuration
        if (Configure-ClientServer -ComputerName $client -ServerAddress $ServerAddress -ServerPort $ServerPort) {
            $stats.Success++
        } else {
            $stats.Failed++
        }
    } else {
        $stats.Failed++
    }
}

# Résumé
Write-Log ""
Write-Log "========================================" "Info"
Write-Log "Résumé du déploiement" "Info"
Write-Log "========================================" "Info"
Write-Log "Total: $($stats.Total)" "Info"
Write-Log "Réussis: $($stats.Success)" "Success"
Write-Log "Échoués: $($stats.Failed)" $(if ($stats.Failed -gt 0) { "Error" } else { "Info" })
Write-Log "Ignorés: $($stats.Skipped)" $(if ($stats.Skipped -gt 0) { "Warning" } else { "Info" })
Write-Log ""

if ($stats.Failed -gt 0) {
    exit 1
} else {
    exit 0
}
