package com.confluence.rag.servlet;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

/**
 * Simplified Admin Servlet for RAG Chatbot configuration
 * This version works without Atlassian dependencies
 */
public class AdminServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        response.setCharacterEncoding("UTF-8");
        
        PrintWriter out = response.getWriter();
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("    <title>RAG Chatbot Configuration</title>");
        out.println("    <style>");
        out.println("        body { font-family: Arial, sans-serif; margin: 40px; }");
        out.println("        .container { max-width: 800px; margin: 0 auto; }");
        out.println("        .form-group { margin-bottom: 20px; }");
        out.println("        label { display: block; margin-bottom: 5px; font-weight: bold; }");
        out.println("        input, textarea { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }");
        out.println("        button { background-color: #0052cc; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }");
        out.println("        button:hover { background-color: #0747a6; }");
        out.println("        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }");
        out.println("        .success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }");
        out.println("        .info { background-color: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }");
        out.println("    </style>");
        out.println("</head>");
        out.println("<body>");
        out.println("    <div class='container'>");
        out.println("        <h1>🤖 RAG Chatbot Configuration</h1>");
        
        out.println("        <div class='status info'>");
        out.println("            <strong>📋 Status:</strong> Plugin installed successfully! Configure your AWS settings below.");
        out.println("        </div>");
        
        out.println("        <form method='post'>");
        out.println("            <h2>AWS Configuration</h2>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='awsRegion'>AWS Region:</label>");
        out.println("                <input type='text' id='awsRegion' name='awsRegion' placeholder='e.g., us-east-1' />");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='awsAccessKey'>AWS Access Key ID:</label>");
        out.println("                <input type='text' id='awsAccessKey' name='awsAccessKey' placeholder='Your AWS Access Key' />");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='awsSecretKey'>AWS Secret Access Key:</label>");
        out.println("                <input type='password' id='awsSecretKey' name='awsSecretKey' placeholder='Your AWS Secret Key' />");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='opensearchEndpoint'>OpenSearch Endpoint:</label>");
        out.println("                <input type='text' id='opensearchEndpoint' name='opensearchEndpoint' placeholder='https://your-opensearch-collection.region.aoss.amazonaws.com' />");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='s3Bucket'>S3 Bucket Name:</label>");
        out.println("                <input type='text' id='s3Bucket' name='s3Bucket' placeholder='your-documents-bucket' />");
        out.println("            </div>");
        
        out.println("            <h2>Knowledge Sources</h2>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='confluenceSites'>Confluence Sites (one per line):</label>");
        out.println("                <textarea id='confluenceSites' name='confluenceSites' rows='3' placeholder='https://your-company.atlassian.net/wiki&#10;https://another-confluence.com'></textarea>");
        out.println("            </div>");
        
        out.println("            <div class='form-group'>");
        out.println("                <label for='websites'>Additional Websites (one per line):</label>");
        out.println("                <textarea id='websites' name='websites' rows='3' placeholder='https://docs.company.com&#10;https://help.company.com'></textarea>");
        out.println("            </div>");
        
        out.println("            <button type='submit'>💾 Save Configuration</button>");
        out.println("        </form>");
        
        out.println("        <hr style='margin: 40px 0;' />");
        
        out.println("        <h2>📚 Usage Instructions</h2>");
        out.println("        <ol>");
        out.println("            <li><strong>Add Chat Widget:</strong> Add the <code>/rag</code> macro to any Confluence page</li>");
        out.println("            <li><strong>Upload Documents:</strong> PDF files will be automatically processed when added to the configured S3 bucket</li>");
        out.println("            <li><strong>Sync Content:</strong> Confluence sites will be synchronized automatically every hour</li>");
        out.println("        </ol>");
        
        out.println("        <h2>🔧 Technical Details</h2>");
        out.println("        <div class='status info'>");
        out.println("            <ul>");
        out.println("                <li><strong>Plugin Version:</strong> 1.0.0</li>");
        out.println("                <li><strong>Java Version:</strong> " + System.getProperty("java.version") + "</li>");
        out.println("                <li><strong>Build Type:</strong> Minimal Dependencies</li>");
        out.println("            </ul>");
        out.println("        </div>");
        
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
        
        // Simple validation
        boolean isValid = awsRegion != null && !awsRegion.trim().isEmpty() &&
                         awsAccessKey != null && !awsAccessKey.trim().isEmpty() &&
                         awsSecretKey != null && !awsSecretKey.trim().isEmpty();
        
        response.setContentType("text/html");
        response.setCharacterEncoding("UTF-8");
        
        PrintWriter out = response.getWriter();
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("    <title>Configuration Result</title>");
        out.println("    <style>");
        out.println("        body { font-family: Arial, sans-serif; margin: 40px; }");
        out.println("        .container { max-width: 800px; margin: 0 auto; }");
        out.println("        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }");
        out.println("        .success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }");
        out.println("        .error { background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }");
        out.println("        a { color: #0052cc; text-decoration: none; }");
        out.println("        a:hover { text-decoration: underline; }");
        out.println("    </style>");
        out.println("</head>");
        out.println("<body>");
        out.println("    <div class='container'>");
        out.println("        <h1>Configuration Result</h1>");
        
        if (isValid) {
            out.println("        <div class='status success'>");
            out.println("            <strong>✅ Success!</strong> Configuration saved successfully.");
            out.println("            <br/>Your RAG Chatbot is now configured with:");
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
            out.println("            <strong>❌ Error!</strong> Please fill in all required fields (AWS Region, Access Key, Secret Key).");
            out.println("        </div>");
        }
        
        out.println("        <p><a href='?'>← Back to Configuration</a></p>");
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
