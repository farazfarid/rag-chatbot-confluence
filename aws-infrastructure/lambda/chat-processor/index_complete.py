import json
import boto3
import os
from typing import Dict, Any, List
from opensearchpy import OpenSearch, RequestsHttpConnection
from aws_requests_auth.aws_auth import AWSRequestsAuth

# Initialize AWS clients
bedrock = boto3.client('bedrock-runtime', region_name=os.environ['BEDROCK_REGION'])

# OpenSearch configuration
opensearch_endpoint = os.environ['OPENSEARCH_ENDPOINT'].replace('https://', '')
auth = AWSRequestsAuth(
    aws_access_key=boto3.Session().get_credentials().access_key,
    aws_secret_access_key=boto3.Session().get_credentials().secret_key,
    aws_token=boto3.Session().get_credentials().token,
    aws_host=opensearch_endpoint,
    aws_region=os.environ['BEDROCK_REGION'],
    aws_service='aoss'
)

opensearch_client = OpenSearch(
    hosts=[{'host': opensearch_endpoint, 'port': 443}],
    http_auth=auth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection
)

def get_embeddings(text: str) -> List[float]:
    """Generate embeddings using AWS Bedrock"""
    try:
        body = json.dumps({
            "inputText": text
        })
        
        response = bedrock.invoke_model(
            body=body,
            modelId='amazon.titan-embed-text-v1',
            accept='application/json',
            contentType='application/json'
        )
        
        response_body = json.loads(response.get('body').read())
        return response_body.get('embedding')
    except Exception as e:
        print(f"Error generating embeddings: {str(e)}")
        return []

def search_similar_documents(query: str, top_k: int = 5) -> List[Dict[str, Any]]:
    """Search for similar documents using vector similarity"""
    query_embedding = get_embeddings(query)
    if not query_embedding:
        return []
    
    search_query = {
        "size": top_k,
        "query": {
            "knn": {
                "embedding": {
                    "vector": query_embedding,
                    "k": top_k
                }
            }
        },
        "_source": ["content", "metadata", "document_id"]
    }
    
    try:
        response = opensearch_client.search(
            index="confluence-rag-documents",
            body=search_query
        )
        
        results = []
        for hit in response['hits']['hits']:
            results.append({
                'content': hit['_source']['content'],
                'metadata': hit['_source']['metadata'],
                'score': hit['_score'],
                'document_id': hit['_source']['document_id']
            })
        
        return results
    except Exception as e:
        print(f"Error searching documents: {str(e)}")
        return []

def generate_response(query: str, context_docs: List[Dict[str, Any]]) -> str:
    """Generate response using AWS Bedrock Claude"""
    context = "\n\n".join([doc['content'] for doc in context_docs])
    
    prompt = f"""Human: You are a helpful assistant that answers questions based on the provided context from Confluence documentation and other knowledge sources.

Context:
{context}

Question: {query}

Please provide a comprehensive answer based on the context provided. If the context doesn't contain enough information to answer the question completely, please say so and provide what information you can based on the available context.
