package com.confluence.rag.service;

import com.confluence.rag.api.RagServiceInterface;
import com.confluence.rag.model.ChatRequest;
import com.confluence.rag.model.ChatResponse;
import com.confluence.rag.model.DocumentProcessingRequest;
import com.confluence.rag.model.DocumentProcessingResponse;
import com.confluence.rag.security.SecurityValidator;
import com.confluence.rag.security.SecurityMonitor;
import com.confluence.rag.logging.S3Logger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Properties;
import java.io.InputStream;
import java.io.IOException;

/**
 * Simplified RAG service implementation without Atlassian dependencies
 */
public class RagServiceSimple implements RagServiceInterface {
    
    private static final Logger logger = LoggerFactory.getLogger(RagServiceSimple.class);
    private final Properties config;
    private final SecurityValidator securityValidator;
    private final SecurityMonitor securityMonitor;
    private final S3Logger s3Logger;
    
    public RagServiceSimple() {
        this.config = new Properties();
        this.securityValidator = new SecurityValidator();
        this.securityMonitor = new SecurityMonitor();
        this.s3Logger = new S3Logger();
        loadConfiguration();
    }
    
    private void loadConfiguration() {
        try (InputStream input = getClass().getResourceAsStream("/application.properties")) {
            if (input != null) {
                config.load(input);
                logger.info("Configuration loaded successfully");
            } else {
                logger.warn("application.properties not found, using defaults");
            }
        } catch (IOException e) {
            logger.error("Error loading configuration", e);
        }
    }
    
    @Override
    public ChatResponse processChat(ChatRequest request) {
        long startTime = System.currentTimeMillis();
        String sessionId = (request != null) ? request.getSessionId() : "unknown";
        String ipAddress = (request != null) ? request.getUserId() : "unknown"; // Using userId as IP placeholder
        String userQuery = (request != null) ? request.getMessage() : "";
        
        // Log the incoming request
        s3Logger.logSystemEvent("CHAT_REQUEST_RECEIVED", 
                               "New chat request received from session: " + sessionId, sessionId);
        
        if (request == null || request.getMessage() == null || request.getMessage().trim().isEmpty()) {
            String errorMessage = "Bitte geben Sie eine gültige Frage ein.";
            s3Logger.logUserQuery(sessionId, ipAddress, userQuery, errorMessage, false, "Empty query");
            return ChatResponse.error(errorMessage, sessionId);
        }
        
        // Check if session is blocked
        if (securityMonitor.isSessionBlocked(sessionId)) {
            logger.warn("Blocked session {} attempted to send message", sessionId);
            String errorMessage = "Ihr Zugriff wurde aufgrund wiederholter Sicherheitsverletzungen temporär blockiert. Bitte wenden Sie sich an Ihren Administrator.";
            s3Logger.logUserQuery(sessionId, ipAddress, userQuery, errorMessage, true, "Session blocked");
            return ChatResponse.error(errorMessage, sessionId);
        }
        
        // Check rate limiting
        if (securityMonitor.isRateLimited(sessionId)) {
            securityMonitor.recordSecurityIncident(sessionId, ipAddress, SecurityMonitor.SecurityIncidentType.RATE_LIMIT_EXCEEDED, "Too many requests");
            String errorMessage = "Sie senden zu viele Anfragen. Bitte warten Sie einen Moment, bevor Sie eine neue Frage stellen.";
            s3Logger.logUserQuery(sessionId, ipAddress, userQuery, errorMessage, true, "Rate limit exceeded");
            s3Logger.logSecurityIncident(sessionId, ipAddress, "RATE_LIMIT_EXCEEDED", "Too many requests", userQuery);
            return ChatResponse.error(errorMessage, sessionId);
        }
        
        // Record the request for rate limiting
        securityMonitor.recordRequest(sessionId);
        
        // SECURITY VALIDATION - Prevent jailbreaking and ensure topic relevance
        SecurityValidator.ValidationResult validation = securityValidator.validateQuery(request.getMessage());
        if (!validation.isValid()) {
            logger.warn("Security validation failed for query: {}", request.getMessage());
            
            // Determine incident type based on validation failure
            SecurityMonitor.SecurityIncidentType incidentType = SecurityMonitor.SecurityIncidentType.SUSPICIOUS_PATTERN;
            String securityDetails = validation.getErrorMessage();
            
            if (validation.getErrorMessage().contains("nicht erlaubte Inhalte")) {
                incidentType = SecurityMonitor.SecurityIncidentType.JAILBREAK_ATTEMPT;
                securityDetails = "Jailbreak attempt detected";
            } else if (validation.getErrorMessage().contains("nicht mit Ihrer Wissensdatenbank zusammenhängen")) {
                incidentType = SecurityMonitor.SecurityIncidentType.OFF_TOPIC_QUERY;
                securityDetails = "Off-topic query";
            }
            
            securityMonitor.recordSecurityIncident(sessionId, ipAddress, incidentType, validation.getErrorMessage());
            
            // Log security violation with full details
            s3Logger.logUserQuery(sessionId, ipAddress, userQuery, validation.getErrorMessage(), true, securityDetails);
            s3Logger.logSecurityIncident(sessionId, ipAddress, incidentType.name(), 
                                       validation.getErrorMessage(), userQuery);
            
            return ChatResponse.error(validation.getErrorMessage(), sessionId);
        }
        
        // Sanitize the query
        String sanitizedQuery = securityValidator.sanitizeQuery(request.getMessage());
        logger.info("Processing sanitized chat request: {}", sanitizedQuery);
        
        try {
            // Search documents with sanitized query
            List<String> documents = searchDocuments(sanitizedQuery, 3);
            String context = buildContext(documents);
            
            // Create secure prompt that prevents jailbreaking
            String securePrompt = securityValidator.createSecurePrompt(sanitizedQuery, context);
            
            // Generate response with security constraints
            String responseText = generateSecureResponse(sanitizedQuery, context);
            
            // Validate the response to ensure it doesn't contain inappropriate content
            String validatedResponse = securityValidator.validateResponse(responseText);
            
            // Calculate response time
            long responseTime = System.currentTimeMillis() - startTime;
            
            // Log successful interaction
            s3Logger.logUserQuery(sessionId, ipAddress, userQuery, validatedResponse, false, 
                                "Query processed successfully in " + responseTime + "ms");
            
            logger.info("Successfully processed secure chat request in {}ms", responseTime);
            return new ChatResponse(validatedResponse, sessionId);
            
        } catch (Exception e) {
            logger.error("Error processing chat request", e);
            securityMonitor.recordSecurityIncident(sessionId, ipAddress, SecurityMonitor.SecurityIncidentType.SYSTEM_MANIPULATION_ATTEMPT, "Processing error: " + e.getMessage());
            
            String errorMessage = "Entschuldigung, aber ich bin auf einen Fehler gestoßen, während ich Ihre Frage bearbeitet habe. Bitte versuchen Sie es erneut oder wenden Sie sich an Ihren Administrator.";
            
            // Log system error
            s3Logger.logUserQuery(sessionId, ipAddress, userQuery, errorMessage, true, "System error: " + e.getMessage());
            s3Logger.logSecurityIncident(sessionId, ipAddress, "SYSTEM_ERROR", 
                                       "Processing error: " + e.getMessage(), userQuery);
            
            return ChatResponse.error(errorMessage, sessionId);
        }
    }
    
    @Override
    public DocumentProcessingResponse processDocument(DocumentProcessingRequest request) {
        if (request == null || request.getContent() == null) {
            logger.warn("Invalid document processing request");
            return new DocumentProcessingResponse(false, "unknown", "Ungültige Dokumentenanfrage");
        }
        
        logger.info("Processing document: {}", request.getDocumentId());
        
        try {
            // Simulate document processing
            String content = request.getContent();
            List<String> chunks = chunkDocument(content);
            
            for (int i = 0; i < chunks.size(); i++) {
                String chunk = chunks.get(i);
                // Simulate vector embedding and storage
                logger.debug("Processing chunk {} of document {}", i + 1, request.getDocumentId());
            }
            
            logger.info("Successfully processed document: {}", request.getDocumentId());
            return new DocumentProcessingResponse(true, request.getDocumentId(), "Dokument erfolgreich verarbeitet");
            
        } catch (Exception e) {
            String docId = (request != null && request.getDocumentId() != null) ? request.getDocumentId() : "unknown";
            logger.error("Error processing document: " + docId, e);
            return new DocumentProcessingResponse(false, docId, "Fehler beim Verarbeiten des Dokuments: " + e.getMessage());
        }
    }
    
    @Override
    public List<String> searchDocuments(String query, int maxResults) {
        List<String> documents = new ArrayList<>();
        
        try {
            // Mock relevant documents based on query keywords
            if (query.toLowerCase().contains("aws") || query.toLowerCase().contains("cloud") || 
                query.toLowerCase().contains("wolke") || query.toLowerCase().contains("dienst")) {
                documents.add("AWS Best Practices und Richtlinien für Cloud-Bereitstellung...");
                documents.add("Cloud-Sicherheitsüberlegungen und Empfehlungen...");
            }
            
            if (query.toLowerCase().contains("confluence") || query.toLowerCase().contains("wiki")) {
                documents.add("Confluence Benutzerhandbuch und Verwaltungstipps...");
                documents.add("Wiki-Inhaltsverwaltung und Zusammenarbeitsfunktionen...");
            }
            
            if (documents.isEmpty()) {
                documents.add("Allgemeine Informationen und hilfreiche Ressourcen...");
            }
            
            // Limit results
            if (documents.size() > maxResults) {
                documents = documents.subList(0, maxResults);
            }
            
        } catch (Exception e) {
            logger.error("Error searching documents", e);
            documents.add("Fehler beim Durchsuchen der Dokumente");
        }
        
        return documents;
    }
    
    @Override
    public boolean isHealthy() {
        try {
            // Simple health check
            return config != null && !config.isEmpty();
        } catch (Exception e) {
            logger.error("Health check failed", e);
            return false;
        }
    }
    
    public List<String> getKnowledgeSources() {
        List<String> sources = new ArrayList<>();
        
        // Get from configuration
        String confluenceSites = config.getProperty("confluence.sites", "");
        String websites = config.getProperty("additional.websites", "");
        String s3Bucket = config.getProperty("aws.s3.bucket", "");
        
        if (!confluenceSites.isEmpty()) {
            for (String site : confluenceSites.split("\n")) {
                if (!site.trim().isEmpty()) {
                    sources.add("Confluence: " + site.trim());
                }
            }
        }
        
        if (!websites.isEmpty()) {
            for (String website : websites.split("\n")) {
                if (!website.trim().isEmpty()) {
                    sources.add("Website: " + website.trim());
                }
            }
        }
        
        if (!s3Bucket.isEmpty()) {
            sources.add("S3 Dokumente: " + s3Bucket);
        }
        
        if (sources.isEmpty()) {
            sources.add("Keine Wissensquellen konfiguriert");
        }
        
        return sources;
    }
    
    public void syncContent() {
        logger.info("Starting content synchronization");
        
        try {
            List<String> sources = getKnowledgeSources();
            
            for (String source : sources) {
                logger.info("Syncing content from: {}", source);
                
                if (source.startsWith("Confluence:")) {
                    syncConfluenceContent(source.substring(11).trim());
                } else if (source.startsWith("Website:")) {
                    syncWebsiteContent(source.substring(8).trim());
                } else if (source.startsWith("S3 Documents:")) {
                    syncS3Content(source.substring(13).trim());
                }
            }
            
            logger.info("Content synchronization completed");
            
        } catch (Exception e) {
            logger.error("Error during content synchronization", e);
        }
    }
    
    private String buildContext(List<String> documents) {
        StringBuilder context = new StringBuilder();
        for (int i = 0; i < documents.size() && i < 3; i++) {
            context.append("Dokument ").append(i + 1).append(": ");
            context.append(documents.get(i));
            context.append("\n\n");
        }
        return context.toString();
    }
    
    private String generateSecureResponse(String query, String context) {
        // Generate response with strict security constraints
        StringBuilder response = new StringBuilder();
        
        // Only provide responses based on the knowledge base context
        if (context == null || context.trim().isEmpty()) {
            return "Basierend auf den verfügbaren Informationen in der Wissensdatenbank kann ich diese Frage nicht vollständig beantworten. Bitte stellen Sie sicher, dass Ihre Frage sich auf die konfigurierten Wissensquellen bezieht.";
        }
        
        // Analyze query and context to provide secure, relevant responses
        String normalizedQuery = query.toLowerCase();
        String normalizedContext = context.toLowerCase();
        
        response.append("Basierend auf den verfügbaren Informationen in der Wissensdatenbank:\n\n");
        
        if (normalizedContext.contains("aws") || normalizedContext.contains("cloud")) {
            if (normalizedQuery.contains("konfigur") || normalizedQuery.contains("einricht") || normalizedQuery.contains("setup")) {
                response.append("Für die AWS-Konfiguration finden Sie in der Dokumentation Schritte zur Einrichtung von Services, Sicherheitsrichtlinien und bewährten Praktiken. ");
            }
            if (normalizedQuery.contains("sicherheit") || normalizedQuery.contains("security")) {
                response.append("Die Sicherheitsdokumentation umfasst Empfehlungen für Zugriffskontrollen, Verschlüsselung und Überwachung. ");
            }
        }
        
        if (normalizedContext.contains("confluence") || normalizedContext.contains("wiki")) {
            if (normalizedQuery.contains("verwaltu") || normalizedQuery.contains("admin") || normalizedQuery.contains("konfigur")) {
                response.append("Die Confluence-Verwaltungsdokumentation bietet Anleitungen für Benutzerverwaltung, Berechtigungen und Systemkonfiguration. ");
            }
            if (normalizedQuery.contains("inhalt") || normalizedQuery.contains("content") || normalizedQuery.contains("seite")) {
                response.append("Für die Inhaltsverwaltung stehen Handbücher zur Seitenerstellung, Zusammenarbeit und Organisationsstrukturen zur Verfügung. ");
            }
        }
        
        // Ensure the response is grounded in the knowledge base
        if (response.length() < 100) {
            response.append("Die spezifischen Informationen zu Ihrer Frage sind in den verfügbaren Dokumenten enthalten. ");
        }
        
        response.append("\n\nFalls Sie detailliertere Informationen benötigen, präzisieren Sie bitte Ihre Frage bezüglich der spezifischen Aspekte aus der Wissensdatenbank.");
        
        return response.toString();
    }
    
    private List<String> chunkDocument(String content) {
        List<String> chunks = new ArrayList<>();
        
        // Simple chunking by paragraphs or fixed size
        String[] paragraphs = content.split("\n\n");
        
        for (String paragraph : paragraphs) {
            if (paragraph.trim().length() > 50) { // Only meaningful chunks
                if (paragraph.length() > 1000) {
                    // Split large paragraphs
                    int start = 0;
                    while (start < paragraph.length()) {
                        int end = Math.min(start + 800, paragraph.length());
                        chunks.add(paragraph.substring(start, end));
                        start = end - 100; // Overlap for context
                    }
                } else {
                    chunks.add(paragraph.trim());
                }
            }
        }
        
        return chunks;
    }
    
    private void syncConfluenceContent(String confluenceUrl) {
        logger.info("Syncing Confluence content from: {}", confluenceUrl);
        // Simulate Confluence API calls and content extraction
    }
    
    private void syncWebsiteContent(String websiteUrl) {
        logger.info("Syncing website content from: {}", websiteUrl);
        // Simulate web scraping and content extraction
    }
    
    private void syncS3Content(String s3Bucket) {
        logger.info("Syncing S3 content from bucket: {}", s3Bucket);
        // Simulate S3 document processing
    }
    
    /**
     * Konfiguriert S3-Logging-Einstellungen
     */
    public void configureS3Logging(String bucketName, String region, String accessKey, String secretKey) {
        s3Logger.configureBucket(bucketName, region, accessKey, secretKey);
        s3Logger.logSystemEvent("S3_CONFIG_UPDATED", 
                               "S3 logging configured with bucket: " + bucketName + " in region: " + region, 
                               null);
        logger.info("S3 logging configured: bucket={}, region={}", bucketName, region);
    }
    
    /**
     * Aktiviert/deaktiviert S3-Logging
     */
    public void setS3LoggingEnabled(boolean enabled) {
        s3Logger.setLoggingEnabled(enabled);
        logger.info("S3 logging {}", enabled ? "enabled" : "disabled");
    }
    
    /**
     * Gibt S3-Logging-Statistiken zurück
     */
    public S3Logger.LoggingStats getS3LoggingStats() {
        return s3Logger.getLoggingStats();
    }
    
    /**
     * Testet die S3-Verbindung
     */
    public boolean testS3Connection() {
        try {
            s3Logger.logSystemEvent("CONNECTION_TEST", "Testing S3 connection", null);
            return true;
        } catch (Exception e) {
            logger.error("S3 connection test failed", e);
            return false;
        }
    }
    
    /**
     * Beendet den Service ordnungsgemäß und schließt alle Logger
     */
    public void shutdown() {
        logger.info("Shutting down RagServiceSimple");
        s3Logger.shutdown();
    }
}
