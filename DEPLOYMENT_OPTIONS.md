# 🚀 Deployment Options Guide

## You have **3 deployment options** for the Confluence RAG Chatbot:

---

## 🔧 **Option 1: JAR Only (No AWS CLI Required)**

**Best for:** Testing, manual AWS setup, or when you prefer to configure AWS through the console.

### Prerequisites:
- ✅ Java 11+
- ✅ Maven 3.6+
- ❌ **NO AWS CLI needed**

### Build Command:
```bash
./build-jar.sh
```

### What you get:
- ✅ Confluence app JAR file ready for upload
- ✅ Works with any AWS setup (manual or automated)
- ✅ Configure everything through Confluence admin interface

### Next steps:
1. **Upload JAR** to Confluence Data Center
2. **Set up AWS manually** (see AWS Manual Setup below)
3. **Configure app** via admin interface with your AWS endpoints

---

## 🏗️ **Option 2: Full Automated Deployment**

**Best for:** Complete end-to-end setup with infrastructure automation.

### Prerequisites:
- ✅ Java 11+
- ✅ Maven 3.6+
- ✅ AWS CLI configured
- ✅ Node.js 16+
- ✅ AWS CDK

### Deploy Command:
```bash
./deploy.sh
```

### What you get:
- ✅ Complete AWS infrastructure (OpenSearch, Bedrock, Lambda, S3, VPC)
- ✅ Confluence app JAR
- ✅ Pre-configured endpoints
- ✅ Ready to use immediately

---

## ⚙️ **Option 3: Manual AWS Setup + JAR**

**Best for:** Enterprise environments with specific AWS requirements or restrictions.

### Steps:

#### 1. Build JAR (No AWS CLI needed):
```bash
./build-jar.sh
```

#### 2. Set up AWS manually:

**Required AWS Services:**
- **S3 Bucket** for document storage
- **OpenSearch Serverless** for vector embeddings
- **Bedrock** access (Claude 3 or Titan models)
- **Lambda functions** (optional, for advanced processing)
- **API Gateway** (optional, for REST endpoints)

**Manual Setup Instructions:**

1. **Create S3 Bucket:**
   - Go to S3 Console
   - Create bucket: `confluence-rag-documents-[your-account]`
   - Enable versioning and encryption

2. **Set up OpenSearch Serverless:**
   - Go to OpenSearch Console
   - Create Serverless collection: `confluence-rag-vectors`
   - Type: Vector search
   - Configure security policies

3. **Enable Bedrock:**
   - Go to Bedrock Console
   - Request access to Claude 3 Sonnet or Titan models
   - Note the model ARNs

4. **Create IAM User/Role:**
   - Create IAM user with permissions for:
     - S3 bucket access
     - OpenSearch collection access
     - Bedrock invoke permissions

#### 3. Configure Confluence App:
- Upload JAR to Confluence
- Go to RAG Chatbot Configuration
- Enter your AWS credentials and endpoints

---

## 🤔 **Why AWS CLI for Option 2?**

The AWS CLI is needed for **automated infrastructure deployment** because:

1. **CDK Bootstrap:** Sets up CDK toolkit resources
2. **Account/Region Detection:** Gets your AWS account ID and region
3. **Stack Deployment:** Deploys CloudFormation stacks
4. **Output Retrieval:** Gets endpoints and ARNs automatically
5. **Resource Validation:** Checks if deployment succeeded

**But for the Confluence app itself:** You can configure **everything manually** through the admin interface!

---

## 📊 **Comparison Table**

| Feature | JAR Only | Full Deployment | Manual Setup |
|---------|----------|-----------------|--------------|
| **AWS CLI Required** | ❌ No | ✅ Yes | ❌ No |
| **Setup Time** | 5 minutes | 20 minutes | 30-60 minutes |
| **Automation Level** | Low | High | Medium |
| **Customization** | High | Medium | Highest |
| **Best For** | Testing/Simple | Production/Quick | Enterprise/Custom |

---

## 🎯 **Recommended Approach**

### For Testing/Development:
```bash
./build-jar.sh
```
Then set up AWS manually or use existing resources.

### For Production:
```bash
./deploy.sh
```
If you have AWS CLI access and want full automation.

### For Enterprise:
Use **Manual Setup** with your organization's AWS governance and security requirements.

---

## 🔐 **Admin Configuration**

Regardless of deployment method, you'll configure these in the Confluence admin interface:

```
AWS Region: us-east-1
AWS Access Key: AKIA...
AWS Secret Key: [your-secret]
Bedrock Model: claude-3-sonnet-20240229-v1:0
OpenSearch Endpoint: https://[collection-id].us-east-1.aoss.amazonaws.com
S3 Bucket: confluence-rag-documents-123456
API Gateway URL: https://[api-id].execute-api.us-east-1.amazonaws.com/prod
```

The app will work with **any valid AWS setup** - whether automated or manual! 🚀
