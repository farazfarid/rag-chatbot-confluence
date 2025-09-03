# 🚀 Confluence RAG Chatbot - Complete Project Structure

```
confluence-rag-chatbot/
├── README.md                          # Main documentation
├── KNOWLEDGE_SOURCES.md               # Knowledge sources configuration guide
├── deploy.sh                          # Automated deployment script
├── 
├── aws-infrastructure/                # AWS CDK Infrastructure
│   ├── package.json                   # CDK dependencies
│   ├── tsconfig.json                  # TypeScript configuration
│   ├── cdk.json                       # CDK configuration
│   ├── bin/
│   │   └── confluence-rag.ts          # CDK app entry point
│   ├── lib/
│   │   ├── confluence-rag-stack.ts    # Main infrastructure stack
│   │   ├── opensearch-stack.ts        # OpenSearch Serverless stack
│   │   └── lambda-stack.ts            # Lambda functions stack
│   └── lambda/                        # Lambda function code
│       ├── document-processor/
│       │   ├── index.py              # Document processing function
│       │   └── requirements.txt      # Python dependencies
│       ├── chat-processor/
│       │   ├── index.py              # Chat processing function
│       │   └── requirements.txt      # Python dependencies
│       └── confluence-sync/
│           ├── index.py              # Confluence synchronization
│           └── requirements.txt      # Python dependencies
│
├── confluence-app/                    # Confluence Data Center App
│   ├── pom.xml                       # Maven configuration
│   └── src/main/
│       ├── java/com/confluence/rag/
│       │   ├── api/                  # Service interfaces
│       │   │   ├── RagServiceInterface.java
│       │   │   └── AwsServiceInterface.java
│       │   ├── model/                # Data models
│       │   │   ├── ChatRequest.java
│       │   │   ├── ChatResponse.java
│       │   │   ├── DocumentProcessingRequest.java
│       │   │   └── DocumentProcessingResponse.java
│       │   ├── service/              # Business logic services
│       │   │   ├── RagService.java
│       │   │   └── AwsService.java
│       │   ├── rest/                 # REST API endpoints
│       │   │   └── RagRestResource.java
│       │   └── servlet/              # Admin interface
│       │       └── AdminServlet.java
│       └── resources/
│           ├── atlassian-plugin.xml   # Plugin descriptor
│           ├── application.properties # Configuration
│           ├── templates/            # Velocity templates
│           │   ├── admin.vm          # Admin configuration page
│           │   └── chat-panel.vm     # Chat widget template
│           ├── css/                  # Stylesheets
│           │   └── confluence-rag-chatbot.css
│           └── js/                   # JavaScript files
│               └── chat-widget.js    # Chat widget functionality
│
└── docs/                             # Additional documentation
    ├── installation-guide.md         # Detailed installation steps
    ├── api-reference.md              # API documentation
    └── troubleshooting.md            # Common issues and solutions
```

## 📦 Key Components

### 🏗️ AWS Infrastructure (`aws-infrastructure/`)
- **CDK Stacks:** Infrastructure as code using TypeScript
- **Lambda Functions:** Serverless processing for documents and chat
- **OpenSearch:** Vector database for semantic search
- **S3:** Secure document storage
- **API Gateway:** RESTful API endpoints
- **VPC:** Private network for enhanced security

### 🔧 Confluence App (`confluence-app/`)
- **JAR/OBR Compatible:** Works with Confluence Data Center 7.0+
- **Admin Interface:** Web-based configuration
- **REST API:** Integration endpoints
- **Chat Widget:** Embedded chat interface
- **Macro Support:** `/rag` macro for pages

### 🤖 AI/ML Pipeline
1. **Document Ingestion:** PDF, Confluence, websites
2. **Text Processing:** Chunking, cleaning, metadata extraction
3. **Embedding Generation:** AWS Bedrock Titan embeddings
4. **Vector Storage:** OpenSearch Serverless with HNSW indexing
5. **Retrieval:** Semantic similarity search
6. **Generation:** AWS Bedrock Claude for responses

## 🔒 Security Features

### Privacy-First Design
- **AWS-Only Processing:** No third-party AI services
- **VPC Isolation:** Private network deployment
- **Encryption:** Data encrypted at rest and in transit
- **IAM Policies:** Fine-grained access control
- **Audit Logging:** Complete activity tracking

### Confluence Integration
- **Permission Aware:** Respects Confluence permissions
- **Session Management:** Secure user sessions
- **Admin Controls:** Comprehensive configuration options

## 🚀 Deployment Options

### Quick Start
```bash
./deploy.sh
```

### Manual Deployment
1. **AWS Infrastructure:**
   ```bash
   cd aws-infrastructure
   npm install
   cdk deploy --all
   ```

2. **Confluence App:**
   ```bash
   cd confluence-app
   mvn clean package
   # Upload JAR to Confluence
   ```

### Development Mode
```bash
cd confluence-app
atlas-run --product confluence --version 7.19.0
```

## 📊 Monitoring & Observability

### AWS CloudWatch
- Lambda function metrics and logs
- API Gateway request tracking
- OpenSearch cluster health
- S3 access patterns

### Application Metrics
- Chat request/response times
- Document processing status
- Sync operation results
- User engagement analytics

## 🔧 Configuration Management

### Environment Variables
- **Development:** Local properties files
- **Production:** AWS Systems Manager Parameter Store
- **Confluence:** Plugin settings via admin interface

### Feature Flags
- Enable/disable specific knowledge sources
- Control AI model selection
- Adjust processing parameters
- Toggle debug modes

## 🧪 Testing Strategy

### Unit Tests
- Java service layer testing
- Lambda function testing
- API endpoint validation

### Integration Tests
- End-to-end chat workflows
- Document processing pipelines
- AWS service connectivity

### Performance Tests
- Load testing with multiple users
- Large document processing
- Concurrent sync operations

## 📈 Scalability Considerations

### Auto-Scaling Components
- **Lambda Functions:** Automatic scaling based on demand
- **OpenSearch Serverless:** Fully managed scaling
- **API Gateway:** Built-in scaling and throttling

### Cost Optimization
- **S3 Lifecycle Policies:** Automatic data archiving
- **Lambda Provisioned Concurrency:** For consistent performance
- **Reserved Capacity:** For predictable workloads

## 🔄 Maintenance & Updates

### Regular Tasks
- **Weekly:** Review sync logs and performance metrics
- **Monthly:** Update knowledge base content
- **Quarterly:** Review and optimize costs

### Update Process
1. Test in development environment
2. Deploy AWS infrastructure updates
3. Update Confluence app
4. Validate functionality
5. Monitor for issues

This architecture provides a robust, scalable, and privacy-focused RAG chatbot solution specifically designed for Confluence Data Center environments.
