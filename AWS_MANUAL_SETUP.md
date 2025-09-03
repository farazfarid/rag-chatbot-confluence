# 🔧 Manual AWS Setup Guide

## Overview

You can set up the required AWS services manually without using AWS CLI or CDK. This guide walks you through creating the necessary resources via the AWS Console.

## Required AWS Services

### 1. 🪣 **S3 Bucket for Document Storage**

**Steps:**
1. Go to [S3 Console](https://console.aws.amazon.com/s3/)
2. Click "Create bucket"
3. **Bucket name:** `confluence-rag-documents-[random-suffix]`
4. **Region:** Choose your preferred region
5. **Settings:**
   - ✅ Enable versioning
   - ✅ Enable default encryption (SSE-S3)
   - ✅ Block all public access
6. Click "Create bucket"

**Note:** Remember the exact bucket name and region for configuration.

---

### 2. 🔍 **OpenSearch Serverless for Vector Storage**

**Steps:**
1. Go to [OpenSearch Console](https://console.aws.amazon.com/aos/)
2. Click "Create collection" (Serverless)
3. **Collection details:**
   - **Name:** `confluence-rag-vectors`
   - **Type:** Vector search
   - **Description:** Vector database for RAG chatbot
4. **Security:**
   - Create encryption policy (accept defaults)
   - Create network policy (public access for now)
   - Create data access policy with your AWS account ARN
5. Click "Create"
6. **Wait 5-10 minutes** for collection to be active

**Note:** Copy the collection endpoint URL for configuration.

---

### 3. 🤖 **Amazon Bedrock for AI Models**

**Steps:**
1. Go to [Bedrock Console](https://console.aws.amazon.com/bedrock/)
2. Navigate to "Model access" in the left sidebar
3. **Request access to models:**
   - ✅ Claude 3 Sonnet (anthropic.claude-3-sonnet-20240229-v1:0)
   - ✅ Titan Text Embeddings (amazon.titan-embed-text-v1)
4. Click "Request model access"
5. **Wait for approval** (usually instant for Titan, may take time for Claude)

**Available regions for Bedrock:**
- `us-east-1` (N. Virginia) - Recommended
- `us-west-2` (Oregon)  
- `eu-west-1` (Ireland)

---

### 4. 👤 **IAM User for Confluence App**

**Steps:**
1. Go to [IAM Console](https://console.aws.amazon.com/iam/)
2. Click "Users" → "Create user"
3. **User details:**
   - **Username:** `confluence-rag-user`
   - **Access type:** Programmatic access
4. **Permissions:** Create custom policy with this JSON:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::confluence-rag-documents-*",
                "arn:aws:s3:::confluence-rag-documents-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "aoss:APIAccessAll"
            ],
            "Resource": "arn:aws:aoss:*:*:collection/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel"
            ],
            "Resource": [
                "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
                "arn:aws:bedrock:*::foundation-model/amazon.titan-embed-text-v1"
            ]
        }
    ]
}
```

5. **Download credentials:** Save the Access Key ID and Secret Access Key

---

### 5. ⚡ **Lambda Functions (Optional)**

**For advanced document processing, you can create Lambda functions:**

1. Go to [Lambda Console](https://console.aws.amazon.com/lambda/)
2. Create function: `confluence-rag-document-processor`
3. **Runtime:** Python 3.11
4. **Code:** Upload the code from `aws-infrastructure/lambda/document-processor/`
5. **Environment variables:**
   - `OPENSEARCH_ENDPOINT`: Your collection endpoint
   - `S3_BUCKET`: Your bucket name
   - `BEDROCK_REGION`: Your region

**Note:** This is optional - the Confluence app can work without Lambda functions.

---

### 6. 🌐 **API Gateway (Optional)**

**For REST API endpoints:**

1. Go to [API Gateway Console](https://console.aws.amazon.com/apigateway/)
2. Create REST API: `confluence-rag-api`
3. Create resources and methods
4. Deploy to stage: `prod`

**Note:** This is optional - the Confluence app has built-in REST endpoints.

---

## 📝 **Configuration Summary**

After setting up AWS manually, you'll need these values for the Confluence admin interface:

```
AWS Region: [your-chosen-region]
AWS Access Key ID: AKIA[your-access-key]
AWS Secret Access Key: [your-secret-key]
Bedrock Model: anthropic.claude-3-sonnet-20240229-v1:0
OpenSearch Endpoint: https://[collection-id].[region].aoss.amazonaws.com
S3 Bucket: confluence-rag-documents-[your-suffix]
```

## 💰 **Cost Estimation**

**Monthly costs for small usage (< 100 users):**
- **S3:** $1-5 (storage and requests)
- **OpenSearch Serverless:** $20-50 (compute and storage)
- **Bedrock:** $10-30 (API calls)
- **Total:** ~$30-85/month

## 🔐 **Security Best Practices**

1. **Use least privilege IAM policies**
2. **Enable CloudTrail logging**
3. **Set up billing alerts**
4. **Regularly rotate access keys**
5. **Use VPC endpoints if possible**

## 🆘 **Troubleshooting**

### Common Issues:

1. **"Access Denied" errors:**
   - Check IAM policy permissions
   - Verify resource ARNs are correct
   - Ensure OpenSearch data access policy includes your account

2. **"Model not available" errors:**
   - Request access to Bedrock models
   - Check if models are available in your region
   - Wait for approval (can take up to 24 hours)

3. **OpenSearch connection failures:**
   - Verify collection is in "Active" state
   - Check network policy allows access
   - Ensure endpoint URL is correct

## ✅ **Verification Steps**

Test your setup:

1. **S3:** Try uploading a test file via console
2. **OpenSearch:** Check collection status (should be "Active")
3. **Bedrock:** Go to playgrounds and test model access
4. **IAM:** Use AWS CLI to test credentials (if available)

Once everything is set up, configure the Confluence app with your values and test the installation!

---

**Need help?** Check the [troubleshooting guide](README.md#troubleshooting) or create an issue in the repository.
