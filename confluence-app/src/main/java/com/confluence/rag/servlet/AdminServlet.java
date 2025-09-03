package com.confluence.rag.servlet;

import com.confluence.rag.service.RagService;
import com.atlassian.templaterenderer.velocity.one.six.VelocityTemplateRenderer;
import com.atlassian.sal.api.user.UserManager;
import com.atlassian.sal.api.auth.LoginUriProvider;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletException;
import javax.inject.Inject;

import java.io.IOException;
import java.net.URI;
import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Admin servlet for RAG Chatbot configuration
 */
public class AdminServlet extends HttpServlet {
    
    private static final Logger LOG = LoggerFactory.getLogger(AdminServlet.class);
    
    private final VelocityTemplateRenderer templateRenderer;
    private final UserManager userManager;
    private final LoginUriProvider loginUriProvider;
    private final RagService ragService;
    
    @Inject
    public AdminServlet(VelocityTemplateRenderer templateRenderer,
                       UserManager userManager,
                       LoginUriProvider loginUriProvider,
                       RagService ragService) {
        this.templateRenderer = templateRenderer;
        this.userManager = userManager;
        this.loginUriProvider = loginUriProvider;
        this.ragService = ragService;
    }
    
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        
        String username = userManager.getRemoteUsername(req);
        if (username == null || !userManager.isSystemAdmin(username)) {
            redirectToLogin(req, resp);
            return;
        }
        
        Map<String, Object> context = new HashMap<>();
        
        // Load current configuration
        context.put("awsRegion", ragService.getConfigValue("aws.region"));
        context.put("awsAccessKey", ragService.getConfigValue("aws.access.key.id"));
        context.put("bedrockModel", ragService.getConfigValue("aws.bedrock.model"));
        context.put("opensearchEndpoint", ragService.getConfigValue("aws.opensearch.endpoint"));
        context.put("s3Bucket", ragService.getConfigValue("aws.s3.bucket"));
        context.put("apiGatewayUrl", ragService.getConfigValue("aws.api.gateway.url"));
        
        // Service status
        context.put("serviceHealthy", ragService.isHealthy());
        
        resp.setContentType("text/html;charset=utf-8");
        templateRenderer.render("/templates/admin.vm", context, resp.getWriter());
    }
    
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) 
            throws ServletException, IOException {
        
        String username = userManager.getRemoteUsername(req);
        if (username == null || !userManager.isSystemAdmin(username)) {
            redirectToLogin(req, resp);
            return;
        }
        
        try {
            // Save configuration
            ragService.setConfigValue("aws.region", req.getParameter("awsRegion"));
            ragService.setConfigValue("aws.access.key.id", req.getParameter("awsAccessKey"));
            ragService.setConfigValue("aws.secret.access.key", req.getParameter("awsSecretKey"));
            ragService.setConfigValue("aws.bedrock.model", req.getParameter("bedrockModel"));
            ragService.setConfigValue("aws.opensearch.endpoint", req.getParameter("opensearchEndpoint"));
            ragService.setConfigValue("aws.s3.bucket", req.getParameter("s3Bucket"));
            ragService.setConfigValue("aws.api.gateway.url", req.getParameter("apiGatewayUrl"));
            
            // Redirect with success message
            resp.sendRedirect(req.getRequestURI() + "?saved=true");
            
        } catch (Exception e) {
            LOG.error("Error saving configuration", e);
            resp.sendRedirect(req.getRequestURI() + "?error=" + e.getMessage());
        }
    }
    
    private void redirectToLogin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.sendRedirect(loginUriProvider.getLoginUri(getUri(req)).toASCIIString());
    }
    
    private URI getUri(HttpServletRequest req) {
        StringBuffer builder = req.getRequestURL();
        if (req.getQueryString() != null) {
            builder.append("?");
            builder.append(req.getQueryString());
        }
        return URI.create(builder.toString());
    }
}
