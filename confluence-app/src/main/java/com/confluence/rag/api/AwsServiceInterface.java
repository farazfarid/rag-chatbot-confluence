package com.confluence.rag.api;

import com.confluence.rag.model.DocumentProcessingRequest;
import java.util.List;

/**
 * Interface for AWS service operations
 */
public interface AwsServiceInterface {
    
    /**
     * Generate AI response using AWS Bedrock
     * @param query User query
     * @param context Relevant context from documents
     * @return AI-generated response
     */
    String generateResponse(String query, String context);
    
    /**
     * Process document through AWS Lambda
     * @param request Document processing request
     * @return true if successful
     */
    boolean processDocument(DocumentProcessingRequest request);
    
    /**
     * Search documents using AWS OpenSearch
     * @param query Search query
     * @param maxResults Maximum number of results
     * @return List of relevant document excerpts
     */
    List<String> searchDocuments(String query, int maxResults);
    
    /**
     * Check if AWS services are healthy
     * @return true if healthy
     */
    boolean isHealthy();
}
