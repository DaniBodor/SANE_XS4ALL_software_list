# This script is based on https://gitlab.com/rsc-surf-nl/plugins/ollama-windows/-/blob/main/ollama-windows.ps1
# Despite not being licensed at the time, permission was given by the author of the script to use it in this project.

# The script downloads the SolrWayback bundle, extracts it, and copies the
# required properties files into the configured user home folder.

# Run as Administrator
#

# Expected env vars for installation:
$Default_Version = "5.4.2"
$Default_GithubBaseUrl = "https://github.com/netarchivesuite/solrwayback/releases/download"
$Default_InstallDir = "C:\Program Files\solrwayback"
$Default_UserHome = Join-Path $Default_InstallDir "user\home"
$Default_JavaHome = "C:\Program Files\Java\jdk-11"

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

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (!(Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

try {
    Assert-Admin

    Write-Log "Checking for Java 11 installation"

    # Install Java11 if not found
    $JavaHome = Get-EnvVar `
        -Name "JAVA_HOME" `
        -Default $Default_JavaHome

    if (!(Test-Path $JavaHome)) {
        $msi = Join-Path $env:TEMP "temurin11.msi"
        $javaInstallerUrl = "https://aka.ms/download-jdk/microsoft-jdk-11-windows-x64.msi"

        Write-Log "Java 11 not detected; downloading Java 11 MSI from $javaInstallerUrl"
        Invoke-WebRequest -Uri $javaInstallerUrl -OutFile $msi

        Write-Log "Installing Java 11 to $Default_JavaHome"
        Start-Process -FilePath 'msiexec.exe' -Wait -ArgumentList "/i", "`"$msi`"", "INSTALLDIR=`"$Default_JavaHome`"", "/qn"

        $JavaHome = Get-EnvVar `
            -Name "JAVA_HOME" `
            -Default $Default_JavaHome

        if (!(Test-Path $JavaHome)) {
            throw "JAVA_HOME path does not exist after running installer: $JavaHome"
        }
    }

    Write-Log "Starting SolrWayback installation"

    $SolrwaybackVersion = Get-EnvVar `
        -Name "SOLRWAYBACK_VERSION"`
        -Default $Default_Version
    $GithubBaseUrl = Get-EnvVar `
        -Name "SOLRWAYBACK_GITHUB_BASE_URL" `
        -Default $Default_GithubBaseUrl
    $InstallDir = Get-EnvVar `
        -Name "SOLRWAYBACK_INSTALL_DIR" `
        -Default $Default_InstallDir
    $UserHome = Get-EnvVar `
        -Name "SOLRWAYBACK_USER_HOME" `
        -Default $Default_UserHome

    $VersionToken = if ($SolrwaybackVersion.StartsWith("v")) { $SolrwaybackVersion.Substring(1) } else { $SolrwaybackVersion }
    $VersionedPackageName = "solrwayback_package_$VersionToken"
    $AssetName = "$VersionedPackageName.zip"
    $DownloadUrl = "$GithubBaseUrl/$VersionToken/$AssetName"

    $TempDir = "C:\Temp\solrwayback"
    $ZipPath = Join-Path $TempDir $AssetName

    Write-Log "Version: $VersionToken"
    Write-Log "Download URL: $DownloadUrl"
    Write-Log "Install dir: $InstallDir"
    Write-Log "User home: $UserHome"
    Write-Log "Java home: $JavaHome"

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

    $FilesToCopy = @(
    "solrwayback.properties",
    "solrwaybackweb.properties"
    )

    $PackageLocation = Join-Path $InstallDir $VersionedPackageName
    $PropertiesPath = Join-Path $PackageLocation "properties"

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
    Write-Log "Users may need to sign out/in before proceeding."
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
