# Enhanced Build Script - SOPTIM Community Elements Chatbot
param([switch]$Verbose, [switch]$SkipValidation)

Write-Host "=== Building SOPTIM Community Elements Chatbot ===" -ForegroundColor Cyan

# Pre-build validation
if (!$SkipValidation) {
    Write-Host "`nRunning pre-build validation..." -ForegroundColor Yellow
    & ".\validate-dependencies.ps1" -CheckOnly
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Validation failed! Fix issues before building." -ForegroundColor Red
        exit 1
    }
}

# Check Maven
Write-Host "`nChecking Maven..." -ForegroundColor Yellow
try {
    $mavenVersion = mvn -version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Maven: OK" -ForegroundColor Green
        if ($Verbose) { 
            $mavenVersion -split "`n" | Select-Object -First 2 | ForEach-Object { 
                Write-Host "  $_" -ForegroundColor Gray 
            }
        }
    } else { 
        throw "Maven command failed" 
    }
} catch {
    Write-Host "✗ Maven not found or not working!" -ForegroundColor Red
    Write-Host "Install Maven from: https://maven.apache.org/download.cgi" -ForegroundColor Yellow
    exit 1
}

Set-Location confluence-app

# Clean
Write-Host "Cleaning..." -ForegroundColor Yellow
Remove-Item target -Recurse -Force -ErrorAction SilentlyContinue

# Copy plugin descriptor
if (Test-Path "src\main\resources\atlassian-plugin-simple.xml") {
    Copy-Item "src\main\resources\atlassian-plugin-simple.xml" "src\main\resources\atlassian-plugin.xml" -Force
}

# Build
Write-Host "`nBuilding JAR..." -ForegroundColor Yellow
$buildStart = Get-Date

if ($Verbose) {
    mvn -f pom-minimal.xml clean package "-Dmaven.test.skip=true"
} else {
    mvn -f pom-minimal.xml clean package "-Dmaven.test.skip=true" -q
}

$buildEnd = Get-Date
$buildTime = [math]::Round(($buildEnd - $buildStart).TotalSeconds, 1)

if ($LASTEXITCODE -eq 0) {
    $jar = "target\soptim-community-elements-chatbot-1.0.0.jar"
    if (Test-Path $jar) {
        $jarSize = [math]::Round((Get-Item $jar).Length / 1MB, 2)
        Write-Host "`n✅ BUILD SUCCESS!" -ForegroundColor Green
        Write-Host "JAR: $jar ($jarSize MB)" -ForegroundColor White
        Write-Host "Build time: $buildTime seconds" -ForegroundColor Gray
        
        # Quick JAR validation
        Write-Host "`nValidating JAR..." -ForegroundColor Yellow
        $jarCommand = Get-Command jar -ErrorAction SilentlyContinue
        if ($jarCommand) {
            try {
                $jarContents = & jar -tf $jar 2>$null
                $classCount = ($jarContents | Where-Object { $_.EndsWith('.class') }).Count
                Write-Host "✓ JAR contains $classCount class files" -ForegroundColor Green
            } catch {
                Write-Host "⚠ Could not validate JAR contents" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "1. Analyze JAR: .\analyze-jar.ps1" -ForegroundColor White
        Write-Host "2. Preview UI: Open ui-preview.html" -ForegroundColor White
        Write-Host "3. Install in Confluence: Upload JAR via Manage Apps" -ForegroundColor White
    } else {
        Write-Host "✗ JAR file not created!" -ForegroundColor Red
    }
} else {
    Write-Host "`n❌ BUILD FAILED!" -ForegroundColor Red
    Write-Host "Build time: $buildTime seconds" -ForegroundColor Gray
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Run: .\validate-dependencies.ps1 -Verbose" -ForegroundColor White
    Write-Host "2. Check for compilation errors above" -ForegroundColor White
    Write-Host "3. Try: .\build-basic.ps1 -Verbose" -ForegroundColor White
}

Set-Location ..
Read-Host "Press Enter"
