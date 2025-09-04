@echo off
setlocal enabledelayedexpansion

echo === Quick Build and Deploy ===
echo.

echo Step 1: Validation
call validate-dependencies.bat >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Validation failed!
    echo Running detailed validation...
    call validate-dependencies.bat
    pause
    exit /b 1
)
echo ✅ Validation passed

echo.
echo Step 2: Building
call build-basic.bat skip >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Build failed!
    echo Running detailed build...
    call build-basic.bat skip verbose
    pause
    exit /b 1
)
echo ✅ Build completed

echo.
echo Step 3: JAR Analysis
if exist "confluence-app\target\confluence-rag-chatbot-1.0.0.jar" (
    for %%a in ("confluence-app\target\confluence-rag-chatbot-1.0.0.jar") do (
        set "jarSize=%%~za"
        set /a jarSizeMB=!jarSize!/1048576
    )
    echo ✅ JAR created successfully ^(!jarSizeMB! MB^)
) else (
    echo ❌ JAR not found
    pause
    exit /b 1
)

echo.
echo Step 4: Ready for deployment
echo.
echo Installation steps:
echo 1. Go to Confluence ^> Administration ^> Manage Apps
echo 2. Click "Upload App"
echo 3. Select: confluence-app\target\confluence-rag-chatbot-1.0.0.jar
echo 4. Click "Upload"
echo 5. Configure at: your-confluence-url/plugins/servlet/rag-admin

echo.
echo Testing options:
echo - Preview UI: Open ui-preview.html in browser
echo - Detailed analysis: analyze-jar.bat detailed
echo - Plugin testing: test-plugin.bat

echo.
echo ✅ BUILD PIPELINE COMPLETE!
pause
