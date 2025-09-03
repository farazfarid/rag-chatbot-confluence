# Knowledge Sources Configuration Guide

This guide explains how to configure different knowledge sources for your Confluence RAG chatbot.

## 🌐 Confluence Sites

### Adding Confluence Cloud/Server Instances

1. **Access Admin Configuration:**
   - Go to Confluence Administration → Apps → RAG Chatbot Configuration
   - Click on "Knowledge Sources" tab
   - Select "Confluence Sites"

2. **Add New Site:**
   ```
   Site Name: Your Site Name
   Base URL: https://your-site.atlassian.net/wiki (Cloud) or http://your-server:8090 (Server)
   Authentication Type: 
     - Personal Access Token (recommended)
     - Basic Authentication
     - OAuth (for Cloud)
   ```

3. **Authentication Setup:**

   **For Confluence Cloud (PAT):**
   - Go to https://id.atlassian.com/manage-profile/security/api-tokens
   - Create new token
   - Use your email + token for authentication

   **For Confluence Data Center/Server:**
   - Username + Password
   - Or create service account with read permissions

4. **Sync Configuration:**
   ```
   Spaces to Include: All / Specific spaces (comma-separated keys)
   Content Types: Pages, Blog Posts, Comments
   Sync Frequency: Hourly, Daily, Weekly
   Last Modified Filter: Only content modified in last X days
   ```

### Supported Confluence Versions
- ✅ Confluence Cloud
- ✅ Confluence Data Center 7.0+
- ✅ Confluence Server 7.0+
- ❌ Confluence Server < 7.0 (limited API support)

## 📄 PDF Documents

### Uploading PDF Files

1. **Single File Upload:**
   - Go to Knowledge Sources → PDF Documents
   - Click "Upload PDF"
   - Select file (max 50MB)
   - Add metadata (title, description, tags)

2. **Bulk Upload via S3:**
   - Upload PDFs to your configured S3 bucket
   - Structure: `s3://your-bucket/pdfs/category/filename.pdf`
   - Use folder structure for organization
   - Sync will automatically detect new files

3. **Supported Features:**
   - Text extraction from searchable PDFs
   - OCR for scanned documents (requires additional AWS Textract setup)
   - Metadata extraction (title, author, creation date)
   - Automatic chunking for large documents

### PDF Processing Pipeline
```
PDF Upload → Text Extraction → Chunking → Embedding Generation → OpenSearch Indexing
```

## 🌍 External Websites

### Adding Website Sources

1. **Website Configuration:**
   ```
   Site Name: Documentation Site
   Start URL: https://docs.example.com
   Crawl Depth: 2 (number of link levels to follow)
   URL Patterns: 
     Include: /docs/*, /api/*
     Exclude: /login*, /admin*
   ```

2. **Content Filters:**
   - CSS Selectors for content extraction
   - Remove navigation, ads, footers
   - Example: `article, .content, .documentation`

3. **Crawl Settings:**
   ```
   Max Pages: 1000
   Crawl Frequency: Weekly
   Respect robots.txt: Yes
   Delay Between Requests: 1 second
   User Agent: ConfluenceRagBot/1.0
   ```

### Supported Website Types
- ✅ Static documentation sites
- ✅ WordPress sites
- ✅ GitBook documentation
- ✅ Notion public pages
- ✅ GitHub Pages
- ❌ Sites requiring authentication
- ❌ JavaScript-heavy SPAs (limited support)

## 🔄 Synchronization

### Automatic Sync
- **Confluence:** Checks for new/modified content every hour
- **PDFs:** Monitors S3 bucket for new uploads
- **Websites:** Weekly crawl by default

### Manual Sync
- Use the "Sync Now" button in admin interface
- API endpoint: `POST /rest/rag/1.0/sync`
- CLI command: `curl -X POST your-api-url/sync`

### Sync Status Monitoring
- View sync logs in admin interface
- Check CloudWatch logs for detailed information
- Monitor sync success/failure rates

## 📊 Content Processing

### Document Chunking
- **Chunk Size:** 1000 characters (configurable)
- **Overlap:** 200 characters to maintain context
- **Smart Splitting:** Breaks at sentence boundaries when possible

### Embedding Generation
- **Model:** Amazon Titan Text Embeddings
- **Dimensions:** 1536
- **Language Support:** English (primary), 25+ other languages

### Vector Storage
- **OpenSearch Serverless:** Fully managed, auto-scaling
- **Index Strategy:** One index per content type
- **Similarity Search:** Cosine similarity with HNSW algorithm

## 🔍 Search Configuration

### Search Parameters
```
Default Results: 5 relevant chunks
Max Context Length: 4000 characters
Similarity Threshold: 0.7
Boost Factors:
  - Recent content: 1.2x
  - Same space: 1.5x
  - Exact matches: 2.0x
```

### Content Filtering
- **Space-based:** Limit search to specific Confluence spaces
- **Date-based:** Prioritize recent content
- **User-based:** Respect Confluence permissions (coming soon)

## 🛠️ Troubleshooting

### Common Issues

1. **Confluence Sync Failing:**
   - Check network connectivity from AWS to Confluence
   - Verify authentication credentials
   - Check rate limiting settings

2. **PDF Processing Errors:**
   - Ensure PDF is not password-protected
   - Check file size limits (50MB default)
   - Verify S3 bucket permissions

3. **Website Crawling Issues:**
   - Check robots.txt compliance
   - Verify SSL certificates
   - Monitor rate limiting

### Debug Mode
Enable debug logging in the admin interface to get detailed information about processing steps.

### Performance Optimization
- **Large Sites:** Increase sync frequency for important content
- **Many PDFs:** Use S3 lifecycle policies to manage storage costs
- **Heavy Usage:** Consider increasing Lambda memory allocation

For additional support, check the main README.md or create an issue in the repository.
