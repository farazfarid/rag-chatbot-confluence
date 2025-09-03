package com.confluence.rag.rest;

import com.confluence.rag.api.RagServiceInterface;
import com.confluence.rag.model.ChatRequest;
import com.confluence.rag.model.ChatResponse;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * REST API for RAG Chatbot operations
 */
@Path("/")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class RagRestResource {
    
    private static final Logger LOG = LoggerFactory.getLogger(RagRestResource.class);
    
    private final RagServiceInterface ragService;
    
    @Inject
    public RagRestResource(RagServiceInterface ragService) {
        this.ragService = ragService;
    }
    
    /**
     * Process chat request
     */
    @POST
    @Path("/chat")
    public Response chat(ChatRequest request) {
        try {
            LOG.info("Received chat request from user: {}", request.getUserId());
            
            ChatResponse response = ragService.processChat(request);
            
            if (response.getError() != null) {
                return Response.status(Response.Status.BAD_REQUEST).entity(response).build();
            }
            
            return Response.ok(response).build();
            
        } catch (Exception e) {
            LOG.error("Error processing chat request", e);
            ChatResponse errorResponse = ChatResponse.error("Internal server error", 
                request != null ? request.getSessionId() : null);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(errorResponse).build();
        }
    }
    
    /**
     * Health check endpoint
     */
    @GET
    @Path("/health")
    public Response health() {
        try {
            boolean isHealthy = ragService.isHealthy();
            
            if (isHealthy) {
                return Response.ok("{\"status\": \"healthy\"}").build();
            } else {
                return Response.status(Response.Status.SERVICE_UNAVAILABLE)
                    .entity("{\"status\": \"unhealthy\"}").build();
            }
            
        } catch (Exception e) {
            LOG.error("Health check failed", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity("{\"status\": \"error\", \"message\": \"" + e.getMessage() + "\"}").build();
        }
    }
    
    /**
     * Search documents endpoint
     */
    @GET
    @Path("/search")
    public Response search(@QueryParam("q") String query, 
                          @QueryParam("limit") @DefaultValue("5") int limit) {
        try {
            if (query == null || query.trim().isEmpty()) {
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Query parameter 'q' is required\"}").build();
            }
            
            java.util.List<String> results = ragService.searchDocuments(query, limit);
            
            return Response.ok()
                .entity("{\"results\": " + 
                    com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(results) + "}")
                .build();
                
        } catch (Exception e) {
            LOG.error("Error searching documents", e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity("{\"error\": \"" + e.getMessage() + "\"}").build();
        }
    }
}
