# This script is based on https://gitlab.com/rsc-surf-nl/plugins/ollama-windows/-/blob/main/ollama-windows.ps1
# Despite not being licensed at the time, permission was given by the author of the script to use it in this project.

# The script downloads the SolrWayback bundle, extracts it, and copies the
# required properties files into the configured user home folder.

# Run as Administrator
#
# Expected env vars for installation:
#   SOLRWAYBACK_VERSION=5.4.2
#   SOLRWAYBACK_GITHUB_BASE_URL=https://github.com/netarchivesuite/solrwayback/releases/download
#   SOLRWAYBACK_INSTALL_DIR=C:\Program Files\solrwayback
#   SOLRWAYBACK_USER_HOME=C:\Program Files\solrwayback\user\home
#
# Required Windows-only env var:
#   JAVA_HOME=C:\Program Files\Java\jdk-11
#

$ErrorActionPreference = "Stop"
$LogFile = "C:\logs\install-solrwayback.log"

function Write-Log {
    param([string]$Message)

    $dir = Split-Path $LogFile -Parent
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $line = "{0:u}: {1}" -f (Get-Date), $Message
    $line | Tee-Object -FilePath $LogFile -Append
}

function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Please run this script as an Administrator."
    }
}

function Get-EnvVar {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Default = $null
    )

    $value = [Environment]::GetEnvironmentVariable($Name, "Machine")

    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    }

    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value
}

function Get-EnvVarOrFail {
    param([Parameter(Mandatory = $true)][string]$Name)

    $value = Get-EnvVar -Name $Name

    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Required environment variable '$Name' is not set or empty."
    }

    return $value
}

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Resolve-ExtractedPropertiesPath {
    param([Parameter(Mandatory = $true)][string]$BaseDir)
    $bundle = Join-Path $BaseDir "src\bundle\properties"
    if (Test-Path $bundle) {
        return $bundle
    }

    throw "Required properties folder not found at exact path: $bundle"
}

try {
    Assert-Admin
    Write-Log "Starting SolrWayback installation"

    $SolrwaybackVersion = Get-EnvVar `
        -Name "SOLRWAYBACK_VERSION"`
        -Default "5.4.2"

    $GithubBaseUrl = Get-EnvVar `
    -Name "SOLRWAYBACK_GITHUB_BASE_URL" `
    -Default "https://github.com/netarchivesuite/solrwayback/releases/download"
    $InstallDir = Get-EnvVar`
        -Name "SOLRWAYBACK_INSTALL_DIR" `
        -Default "C:\Program Files\solrwayback"
    $UserHome = Get-EnvVar `
        -Name "SOLRWAYBACK_USER_HOME" `
        -Default (Join-Path $InstallDir "user\home")
    $JavaHome = Get-EnvVarOrFail `
        -Name "JAVA_HOME"

    if (!(Test-Path $JavaHome)) {
        throw "JAVA_HOME path does not exist: $JavaHome"
    }

    $VersionToken = if ($SolrwaybackVersion.StartsWith("v")) { $SolrwaybackVersion.Substring(1) } else { $SolrwaybackVersion }
    $AssetName = "solrwayback_package_$VersionToken.zip"
    $DownloadUrl = "$GithubBaseUrl/$VersionToken/$AssetName"

    $TempDir = "C:\Temp\solrwayback"
    $ZipPath = Join-Path $TempDir $AssetName

    Write-Log "Version: $VersionToken"
    Write-Log "Download URL: $DownloadUrl"
    Write-Log "Install dir: $InstallDir"
    Write-Log "User home: $UserHome"
    Write-Log "JAVA_HOME: $JavaHome"

    Ensure-Directory $TempDir
    Ensure-Directory $InstallDir
    Ensure-Directory $UserHome

    Write-Log "Downloading SolrWayback bundle"
    curl.exe `
        -L `
        --fail `
        --output $ZipPath `
        $DownloadUrl

    if ($LASTEXITCODE -ne 0) {
        throw "Download failed with exit code $LASTEXITCODE"
    }

    Write-Log "Extracting SolrWayback bundle to $InstallDir"
    Expand-Archive `
        -Path $ZipPath `
        -DestinationPath $InstallDir `
        -Force

    $PropertiesPath = Resolve-ExtractedPropertiesPath -BaseDir $InstallDir

    $FilesToCopy = @(
        "solrwayback.properties",
        "solrwaybackweb.properties"
    )

    foreach ($fileName in $FilesToCopy) {
        $sourceFile = Join-Path $PropertiesPath $fileName
        if (!(Test-Path $sourceFile)) {
            throw "Required properties file not found: $sourceFile"
        }

        Copy-Item -Path $sourceFile -Destination $UserHome -Force
        Write-Log "Copied $fileName to $UserHome"
    }

    Write-Log "SolrWayback installation complete"
    Write-Log "If screenshot previews are required, verify chrome.command and screenshot.temp.imagedir in $UserHome\solrwayback.properties"
    Write-Log "Users may need to sign out/in before JAVA_HOME is visible in new sessions."
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
