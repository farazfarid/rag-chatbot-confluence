package com.confluence.rag.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;

/**
 * Security monitoring service to track and prevent abuse
 */
public class SecurityMonitor {
    
    private static final Logger logger = LoggerFactory.getLogger(SecurityMonitor.class);
    
    // Track blocked attempts by IP/session
    private final Map<String, SecurityStats> securityStats = new ConcurrentHashMap<>();
    
    // Track recent blocked attempts for pattern analysis
    private final List<SecurityIncident> recentIncidents = new ArrayList<>();
    
    // Rate limiting
    private final Map<String, RateLimitInfo> rateLimits = new ConcurrentHashMap<>();
    
    private static final int MAX_REQUESTS_PER_MINUTE = 30;
    private static final int MAX_REQUESTS_PER_HOUR = 500;
    private static final int MAX_BLOCKED_ATTEMPTS_BEFORE_BLOCK = 5;
    
    /**
     * Records a security incident
     */
    public void recordSecurityIncident(String sessionId, String ipAddress, SecurityIncidentType type, String details) {
        logger.warn("Security incident: {} from session {} (IP: {}) - {}", type, sessionId, ipAddress, details);
        
        // Update statistics
        SecurityStats stats = securityStats.computeIfAbsent(sessionId, k -> new SecurityStats());
        stats.incrementIncident(type);
        
        // Record incident
        SecurityIncident incident = new SecurityIncident(sessionId, ipAddress, type, details, LocalDateTime.now());
        synchronized (recentIncidents) {
            recentIncidents.add(incident);
            
            // Keep only last 1000 incidents
            if (recentIncidents.size() > 1000) {
                recentIncidents.remove(0);
            }
        }
        
        // Check if session should be temporarily blocked
        if (stats.getTotalBlockedAttempts() >= MAX_BLOCKED_ATTEMPTS_BEFORE_BLOCK) {
            logger.error("Session {} temporarily blocked due to {} security incidents", sessionId, stats.getTotalBlockedAttempts());
            stats.setTemporarilyBlocked(true);
        }
    }
    
    /**
     * Checks if a session is currently rate limited
     */
    public boolean isRateLimited(String sessionId) {
        RateLimitInfo rateLimitInfo = rateLimits.get(sessionId);
        if (rateLimitInfo == null) {
            return false;
        }
        
        LocalDateTime now = LocalDateTime.now();
        
        // Clean up old requests
        rateLimitInfo.cleanupOldRequests(now);
        
        // Check minute limit
        long requestsInLastMinute = rateLimitInfo.getRequestsInTimeframe(now.minus(1, ChronoUnit.MINUTES));
        if (requestsInLastMinute >= MAX_REQUESTS_PER_MINUTE) {
            logger.warn("Rate limit exceeded for session {}: {} requests in last minute", sessionId, requestsInLastMinute);
            return true;
        }
        
        // Check hour limit
        long requestsInLastHour = rateLimitInfo.getRequestsInTimeframe(now.minus(1, ChronoUnit.HOURS));
        if (requestsInLastHour >= MAX_REQUESTS_PER_HOUR) {
            logger.warn("Rate limit exceeded for session {}: {} requests in last hour", sessionId, requestsInLastHour);
            return true;
        }
        
        return false;
    }
    
    /**
     * Records a request for rate limiting
     */
    public void recordRequest(String sessionId) {
        RateLimitInfo rateLimitInfo = rateLimits.computeIfAbsent(sessionId, k -> new RateLimitInfo());
        rateLimitInfo.addRequest(LocalDateTime.now());
    }
    
    /**
     * Checks if a session is temporarily blocked
     */
    public boolean isSessionBlocked(String sessionId) {
        SecurityStats stats = securityStats.get(sessionId);
        return stats != null && stats.isTemporarilyBlocked();
    }
    
    /**
     * Gets security statistics for a session
     */
    public SecurityStats getSecurityStats(String sessionId) {
        return securityStats.get(sessionId);
    }
    
    /**
     * Gets recent security incidents
     */
    public List<SecurityIncident> getRecentIncidents(int limit) {
        synchronized (recentIncidents) {
            return new ArrayList<>(recentIncidents.subList(
                Math.max(0, recentIncidents.size() - limit), 
                recentIncidents.size()
            ));
        }
    }
    
    /**
     * Unblocks a session (admin function)
     */
    public void unblockSession(String sessionId) {
        SecurityStats stats = securityStats.get(sessionId);
        if (stats != null) {
            stats.setTemporarilyBlocked(false);
            stats.reset();
            logger.info("Session {} manually unblocked", sessionId);
        }
    }
    
    /**
     * Security incident types
     */
    public enum SecurityIncidentType {
        JAILBREAK_ATTEMPT,
        PROMPT_INJECTION,
        OFF_TOPIC_QUERY,
        RATE_LIMIT_EXCEEDED,
        SUSPICIOUS_PATTERN,
        CODE_INJECTION_ATTEMPT,
        PERSONAL_INFO_REQUEST,
        SYSTEM_MANIPULATION_ATTEMPT
    }
    
    /**
     * Security statistics for a session
     */
    public static class SecurityStats {
        private final Map<SecurityIncidentType, AtomicInteger> incidents = new ConcurrentHashMap<>();
        private volatile boolean temporarilyBlocked = false;
        private final LocalDateTime createdAt = LocalDateTime.now();
        
        public void incrementIncident(SecurityIncidentType type) {
            incidents.computeIfAbsent(type, k -> new AtomicInteger(0)).incrementAndGet();
        }
        
        public int getIncidentCount(SecurityIncidentType type) {
            AtomicInteger count = incidents.get(type);
            return count != null ? count.get() : 0;
        }
        
        public int getTotalBlockedAttempts() {
            return incidents.values().stream().mapToInt(AtomicInteger::get).sum();
        }
        
        public boolean isTemporarilyBlocked() {
            return temporarilyBlocked;
        }
        
        public void setTemporarilyBlocked(boolean blocked) {
            this.temporarilyBlocked = blocked;
        }
        
        public void reset() {
            incidents.clear();
        }
        
        public LocalDateTime getCreatedAt() {
            return createdAt;
        }
    }
    
    /**
     * Security incident record
     */
    public static class SecurityIncident {
        private final String sessionId;
        private final String ipAddress;
        private final SecurityIncidentType type;
        private final String details;
        private final LocalDateTime timestamp;
        
        public SecurityIncident(String sessionId, String ipAddress, SecurityIncidentType type, String details, LocalDateTime timestamp) {
            this.sessionId = sessionId;
            this.ipAddress = ipAddress;
            this.type = type;
            this.details = details;
            this.timestamp = timestamp;
        }
        
        // Getters
        public String getSessionId() { return sessionId; }
        public String getIpAddress() { return ipAddress; }
        public SecurityIncidentType getType() { return type; }
        public String getDetails() { return details; }
        public LocalDateTime getTimestamp() { return timestamp; }
    }
    
    /**
     * Rate limiting information
     */
    private static class RateLimitInfo {
        private final List<LocalDateTime> requests = new ArrayList<>();
        
        public void addRequest(LocalDateTime timestamp) {
            synchronized (requests) {
                requests.add(timestamp);
            }
        }
        
        public void cleanupOldRequests(LocalDateTime now) {
            synchronized (requests) {
                requests.removeIf(timestamp -> timestamp.isBefore(now.minus(1, ChronoUnit.HOURS)));
            }
        }
        
        public long getRequestsInTimeframe(LocalDateTime since) {
            synchronized (requests) {
                return requests.stream().filter(timestamp -> timestamp.isAfter(since)).count();
            }
        }
    }
}
