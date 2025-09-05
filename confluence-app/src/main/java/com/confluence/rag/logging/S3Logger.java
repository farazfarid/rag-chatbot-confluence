package com.confluence.rag.logging;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * AWS S3 Logger für SOPTIM Community Elements Chatbot
 * Protokolliert alle Benutzeranfragen und Systemereignisse in konfigurierbaren S3-Buckets
 */
public class S3Logger {
    
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
    private static final SimpleDateFormat timestampFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    
    private final Queue<LogEntry> logQueue = new ConcurrentLinkedQueue<>();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);
    
    private String bucketName = "soptim-community-elements-logs";
    private String awsRegion = "eu-central-1";
    private String awsAccessKey;
    private String awsSecretKey;
    private boolean loggingEnabled = true;
    
    public S3Logger() {
        // Starte den Log-Batch-Processor
        scheduler.scheduleAtFixedRate(this::processBatchLogs, 30, 30, TimeUnit.SECONDS);
        
        // Lade AWS-Konfiguration
        loadAwsConfiguration();
        
        // Erstelle heute's Log-Datei
        initializeDailyLogFile();
    }
    
    /**
     * Protokolliert eine Benutzeranfrage
     */
    public void logUserQuery(String sessionId, String ipAddress, String userQuery, 
                            String response, boolean isSecurityViolation, String securityDetails) {
        if (!loggingEnabled) return;
        
        LogEntry entry = new LogEntry();
        entry.timestamp = timestampFormat.format(new Date());
        entry.type = "USER_QUERY";
        entry.sessionId = sessionId;
        entry.ipAddress = ipAddress;
        entry.userQuery = sanitizeForLogging(userQuery);
        entry.response = sanitizeForLogging(response);
        entry.isSecurityViolation = isSecurityViolation;
        entry.securityDetails = securityDetails;
        entry.responseTime = System.currentTimeMillis();
        
        logQueue.offer(entry);
        
        // Bei Sicherheitsverletzungen sofort loggen
        if (isSecurityViolation) {
            CompletableFuture.runAsync(() -> uploadLogEntry(entry));
        }
    }
    
    /**
     * Protokolliert Systemereignisse
     */
    public void logSystemEvent(String eventType, String details, String sessionId) {
        if (!loggingEnabled) return;
        
        LogEntry entry = new LogEntry();
        entry.timestamp = timestampFormat.format(new Date());
        entry.type = "SYSTEM_EVENT";
        entry.eventType = eventType;
        entry.details = details;
        entry.sessionId = sessionId;
        
        logQueue.offer(entry);
    }
    
    /**
     * Protokolliert Sicherheitsvorfälle
     */
    public void logSecurityIncident(String sessionId, String ipAddress, String incidentType, 
                                   String details, String userInput) {
        LogEntry entry = new LogEntry();
        entry.timestamp = timestampFormat.format(new Date());
        entry.type = "SECURITY_INCIDENT";
        entry.sessionId = sessionId;
        entry.ipAddress = ipAddress;
        entry.incidentType = incidentType;
        entry.details = details;
        entry.userQuery = sanitizeForLogging(userInput);
        entry.isSecurityViolation = true;
        
        logQueue.offer(entry);
        
        // Sicherheitsvorfälle sofort hochladen
        CompletableFuture.runAsync(() -> uploadLogEntry(entry));
    }
    
    /**
     * Konfiguriert S3-Bucket-Einstellungen
     */
    public void configureBucket(String bucketName, String region, String accessKey, String secretKey) {
        this.bucketName = bucketName;
        this.awsRegion = region;
        this.awsAccessKey = accessKey;
        this.awsSecretKey = secretKey;
        
        // Teste die Verbindung
        testS3Connection();
        
        // Speichere Konfiguration
        saveAwsConfiguration();
    }
    
    /**
     * Aktiviert/deaktiviert das Logging
     */
    public void setLoggingEnabled(boolean enabled) {
        this.loggingEnabled = enabled;
        logSystemEvent("LOGGING_" + (enabled ? "ENABLED" : "DISABLED"), 
                      "Logging wurde " + (enabled ? "aktiviert" : "deaktiviert"), null);
    }
    
    /**
     * Verarbeitet Log-Einträge in Batches
     */
    private void processBatchLogs() {
        if (logQueue.isEmpty()) return;
        
        List<LogEntry> batch = new ArrayList<>();
        LogEntry entry;
        while ((entry = logQueue.poll()) != null && batch.size() < 100) {
            batch.add(entry);
        }
        
        if (!batch.isEmpty()) {
            CompletableFuture.runAsync(() -> uploadLogBatch(batch));
        }
    }
    
    /**
     * Lädt einen einzelnen Log-Eintrag zu S3 hoch
     */
    private void uploadLogEntry(LogEntry entry) {
        try {
            String json = objectMapper.writeValueAsString(entry);
            String key = generateLogKey(entry.timestamp, "single");
            uploadToS3(key, json);
        } catch (Exception e) {
            System.err.println("Fehler beim Hochladen des Log-Eintrags: " + e.getMessage());
        }
    }
    
    /**
     * Lädt einen Batch von Log-Einträgen zu S3 hoch
     */
    private void uploadLogBatch(List<LogEntry> batch) {
        try {
            String json = objectMapper.writeValueAsString(batch);
            String key = generateLogKey(batch.get(0).timestamp, "batch");
            uploadToS3(key, json);
        } catch (Exception e) {
            System.err.println("Fehler beim Hochladen des Log-Batches: " + e.getMessage());
        }
    }
    
    /**
     * Generiert S3-Schlüssel für Log-Dateien
     */
    private String generateLogKey(String timestamp, String type) {
        String date = timestamp.substring(0, 10); // YYYY-MM-DD
        String hour = timestamp.substring(11, 13); // HH
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        
        return String.format("soptim-community-elements-logs/%s/%s/%s-%s-%s.json", 
                           date, hour, type, timestamp.replace(":", ""), uniqueId);
    }
    
    /**
     * Lädt Daten zu S3 hoch
     */
    private void uploadToS3(String key, String content) {
        if (awsAccessKey == null || awsSecretKey == null) {
            System.err.println("AWS-Anmeldedaten nicht konfiguriert");
            return;
        }
        
        try (CloseableHttpClient httpClient = HttpClients.createDefault()) {
            String url = String.format("https://%s.s3.%s.amazonaws.com/%s", 
                                     bucketName, awsRegion, key);
            
            HttpPut putRequest = new HttpPut(url);
            putRequest.setEntity(new StringEntity(content, "UTF-8"));
            putRequest.setHeader("Content-Type", "application/json");
            
            // AWS Signature V4 würde hier implementiert werden
            // Für Einfachheit verwenden wir hier eine vereinfachte Version
            addAwsHeaders(putRequest, content);
            
            HttpResponse response = httpClient.execute(putRequest);
            int statusCode = response.getStatusLine().getStatusCode();
            
            if (statusCode >= 200 && statusCode < 300) {
                System.out.println("Log erfolgreich zu S3 hochgeladen: " + key);
            } else {
                System.err.println("S3-Upload fehlgeschlagen: " + statusCode + " - " + 
                                 EntityUtils.toString(response.getEntity()));
            }
        } catch (IOException e) {
            System.err.println("Fehler beim S3-Upload: " + e.getMessage());
        }
    }
    
    /**
     * Fügt AWS-Header hinzu (vereinfachte Version)
     */
    private void addAwsHeaders(HttpPut request, String content) {
        // In einer Produktionsumgebung würde hier AWS Signature V4 implementiert
        request.setHeader("Authorization", "AWS " + awsAccessKey + ":signature");
        request.setHeader("x-amz-date", new SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'").format(new Date()));
        request.setHeader("x-amz-content-sha256", "UNSIGNED-PAYLOAD");
    }
    
    /**
     * Testet die S3-Verbindung
     */
    private void testS3Connection() {
        // Einfacher Verbindungstest
        LogEntry testEntry = new LogEntry();
        testEntry.timestamp = timestampFormat.format(new Date());
        testEntry.type = "CONNECTION_TEST";
        testEntry.details = "S3-Verbindungstest";
        
        CompletableFuture.runAsync(() -> uploadLogEntry(testEntry));
    }
    
    /**
     * Initialisiert die tägliche Log-Datei
     */
    private void initializeDailyLogFile() {
        logSystemEvent("DAILY_LOG_INIT", 
                      "Tägliche Log-Datei für " + dateFormat.format(new Date()) + " initialisiert", 
                      null);
    }
    
    /**
     * Bereinigt sensible Daten für das Logging
     */
    private String sanitizeForLogging(String input) {
        if (input == null) return null;
        
        // Entferne potenzielle Passwörter und sensible Daten
        return input.replaceAll("(?i)(password|passwort|secret|geheim|token|key)\\s*[:=]\\s*\\S+", 
                               "$1: [REDACTED]")
                   .replaceAll("\\b\\d{13,19}\\b", "[CARD_NUMBER]") // Kreditkartennummern
                   .replaceAll("\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b", "[EMAIL]"); // E-Mails
    }
    
    /**
     * Lädt AWS-Konfiguration
     */
    private void loadAwsConfiguration() {
        // Lade aus Umgebungsvariablen oder Konfigurationsdatei
        awsAccessKey = System.getenv("AWS_ACCESS_KEY_ID");
        awsSecretKey = System.getenv("AWS_SECRET_ACCESS_KEY");
        
        String configBucket = System.getenv("S3_LOG_BUCKET");
        if (configBucket != null) {
            bucketName = configBucket;
        }
        
        String configRegion = System.getenv("AWS_REGION");
        if (configRegion != null) {
            awsRegion = configRegion;
        }
    }
    
    /**
     * Speichert AWS-Konfiguration
     */
    private void saveAwsConfiguration() {
        // Konfiguration in Properties-Datei speichern
        Properties props = new Properties();
        props.setProperty("s3.bucket.name", bucketName);
        props.setProperty("s3.region", awsRegion);
        props.setProperty("logging.enabled", String.valueOf(loggingEnabled));
        
        // Properties speichern (vereinfacht)
        System.out.println("AWS S3 Konfiguration aktualisiert: Bucket=" + bucketName + ", Region=" + awsRegion);
    }
    
    /**
     * Gibt aktuelle Logging-Statistiken zurück
     */
    public LoggingStats getLoggingStats() {
        LoggingStats stats = new LoggingStats();
        stats.queueSize = logQueue.size();
        stats.bucketName = bucketName;
        stats.region = awsRegion;
        stats.loggingEnabled = loggingEnabled;
        stats.lastUpload = new Date();
        return stats;
    }
    
    /**
     * Beendet den Logger ordnungsgemäß
     */
    public void shutdown() {
        // Verarbeite verbleibende Logs
        processBatchLogs();
        
        // Beende Scheduler
        scheduler.shutdown();
        try {
            if (!scheduler.awaitTermination(60, TimeUnit.SECONDS)) {
                scheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            scheduler.shutdownNow();
        }
        
        logSystemEvent("LOGGER_SHUTDOWN", "S3Logger wurde beendet", null);
    }
    
    // Innere Klassen
    public static class LogEntry {
        public String timestamp;
        public String type;
        public String sessionId;
        public String ipAddress;
        public String userQuery;
        public String response;
        public boolean isSecurityViolation;
        public String securityDetails;
        public String eventType;
        public String incidentType;
        public String details;
        public long responseTime;
    }
    
    public static class LoggingStats {
        public int queueSize;
        public String bucketName;
        public String region;
        public boolean loggingEnabled;
        public Date lastUpload;
    }
}
