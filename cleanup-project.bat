@echo off
setlocal enabledelayedexpansion

echo === Project Cleanup and Analysis ===
echo.

set "projectPath=%cd%"
echo Analyzing project at: %projectPath%

if not exist "confluence-app" (
    echo Error: confluence-app directory not found!
    pause
    exit /b 1
)

echo.
echo 1. Analyzing Java Files...

set validCount=0
set emptyCount=0

for /r "confluence-app\src\main\java" %%f in (*.java) do (
    if exist "%%f" (
        for %%a in ("%%f") do set "size=%%~za"
        if !size! LSS 50 (
            echo    Empty/Invalid: %%~nxf ^(!size! bytes^)
            set /a emptyCount+=1
            echo %%f >> empty_files.tmp
        ) else (
            set /a validCount+=1
        )
    )
)

echo.
echo Java Files Summary:
echo    Valid: %validCount%
echo    Empty/Invalid: %emptyCount%

if %emptyCount% GTR 0 (
    echo.
    echo Files to remove:
    if exist empty_files.tmp (
        for /f "delims=" %%i in (empty_files.tmp) do echo    %%i
    )
    
    echo.
    set /p "delete=Delete empty files? (y/n): "
    if /i "!delete!"=="y" (
        echo Deleting empty files...
        if exist empty_files.tmp (
            for /f "delims=" %%i in (empty_files.tmp) do (
                del "%%i" 2>nul
                if not exist "%%i" echo    Deleted: %%i
            )
        )
    )
)

if exist empty_files.tmp del empty_files.tmp

echo.
echo 2. Analyzing Resource Files...

set "resources[0]=confluence-app\src\main\resources\atlassian-plugin.xml"
set "resources[1]=confluence-app\src\main\resources\templates\admin.vm"
set "resources[2]=confluence-app\src\main\resources\js\rag-chat.js"
set "resources[3]=confluence-app\src\main\resources\css\rag-chat.css"
set "resources[4]=confluence-app\src\main\resources\application.properties"

for /l %%i in (0,1,4) do (
    if exist "!resources[%%i]!" (
        for %%a in ("!resources[%%i]!") do echo    ✓ !resources[%%i]! ^(%%~za bytes^)
    ) else (
        echo    ✗ !resources[%%i]! ^(missing^)
    )
)

echo.
echo 3. Analyzing POM Files...

if exist "confluence-app\pom.xml" (
    echo    ✓ pom.xml
) else (
    echo    ✗ pom.xml ^(missing^)
)

if exist "confluence-app\pom-minimal.xml" (
    echo    ✓ pom-minimal.xml
) else (
    echo    ✗ pom-minimal.xml ^(missing^)
)

if exist "confluence-app\pom-simple.xml" (
    echo    ✓ pom-simple.xml
) else (
    echo    ✗ pom-simple.xml ^(missing^)
)

echo.
echo 4. Build Scripts Analysis...

for %%f in (build*.bat) do (
    if exist "%%f" echo    ✓ %%f
)

for %%f in (deploy*) do (
    if exist "%%f" echo    ✓ %%f
)

echo.
echo === RECOMMENDED ACTIONS ===
if %emptyCount% GTR 0 echo 1. Remove empty Java files: Run cleanup-project.bat again
echo 2. Run validation: validate-dependencies.bat
echo 3. Build project: build-basic.bat
echo 4. Analyze JAR: analyze-jar.bat
echo 5. Preview UI: Open ui-preview.html in browser

echo.
echo === QUICK COMMANDS ===
echo Validate:  validate-dependencies.bat
echo Build:     build-basic.bat
echo Analyze:   analyze-jar.bat
echo Cleanup:   cleanup-project.bat

echo.
pause
