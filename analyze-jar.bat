@echo off
setlocal enabledelayedexpansion

echo === JAR Analysis Tool ===
echo.

set "jarPath=confluence-app\target\confluence-rag-chatbot-1.0.0.jar"
set "detailed=%1"

if not exist "%jarPath%" (
    echo JAR file not found: %jarPath%
    echo Run build-basic.bat first to create the JAR file.
    pause
    exit /b 1
)

for %%a in ("%jarPath%") do (
    set "jarSize=%%~za"
    set "jarDate=%%~ta"
)

set /a jarSizeMB=!jarSize!/1048576

echo JAR File: confluence-rag-chatbot-1.0.0.jar
echo Size: !jarSizeMB! MB
echo Created: !jarDate!

REM Check if jar command is available
jar -version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo Warning: 'jar' command not found in PATH
    echo Install Java JDK to use jar command for detailed analysis
    
    REM Try to find jar.exe in common locations
    set "jarFound=false"
    for %%p in ("%JAVA_HOME%\bin\jar.exe" "C:\Program Files\Java\*\bin\jar.exe" "C:\Program Files\OpenJDK\*\bin\jar.exe") do (
        if exist "%%p" (
            echo Found jar at: %%p
            set "jarFound=true"
            set "jarCmd=%%p"
            goto :jarFound
        )
    )
    
    if "!jarFound!"=="false" (
        echo Could not find jar command. Install Java JDK for detailed analysis.
        goto :skipAnalysis
    )
) else (
    set "jarCmd=jar"
)

:jarFound
echo.
echo === JAR Contents Analysis ===

REM Get JAR contents
"%jarCmd%" -tf "%jarPath%" > jar_contents.tmp 2>nul
if %errorlevel% equ 0 (
    for /f %%i in ('type jar_contents.tmp ^| find ".class" /c') do set classCount=%%i
    for /f %%i in ('type jar_contents.tmp ^| find /v ".class" /c') do set resourceCount=%%i
    for /f %%i in ('type jar_contents.tmp ^| find /" /c') do set dirCount=%%i
    
    echo Total entries: 
    type jar_contents.tmp | find /c ""
    echo Class files: %classCount%
    echo Resource files: %resourceCount%
    echo Directories: %dirCount%
    
    echo.
    echo === Key Files Check ===
    
    findstr /c:"META-INF/MANIFEST.MF" jar_contents.tmp >nul && echo ✓ META-INF/MANIFEST.MF || echo ✗ META-INF/MANIFEST.MF ^(missing^)
    findstr /c:"atlassian-plugin.xml" jar_contents.tmp >nul && echo ✓ atlassian-plugin.xml || echo ✗ atlassian-plugin.xml ^(missing^)
    findstr /c:"com/confluence/rag/servlet/AdminServletSimple.class" jar_contents.tmp >nul && echo ✓ AdminServletSimple.class || echo ✗ AdminServletSimple.class ^(missing^)
    findstr /c:"com/confluence/rag/service/RagServiceSimple.class" jar_contents.tmp >nul && echo ✓ RagServiceSimple.class || echo ✗ RagServiceSimple.class ^(missing^)
    findstr /c:"com/confluence/rag/rest/RagRestResource.class" jar_contents.tmp >nul && echo ✓ RagRestResource.class || echo ✗ RagRestResource.class ^(missing^)
    
    echo.
    echo === Manifest Analysis ===
    
    REM Extract and show manifest
    "%jarCmd%" -xf "%jarPath%" META-INF/MANIFEST.MF >nul 2>&1
    if exist "META-INF\MANIFEST.MF" (
        for /f "delims=" %%i in ('type "META-INF\MANIFEST.MF" ^| findstr /i "Atlassian Bundle Version"') do echo   %%i
        rmdir /s /q "META-INF" >nul 2>&1
    )
    
    if "%detailed%"=="detailed" (
        echo.
        echo === All JAR Contents ===
        for /f "delims=" %%i in (jar_contents.tmp) do (
            echo %%i | findstr /c:".class" >nul && echo   [CLASS] %%i || (
                echo %%i | findstr /c:"/" >nul && echo   [DIR]   %%i || echo   [FILE]  %%i
            )
        )
    )
    
    del jar_contents.tmp >nul 2>&1
) else (
    echo Error analyzing JAR contents
)

:skipAnalysis
echo.
echo === Installation Instructions ===
echo 1. Go to Confluence Administration → Manage Apps
echo 2. Click 'Upload App'
echo 3. Select this JAR file: %jarPath%
echo 4. Click 'Upload'
echo 5. Configure at: /plugins/servlet/rag-admin

echo.
echo === Testing URLs ^(after installation^) ===
echo Admin Interface: {confluence-url}/plugins/servlet/rag-admin
echo REST API: {confluence-url}/rest/rag/1.0/chat
echo Health Check: {confluence-url}/rest/rag/1.0/health

if not "%detailed%"=="detailed" (
    echo.
    echo Use 'analyze-jar.bat detailed' to see all JAR contents
)

echo.
pause
