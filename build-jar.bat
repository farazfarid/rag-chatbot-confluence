@echo off
REM Confluence RAG Chatbot - JAR Build Script (Windows Batch)
REM This script builds only the Confluence app JAR without requiring AWS CLI

echo 🔨 Building Confluence RAG Chatbot JAR...

REM Check prerequisites
echo 📋 Checking prerequisites...

REM Check if Maven is installed
mvn -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Maven is not installed. Please install Maven 3.6+ first.
    echo    Download from: https://maven.apache.org/download.cgi
    pause
    exit /b 1
)

REM Check if Java is installed
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Java is not installed. Please install Java 11+ first.
    echo    Download from: https://adoptium.net/
    pause
    exit /b 1
)

echo ✅ Maven installed
echo ✅ Java installed

REM Build Confluence App
echo 🔨 Building Confluence app...
cd confluence-app

REM Clean and build
echo 📦 Running Maven clean package...
mvn clean package -q

if exist "target\confluence-rag-chatbot-1.0.0.jar" (
    echo ✅ Confluence app built successfully!
    echo.
    echo 📁 JAR location: confluence-app\target\confluence-rag-chatbot-1.0.0.jar
    for %%A in ("target\confluence-rag-chatbot-1.0.0.jar") do echo 📏 File size: %%~zA bytes
    echo.
    echo 🎉 Ready for installation!
    echo.
    echo 📋 Next steps:
    echo 1. Upload the JAR file to your Confluence Data Center:
    echo    - Go to Confluence Administration → Manage Apps
    echo    - Click 'Upload app'
    echo    - Select: confluence-app\target\confluence-rag-chatbot-1.0.0.jar
    echo.
    echo 2. Configure the app:
    echo    - Go to Administration → RAG Chatbot Configuration
    echo    - Enter your AWS credentials and endpoints
    echo    - Add knowledge sources (Confluence sites, PDFs, websites)
    echo.
    echo 3. Test the installation:
    echo    - Add the /rag macro to any Confluence page
    echo    - Or use the chat widget in the sidebar
    echo.
    echo 📖 For AWS infrastructure setup (optional):
    echo    - If you need AWS infrastructure, install AWS CLI first
    echo    - Then run: deploy.bat for full deployment
    echo.
    echo 🔧 Manual AWS setup:
    echo    - You can set up AWS resources manually via console
    echo    - Configure the app with your AWS endpoints in the admin interface
) else (
    echo ❌ Failed to build Confluence app
    echo Check the Maven output above for errors
    pause
    exit /b 1
)

cd ..
echo.
echo Press any key to continue...
pause >nul
