package com.confluence.rag.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Model class for document processing responses
 */
public class DocumentProcessingResponse {
    
    @JsonProperty("success")
    private boolean success;
    
    @JsonProperty("documentId")
    private String documentId;
    
    @JsonProperty("message")
    private String message;
    
    @JsonProperty("chunksProcessed")
    private int chunksProcessed;
    
    @JsonProperty("timestamp")
    private long timestamp;
    
    public DocumentProcessingResponse() {
        this.timestamp = System.currentTimeMillis();
    }
    
    public DocumentProcessingResponse(boolean success, String documentId, String message) {
        this();
        this.success = success;
        this.documentId = documentId;
        this.message = message;
    }
    
    // Getters and Setters
    public boolean isSuccess() {
        return success;
    }
    
    public void setSuccess(boolean success) {
        this.success = success;
    }
    
    public String getDocumentId() {
        return documentId;
    }
    
    public void setDocumentId(String documentId) {
        this.documentId = documentId;
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
    
    public int getChunksProcessed() {
        return chunksProcessed;
    }
    
    public void setChunksProcessed(int chunksProcessed) {
        this.chunksProcessed = chunksProcessed;
    }
    
    public long getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }
}
