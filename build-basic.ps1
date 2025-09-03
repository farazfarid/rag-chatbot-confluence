# Basic Build Script - Confluence RAG Chatbot
param([switch]$Verbose)

Write-Host "Building Confluence RAG Chatbot..." -ForegroundColor Cyan

# Check Maven
try {
    mvn -version | Out-Null
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "Maven: OK" -ForegroundColor Green
} catch {
    Write-Host "Maven not found!" -ForegroundColor Red
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
Write-Host "Building..." -ForegroundColor Yellow
if ($Verbose) {
    mvn -f pom-minimal.xml clean package -Dmaven.test.skip=true
} else {
    mvn -f pom-minimal.xml clean package -Dmaven.test.skip=true -q
}

if ($LASTEXITCODE -eq 0) {
    $jar = "target\confluence-rag-chatbot-1.0.0.jar"
    if (Test-Path $jar) {
        Write-Host "SUCCESS!" -ForegroundColor Green
        Write-Host "JAR: $jar" -ForegroundColor White
    } else {
        Write-Host "JAR not found!" -ForegroundColor Red
    }
} else {
    Write-Host "Build failed!" -ForegroundColor Red
}

Set-Location ..
Read-Host "Press Enter"
