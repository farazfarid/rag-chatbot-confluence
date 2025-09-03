package com.confluence.rag.api;

import com.confluence.rag.model.ChatRequest;
import com.confluence.rag.model.ChatResponse;
import com.confluence.rag.model.DocumentProcessingRequest;
import com.confluence.rag.model.DocumentProcessingResponse;

/**
 * Interface for RAG (Retrieval-Augmented Generation) service operations
 */
public interface RagServiceInterface {
    
    /**
     * Process a chat request and return AI-generated response
     * @param request Chat request containing user query
     * @return Chat response with AI-generated answer
     */
    ChatResponse processChat(ChatRequest request);
    
    /**
     * Process a document for indexing in the knowledge base
     * @param request Document processing request
     * @return Processing response with status
     */
    DocumentProcessingResponse processDocument(DocumentProcessingRequest request);
    
    /**
     * Search for relevant documents based on query
     * @param query Search query
     * @param maxResults Maximum number of results to return
     * @return List of relevant document excerpts
     */
    java.util.List<String> searchDocuments(String query, int maxResults);
    
    /**
     * Health check for the RAG service
     * @return true if service is healthy
     */
    boolean isHealthy();
}
