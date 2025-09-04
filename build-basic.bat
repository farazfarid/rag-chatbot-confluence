@echo off
setlocal enabledelayedexpansion

echo === Building Confluence RAG Chatbot ===
echo.

set "skipValidation=%1"
set "verbose=%2"

REM Pre-build validation (unless skipped)
if not "%skipValidation%"=="skip" (
    echo Running pre-build validation...
    call validate-dependencies.bat >nul 2>&1
    if !errorlevel! neq 0 (
        echo Validation failed! Run validate-dependencies.bat to see details.
        pause
        exit /b 1
    )
    echo ✓ Pre-validation passed
)

echo.
echo Checking Maven...
mvn -version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Maven: OK
    if "%verbose%"=="verbose" mvn -version | findstr "Apache Maven"
) else (
    echo ✗ Maven not found or not working!
    echo Install Maven from: https://maven.apache.org/download.cgi
    pause
    exit /b 1
)

cd confluence-app

echo.
echo Cleaning previous build...
if exist "target" rmdir /s /q "target" >nul 2>&1

REM Copy plugin descriptor
if exist "src\main\resources\atlassian-plugin-simple.xml" (
    copy "src\main\resources\atlassian-plugin-simple.xml" "src\main\resources\atlassian-plugin.xml" >nul 2>&1
)

echo.
echo Building JAR...
set startTime=%time%

if "%verbose%"=="verbose" (
    mvn -f pom-minimal.xml clean package "-Dmaven.test.skip=true"
) else (
    mvn -f pom-minimal.xml clean package "-Dmaven.test.skip=true" -q
)

set buildResult=%errorlevel%
set endTime=%time%

if %buildResult% equ 0 (
    set "jar=target\confluence-rag-chatbot-1.0.0.jar"
    if exist "!jar!" (
        for %%a in ("!jar!") do set "jarSize=%%~za"
        set /a jarSizeMB=!jarSize!/1048576
        echo.
        echo ✅ BUILD SUCCESS!
        echo JAR: !jar! ^(!jarSizeMB! MB^)
        
        REM Quick JAR validation
        echo.
        echo Validating JAR...
        jar -tf "!jar!" >nul 2>&1
        if !errorlevel! equ 0 (
            for /f %%i in ('jar -tf "!jar!" ^| find ".class" /c') do set classCount=%%i
            echo ✓ JAR contains !classCount! class files
        ) else (
            echo ⚠ Could not validate JAR contents ^(jar command not found^)
        )
        
        echo.
        echo Next steps:
        echo 1. Analyze JAR: analyze-jar.bat
        echo 2. Preview UI: Open ui-preview.html
        echo 3. Install in Confluence: Upload JAR via Manage Apps
    ) else (
        echo ✗ JAR file not created!
    )
) else (
    echo.
    echo ❌ BUILD FAILED!
    echo.
    echo Troubleshooting:
    echo 1. Run: validate-dependencies.bat
    echo 2. Check for compilation errors above
    echo 3. Try: build-basic.bat skip verbose
)

cd ..
echo.
pause
