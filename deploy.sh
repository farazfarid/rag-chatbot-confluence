#!/bin/bash

# Confluence RAG Chatbot Deployment Script
# This script sets up AWS infrastructure and deploys the Confluence app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="confluence-rag-chatbot"
ENVIRONMENT="dev"
AWS_REGION="us-east-1"

echo -e "${BLUE}🚀 Starting Confluence RAG Chatbot Deployment${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Forge CLI is installed
if ! command -v forge &> /dev/null; then
    echo -e "${RED}❌ Forge CLI is not installed. Please install it first.${NC}"
    echo -e "${YELLOW}Run: npm install -g @forge/cli${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${BLUE}🔐 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure'${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials verified${NC}"

# Install dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
npm install

echo -e "${GREEN}✅ Dependencies installed${NC}"

# Deploy AWS Infrastructure
echo -e "${BLUE}🏗️  Deploying AWS infrastructure...${NC}"

# Check if stack exists
if aws cloudformation describe-stacks --stack-name "$STACK_NAME-$ENVIRONMENT" --region "$AWS_REGION" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Stack exists, updating...${NC}"
    aws cloudformation update-stack \
        --stack-name "$STACK_NAME-$ENVIRONMENT" \
        --template-body file://aws/cloudformation-template.yml \
        --parameters ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$AWS_REGION"
    
    echo -e "${BLUE}⏳ Waiting for stack update to complete...${NC}"
    aws cloudformation wait stack-update-complete \
        --stack-name "$STACK_NAME-$ENVIRONMENT" \
        --region "$AWS_REGION"
else
    echo -e "${YELLOW}🆕 Creating new stack...${NC}"
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME-$ENVIRONMENT" \
        --template-body file://aws/cloudformation-template.yml \
        --parameters ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$AWS_REGION"
    
    echo -e "${BLUE}⏳ Waiting for stack creation to complete...${NC}"
    aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME-$ENVIRONMENT" \
        --region "$AWS_REGION"
fi

echo -e "${GREEN}✅ AWS infrastructure deployed successfully${NC}"

# Get stack outputs
echo -e "${BLUE}📋 Retrieving stack outputs...${NC}"
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME-$ENVIRONMENT" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs')

S3_BUCKET=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="S3BucketName") | .OutputValue')
OPENSEARCH_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.[] | select(.OutputKey=="OpenSearchEndpoint") | .OutputValue')

echo -e "${GREEN}✅ S3 Bucket: $S3_BUCKET${NC}"
echo -e "${GREEN}✅ OpenSearch Endpoint: $OPENSEARCH_ENDPOINT${NC}"

# Create environment configuration
echo -e "${BLUE}⚙️  Creating environment configuration...${NC}"
cat > .env << EOF
# AWS Configuration
AWS_REGION=$AWS_REGION
S3_BUCKET_NAME=$S3_BUCKET
OPENSEARCH_ENDPOINT=https://$OPENSEARCH_ENDPOINT
BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0

# Environment
ENVIRONMENT=$ENVIRONMENT

# Admin Account IDs (replace with actual account IDs)
ADMIN_ACCOUNT_ID_1=your-admin-account-id-1
ADMIN_ACCOUNT_ID_2=your-admin-account-id-2
EOF

echo -e "${GREEN}✅ Environment configuration created${NC}"

# Build the Confluence app
echo -e "${BLUE}🔨 Building Confluence app...${NC}"
forge build

echo -e "${GREEN}✅ App built successfully${NC}"

# Deploy the Confluence app
echo -e "${BLUE}🚀 Deploying Confluence app...${NC}"

# Check if app is already installed
if forge list | grep -q "confluence-rag-chatbot"; then
    echo -e "${YELLOW}⚠️  App already installed, updating...${NC}"
    forge deploy
else
    echo -e "${YELLOW}🆕 Installing new app...${NC}"
    forge deploy
    echo -e "${BLUE}📝 Don't forget to install the app in your Confluence site!${NC}"
    echo -e "${BLUE}Run: forge install${NC}"
fi

echo -e "${GREEN}✅ Confluence app deployed successfully${NC}"

# Setup OpenSearch index
echo -e "${BLUE}🔍 Setting up OpenSearch index...${NC}"

# Create index mapping
curl -X PUT "https://$OPENSEARCH_ENDPOINT/confluence-rag-documents" \
    -H "Content-Type: application/json" \
    -d '{
        "mappings": {
            "properties": {
                "content": {
                    "type": "text",
                    "analyzer": "standard"
                },
                "title": {
                    "type": "text",
                    "analyzer": "standard"
                },
                "source": {
                    "type": "keyword"
                },
                "type": {
                    "type": "keyword"
                },
                "documentId": {
                    "type": "keyword"
                },
                "chunkIndex": {
                    "type": "integer"
                },
                "embedding": {
                    "type": "dense_vector",
                    "dims": 1536
                },
                "timestamp": {
                    "type": "date"
                }
            }
        },
        "settings": {
            "index": {
                "number_of_shards": 1,
                "number_of_replicas": 0,
                "knn": true,
                "knn.algo_param.ef_search": 100
            }
        }
    }' 2>/dev/null || echo -e "${YELLOW}⚠️  Index might already exist${NC}"

echo -e "${GREEN}✅ OpenSearch index configured${NC}"

# Final instructions
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo -e "${YELLOW}1. Update the admin account IDs in .env file${NC}"
echo -e "${YELLOW}2. Run 'forge install' to install the app in your Confluence site${NC}"
echo -e "${YELLOW}3. Configure AWS credentials for the app if needed${NC}"
echo -e "${YELLOW}4. Test the chatbot functionality${NC}"

echo -e "${BLUE}🔗 Useful commands:${NC}"
echo -e "${YELLOW}- View logs: forge logs${NC}"
echo -e "${YELLOW}- Update app: forge deploy${NC}"
echo -e "${YELLOW}- Uninstall app: forge uninstall${NC}"

echo -e "${GREEN}✨ Happy chatting with your AI Knowledge Assistant!${NC}"
