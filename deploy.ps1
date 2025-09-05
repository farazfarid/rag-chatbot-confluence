# SOPTIM Community Elements Chatbot Deployment Script (PowerShell)
# This script deploys the complete AWS infrastructure and builds the Confluence app

param(
    [switch]$Verbose,
    [string]$Region = "",
    [switch]$SkipBootstrap
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting SOPTIM Community Elements Chatbot deployment..." -ForegroundColor Cyan

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>$null
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "✅ AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if CDK is installed
try {
    $cdkVersion = cdk --version 2>$null
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "✅ AWS CDK: $cdkVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CDK is not installed. Installing..." -ForegroundColor Yellow
    npm install -g aws-cdk
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install CDK. Please install Node.js first." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Check if Maven is installed
try {
    $mavenVersion = mvn -version 2>$null | Select-Object -First 1
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "✅ Maven: $mavenVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Maven is not installed. Please install Maven 3.6+ first." -ForegroundColor Red
    Write-Host "   Download from: https://maven.apache.org/download.cgi" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Java is installed
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "✅ Java: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Java is not installed. Please install Java 11+ first." -ForegroundColor Red
    Write-Host "   Download from: https://adoptium.net/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check AWS credentials
Write-Host "🔑 Checking AWS credentials..." -ForegroundColor Yellow
try {
    $awsIdentity = aws sts get-caller-identity 2>$null
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Host "❌ AWS credentials not configured. Please run 'aws configure' first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Get AWS account and region
$AWS_ACCOUNT = aws sts get-caller-identity --query Account --output text
$AWS_REGION = if ($Region) { $Region } else { aws configure get region }

if (-not $AWS_REGION) {
    Write-Host "❌ AWS region not configured. Please set a region:" -ForegroundColor Red
    $AWS_REGION = Read-Host "Enter AWS region (e.g., us-east-1)"
}

Write-Host "✅ AWS Account: $AWS_ACCOUNT" -ForegroundColor Green
Write-Host "✅ AWS Region: $AWS_REGION" -ForegroundColor Green

# Deploy AWS Infrastructure
Write-Host "🏗️ Deploying AWS infrastructure..." -ForegroundColor Cyan
Set-Location aws-infrastructure

# Install dependencies
Write-Host "📦 Installing CDK dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Bootstrap CDK (if needed)
if (-not $SkipBootstrap) {
    Write-Host "🎯 Bootstrapping CDK..." -ForegroundColor Yellow
    cdk bootstrap "aws://$AWS_ACCOUNT/$AWS_REGION"
}

# Create Lambda deployment packages
Write-Host "📦 Creating Lambda deployment packages..." -ForegroundColor Yellow

# Document processor
Set-Location "lambda\document-processor"
pip install -r requirements.txt -t .
Compress-Archive -Path * -DestinationPath "..\..\document-processor.zip" -Force
Set-Location "..\..\"

# Chat processor  
Set-Location "lambda\chat-processor"
pip install -r requirements.txt -t .
Compress-Archive -Path * -DestinationPath "..\..\chat-processor.zip" -Force
Set-Location "..\..\"

# Deploy stacks
Write-Host "🚀 Deploying CDK stacks..." -ForegroundColor Yellow
cdk deploy --all --require-approval never
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ CDK deployment failed" -ForegroundColor Red
    Set-Location ..
    Read-Host "Press Enter to exit"
    exit 1
}

# Get outputs
Write-Host "📄 Getting deployment outputs..." -ForegroundColor Yellow
try {
    $API_GATEWAY_URL = aws cloudformation describe-stacks --stack-name ConfluenceRagLambdaStack --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text
    $OPENSEARCH_ENDPOINT = aws cloudformation describe-stacks --stack-name ConfluenceRagOpenSearchStack --query "Stacks[0].Outputs[?OutputKey=='OpenSearchCollectionEndpoint'].OutputValue" --output text
    $S3_BUCKET = aws cloudformation describe-stacks --stack-name ConfluenceRagStack --query "Stacks[0].Outputs[?OutputKey=='DocumentsBucketName'].OutputValue" --output text

    Write-Host "✅ API Gateway URL: $API_GATEWAY_URL" -ForegroundColor Green
    Write-Host "✅ OpenSearch Endpoint: $OPENSEARCH_ENDPOINT" -ForegroundColor Green
    Write-Host "✅ S3 Bucket: $S3_BUCKET" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not retrieve all outputs. Check CloudFormation console." -ForegroundColor Yellow
}

Set-Location ..

# Build Confluence App
Write-Host "🔨 Building Confluence app..." -ForegroundColor Cyan
Set-Location confluence-app

# Update application.properties with actual values
Write-Host "⚙️ Updating configuration..." -ForegroundColor Yellow
try {
    $configPath = "src\main\resources\application.properties"
    $content = Get-Content $configPath -Raw
    
    $content = $content -replace "aws\.region=.*", "aws.region=$AWS_REGION"
    if ($OPENSEARCH_ENDPOINT) {
        $content = $content -replace "aws\.opensearch\.endpoint=.*", "aws.opensearch.endpoint=$OPENSEARCH_ENDPOINT"
    }
    if ($S3_BUCKET) {
        $content = $content -replace "aws\.s3\.bucket=.*", "aws.s3.bucket=$S3_BUCKET"
    }
    if ($API_GATEWAY_URL) {
        $content = $content -replace "aws\.api\.gateway\.url=.*", "aws.api.gateway.url=$API_GATEWAY_URL"
    }
    
    Set-Content $configPath -Value $content
} catch {
    Write-Host "⚠️ Could not update configuration file automatically" -ForegroundColor Yellow
}

# Build JAR
Write-Host "📦 Building Confluence app JAR..." -ForegroundColor Yellow
try {
    if ($Verbose) {
        mvn clean package
    } else {
        mvn clean package -q
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Maven build failed"
    }
} catch {
    Write-Host "❌ Failed to build Confluence app" -ForegroundColor Red
    Set-Location ..
    Read-Host "Press Enter to exit"
    exit 1
}

$jarPath = "target\soptim-community-elements-chatbot-1.0.0.jar"
if (Test-Path $jarPath) {
    Write-Host "✅ Confluence app built successfully!" -ForegroundColor Green
    Write-Host "📁 JAR location: confluence-app\$jarPath" -ForegroundColor White
} else {
    Write-Host "❌ Failed to build Confluence app" -ForegroundColor Red
    Set-Location ..
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location ..

# Final instructions
Write-Host ""
Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Upload the JAR file to your Confluence Data Center:" -ForegroundColor White
Write-Host "   File: confluence-app\$jarPath" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Configure the app in Confluence Administration:" -ForegroundColor White
Write-Host "   - Go to Manage Apps → SOPTIM Community Elements Chatbot Configuration" -ForegroundColor Gray
Write-Host "   - Enter your AWS credentials and verify the auto-configured endpoints" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test the installation:" -ForegroundColor White
Write-Host "   - Add the /rag macro to any Confluence page" -ForegroundColor Gray
Write-Host "   - Or use the chat widget in the sidebar" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 AWS Resources Created:" -ForegroundColor Cyan
Write-Host "   - VPC with public/private subnets" -ForegroundColor Gray
Write-Host "   - OpenSearch Serverless collection for vector storage" -ForegroundColor Gray
Write-Host "   - S3 bucket for document storage" -ForegroundColor Gray
Write-Host "   - Lambda functions for document processing and chat" -ForegroundColor Gray
Write-Host "   - API Gateway for REST endpoints" -ForegroundColor Gray
Write-Host "   - IAM roles and policies" -ForegroundColor Gray
Write-Host ""
Write-Host "💰 Estimated monthly cost: `$50-200 (depending on usage)" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔗 Useful links:" -ForegroundColor Cyan
Write-Host "   - API Gateway: https://console.aws.amazon.com/apigateway/home?region=$AWS_REGION" -ForegroundColor Gray
Write-Host "   - OpenSearch: https://console.aws.amazon.com/aos/home?region=$AWS_REGION" -ForegroundColor Gray
if ($S3_BUCKET) {
    Write-Host "   - S3 Bucket: https://console.aws.amazon.com/s3/buckets/$S3_BUCKET`?region=$AWS_REGION" -ForegroundColor Gray
}
Write-Host ""
Write-Host "For support, check the README.md file or create an issue in the repository." -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to continue"
