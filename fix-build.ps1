# Fix Build Script - Confluence RAG Chatbot
Write-Host "Building Confluence RAG Chatbot..." -ForegroundColor Cyan

# Navigate to confluence-app directory
Set-Location confluence-app

# The correct Maven command - using quotes to prevent parameter parsing issues
Write-Host "Running Maven build..." -ForegroundColor Yellow

# Method 1: Use quotes around the entire command
& cmd /c 'mvn -f pom-minimal.xml clean package "-Dmaven.test.skip=true" -q'

# Check if build succeeded
if ($LASTEXITCODE -eq 0) {
    $jar = "target\confluence-rag-chatbot-1.0.0.jar"
    if (Test-Path $jar) {
        Write-Host "SUCCESS!" -ForegroundColor Green
        Write-Host "JAR created: $jar" -ForegroundColor White
        Write-Host "File size: $((Get-Item $jar).Length / 1MB) MB" -ForegroundColor White
    } else {
        Write-Host "JAR file not found!" -ForegroundColor Red
    }
} else {
    Write-Host "Build failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    
    # Try alternative approach
    Write-Host "Trying alternative command..." -ForegroundColor Yellow
    & mvn '-f' 'pom-minimal.xml' 'clean' 'package' '-Dmaven.test.skip=true'
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Alternative command succeeded!" -ForegroundColor Green
    }
}

Set-Location ..
Write-Host "Done." -ForegroundColor White
