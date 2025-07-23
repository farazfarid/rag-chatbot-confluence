import Resolver from '@forge/resolver';
import { storage } from '@forge/api';
import AWSServices from '../utils/awsServices.js';
import DocumentProcessor from '../utils/documentProcessor.js';
import { v4 as uuidv4 } from 'uuid';

const resolver = new Resolver();

// Constants
const OPENSEARCH_INDEX = 'confluence-rag-documents';
const MAX_CONTEXT_LENGTH = 4000;

// Chat functionality
resolver.define('sendMessage', async (req) => {
  try {
    const { message, conversationId } = req.payload;
    
    if (!message || !message.trim()) {
      throw new Error('Message cannot be empty');
    }

    // Generate embedding for the user's message
    const messageEmbedding = await AWSServices.generateEmbedding(message);
    
    // Perform vector search to find relevant context
    const searchResults = await AWSServices.vectorSearch(
      OPENSEARCH_INDEX, 
      messageEmbedding, 
      5
    );
    
    // Extract context from search results
    const context = searchResults.hits
      .map(hit => hit._source.content)
      .join('\n\n')
      .substring(0, MAX_CONTEXT_LENGTH);
    
    // Generate AI response using context
    const aiResponse = await AWSServices.generateResponse(message, context);
    
    // Store conversation
    const conversationKey = conversationId || uuidv4();
    const conversation = await storage.get(`conversation:${conversationKey}`) || { messages: [] };
    
    conversation.messages.push(
      { role: 'user', content: message, timestamp: new Date().toISOString() },
      { role: 'assistant', content: aiResponse, timestamp: new Date().toISOString(), sources: searchResults.hits.map(hit => hit._source) }
    );
    
    await storage.set(`conversation:${conversationKey}`, conversation);
    
    return {
      success: true,
      response: aiResponse,
      conversationId: conversationKey,
      sources: searchResults.hits.map(hit => ({
        title: hit._source.title,
        source: hit._source.source,
        snippet: hit._source.content.substring(0, 200) + '...'
      }))
    };
  } catch (error) {
    console.error('Chat error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Get conversation history
resolver.define('getConversation', async (req) => {
  try {
    const { conversationId } = req.payload;
    
    if (!conversationId) {
      return { success: true, messages: [] };
    }
    
    const conversation = await storage.get(`conversation:${conversationId}`) || { messages: [] };
    
    return {
      success: true,
      messages: conversation.messages
    };
  } catch (error) {
    console.error('Get conversation error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Admin functionality - Upload documents
resolver.define('uploadDocument', async (req) => {
  try {
    const { file, title, type, source } = req.payload;
    
    if (!file || !title || !type) {
      throw new Error('File, title, and type are required');
    }
    
    // Process the document
    const processedDoc = await DocumentProcessor.processDocument(
      Buffer.from(file, 'base64'),
      type,
      title,
      source || 'Upload'
    );
    
    // Upload original file to S3
    const s3Key = `documents/${processedDoc.id}/${title}`;
    await AWSServices.uploadToS3(s3Key, Buffer.from(file, 'base64'));
    
    // Index document chunks in OpenSearch
    for (const chunk of processedDoc.chunks) {
      await AWSServices.indexDocument(OPENSEARCH_INDEX, chunk.id, chunk);
    }
    
    // Store document metadata
    const documents = await storage.get('documents') || [];
    documents.push({
      ...processedDoc,
      s3Key,
      uploadedAt: new Date().toISOString()
    });
    await storage.set('documents', documents);
    
    return {
      success: true,
      documentId: processedDoc.id,
      chunksCount: processedDoc.chunks.length
    };
  } catch (error) {
    console.error('Upload document error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Admin functionality - Add website
resolver.define('addWebsite', async (req) => {
  try {
    const { url, title } = req.payload;
    
    if (!url || !title) {
      throw new Error('URL and title are required');
    }
    
    // Process the website
    const processedDoc = await DocumentProcessor.processDocument(
      url,
      'url',
      title,
      url
    );
    
    // Index document chunks in OpenSearch
    for (const chunk of processedDoc.chunks) {
      await AWSServices.indexDocument(OPENSEARCH_INDEX, chunk.id, chunk);
    }
    
    // Store document metadata
    const websites = await storage.get('websites') || [];
    websites.push({
      ...processedDoc,
      addedAt: new Date().toISOString()
    });
    await storage.set('websites', websites);
    
    return {
      success: true,
      documentId: processedDoc.id,
      chunksCount: processedDoc.chunks.length
    };
  } catch (error) {
    console.error('Add website error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Admin functionality - Get documents
resolver.define('getDocuments', async (req) => {
  try {
    const documents = await storage.get('documents') || [];
    const websites = await storage.get('websites') || [];
    
    return {
      success: true,
      documents: documents.map(doc => ({
        id: doc.id,
        title: doc.title,
        type: doc.type,
        source: doc.source,
        chunksCount: doc.chunks?.length || 0,
        uploadedAt: doc.uploadedAt || doc.processedAt
      })),
      websites: websites.map(site => ({
        id: site.id,
        title: site.title,
        source: site.source,
        chunksCount: site.chunks?.length || 0,
        addedAt: site.addedAt || site.processedAt
      }))
    };
  } catch (error) {
    console.error('Get documents error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Admin functionality - Delete document
resolver.define('deleteDocument', async (req) => {
  try {
    const { documentId, type } = req.payload;
    
    if (!documentId) {
      throw new Error('Document ID is required');
    }
    
    const storageKey = type === 'website' ? 'websites' : 'documents';
    const items = await storage.get(storageKey) || [];
    const itemIndex = items.findIndex(item => item.id === documentId);
    
    if (itemIndex === -1) {
      throw new Error('Document not found');
    }
    
    const item = items[itemIndex];
    
    // Delete from OpenSearch
    for (const chunk of item.chunks || []) {
      try {
        // Note: OpenSearch deletion would need proper client implementation
        console.log(`Deleting chunk ${chunk.id} from OpenSearch`);
      } catch (error) {
        console.error(`Error deleting chunk ${chunk.id}:`, error);
      }
    }
    
    // Delete from S3 if it's a file
    if (item.s3Key) {
      try {
        await AWSServices.deleteFromS3(item.s3Key);
      } catch (error) {
        console.error('Error deleting from S3:', error);
      }
    }
    
    // Remove from storage
    items.splice(itemIndex, 1);
    await storage.set(storageKey, items);
    
    return {
      success: true,
      message: 'Document deleted successfully'
    };
  } catch (error) {
    console.error('Delete document error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Admin functionality - Get settings
resolver.define('getSettings', async (req) => {
  try {
    const settings = await storage.get('settings') || {
      chatbotName: 'AI Knowledge Assistant',
      welcomeMessage: 'Hello! I\'m your AI Knowledge Assistant. Ask me anything about your knowledge base.',
      theme: {
        primaryColor: '#1976d2',
        secondaryColor: '#ffffff',
        textColor: '#333333',
        backgroundColor: '#f5f5f5'
      },
      awsConfig: {
        region: '',
        s3Bucket: '',
        openSearchEndpoint: '',
        bedrockModelId: 'anthropic.claude-3-sonnet-20240229-v1:0'
      }
    };
    
    return {
      success: true,
      settings
    };
  } catch (error) {
    console.error('Get settings error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Admin functionality - Update settings
resolver.define('updateSettings', async (req) => {
  try {
    const { settings } = req.payload;
    
    if (!settings) {
      throw new Error('Settings are required');
    }
    
    await storage.set('settings', settings);
    
    return {
      success: true,
      message: 'Settings updated successfully'
    };
  } catch (error) {
    console.error('Update settings error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Check if user is admin
resolver.define('checkAdminAccess', async (req) => {
  try {
    // In a real implementation, you would check the user's account ID
    // against a list of admin account IDs
    const { accountId } = req.context;
    const adminAccountIds = process.env.ADMIN_ACCOUNT_IDS?.split(',') || [];
    
    const isAdmin = adminAccountIds.includes(accountId);
    
    return {
      success: true,
      isAdmin
    };
  } catch (error) {
    console.error('Check admin access error:', error);
    return {
      success: false,
      error: error.message,
      isAdmin: false
    };
  }
});

// Health check
resolver.define('healthCheck', async (req) => {
  return {
    success: true,
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  };
});

export const handler = resolver.getDefinitions();
