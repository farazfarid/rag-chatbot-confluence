@echo off
REM SOPTIM Community Elements Chatbot Deployment Script (Windows Batch)
REM This script deploys the complete AWS infrastructure and builds the Confluence app

setlocal enabledelayedexpansion

echo 🚀 Starting SOPTIM Community Elements Chatbot deployment...

REM Check prerequisites
echo 📋 Checking prerequisites...

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CLI is not installed. Please install it first.
    echo    Download from: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

REM Check if CDK is installed
cdk --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CDK is not installed. Installing...
    npm install -g aws-cdk
    if %errorlevel% neq 0 (
        echo ❌ Failed to install CDK. Please install Node.js first.
        pause
        exit /b 1
    )
)

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

REM Check AWS credentials
echo 🔑 Checking AWS credentials...
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS credentials not configured. Please run 'aws configure' first.
    pause
    exit /b 1
)

REM Get AWS account and region
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT=%%i
for /f "tokens=*" %%i in ('aws configure get region') do set AWS_REGION=%%i

echo ✅ AWS Account: %AWS_ACCOUNT%
echo ✅ AWS Region: %AWS_REGION%

REM Deploy AWS Infrastructure
echo 🏗️  Deploying AWS infrastructure...
cd aws-infrastructure

REM Install dependencies
echo 📦 Installing CDK dependencies...
npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

REM Bootstrap CDK (if needed)
echo 🎯 Bootstrapping CDK...
cdk bootstrap aws://%AWS_ACCOUNT%/%AWS_REGION%

REM Create Lambda deployment packages
echo 📦 Creating Lambda deployment packages...

REM Document processor
cd lambda\document-processor
pip install -r requirements.txt -t .
powershell Compress-Archive -Path * -DestinationPath ..\..\document-processor.zip -Force
cd ..\..

REM Chat processor  
cd lambda\chat-processor
pip install -r requirements.txt -t .
powershell Compress-Archive -Path * -DestinationPath ..\..\chat-processor.zip -Force
cd ..\..

REM Deploy stacks
echo 🚀 Deploying CDK stacks...
cdk deploy --all --require-approval never
if %errorlevel% neq 0 (
    echo ❌ CDK deployment failed
    pause
    exit /b 1
)

REM Get outputs
echo 📄 Getting deployment outputs...
for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name ConfluenceRagLambdaStack --query "Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue" --output text') do set API_GATEWAY_URL=%%i
for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name ConfluenceRagOpenSearchStack --query "Stacks[0].Outputs[?OutputKey==`OpenSearchCollectionEndpoint`].OutputValue" --output text') do set OPENSEARCH_ENDPOINT=%%i
for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name ConfluenceRagStack --query "Stacks[0].Outputs[?OutputKey==`DocumentsBucketName`].OutputValue" --output text') do set S3_BUCKET=%%i

echo ✅ API Gateway URL: %API_GATEWAY_URL%
echo ✅ OpenSearch Endpoint: %OPENSEARCH_ENDPOINT%
echo ✅ S3 Bucket: %S3_BUCKET%

cd ..

REM Build Confluence App
echo 🔨 Building Confluence app...
cd confluence-app

REM Update application.properties with actual values
echo ⚙️  Updating configuration...
powershell -Command "(Get-Content src\main\resources\application.properties) -replace 'aws.region=.*', 'aws.region=%AWS_REGION%' | Set-Content src\main\resources\application.properties"
powershell -Command "(Get-Content src\main\resources\application.properties) -replace 'aws.opensearch.endpoint=.*', 'aws.opensearch.endpoint=%OPENSEARCH_ENDPOINT%' | Set-Content src\main\resources\application.properties"
powershell -Command "(Get-Content src\main\resources\application.properties) -replace 'aws.s3.bucket=.*', 'aws.s3.bucket=%S3_BUCKET%' | Set-Content src\main\resources\application.properties"
powershell -Command "(Get-Content src\main\resources\application.properties) -replace 'aws.api.gateway.url=.*', 'aws.api.gateway.url=%API_GATEWAY_URL%' | Set-Content src\main\resources\application.properties"

REM Build JAR
echo 📦 Building Confluence app JAR...
mvn clean package -q

if exist "target\soptim-community-elements-chatbot-1.0.0.jar" (
    echo ✅ Confluence app built successfully!
    echo 📁 JAR location: confluence-app\target\soptim-community-elements-chatbot-1.0.0.jar
) else (
    echo ❌ Failed to build Confluence app
    pause
    exit /b 1
)

cd ..

REM Final instructions
echo.
echo 🎉 Deployment completed successfully!
echo.
echo 📋 Next steps:
echo 1. Upload the JAR file to your Confluence Data Center:
echo    File: confluence-app\target\soptim-community-elements-chatbot-1.0.0.jar
echo.
echo 2. Configure the app in Confluence Administration:
echo    - Go to Manage Apps → SOPTIM Community Elements Chatbot Configuration
echo    - Enter your AWS credentials and verify the auto-configured endpoints
echo.
echo 3. Test the installation:
echo    - Add the /rag macro to any Confluence page
echo    - Or use the chat widget in the sidebar
echo.
echo 📊 AWS Resources Created:
echo    - VPC with public/private subnets
echo    - OpenSearch Serverless collection for vector storage
echo    - S3 bucket for document storage
echo    - Lambda functions for document processing and chat
echo    - API Gateway for REST endpoints
echo    - IAM roles and policies
echo.
echo 💰 Estimated monthly cost: $50-200 (depending on usage)
echo.
echo 🔗 Useful links:
echo    - API Gateway: https://console.aws.amazon.com/apigateway/home?region=%AWS_REGION%
echo    - OpenSearch: https://console.aws.amazon.com/aos/home?region=%AWS_REGION%
echo    - S3 Bucket: https://console.aws.amazon.com/s3/buckets/%S3_BUCKET%?region=%AWS_REGION%
echo.
echo For support, check the README.md file or create an issue in the repository.
echo.
pause
