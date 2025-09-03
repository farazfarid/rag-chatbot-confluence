# Confluence RAG Chatbot - JAR Build Script (PowerShell)
# This script builds only the Confluence app JAR without requiring AWS CLI

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "🔨 Building Confluence RAG Chatbot JAR..." -ForegroundColor Cyan

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

# Check if Maven is installed
try {
    $mavenVersion = mvn -version 2>$null
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "✅ Maven: $($mavenVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "❌ Maven is not installed. Please install Maven 3.6+ first." -ForegroundColor Red
    Write-Host "   Download from: https://maven.apache.org/download.cgi" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Java is installed
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "✅ Java: $javaVersion" -ForegroundColor Green
    
    # Extract Java version number
    $versionMatch = [regex]::Match($javaVersion, '"(\d+)\.(\d+)')
    if ($versionMatch.Success) {
        $majorVersion = [int]$versionMatch.Groups[1].Value
        if ($majorVersion -lt 11) {
            Write-Host "❌ Java 11+ is required. Current version appears to be Java $majorVersion" -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
} catch {
    Write-Host "❌ Java is not installed. Please install Java 11+ first." -ForegroundColor Red
    Write-Host "   Download from: https://adoptium.net/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Build Confluence App
Write-Host "🔨 Building Confluence app..." -ForegroundColor Cyan
Set-Location confluence-app

# Clean and build
Write-Host "📦 Running Maven clean package..." -ForegroundColor Yellow
try {
    if ($Verbose) {
        mvn clean package
    } else {
        mvn clean package -q
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Maven build failed"
    }
} catch {
    Write-Host "❌ Maven build failed. Run with -Verbose for more details." -ForegroundColor Red
    Set-Location ..
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if JAR was created
$jarPath = "target\confluence-rag-chatbot-1.0.0.jar"
if (Test-Path $jarPath) {
    Write-Host "✅ Confluence app built successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 JAR location: confluence-app\$($jarPath)" -ForegroundColor White
    
    $fileSize = (Get-Item $jarPath).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    Write-Host "📏 File size: $fileSizeMB MB" -ForegroundColor White
    Write-Host ""
    Write-Host "🎉 Ready for installation!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Upload the JAR file to your Confluence Data Center:" -ForegroundColor White
    Write-Host "   - Go to Confluence Administration → Manage Apps" -ForegroundColor Gray
    Write-Host "   - Click 'Upload app'" -ForegroundColor Gray
    Write-Host "   - Select: confluence-app\$($jarPath)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Configure the app:" -ForegroundColor White
    Write-Host "   - Go to Administration → RAG Chatbot Configuration" -ForegroundColor Gray
    Write-Host "   - Enter your AWS credentials and endpoints" -ForegroundColor Gray
    Write-Host "   - Add knowledge sources (Confluence sites, PDFs, websites)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Test the installation:" -ForegroundColor White
    Write-Host "   - Add the /rag macro to any Confluence page" -ForegroundColor Gray
    Write-Host "   - Or use the chat widget in the sidebar" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📖 For AWS infrastructure setup (optional):" -ForegroundColor Cyan
    Write-Host "   - If you need AWS infrastructure, install AWS CLI first" -ForegroundColor Gray
    Write-Host "   - Then run: .\deploy.ps1 for full deployment" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔧 Manual AWS setup:" -ForegroundColor Cyan
    Write-Host "   - You can set up AWS resources manually via console" -ForegroundColor Gray
    Write-Host "   - Configure the app with your AWS endpoints in the admin interface" -ForegroundColor Gray
} else {
    Write-Host "❌ Failed to build Confluence app" -ForegroundColor Red
    Write-Host "Check the Maven output above for errors" -ForegroundColor Yellow
    Set-Location ..
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location ..
Write-Host ""
Read-Host "Press Enter to continue"
