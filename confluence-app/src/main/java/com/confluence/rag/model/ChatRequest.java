package com.confluence.rag.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Model class for chat requests
 */
public class ChatRequest {
    
    @JsonProperty("message")
    private String message;
    
    @JsonProperty("sessionId")
    private String sessionId;
    
    @JsonProperty("userId")
    private String userId;
    
    @JsonProperty("spaceKey")
    private String spaceKey;
    
    @JsonProperty("contextualSources")
    private java.util.List<String> contextualSources;
    
    public ChatRequest() {}
    
    public ChatRequest(String message, String sessionId, String userId) {
        this.message = message;
        this.sessionId = sessionId;
        this.userId = userId;
    }
    
    // Getters and Setters
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
    
    public String getSessionId() {
        return sessionId;
    }
    
    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }
    
    public String getUserId() {
        return userId;
    }
    
    public void setUserId(String userId) {
        this.userId = userId;
    }
    
    public String getSpaceKey() {
        return spaceKey;
    }
    
    public void setSpaceKey(String spaceKey) {
        this.spaceKey = spaceKey;
    }
    
    public java.util.List<String> getContextualSources() {
        return contextualSources;
    }
    
    public void setContextualSources(java.util.List<String> contextualSources) {
        this.contextualSources = contextualSources;
    }
}
