# Confluence RAG Chatbot

🤖 A fully-featured AI-powered chatbot for Confluence that leverages AWS services for RAG (Retrieval-Augmented Generation) capabilities.

## ✨ Features

- **Modern Blue & White UI**: Beautiful, responsive chatbot interface
- **RAG Functionality**: Intelligent responses based on your knowledge base
- **Multi-Source Support**: Upload files, add websites, and Confluence pages
- **AWS Powered**: Uses S3, OpenSearch, and Bedrock for scalable AI
- **Admin Panel**: Comprehensive settings and document management
- **File Support**: PDF, Word documents, text files, and web scraping
- **Vector Search**: Semantic search using embeddings
- **Customizable**: Theme colors, welcome messages, and chatbot name
- **Secure**: Admin-only access to settings and document management

## 🏗️ Architecture

```
Confluence App
    ↓
Forge Runtime
    ↓
AWS Services:
- S3 (Document Storage)
- OpenSearch (Vector Search)
- Bedrock (AI/Embeddings)
- Lambda (Processing)
```

## 🚀 Quick Start

### Prerequisites

1. **Node.js** (v18+)
2. **AWS CLI** configured with appropriate permissions
3. **Forge CLI**: `npm install -g @forge/cli`
4. **AWS Account** with access to:
   - S3
   - OpenSearch
   - Bedrock (Claude models)
   - Lambda
   - CloudFormation

### Installation

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd confluence-rag-chatbot
   npm install
   ```

2. **Deploy infrastructure and app:**
   ```bash
   ./deploy.sh
   ```

3. **Install in Confluence:**
   ```bash
   forge install
   ```

4. **Configure admin access:**
   - Update `.env` with your admin account IDs
   - Redeploy: `forge deploy`

## 🎛️ Admin Panel

Access the admin panel through Confluence (admin users only):

### Settings Management
- **Chatbot Name**: Customize the assistant's name
- **Welcome Message**: Set the initial greeting
- **Theme Colors**: Customize the blue and white theme
- **AWS Configuration**: Manage service endpoints

### Document Management
- **Upload Files**: PDF, Word, text documents
- **Add Websites**: Scrape public websites and Confluence pages
- **View Documents**: See all indexed content
- **Delete Content**: Remove documents from knowledge base

## 🤖 Usage

### For End Users
1. Navigate to any Confluence page
2. Find the "AI Knowledge Assistant" in the homepage feed
3. Start chatting with the AI assistant
4. Ask questions about your uploaded knowledge base

### For Admins
1. Access the "RAG Chatbot Admin" page (admin-only)
2. Upload documents or add websites
3. Customize chatbot settings
4. Monitor and manage the knowledge base

## 🔧 Development

### Local Development
```bash
# Start development tunnel
forge tunnel

# View logs
forge logs

# Lint code
npm run lint
```

### Deployment
```bash
# Deploy changes
forge deploy

# Update AWS infrastructure
./deploy.sh
```

## 🛠️ Supported File Types

- **PDF**: Automatic text extraction
- **Word Documents**: .docx and .doc files
- **Text Files**: Plain text content
- **Websites**: Public URLs and Confluence pages
- **HTML**: Web content with automatic cleaning

## 🌐 AWS Services Used

### S3 (Simple Storage Service)
- Document storage and retrieval
- Versioning and lifecycle management  
- Secure encrypted storage

### OpenSearch
- Vector similarity search
- Full-text search capabilities
- Document indexing and retrieval

### Bedrock
- Claude 3 Sonnet for chat responses
- Titan embeddings for vector generation
- Serverless AI inference

## 🔒 Security Features

- **Admin-Only Access**: Settings restricted to configured admins
- **Encrypted Storage**: S3 encryption at rest
- **HTTPS Endpoints**: All communications encrypted
- **IAM Roles**: Least-privilege AWS access
- **Input Validation**: Secure document processing

## 🎨 Customization

### Theme Customization
Modify colors in the admin panel:
- Primary Color (default: #1976d2)
- Secondary Color (default: #ffffff)
- Text Color (default: #333333)
- Background Color (default: #f5f5f5)

### Chatbot Personality
- Welcome Message
- Chatbot Name
- Response Style (via prompt engineering)

## 🚨 Troubleshooting

### Common Issues

1. **AWS Permissions**
   - Ensure IAM user has required permissions
   - Check Bedrock model access in your region

2. **Document Processing**
   - Verify S3 bucket exists and is accessible
   - Check OpenSearch cluster health

3. **Chat Responses**
   - Confirm Bedrock model availability
   - Check OpenSearch index exists

### Error Messages
- Check Forge logs: `forge logs`
- Review AWS CloudWatch logs
- Verify environment variables

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

- **Documentation**: Check this README
- **Logs**: Use `forge logs` for debugging
- **AWS Issues**: Check CloudWatch logs
- **Forge Issues**: See [Forge documentation](https://developer.atlassian.com/platform/forge/)

---

**Built with ❤️ using Atlassian Forge and AWS AI Services**
