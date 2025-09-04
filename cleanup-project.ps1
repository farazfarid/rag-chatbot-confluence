# Project Cleanup and File Analysis
param([switch]$Delete, [switch]$Verbose)

Write-Host "=== Project Cleanup and Analysis ===" -ForegroundColor Cyan

$projectPath = Get-Location
Write-Host "Analyzing project at: $projectPath" -ForegroundColor White

# Check confluence-app structure
if (!(Test-Path "confluence-app")) {
    Write-Host "Error: confluence-app directory not found!" -ForegroundColor Red
    exit 1
}

Write-Host "`n1. Analyzing Java Files..." -ForegroundColor Yellow

$javaFiles = Get-ChildItem -Path "confluence-app\src\main\java" -Recurse -Filter "*.java" -ErrorAction SilentlyContinue
$emptyFiles = @()
$validFiles = @()
$duplicateFiles = @()

# Group files by name to find duplicates
$fileGroups = $javaFiles | Group-Object Name

foreach ($group in $fileGroups) {
    if ($group.Count -gt 1) {
        Write-Host "   Duplicate files found for: $($group.Name)" -ForegroundColor Red
        foreach ($file in $group.Group) {
            $size = (Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue).Length
            Write-Host "     $($file.FullName) ($size bytes)" -ForegroundColor Yellow
            if ($size -lt 50) {
                $duplicateFiles += $file.FullName
            }
        }
    }
}

foreach ($file in $javaFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    $size = if ($content) { $content.Length } else { 0 }
    
    if ($size -lt 50) {
        $emptyFiles += $file.FullName
        Write-Host "   Empty/Invalid: $($file.Name) ($size bytes)" -ForegroundColor Red
    } else {
        $validFiles += $file.FullName
        if ($Verbose) {
            Write-Host "   Valid: $($file.Name) ($size bytes)" -ForegroundColor Green
        }
    }
}

Write-Host "`nJava Files Summary:" -ForegroundColor Cyan
Write-Host "   Valid: $($validFiles.Count)" -ForegroundColor Green
Write-Host "   Empty/Invalid: $($emptyFiles.Count)" -ForegroundColor Red
Write-Host "   Duplicates: $($duplicateFiles.Count)" -ForegroundColor Yellow

if ($emptyFiles.Count -gt 0 -or $duplicateFiles.Count -gt 0) {
    Write-Host "`nFiles to remove:" -ForegroundColor Yellow
    ($emptyFiles + $duplicateFiles) | Sort-Object -Unique | ForEach-Object {
        Write-Host "   $_" -ForegroundColor Red
    }
    
    if ($Delete) {
        Write-Host "`nDeleting empty and duplicate files..." -ForegroundColor Yellow
        ($emptyFiles + $duplicateFiles) | Sort-Object -Unique | ForEach-Object {
            try {
                Remove-Item $_ -Force
                Write-Host "   Deleted: $_" -ForegroundColor Green
            } catch {
                Write-Host "   Failed to delete: $_ - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "`nUse -Delete flag to remove these files" -ForegroundColor Gray
    }
}

Write-Host "`n2. Analyzing Resource Files..." -ForegroundColor Yellow

$requiredResources = @{
    "confluence-app\src\main\resources\atlassian-plugin.xml" = "Plugin descriptor"
    "confluence-app\src\main\resources\templates\admin.vm" = "Admin template"
    "confluence-app\src\main\resources\js\rag-chat.js" = "Chat JavaScript"
    "confluence-app\src\main\resources\css\rag-chat.css" = "Chat CSS"
    "confluence-app\src\main\resources\application.properties" = "Configuration"
}

foreach ($resource in $requiredResources.GetEnumerator()) {
    if (Test-Path $resource.Key) {
        $size = (Get-Item $resource.Key).Length
        Write-Host "   ✓ $($resource.Value): $($resource.Key) ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $($resource.Value): $($resource.Key) (missing)" -ForegroundColor Red
    }
}

Write-Host "`n3. Analyzing POM Files..." -ForegroundColor Yellow

$pomFiles = @(
    "confluence-app\pom.xml",
    "confluence-app\pom-minimal.xml", 
    "confluence-app\pom-simple.xml"
)

foreach ($pom in $pomFiles) {
    if (Test-Path $pom) {
        $xml = [xml](Get-Content $pom)
        $artifactId = $xml.project.artifactId
        $version = $xml.project.version
        $dependencies = $xml.project.dependencies.dependency.Count
        Write-Host "   ✓ $pom - $artifactId v$version ($dependencies dependencies)" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $pom (missing)" -ForegroundColor Red
    }
}

Write-Host "`n4. Build Scripts Analysis..." -ForegroundColor Yellow

$buildScripts = Get-ChildItem -Filter "build*.ps1" -ErrorAction SilentlyContinue
foreach ($script in $buildScripts) {
    $lines = (Get-Content $script.FullName | Measure-Object -Line).Lines
    Write-Host "   ✓ $($script.Name) ($lines lines)" -ForegroundColor Green
}

$deployScripts = Get-ChildItem -Filter "deploy*" -ErrorAction SilentlyContinue
foreach ($script in $deployScripts) {
    Write-Host "   ✓ $($script.Name)" -ForegroundColor Green
}

Write-Host "`n5. Unused Files Check..." -ForegroundColor Yellow

# Check for common unused files
$potentiallyUnused = @(
    "confluence-app\target",
    "confluence-app\.settings",
    "confluence-app\bin",
    "confluence-app\*.log",
    "confluence-app\*.tmp"
)

foreach ($pattern in $potentiallyUnused) {
    $items = Get-ChildItem $pattern -ErrorAction SilentlyContinue
    if ($items) {
        foreach ($item in $items) {
            Write-Host "   Potentially unused: $($item.FullName)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n=== RECOMMENDED ACTIONS ===" -ForegroundColor Cyan

if ($emptyFiles.Count -gt 0) {
    Write-Host "1. Remove empty Java files: Run with -Delete flag" -ForegroundColor Yellow
}

$missingResources = $requiredResources.GetEnumerator() | Where-Object { !(Test-Path $_.Key) }
if ($missingResources) {
    Write-Host "2. Create missing resource files:" -ForegroundColor Yellow
    $missingResources | ForEach-Object { Write-Host "   - $($_.Value)" -ForegroundColor White }
}

Write-Host "3. Run validation: .\validate-dependencies.ps1" -ForegroundColor Green
Write-Host "4. Build project: .\build-basic.ps1" -ForegroundColor Green
Write-Host "5. Analyze JAR: .\analyze-jar.ps1" -ForegroundColor Green
Write-Host "6. Preview UI: Open ui-preview.html in browser" -ForegroundColor Green

Write-Host "`n=== QUICK COMMANDS ===" -ForegroundColor Cyan
Write-Host "Validate:  .\validate-dependencies.ps1 -Verbose" -ForegroundColor White
Write-Host "Build:     .\build-basic.ps1 -Verbose" -ForegroundColor White
Write-Host "Analyze:   .\analyze-jar.ps1 -Detailed" -ForegroundColor White
Write-Host "Cleanup:   .\cleanup-project.ps1 -Delete" -ForegroundColor White

if (!$Delete -and ($emptyFiles.Count -gt 0 -or $duplicateFiles.Count -gt 0)) {
    Read-Host "`nPress Enter to continue (use -Delete to remove empty files)"
}
