package com.confluence.rag.service;

import com.confluence.rag.api.RagServiceInterface;
import com.confluence.rag.model.ChatRequest;
import com.confluence.rag.model.ChatResponse;
import com.confluence.rag.model.DocumentProcessingRequest;
import com.confluence.rag.model.DocumentProcessingResponse;
import com.atlassian.sal.api.pluginsettings.PluginSettings;
import com.atlassian.sal.api.pluginsettings.PluginSettingsFactory;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;
import javax.inject.Named;
import java.util.List;
import java.util.ArrayList;
import java.util.Properties;
import java.io.InputStream;

/**
 * Implementation of RAG service for Confluence
 */
@Named
@Component
public class RagService implements RagServiceInterface {
    
    private static final Logger LOG = LoggerFactory.getLogger(RagService.class);
    private static final String PLUGIN_KEY = "com.confluence.rag.confluence-rag-chatbot";
    
    private final PluginSettingsFactory pluginSettingsFactory;
    private final AwsService awsService;
    private final Properties config;
    
    @Inject
    public RagService(PluginSettingsFactory pluginSettingsFactory, AwsService awsService) {
        this.pluginSettingsFactory = pluginSettingsFactory;
        this.awsService = awsService;
        this.config = loadConfiguration();
    }
    
    private Properties loadConfiguration() {
        Properties props = new Properties();
        try (InputStream is = getClass().getClassLoader().getResourceAsStream("application.properties")) {
            if (is != null) {
                props.load(is);
            }
        } catch (Exception e) {
            LOG.error("Failed to load application properties", e);
        }
        return props;
    }
    
    @Override
    public ChatResponse processChat(ChatRequest request) {
        try {
            LOG.info("Processing chat request for user: {}", request.getUserId());
            
            // Validate request
            if (request.getMessage() == null || request.getMessage().trim().isEmpty()) {
                return ChatResponse.error("Message cannot be empty", request.getSessionId());
            }
            
            // Search for relevant documents
            List<String> relevantDocs = searchDocuments(request.getMessage(), 5);
            
            // Generate response using AWS Bedrock
            String context = String.join("\n\n", relevantDocs);
            String aiResponse = awsService.generateResponse(request.getMessage(), context);
            
            // Create response
            ChatResponse response = new ChatResponse(aiResponse, request.getSessionId());
            response.setSources(relevantDocs);
            response.setConfidence(0.85); // This would be calculated based on actual relevance scores
            
            LOG.info("Successfully processed chat request");
            return response;
            
        } catch (Exception e) {
            LOG.error("Error processing chat request", e);
            return ChatResponse.error("Failed to process chat request: " + e.getMessage(), request.getSessionId());
        }
    }
    
    @Override
    public DocumentProcessingResponse processDocument(DocumentProcessingRequest request) {
        try {
            LOG.info("Processing document: {}", request.getTitle());
            
            // Send document to AWS Lambda for processing
            boolean success = awsService.processDocument(request);
            
            DocumentProcessingResponse response = new DocumentProcessingResponse();
            response.setSuccess(success);
            response.setDocumentId(request.getDocumentId());
            
            if (success) {
                response.setMessage("Document processed successfully");
            } else {
                response.setMessage("Failed to process document");
            }
            
            return response;
            
        } catch (Exception e) {
            LOG.error("Error processing document", e);
            DocumentProcessingResponse response = new DocumentProcessingResponse();
            response.setSuccess(false);
            response.setMessage("Error: " + e.getMessage());
            return response;
        }
    }
    
    @Override
    public List<String> searchDocuments(String query, int maxResults) {
        try {
            return awsService.searchDocuments(query, maxResults);
        } catch (Exception e) {
            LOG.error("Error searching documents", e);
            return new ArrayList<>();
        }
    }
    
    @Override
    public boolean isHealthy() {
        try {
            // Check AWS service health
            return awsService.isHealthy();
        } catch (Exception e) {
            LOG.error("Health check failed", e);
            return false;
        }
    }
    
    public String getConfigValue(String key) {
        PluginSettings settings = pluginSettingsFactory.createGlobalSettings();
        String value = (String) settings.get(PLUGIN_KEY + "." + key);
        
        if (value == null) {
            value = config.getProperty(key);
        }
        
        return value;
    }
    
    public void setConfigValue(String key, String value) {
        PluginSettings settings = pluginSettingsFactory.createGlobalSettings();
        settings.put(PLUGIN_KEY + "." + key, value);
    }
}
