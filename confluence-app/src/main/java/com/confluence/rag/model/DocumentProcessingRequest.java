package com.confluence.rag.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Model class for document processing requests
 */
public class DocumentProcessingRequest {
    
    @JsonProperty("documentId")
    private String documentId;
    
    @JsonProperty("title")
    private String title;
    
    @JsonProperty("content")
    private String content;
    
    @JsonProperty("sourceUrl")
    private String sourceUrl;
    
    @JsonProperty("documentType")
    private String documentType;
    
    @JsonProperty("spaceKey")
    private String spaceKey;
    
    @JsonProperty("metadata")
    private java.util.Map<String, Object> metadata;
    
    public DocumentProcessingRequest() {}
    
    public DocumentProcessingRequest(String documentId, String title, String content) {
        this.documentId = documentId;
        this.title = title;
        this.content = content;
    }
    
    // Getters and Setters
    public String getDocumentId() {
        return documentId;
    }
    
    public void setDocumentId(String documentId) {
        this.documentId = documentId;
    }
    
    public String getTitle() {
        return title;
    }
    
    public void setTitle(String title) {
        this.title = title;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    public String getSourceUrl() {
        return sourceUrl;
    }
    
    public void setSourceUrl(String sourceUrl) {
        this.sourceUrl = sourceUrl;
    }
    
    public String getDocumentType() {
        return documentType;
    }
    
    public void setDocumentType(String documentType) {
        this.documentType = documentType;
    }
    
    public String getSpaceKey() {
        return spaceKey;
    }
    
    public void setSpaceKey(String spaceKey) {
        this.spaceKey = spaceKey;
    }
    
    public java.util.Map<String, Object> getMetadata() {
        return metadata;
    }
    
    public void setMetadata(java.util.Map<String, Object> metadata) {
        this.metadata = metadata;
    }
}
