# SOPTIM Community Elements Chatbot - AWS Privacy-First Solution

A privacy-focused RAG (Retrieval-Augmented Generation) chatbot for Confluence Data Center that uses AWS services for secure document processing and AI capabilities. Part of the SOPTIM Community Elements suite.

## 🏗️ Architecture

This solution uses AWS services to ensure data privacy:
- **AWS Bedrock**: For LLM inference (stays within AWS)
- **AWS OpenSearch**: Vector database for embeddings
- **AWS Lambda**: Serverless processing functions
- **AWS S3**: Secure document storage
- **AWS API Gateway**: RESTful API endpoints
- **AWS IAM**: Fine-grained access control

## 📋 Prerequisites

### Confluence Data Center
- Confluence Data Center 7.0+ (for JAR/OBR support)
- Administrator access to install apps

### For JAR Only Build (Recommended for Testing)
- Java 11+
- Maven 3.6+
- ❌ **NO AWS CLI needed** - configure via admin interface

### For Full Automated Deployment
- AWS Account with appropriate permissions
- AWS CLI installed and configured
- AWS CDK installed (`npm install -g aws-cdk`)
- Java 11+ (for Confluence app development)
- Maven 3.6+
- Node.js 16+ (for AWS infrastructure)

## 🚀 Installation Guide

### Quick Start (JAR Only - No AWS CLI Required)

**Perfect for testing or if you prefer manual AWS setup:**

1. **Build the Confluence app:**
   ```bash
   ./build-jar.sh
   ```

2. **Upload to Confluence:**
   - Go to Confluence Administration → Manage Apps → Upload App
   - Select: `confluence-app/target/soptim-community-elements-chatbot-1.0.0.jar`

3. **Configure via admin interface:**
   - Go to Administration → SOPTIM Community Elements Chatbot Configuration
   - Enter your AWS credentials and endpoints
   - Add knowledge sources

### Full Automated Deployment (AWS CLI Required)

**For complete infrastructure automation:**

### Step 1: Deploy AWS Infrastructure

1. **Clone and setup the project:**
   ```bash
   git clone <your-repo>
   cd soptim-community-elements-chatbot
   npm install
   ```

2. **Configure AWS credentials:**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret, and preferred region
   ```

3. **Deploy everything:**
   ```bash
   ./deploy.sh
   ```

### Step 2: Manual AWS Setup (Alternative)

If you prefer to set up AWS manually, see [DEPLOYMENT_OPTIONS.md](DEPLOYMENT_OPTIONS.md) for detailed instructions.

The chatbot supports multiple knowledge sources:

#### Confluence Sites
- Add multiple Confluence base URLs
- Configure authentication (basic auth, personal access tokens)
- Set up synchronization schedules

#### PDF Files
- Upload PDFs directly through the admin interface
- Bulk upload via S3 bucket integration

#### External Websites
- Add website URLs for crawling
- Configure crawl depth and filters
- Set up refresh schedules

## 🔧 Configuration

### AWS Configuration
Edit `confluence-app/src/main/resources/application.properties`:

```properties
# AWS Configuration
aws.region=us-east-1
aws.bedrock.model=anthropic.claude-3-sonnet-20240229-v1:0
aws.opensearch.endpoint=https://your-opensearch-domain.region.es.amazonaws.com
aws.s3.bucket=your-confluence-rag-bucket

# API Gateway
aws.api.gateway.url=https://your-api-id.execute-api.region.amazonaws.com/prod
```

### Knowledge Base Settings
- **Confluence Sites:** Supports both Cloud and Data Center instances
- **Document Processing:** Automatic chunking and embedding generation
- **Refresh Intervals:** Configurable sync schedules (hourly, daily, weekly)

## 🔒 Privacy & Security Features

- **AWS-Only Processing:** All data stays within your AWS account
- **VPC Deployment:** Optional VPC deployment for additional isolation
- **Encryption:** Data encrypted at rest and in transit
- **IAM Policies:** Fine-grained access control
- **Audit Logging:** Comprehensive logging via CloudWatch

## 🤖 Usage

1. **In Confluence pages:** Use the `/soptim-chat` macro to add chatbot interface
2. **Sidebar widget:** Access SOPTIM Community Elements Chatbot from any page via sidebar
3. **API Access:** Direct API access for custom integrations

## 📊 Monitoring

- **CloudWatch Dashboards:** Monitor usage and performance
- **X-Ray Tracing:** Distributed tracing for debugging
- **Cost Monitoring:** Track AWS costs per feature

## 🔄 Updating

### Update AWS Infrastructure:
```bash
cd aws-infrastructure
cdk deploy --all
```

### Update Confluence App:
```bash
cd confluence-app
mvn clean package
# Upload new JAR through Confluence admin interface
```

## 🆘 Troubleshooting

### Common Issues

1. **"No AWS credentials found"**
   - Verify AWS CLI configuration
   - Check IAM permissions

2. **"OpenSearch connection failed"**
   - Verify VPC settings if using VPC deployment
   - Check security group configurations

3. **"Confluence authentication failed"**
   - Verify personal access tokens
   - Check network connectivity from AWS to Confluence

### Support
- Check CloudWatch logs for detailed error messages
- Enable debug logging in Confluence app configuration

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

For technical support, please check the troubleshooting section or create an issue in the repository.
