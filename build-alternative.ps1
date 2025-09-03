# Alternative Build Script for Confluence RAG Chatbot
# This script tries the simple build first, then falls back to the full build

param(
    [switch]$Verbose,
    [switch]$UseSimple
)

$ErrorActionPreference = "Stop"

Write-Host "🔨 Confluence RAG Chatbot Alternative Build Script" -ForegroundColor Cyan
Write-Host ""

# Check Maven
$mvnOutput = cmd.exe /c "mvn -version 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Maven not found. Please install Maven 3.6+"
    exit 1
}
$mvnLine = ($mvnOutput | Select-Object -First 1).Trim()
Write-Host "✅ Maven: $mvnLine" -ForegroundColor Green

# Check Java
$javaOutput = cmd.exe /c "java -version 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Java not found. Please install Java 11+"
    exit 1
}
$javaLine = ($javaOutput | Select-Object -First 1).Trim()
Write-Host "✅ Java: $javaLine" -ForegroundColor Green

Set-Location confluence-app

if ($UseSimple) {
    Write-Host "🎯 Using simple build configuration..." -ForegroundColor Yellow
    $pomFile = "pom-simple.xml"
} else {
    Write-Host "🎯 Trying main build configuration first..." -ForegroundColor Yellow
    $pomFile = "pom.xml"
}

# Try main build
Write-Host "📦 Building with $pomFile..." -ForegroundColor Yellow
try {
    if ($Verbose) {
        mvn -f $pomFile clean package
    } else {
        mvn -f $pomFile clean package -q
    }
    
    if ($LASTEXITCODE -eq 0) {
        $jarPath = "target\confluence-rag-chatbot-1.0.0.jar"
        if (Test-Path $jarPath) {
            Write-Host "✅ Build successful!" -ForegroundColor Green
            $fileSize = (Get-Item $jarPath).Length
            $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
            Write-Host "📁 JAR: $jarPath ($fileSizeMB MB)" -ForegroundColor White
            Set-Location ..
            exit 0
        }
    }
} catch {
    Write-Host "❌ Build failed with $pomFile" -ForegroundColor Red
}

# If main build failed and we haven't tried simple yet, try simple
if (-not $UseSimple) {
    Write-Host "🔄 Trying simple build configuration..." -ForegroundColor Yellow
    try {
        if ($Verbose) {
            mvn -f pom-simple.xml clean package
        } else {
            mvn -f pom-simple.xml clean package -q
        }
        
        if ($LASTEXITCODE -eq 0) {
            $jarPath = "target\confluence-rag-chatbot-1.0.0.jar"
            if (Test-Path $jarPath) {
                Write-Host "✅ Simple build successful!" -ForegroundColor Green
                $fileSize = (Get-Item $jarPath).Length
                $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
                Write-Host "📁 JAR: $jarPath ($fileSizeMB MB)" -ForegroundColor White
                Write-Host "ℹ️ Note: Using simplified dependencies" -ForegroundColor Cyan
                Set-Location ..
                exit 0
            }
        }
    } catch {
        Write-Host "❌ Simple build also failed" -ForegroundColor Red
    }
}

Write-Host "❌ All build attempts failed. Please check:" -ForegroundColor Red
Write-Host "  - Internet connection for dependency downloads" -ForegroundColor Yellow
Write-Host "  - Maven and Java versions" -ForegroundColor Yellow
Write-Host "  - Run with -Verbose to see detailed errors" -ForegroundColor Yellow

Set-Location ..
exit 1
