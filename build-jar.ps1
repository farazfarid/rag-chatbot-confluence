<#
.SYNOPSIS
    Build Script für Confluence RAG Chatbot JAR (ohne AWS CLI).
.PARAMETER Version
    Version für das Artefakt (Standard: 1.0.0).
.PARAMETER NonInteractive
    Unterdrückt interaktive Pausen (CI-Modus).
.PARAMETER Verbose
    Gibt Maven-Output detailliert aus.
#>
param(
    [string]$Version = '1.0.0',
    [switch]$NonInteractive,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

function Pause {
    param([string]$Message = 'Press Enter to continue...')
    if (-not $NonInteractive) {
        Read-Host $Message
    }
}

Write-Host "Building Confluence RAG Chatbot JAR (v$Version)..." -ForegroundColor Cyan

# 1) Prerequisites prüfen
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Maven prüfen
$mvnOutput = cmd.exe /c "mvn -version 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Maven nicht gefunden. Bitte Maven 3.6+ installieren."
    Write-Host "Download: https://maven.apache.org/download.cgi" -ForegroundColor Yellow
    Pause
    exit 1
}
$mvnLine = ($mvnOutput | Select-Object -First 1).Trim()
Write-Host "Maven found: $mvnLine" -ForegroundColor Green

# Java prüfen via cmd.exe
$javaOutput = cmd.exe /c "java -version 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Java nicht gefunden. Bitte Java 11+ installieren."
    Write-Host "Download: https://adoptium.net/" -ForegroundColor Yellow
    Pause
    exit 1
}
$javaLine = ($javaOutput | Select-Object -First 1).Trim()
Write-Host "Java found: $javaLine" -ForegroundColor Green

# Java-Version extrahieren und prüfen
$match = [regex]::Match($javaLine, '"?(\d+)(?:\.(\d+))?')
if ($match.Success) {
    $major = [int]$match.Groups[1].Value
    # For Java 9+, the version number is just the major version (e.g., 11, 17, 21)
    # For Java 8 and below, it's 1.x format
    if ($major -eq 1 -and $match.Groups[2].Success) {
        $major = [int]$match.Groups[2].Value
    }
    if ($major -lt 11) {
        Write-Error "Java 11+ erforderlich. Gefunden: $major"
        Pause
        exit 1
    }
    Write-Host "Java version: $major (OK)" -ForegroundColor Green
} else {
    Write-Warning "Konnte Java-Version nicht parsen. Fortsetzung auf eigene Gefahr."
}

# 2) Build
$appDir = 'confluence-app'
if (-not (Test-Path $appDir -PathType Container)) {
    Write-Error "Verzeichnis '$appDir' existiert nicht."
    exit 1
}
Push-Location $appDir

Write-Host 'Running Maven clean & package...' -ForegroundColor Cyan
Write-Host 'Clearing dependency cache...' -ForegroundColor Yellow

# Force update of snapshots and clear cache for problematic dependencies
$mvnArgs = @('dependency:purge-local-repository', 'clean', 'package', '-U', '--fail-at-end')
if (-not $Verbose) { $mvnArgs += '-q' }

# Maven via cmd.exe für konsistente Stream-Behandlung
cmd.exe /c "mvn $($mvnArgs -join ' ') 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ Maven Build fehlgeschlagen." -ForegroundColor Red
    Write-Host "Versuche alternative Lösungen..." -ForegroundColor Yellow
    
    # Try with just basic clean package and force updates
    Write-Host "Versuche vereinfachten Build..." -ForegroundColor Yellow
    $simpleArgs = @('clean', 'compile', 'package', '-U', '-Dmaven.test.skip=true')
    if (-not $Verbose) { $simpleArgs += '-q' }
    
    cmd.exe /c "mvn $($simpleArgs -join ' ') 2>&1"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Auch der vereinfachte Build ist fehlgeschlagen. Mit -Verbose mehr Details."
        Pop-Location
        Pause
        exit 1
    }
}

# 3) Ergebnis prüfen
$jar = "target\confluence-rag-chatbot-$Version.jar"
if (Test-Path $jar) {
    $sizeMB = [math]::Round((Get-Item $jar).Length /1MB, 2)
    Write-Host "Build erfolgreich: $jar ($($sizeMB) MB)" -ForegroundColor Green
} else {
    Write-Error "JAR nicht gefunden: $jar"
    Pop-Location
    Pause
    exit 1
}

Pop-Location
Pause 'Fertig. Enter zum Beenden...'
