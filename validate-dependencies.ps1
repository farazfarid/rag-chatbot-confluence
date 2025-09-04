# Dependency Validation Script - Confluence RAG Chatbot
param([switch]$Verbose, [switch]$CheckOnly)

Write-Host "=== Confluence RAG Chatbot - Dependency Validation ===" -ForegroundColor Cyan

$confluenceAppPath = "confluence-app"
$errors = @()
$warnings = @()

# Check if we're in the right directory
if (!(Test-Path $confluenceAppPath)) {
    Write-Host "Error: confluence-app directory not found!" -ForegroundColor Red
    exit 1
}

Set-Location $confluenceAppPath

Write-Host "`n1. Checking Maven Installation..." -ForegroundColor Yellow
try {
    $mavenVersion = mvn -version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Maven: OK" -ForegroundColor Green
        if ($Verbose) { Write-Host "   $($mavenVersion -split "`n" | Select-Object -First 1)" -ForegroundColor Gray }
    } else {
        $errors += "Maven not found or not working"
    }
} catch {
    $errors += "Maven not found: $($_.Exception.Message)"
}

Write-Host "`n2. Checking Java Files Structure..." -ForegroundColor Yellow
$javaFiles = Get-ChildItem -Path "src\main\java" -Recurse -Filter "*.java"
$emptyFiles = @()
$validFiles = @()

foreach ($file in $javaFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($content) -or $content.Length -lt 50) {
        $emptyFiles += $file.Name
    } else {
        $validFiles += $file.Name
    }
}

Write-Host "   Valid Java Files: $($validFiles.Count)" -ForegroundColor Green
if ($Verbose) {
    $validFiles | ForEach-Object { Write-Host "   ✓ $_" -ForegroundColor Gray }
}

if ($emptyFiles.Count -gt 0) {
    Write-Host "   Empty/Invalid Files: $($emptyFiles.Count)" -ForegroundColor Red
    $emptyFiles | ForEach-Object { 
        Write-Host "   ✗ $_" -ForegroundColor Red 
        $warnings += "Empty or invalid file: $_"
    }
}

Write-Host "`n3. Checking POM Files..." -ForegroundColor Yellow
$pomFiles = @("pom.xml", "pom-minimal.xml", "pom-simple.xml")
foreach ($pom in $pomFiles) {
    if (Test-Path $pom) {
        Write-Host "   ✓ $pom" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $pom (missing)" -ForegroundColor Red
        $warnings += "Missing POM file: $pom"
    }
}

Write-Host "`n4. Checking Resource Files..." -ForegroundColor Yellow
$resourceFiles = @(
    "src\main\resources\atlassian-plugin.xml",
    "src\main\resources\templates\admin.vm",
    "src\main\resources\js\rag-chat.js",
    "src\main\resources\css\rag-chat.css"
)

foreach ($resource in $resourceFiles) {
    if (Test-Path $resource) {
        Write-Host "   ✓ $resource" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $resource (missing)" -ForegroundColor Yellow
        $warnings += "Missing resource: $resource"
    }
}

Write-Host "`n5. Validating Java Dependencies..." -ForegroundColor Yellow
if (!$CheckOnly) {
    try {
        Write-Host "   Running Maven dependency check..." -ForegroundColor Gray
        $depResult = mvn -f pom-minimal.xml dependency:resolve -q 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✓ Dependencies resolved" -ForegroundColor Green
        } else {
            Write-Host "   ✗ Dependency issues found" -ForegroundColor Red
            $errors += "Maven dependencies not resolved"
            if ($Verbose) {
                Write-Host "   Error details:" -ForegroundColor Red
                $depResult | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
            }
        }
    } catch {
        $errors += "Failed to check dependencies: $($_.Exception.Message)"
    }
}

Write-Host "`n6. Compilation Test..." -ForegroundColor Yellow
if (!$CheckOnly) {
    try {
        Write-Host "   Testing compilation..." -ForegroundColor Gray
        $compileResult = mvn -f pom-minimal.xml compile -q 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✓ Compilation successful" -ForegroundColor Green
        } else {
            Write-Host "   ✗ Compilation failed" -ForegroundColor Red
            $errors += "Java compilation failed"
            if ($Verbose) {
                Write-Host "   Compilation errors:" -ForegroundColor Red
                $compileResult | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
            }
        }
    } catch {
        $errors += "Failed to test compilation: $($_.Exception.Message)"
    }
}

# Summary
Write-Host "`n=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Java Files: $($validFiles.Count) valid, $($emptyFiles.Count) empty/invalid" -ForegroundColor White
Write-Host "Warnings: $($warnings.Count)" -ForegroundColor Yellow
Write-Host "Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { "Red" } else { "Green" })

if ($warnings.Count -gt 0) {
    Write-Host "`nWarnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
}

if ($errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  • $_" -ForegroundColor Red }
    Write-Host "`nRecommendation: Fix errors before building" -ForegroundColor Red
} else {
    Write-Host "`n✅ All validations passed! Ready to build." -ForegroundColor Green
}

Set-Location ..
if (!$CheckOnly) { Read-Host "`nPress Enter to continue" }
