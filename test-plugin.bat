@echo off
setlocal enabledelayedexpansion

echo === Test Script for Confluence RAG Chatbot ===
echo.

set "confluenceUrl=http://localhost:1990/confluence"
if not "%1"=="" set "confluenceUrl=%1"

REM Check if JAR exists
set "jarPath=confluence-app\target\confluence-rag-chatbot-1.0.0.jar"
if not exist "%jarPath%" (
    echo JAR not found! Run build-basic.bat first.
    pause
    exit /b 1
)

echo JAR found: %jarPath%

for %%a in ("%jarPath%") do (
    set "jarSize=%%~za"
    set /a jarSizeMB=!jarSize!/1048576
)

echo File size: !jarSizeMB! MB

REM Test URLs
set "adminUrl=%confluenceUrl%/plugins/servlet/rag-admin"
set "restUrl=%confluenceUrl%/rest/rag/1.0/chat"

echo.
echo Admin interface should be available at: %adminUrl%
echo REST API endpoint: %restUrl%

echo.
echo Test Payload Example:
echo {
echo   "message": "Hello, test message",
echo   "sessionId": "test-session-123"
echo }

echo.
echo To test manually:
echo 1. Install JAR in Confluence: Administration ^> Manage Apps ^> Upload App
echo 2. Configure AWS: %adminUrl%
echo 3. Test chat: POST to %restUrl%

echo.
echo JAR Contents Summary:
jar -tf "%jarPath%" 2>nul | find /c ""
echo Total files in JAR

jar -tf "%jarPath%" 2>nul | find ".class" | find /c ""
echo Class files

echo.
echo Testing complete. Install the JAR in Confluence to proceed.
pause
