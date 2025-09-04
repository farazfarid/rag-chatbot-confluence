@echo off
setlocal enabledelayedexpansion

echo === Confluence RAG Chatbot - Dependency Validation ===
echo.

set "confluenceAppPath=confluence-app"
set errorCount=0
set warningCount=0

REM Check if we're in the right directory
if not exist "%confluenceAppPath%" (
    echo Error: confluence-app directory not found!
    pause
    exit /b 1
)

cd "%confluenceAppPath%"

echo 1. Checking Maven Installation...
mvn -version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Maven: OK
    mvn -version | findstr "Apache Maven"
) else (
    echo ✗ Maven not found or not working
    set /a errorCount+=1
)

echo.
echo 2. Checking Java Files Structure...

set validFiles=0
set emptyFiles=0

for /r "src\main\java" %%f in (*.java) do (
    if exist "%%f" (
        for %%a in ("%%f") do set "size=%%~za"
        if !size! LSS 50 (
            echo    ✗ %%~nxf ^(empty/invalid^)
            set /a emptyFiles+=1
            set /a warningCount+=1
        ) else (
            set /a validFiles+=1
        )
    )
)

echo    Valid Java Files: %validFiles%
echo    Empty/Invalid Files: %emptyFiles%

echo.
echo 3. Checking POM Files...

if exist "pom.xml" (
    echo    ✓ pom.xml
) else (
    echo    ✗ pom.xml ^(missing^)
    set /a warningCount+=1
)

if exist "pom-minimal.xml" (
    echo    ✓ pom-minimal.xml
) else (
    echo    ✗ pom-minimal.xml ^(missing^)
    set /a warningCount+=1
)

if exist "pom-simple.xml" (
    echo    ✓ pom-simple.xml
) else (
    echo    ✗ pom-simple.xml ^(missing^)
    set /a warningCount+=1
)

echo.
echo 4. Checking Resource Files...

if exist "src\main\resources\atlassian-plugin.xml" (
    echo    ✓ atlassian-plugin.xml
) else (
    echo    ✗ atlassian-plugin.xml ^(missing^)
    set /a warningCount+=1
)

if exist "src\main\resources\templates\admin.vm" (
    echo    ✓ admin.vm template
) else (
    echo    ✗ admin.vm template ^(missing^)
    set /a warningCount+=1
)

if exist "src\main\resources\js\rag-chat.js" (
    echo    ✓ rag-chat.js
) else (
    echo    ✗ rag-chat.js ^(missing^)
    set /a warningCount+=1
)

if exist "src\main\resources\css\rag-chat.css" (
    echo    ✓ rag-chat.css
) else (
    echo    ✗ rag-chat.css ^(missing^)
    set /a warningCount+=1
)

echo.
echo 5. Validating Maven Dependencies...
echo    Running Maven dependency check...

mvn -f pom-minimal.xml dependency:resolve -q >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✓ Dependencies resolved
) else (
    echo    ✗ Dependency issues found
    set /a errorCount+=1
)

echo.
echo 6. Compilation Test...
echo    Testing compilation...

mvn -f pom-minimal.xml compile -q >nul 2>&1
if %errorlevel% equ 0 (
    echo    ✓ Compilation successful
) else (
    echo    ✗ Compilation failed
    set /a errorCount+=1
    echo    Run with detailed output: mvn -f pom-minimal.xml compile
)

REM Summary
echo.
echo === VALIDATION SUMMARY ===
echo Java Files: %validFiles% valid, %emptyFiles% empty/invalid
echo Warnings: %warningCount%
echo Errors: %errorCount%

if %errorCount% GTR 0 (
    echo.
    echo ❌ VALIDATION FAILED - Fix errors before building
) else (
    echo.
    echo ✅ All validations passed! Ready to build.
)

cd ..
echo.
pause
