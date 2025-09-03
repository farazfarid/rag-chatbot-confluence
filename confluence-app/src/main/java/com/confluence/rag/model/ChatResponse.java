package com.confluence.rag.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Model class for chat responses
 */
public class ChatResponse {
    
    @JsonProperty("response")
    private String response;
    
    @JsonProperty("sessionId")
    private String sessionId;
    
    @JsonProperty("sources")
    private java.util.List<String> sources;
    
    @JsonProperty("confidence")
    private double confidence;
    
    @JsonProperty("timestamp")
    private long timestamp;
    
    @JsonProperty("error")
    private String error;
    
    public ChatResponse() {
        this.timestamp = System.currentTimeMillis();
    }
    
    public ChatResponse(String response, String sessionId) {
        this();
        this.response = response;
        this.sessionId = sessionId;
    }
    
    // Getters and Setters
    public String getResponse() {
        return response;
    }
    
    public void setResponse(String response) {
        this.response = response;
    }
    
    public String getSessionId() {
        return sessionId;
    }
    
    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }
    
    public java.util.List<String> getSources() {
        return sources;
    }
    
    public void setSources(java.util.List<String> sources) {
        this.sources = sources;
    }
    
    public double getConfidence() {
        return confidence;
    }
    
    public void setConfidence(double confidence) {
        this.confidence = confidence;
    }
    
    public long getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }
    
    public String getError() {
        return error;
    }
    
    public void setError(String error) {
        this.error = error;
    }
    
    public static ChatResponse error(String error, String sessionId) {
        ChatResponse response = new ChatResponse();
        response.setError(error);
        response.setSessionId(sessionId);
        return response;
    }
}
