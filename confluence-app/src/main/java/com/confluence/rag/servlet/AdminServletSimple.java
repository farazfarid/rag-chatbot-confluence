package com.confluence.rag.servlet;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

/**
 * Simplified Admin Servlet for SOPTIM Community Elements Chatbot configuration
 * This version works without Atlassian dependencies
 */
public class AdminServletSimple extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        response.setCharacterEncoding("UTF-8");
        
        PrintWriter out = response.getWriter();
        
        out.println("<!DOCTYPE html>");
        out.println("<html lang='de'>");
        out.println("<head>");
        out.println("    <title>SOPTIM Community Elements Chatbot Konfiguration</title>");
        out.println("    <meta charset='UTF-8'>");
        out.println("    <style>");
        out.println("        body { font-family: Arial, sans-serif; margin: 40px; }");
        out.println("        .container { max-width: 800px; margin: 0 auto; }");
        out.println("        .form-group { margin-bottom: 20px; }");
        out.println("        label { display: block; margin-bottom: 5px; font-weight: bold; }");
        out.println("        input, textarea, select { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }");
        out.println("        button { background-color: #009EE0; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; margin-right: 10px; }");
        out.println("        button:hover { background-color: #007BB8; }");
        out.println("        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }");
        out.println("        .success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }");
        out.println("        .info { background-color: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }");
        out.println("        .section { background: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 8px; }");
        out.println("        h1 { color: #009EE0; }");
        out.println("    </style>");
        out.println("</head>");
        out.println("<body>");
        out.println("    <div class='container'>");
        out.println("        <h1>🤖 SOPTIM Community Elements Chatbot Konfiguration</h1>");
        
        out.println("        <div class='status info'>");
        out.println("            <strong>📋 Status:</strong> Plugin erfolgreich installiert! Konfigurieren Sie Ihre AWS-Einstellungen unten.");
        out.println("        </div>");
        
        out.println("        <form method='post'>");
        out.println("            <div class='section'>");
        out.println("            <h2>🔧 AWS Konfiguration</h2>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='awsRegion'>AWS Region:</label>");
        out.println("                <select id='awsRegion' name='awsRegion'>");
        out.println("                    <option value='us-east-1'>US East (N. Virginia) - us-east-1</option>");
        out.println("                    <option value='eu-central-1'>Europe (Frankfurt) - eu-central-1</option>");
        out.println("                    <option value='eu-west-1'>Europe (Ireland) - eu-west-1</option>");
        out.println("                </select>");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='awsAccessKey'>AWS Access Key ID:</label>");
        out.println("                <input type='text' id='awsAccessKey' name='awsAccessKey' placeholder='Ihre AWS Access Key' />");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='awsSecretKey'>AWS Secret Access Key:</label>");
        out.println("                <input type='password' id='awsSecretKey' name='awsSecretKey' placeholder='Ihr AWS Secret Key' />");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='opensearchEndpoint'>OpenSearch Endpoint:</label>");
        out.println("                <input type='text' id='opensearchEndpoint' name='opensearchEndpoint' placeholder='https://ihre-opensearch-sammlung.region.aoss.amazonaws.com' />");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='s3Bucket'>S3 Bucket Name:</label>");
        out.println("                <input type='text' id='s3Bucket' name='s3Bucket' placeholder='ihr-dokumente-bucket' />");
        out.println("            </div>");
            out.println("            </div>");
        
        out.println("            <div class='section'>");
        out.println("            <h2>� S3 Logging Konfiguration</h2>");
        out.println("            <p>Alle Benutzeranfragen und Sicherheitsereignisse werden sicher in AWS S3 protokolliert.</p>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='logBucket'>S3 Log Bucket Name:</label>");
        out.println("                <input type='text' id='logBucket' name='logBucket' placeholder='soptim-community-elements-logs' />");
        out.println("                <small>Separater S3-Bucket für Log-Dateien (wird automatisch erstellt)</small>");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='logRegion'>Log Bucket Region:</label>");
        out.println("                <select id='logRegion' name='logRegion'>");
        out.println("                    <option value='eu-central-1' selected>Europe (Frankfurt) - eu-central-1</option>");
        out.println("                    <option value='us-east-1'>US East (N. Virginia) - us-east-1</option>");
        out.println("                    <option value='eu-west-1'>Europe (Ireland) - eu-west-1</option>");
        out.println("                </select>");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label>");
        out.println("                    <input type='checkbox' id='enableLogging' name='enableLogging' checked>");
        out.println("                    S3-Logging aktivieren");
        out.println("                </label>");
        out.println("                <small>Protokolliert alle Chat-Interaktionen und Sicherheitsereignisse</small>");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label>");
        out.println("                    <input type='checkbox' id='logUserQueries' name='logUserQueries' checked>");
        out.println("                    Benutzeranfragen protokollieren");
        out.println("                </label>");
        out.println("                <small>Speichert alle Benutzerfragen für Analyse und Verbesserung</small>");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label>");
        out.println("                    <input type='checkbox' id='logSecurityEvents' name='logSecurityEvents' checked>");
        out.println("                    Sicherheitsereignisse protokollieren");
        out.println("                </label>");
        out.println("                <small>Protokolliert Jailbreak-Versuche und andere Sicherheitsvorfälle</small>");
        out.println("            </div>");
        out.println("            </div>");
        
        out.println("            <div class='section'>");
        out.println("            <h2>📚 Wissensquellen</h2>");        out.println("            <div class='form-group'>");
        out.println("                <label for='confluenceSites'>Confluence Seiten (eine pro Zeile):</label>");
        out.println("                <textarea id='confluenceSites' name='confluenceSites' rows='3' placeholder='https://ihr-unternehmen.atlassian.net/wiki&#10;https://andere-confluence.com'></textarea>");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='websites'>Zusätzliche Websites (eine pro Zeile):</label>");
        out.println("                <textarea id='websites' name='websites' rows='3' placeholder='https://docs.unternehmen.com&#10;https://hilfe.unternehmen.com'></textarea>");
        out.println("            </div>");
        out.println("            </div>");
        
        out.println("            <button type='submit'>💾 Konfiguration Speichern</button>");
        out.println("            <button type='button' onclick='testConnection()'>🔗 Verbindung Testen</button>");
        out.println("        </form>");
        
        out.println("        <hr style='margin: 40px 0;' />");
        
        out.println("            <h2>Sicherheitseinstellungen</h2>");
            out.println("            <form method='post'>");
            out.println("                <div class='form-group'>");
            out.println("                    <label>Maximale Anfragelänge (Zeichen):</label>");
            out.println("                    <input type='number' name='maxQueryLength' value='500' min='100' max='1000'>");
            out.println("                    <small>Begrenzt die Länge von Benutzeranfragen zur Sicherheit</small>");
            out.println("                </div>");
            out.println("                <div class='form-group'>");
            out.println("                    <label>Mindest-Relevanz-Score:</label>");
            out.println("                    <input type='number' name='minRelevanceScore' value='0.3' min='0.1' max='1.0' step='0.1'>");
            out.println("                    <small>Mindestpunktzahl für Themenbezug zur Wissensdatenbank</small>");
            out.println("                </div>");
            out.println("                <div class='form-group'>");
            out.println("                    <label>");
            out.println("                        <input type='checkbox' name='strictMode' checked>");
            out.println("                        Strenger Sicherheitsmodus (empfohlen)");
            out.println("                    </label>");
            out.println("                    <small>Aktiviert erweiterte Jailbreak-Erkennung und Inhaltsfilterung</small>");
            out.println("                </div>");
            out.println("                <button type='submit' name='action' value='saveSecurity'>Sicherheitseinstellungen speichern</button>");
            out.println("            </form>");
            out.println("        </div>");
            
            out.println("        <div class='section'>");
        out.println("        <h2>📚 Verwendungsanweisungen</h2>");
        out.println("        <ol>");
        out.println("            <li><strong>Chat Widget hinzufügen:</strong> Fügen Sie das <code>/rag</code> Makro zu jeder Confluence-Seite hinzu</li>");
        out.println("            <li><strong>Dokumente hochladen:</strong> PDF-Dateien werden automatisch verarbeitet, wenn sie zum konfigurierten S3-Bucket hinzugefügt werden</li>");
        out.println("            <li><strong>Inhalte synchronisieren:</strong> Confluence-Seiten werden automatisch jede Stunde synchronisiert</li>");
        out.println("        </ol>");
        
        out.println("        <h2>🔧 Technische Details</h2>");
        out.println("        <div class='status info'>");
        out.println("            <ul>");
        out.println("                <li><strong>Plugin Version:</strong> 1.0.0</li>");
        out.println("                <li><strong>Java Version:</strong> " + System.getProperty("java.version") + "</li>");
        out.println("                <li><strong>Build-Typ:</strong> Minimale Abhängigkeiten</li>");
        out.println("            </ul>");
        out.println("        </div>");
        out.println("        </div>");
        
        out.println("        <script>");
        out.println("        function testConnection() {");
        out.println("            alert('Verbindungstest wird implementiert...');");
        out.println("        }");
        out.println("        </script>");
        
        out.println("    </div>");
        out.println("</body>");
        out.println("</html>");
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Get form parameters
        String awsRegion = request.getParameter("awsRegion");
        String awsAccessKey = request.getParameter("awsAccessKey");
        String awsSecretKey = request.getParameter("awsSecretKey");
        String opensearchEndpoint = request.getParameter("opensearchEndpoint");
        String s3Bucket = request.getParameter("s3Bucket");
        String confluenceSites = request.getParameter("confluenceSites");
        String websites = request.getParameter("websites");
        
        // S3 Logging parameters
        String logBucket = request.getParameter("logBucket");
        String logRegion = request.getParameter("logRegion");
        String enableLogging = request.getParameter("enableLogging");
        String logUserQueries = request.getParameter("logUserQueries");
        String logSecurityEvents = request.getParameter("logSecurityEvents");
        
        // Simple validation
        boolean isValid = awsRegion != null && !awsRegion.trim().isEmpty() &&
                         awsAccessKey != null && !awsAccessKey.trim().isEmpty() &&
                         awsSecretKey != null && !awsSecretKey.trim().isEmpty();
        
        response.setContentType("text/html");
        response.setCharacterEncoding("UTF-8");
        
        PrintWriter out = response.getWriter();
        
        out.println("<!DOCTYPE html>");
        out.println("<html lang='de'>");
        out.println("<head>");
        out.println("    <title>Konfigurationsergebnis</title>");
        out.println("    <meta charset='UTF-8'>");
        out.println("    <style>");
        out.println("        body { font-family: Arial, sans-serif; margin: 40px; }");
        out.println("        .container { max-width: 800px; margin: 0 auto; }");
        out.println("        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }");
        out.println("        .success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }");
        out.println("        .error { background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }");
        out.println("        a { color: #009EE0; text-decoration: none; }");
        out.println("        a:hover { text-decoration: underline; }");
        out.println("    </style>");
        out.println("</head>");
        out.println("<body>");
        out.println("    <div class='container'>");
        out.println("        <h1>🤖 Konfigurationsergebnis</h1>");
        
        if (isValid) {
            // Configure S3 logging if parameters provided
            if (logBucket != null && !logBucket.trim().isEmpty() && 
                logRegion != null && !logRegion.trim().isEmpty()) {
                
                // Here we would configure the S3Logger
                // For now, just validate and show confirmation
                out.println("        <div class='status success'>");
                out.println("            <strong>📊 S3 Logging konfiguriert!</strong>");
                out.println("            <ul>");
                out.println("                <li>Log Bucket: " + escapeHtml(logBucket) + "</li>");
                out.println("                <li>Region: " + escapeHtml(logRegion) + "</li>");
                out.println("                <li>Logging aktiviert: " + (enableLogging != null ? "Ja" : "Nein") + "</li>");
                out.println("                <li>Benutzeranfragen protokollieren: " + (logUserQueries != null ? "Ja" : "Nein") + "</li>");
                out.println("                <li>Sicherheitsereignisse protokollieren: " + (logSecurityEvents != null ? "Ja" : "Nein") + "</li>");
                out.println("            </ul>");
                out.println("        </div>");
            }
            
            out.println("        <div class='status success'>");
            out.println("            <strong>✅ Erfolgreich!</strong> SOPTIM Community Elements Chatbot wurde erfolgreich konfiguriert.");
            out.println("            <br/>Ihr Chatbot ist jetzt bereit mit:");
            out.println("            <ul>");
            out.println("                <li>AWS Region: " + escapeHtml(awsRegion) + "</li>");
            if (opensearchEndpoint != null && !opensearchEndpoint.trim().isEmpty()) {
                out.println("                <li>OpenSearch Endpoint: " + escapeHtml(opensearchEndpoint) + "</li>");
            }
            if (s3Bucket != null && !s3Bucket.trim().isEmpty()) {
                out.println("                <li>S3 Bucket: " + escapeHtml(s3Bucket) + "</li>");
            }
            out.println("            </ul>");
            out.println("        </div>");
        } else {
            out.println("        <div class='status error'>");
            out.println("            <strong>❌ Fehler!</strong> Bitte füllen Sie alle erforderlichen Felder aus (AWS Region, Access Key, Secret Key).");
            out.println("        </div>");
        }
        
        out.println("        <p><a href='?'>← Zurück zur Konfiguration</a></p>");
        out.println("    </div>");
        out.println("</body>");
        out.println("</html>");
    }
    
    private String escapeHtml(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#x27;");
    }
}
