# Simple Maven Build Script
# This script performs a basic build without complex dependency management

param(
    [switch]$Verbose,
    [switch]$ClearCache
)

$ErrorActionPreference = "Stop"

Write-Host "🔨 Simple Confluence RAG Chatbot Build" -ForegroundColor Cyan
Write-Host ""

# Check Maven
Write-Host "Checking Maven..." -ForegroundColor Yellow
$mvnOutput = cmd.exe /c "mvn -version 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Maven not found. Please install Maven 3.6+"
    exit 1
}
$mvnLine = ($mvnOutput | Select-Object -First 1).Trim()
Write-Host "✅ $mvnLine" -ForegroundColor Green

# Check Java
Write-Host "Checking Java..." -ForegroundColor Yellow
$javaOutput = cmd.exe /c "java -version 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Java not found. Please install Java 11+"
    exit 1
}
$javaLine = ($javaOutput | Select-Object -First 1).Trim()
Write-Host "✅ $javaLine" -ForegroundColor Green

Set-Location confluence-app

if ($ClearCache) {
    Write-Host "🧹 Clearing Maven cache..." -ForegroundColor Yellow
    Remove-Item -Path "$env:USERPROFILE\.m2\repository\com\confluence\rag" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:USERPROFILE\.m2\repository\software\amazon" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:USERPROFILE\.m2\repository\javax\activation" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "📦 Building JAR..." -ForegroundColor Cyan

# Simple build approach
try {
    Write-Host "Step 1: Clean project..." -ForegroundColor Yellow
    if ($Verbose) {
        mvn clean
    } else {
        mvn clean -q
    }
    
    Write-Host "Step 2: Compile sources..." -ForegroundColor Yellow
    if ($Verbose) {
        mvn compile -U
    } else {
        mvn compile -U -q
    }
    
    Write-Host "Step 3: Package JAR..." -ForegroundColor Yellow
    if ($Verbose) {
        mvn package -Dmaven.test.skip=true -U
    } else {
        mvn package -Dmaven.test.skip=true -U -q
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Maven build failed"
    }
    
} catch {
    Write-Host "❌ Build failed. Trying with offline mode..." -ForegroundColor Red
    try {
        if ($Verbose) {
            mvn clean compile package -Dmaven.test.skip=true -o
        } else {
            mvn clean compile package -Dmaven.test.skip=true -o -q
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Offline build also failed"
        }
        Write-Host "✅ Offline build succeeded!" -ForegroundColor Green
    } catch {
        Write-Host "❌ All build attempts failed" -ForegroundColor Red
        Write-Host "Try running with -Verbose for more details" -ForegroundColor Yellow
        Write-Host "Or try clearing cache with -ClearCache" -ForegroundColor Yellow
        Set-Location ..
        exit 1
    }
}

# Check result
$jarPath = "target\confluence-rag-chatbot-1.0.0.jar"
if (Test-Path $jarPath) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    $fileSize = (Get-Item $jarPath).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    Write-Host "📁 JAR: $jarPath ($fileSizeMB MB)" -ForegroundColor White
    Write-Host ""
    Write-Host "🎉 Ready for Confluence installation!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Go to Confluence Administration → Manage Apps" -ForegroundColor White
    Write-Host "2. Click 'Upload app'" -ForegroundColor White
    Write-Host "3. Select: confluence-app\$jarPath" -ForegroundColor White
    Write-Host "4. Configure in Administration → RAG Chatbot" -ForegroundColor White
} else {
    Write-Host "❌ JAR file not found after build" -ForegroundColor Red
    exit 1
}

Set-Location ..
Write-Host ""
Read-Host "Press Enter to continue"
