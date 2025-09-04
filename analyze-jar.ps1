# JAR Analysis Tool - Confluence RAG Chatbot
param([string]$JarPath = "confluence-app\target\confluence-rag-chatbot-1.0.0.jar", [switch]$Detailed)

Write-Host "=== JAR Analysis Tool ===" -ForegroundColor Cyan

if (!(Test-Path $JarPath)) {
    Write-Host "JAR file not found: $JarPath" -ForegroundColor Red
    Write-Host "Run build-basic.ps1 first to create the JAR file." -ForegroundColor Yellow
    exit 1
}

$jarInfo = Get-Item $JarPath
Write-Host "`nJAR File: $($jarInfo.Name)" -ForegroundColor Green
Write-Host "Size: $([math]::Round($jarInfo.Length / 1MB, 2)) MB" -ForegroundColor White
Write-Host "Created: $($jarInfo.CreationTime)" -ForegroundColor White
Write-Host "Modified: $($jarInfo.LastWriteTime)" -ForegroundColor White

# Check if jar command is available
$jarCommand = Get-Command jar -ErrorAction SilentlyContinue
if (!$jarCommand) {
    Write-Host "`nWarning: 'jar' command not found in PATH" -ForegroundColor Yellow
    Write-Host "Install Java JDK to use jar command for detailed analysis" -ForegroundColor Yellow
    
    # Try to find jar.exe in common locations
    $possiblePaths = @(
        "${env:JAVA_HOME}\bin\jar.exe",
        "C:\Program Files\Java\*\bin\jar.exe",
        "C:\Program Files (x86)\Java\*\bin\jar.exe",
        "${env:ProgramFiles}\OpenJDK\*\bin\jar.exe"
    )
    
    foreach ($path in $possiblePaths) {
        $found = Get-ChildItem $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            Write-Host "Found jar at: $($found.FullName)" -ForegroundColor Green
            $jarCommand = $found.FullName
            break
        }
    }
}

if ($jarCommand) {
    Write-Host "`n=== JAR Contents Analysis ===" -ForegroundColor Yellow
    
    try {
        # List JAR contents
        $jarContents = & $jarCommand -tf $JarPath 2>$null
        
        if ($jarContents) {
            $classFiles = $jarContents | Where-Object { $_.EndsWith('.class') }
            $resourceFiles = $jarContents | Where-Object { !$_.EndsWith('.class') -and !$_.EndsWith('/') }
            $directories = $jarContents | Where-Object { $_.EndsWith('/') }
            
            Write-Host "Total entries: $($jarContents.Count)" -ForegroundColor White
            Write-Host "Class files: $($classFiles.Count)" -ForegroundColor Green
            Write-Host "Resource files: $($resourceFiles.Count)" -ForegroundColor Green
            Write-Host "Directories: $($directories.Count)" -ForegroundColor Green
            
            # Check for key files
            Write-Host "`n=== Key Files Check ===" -ForegroundColor Yellow
            $keyFiles = @(
                "META-INF/MANIFEST.MF",
                "atlassian-plugin.xml",
                "com/confluence/rag/servlet/AdminServletSimple.class",
                "com/confluence/rag/service/RagServiceSimple.class",
                "com/confluence/rag/rest/RagRestResource.class"
            )
            
            foreach ($file in $keyFiles) {
                if ($jarContents -contains $file) {
                    Write-Host "✓ $file" -ForegroundColor Green
                } else {
                    Write-Host "✗ $file (missing)" -ForegroundColor Red
                }
            }
            
            # Show manifest
            Write-Host "`n=== Manifest Analysis ===" -ForegroundColor Yellow
            try {
                $manifest = & $jarCommand -xf $JarPath META-INF/MANIFEST.MF 2>$null
                if (Test-Path "META-INF\MANIFEST.MF") {
                    $manifestContent = Get-Content "META-INF\MANIFEST.MF"
                    $manifestContent | ForEach-Object { 
                        if ($_ -match "Atlassian|Bundle|Version") {
                            Write-Host "  $_" -ForegroundColor Green
                        }
                    }
                    Remove-Item "META-INF" -Recurse -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Host "Could not extract manifest" -ForegroundColor Yellow
            }
            
            if ($Detailed) {
                Write-Host "`n=== All JAR Contents ===" -ForegroundColor Yellow
                $jarContents | Sort-Object | ForEach-Object {
                    if ($_.EndsWith('.class')) {
                        Write-Host "  [CLASS] $_" -ForegroundColor Cyan
                    } elseif ($_.EndsWith('/')) {
                        Write-Host "  [DIR]   $_" -ForegroundColor Gray
                    } else {
                        Write-Host "  [FILE]  $_" -ForegroundColor White
                    }
                }
            }
        }
    } catch {
        Write-Host "Error analyzing JAR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Installation Instructions ===" -ForegroundColor Yellow
Write-Host "1. Go to Confluence Administration → Manage Apps" -ForegroundColor White
Write-Host "2. Click 'Upload App'" -ForegroundColor White
Write-Host "3. Select this JAR file: $JarPath" -ForegroundColor White
Write-Host "4. Click 'Upload'" -ForegroundColor White
Write-Host "5. Configure at: /plugins/servlet/rag-admin" -ForegroundColor White

Write-Host "`n=== Testing URLs (after installation) ===" -ForegroundColor Yellow
Write-Host "Admin Interface: {confluence-url}/plugins/servlet/rag-admin" -ForegroundColor Green
Write-Host "REST API: {confluence-url}/rest/rag/1.0/chat" -ForegroundColor Green
Write-Host "Health Check: {confluence-url}/rest/rag/1.0/health" -ForegroundColor Green

if (!$Detailed) {
    Write-Host "`nUse -Detailed flag to see all JAR contents" -ForegroundColor Gray
}

Read-Host "`nPress Enter to continue"
