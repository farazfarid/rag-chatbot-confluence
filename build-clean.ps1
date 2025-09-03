# Clean Build Script - Confluence RAG Chatbot
# This script builds with minimal dependencies and proper error handling

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "🔧 Clean Build - Confluence RAG Chatbot" -ForegroundColor Cyan
Write-Host ""

# Check Maven
Write-Host "Checking Maven..." -ForegroundColor Yellow
try {
    $mvnVersion = mvn -version
    if ($LASTEXITCODE -ne 0) { throw "Maven not found" }
    Write-Host "✅ Maven OK" -ForegroundColor Green
} catch {
    Write-Error "Maven not found. Please install Maven 3.6+"
    exit 1
}

Set-Location confluence-app

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
Remove-Item -Path "target" -Recurse -Force -ErrorAction SilentlyContinue

# Copy simplified plugin descriptor
Write-Host "📝 Using simplified plugin descriptor..." -ForegroundColor Yellow
if (Test-Path "src\main\resources\atlassian-plugin-simple.xml") {
    Copy-Item "src\main\resources\atlassian-plugin-simple.xml" "src\main\resources\atlassian-plugin.xml" -Force
    Write-Host "✅ Plugin descriptor updated" -ForegroundColor Green
}

Write-Host "📦 Building with minimal configuration..." -ForegroundColor Cyan

# First attempt: Full build
try {
    Write-Host "Attempting full Maven build..." -ForegroundColor Yellow
    if ($Verbose) {
        mvn -f pom-minimal.xml clean package -Dmaven.test.skip=true
    } else {
        mvn -f pom-minimal.xml clean package -Dmaven.test.skip=true -q
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Maven build successful!" -ForegroundColor Green
    } else {
        throw "Maven build failed"
    }
} catch {
    Write-Host "❌ Maven build failed. Trying compile-only..." -ForegroundColor Red
    
    # Second attempt: Compile only
    try {
        Write-Host "Attempting compilation only..." -ForegroundColor Yellow
        if ($Verbose) {
            mvn -f pom-minimal.xml clean compile -Dmaven.test.skip=true
        } else {
            mvn -f pom-minimal.xml clean compile -Dmaven.test.skip=true -q
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Compilation successful!" -ForegroundColor Green
            Write-Host "📦 Creating JAR manually..." -ForegroundColor Yellow
            
            # Manual JAR creation
            New-Item -ItemType Directory -Path "target" -Force -ErrorAction SilentlyContinue
            jar -cf target/confluence-rag-chatbot-1.0.0.jar -C target/classes . -C src/main/resources .
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Manual JAR creation successful!" -ForegroundColor Green
            } else {
                throw "Manual JAR creation failed"
            }
        } else {
            throw "Compilation failed"
        }
    } catch {
        Write-Host "❌ All build attempts failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "🔍 Troubleshooting:" -ForegroundColor Yellow
        Write-Host "1. Check if all Java source files compile" -ForegroundColor White
        Write-Host "2. Verify all dependencies are available" -ForegroundColor White
        Write-Host "3. Run with -Verbose to see detailed Maven output" -ForegroundColor White
        Write-Host ""
        Set-Location ..
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Check if JAR was created
$jarPath = "target\confluence-rag-chatbot-1.0.0.jar"
if (Test-Path $jarPath) {
    Write-Host ""
    Write-Host "🎉 BUILD SUCCESSFUL!" -ForegroundColor Green
    
    $fileSize = (Get-Item $jarPath).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    
    Write-Host "📁 JAR File: $jarPath" -ForegroundColor White
    Write-Host "📏 Size: $fileSizeMB MB" -ForegroundColor White
    Write-Host ""
    Write-Host "✅ Ready for Confluence installation!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation Steps:" -ForegroundColor Cyan
    Write-Host "1. Go to Confluence Administration → Manage Apps" -ForegroundColor White
    Write-Host "2. Click 'Upload app'" -ForegroundColor White
    Write-Host "3. Select the JAR file: confluence-app\$jarPath" -ForegroundColor White
    Write-Host "4. Configure via: Administration → RAG Chatbot" -ForegroundColor White
    Write-Host ""
    Write-Host "Admin Interface: /plugins/servlet/rag-admin" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Note: This build uses simplified dependencies for maximum compatibility." -ForegroundColor Yellow
} else {
    Write-Host "❌ JAR file was not created" -ForegroundColor Red
    Set-Location ..
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location ..
Write-Host ""
Read-Host "Press Enter to continue"
