#!/bin/bash

# Confluence RAG Chatbot Deployment Script
# This script deploys the complete AWS infrastructure and builds the Confluence app

set -e

echo "🚀 Starting Confluence RAG Chatbot deployment..."

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! command -v cdk &> /dev/null; then
    echo "❌ AWS CDK is not installed. Installing..."
    npm install -g aws-cdk
fi

if ! command -v mvn &> /dev/null; then
    echo "❌ Maven is not installed. Please install Maven 3.6+ first."
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed. Please install Java 11+ first."
    exit 1
fi

# Check AWS credentials
echo "🔑 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

echo "✅ AWS Account: $AWS_ACCOUNT"
echo "✅ AWS Region: $AWS_REGION"

# Deploy AWS Infrastructure
echo "🏗️  Deploying AWS infrastructure..."
cd aws-infrastructure

# Install dependencies
echo "📦 Installing CDK dependencies..."
npm install

# Bootstrap CDK (if needed)
echo "🎯 Bootstrapping CDK..."
cdk bootstrap aws://$AWS_ACCOUNT/$AWS_REGION

# Create Lambda deployment packages
echo "📦 Creating Lambda deployment packages..."

# Document processor
cd lambda/document-processor
pip install -r requirements.txt -t .
zip -r ../../document-processor.zip . -x "*.pyc" "__pycache__/*"
cd ../..

# Chat processor  
cd lambda/chat-processor
pip install -r requirements.txt -t .
zip -r ../../chat-processor.zip . -x "*.pyc" "__pycache__/*"
cd ../..

# Deploy stacks
echo "🚀 Deploying CDK stacks..."
cdk deploy --all --require-approval never

# Get outputs
echo "📄 Getting deployment outputs..."
API_GATEWAY_URL=$(aws cloudformation describe-stacks --stack-name ConfluenceRagLambdaStack --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text)
OPENSEARCH_ENDPOINT=$(aws cloudformation describe-stacks --stack-name ConfluenceRagOpenSearchStack --query 'Stacks[0].Outputs[?OutputKey==`OpenSearchCollectionEndpoint`].OutputValue' --output text)
S3_BUCKET=$(aws cloudformation describe-stacks --stack-name ConfluenceRagStack --query 'Stacks[0].Outputs[?OutputKey==`DocumentsBucketName`].OutputValue' --output text)

echo "✅ API Gateway URL: $API_GATEWAY_URL"
echo "✅ OpenSearch Endpoint: $OPENSEARCH_ENDPOINT"
echo "✅ S3 Bucket: $S3_BUCKET"

cd ..

# Build Confluence App
echo "🔨 Building Confluence app..."
cd confluence-app

# Update application.properties with actual values
echo "⚙️  Updating configuration..."
sed -i.bak "s|aws.region=.*|aws.region=$AWS_REGION|g" src/main/resources/application.properties
sed -i.bak "s|aws.opensearch.endpoint=.*|aws.opensearch.endpoint=$OPENSEARCH_ENDPOINT|g" src/main/resources/application.properties
sed -i.bak "s|aws.s3.bucket=.*|aws.s3.bucket=$S3_BUCKET|g" src/main/resources/application.properties
sed -i.bak "s|aws.api.gateway.url=.*|aws.api.gateway.url=$API_GATEWAY_URL|g" src/main/resources/application.properties

# Build JAR
echo "📦 Building Confluence app JAR..."
mvn clean package

if [ -f "target/confluence-rag-chatbot-1.0.0.jar" ]; then
    echo "✅ Confluence app built successfully!"
    echo "📁 JAR location: confluence-app/target/confluence-rag-chatbot-1.0.0.jar"
else
    echo "❌ Failed to build Confluence app"
    exit 1
fi

cd ..

# Final instructions
echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Upload the JAR file to your Confluence Data Center:"
echo "   File: confluence-app/target/confluence-rag-chatbot-1.0.0.jar"
echo ""
echo "2. Configure the app in Confluence Administration:"
echo "   - Go to Manage Apps → RAG Chatbot Configuration"
echo "   - Enter your AWS credentials and verify the auto-configured endpoints"
echo ""
echo "3. Test the installation:"
echo "   - Add the /rag macro to any Confluence page"
echo "   - Or use the chat widget in the sidebar"
echo ""
echo "📊 AWS Resources Created:"
echo "   - VPC with public/private subnets"
echo "   - OpenSearch Serverless collection for vector storage"
echo "   - S3 bucket for document storage"
echo "   - Lambda functions for document processing and chat"
echo "   - API Gateway for REST endpoints"
echo "   - IAM roles and policies"
echo ""
echo "💰 Estimated monthly cost: $50-200 (depending on usage)"
echo ""
echo "🔗 Useful links:"
echo "   - API Gateway: https://console.aws.amazon.com/apigateway/home?region=$AWS_REGION"
echo "   - OpenSearch: https://console.aws.amazon.com/aos/home?region=$AWS_REGION"
echo "   - S3 Bucket: https://console.aws.amazon.com/s3/buckets/$S3_BUCKET?region=$AWS_REGION"
echo ""
echo "For support, check the README.md file or create an issue in the repository."
