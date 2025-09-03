import json
import boto3
import os
from typing import Dict, Any, List

# Initialize AWS clients
bedrock = boto3.client('bedrock-runtime', region_name=os.environ['BEDROCK_REGION'])

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

def generate_response(query: str, context: str) -> str:
    """Generate response using AWS Bedrock Claude"""
    prompt = f"""Human: You are a helpful assistant that answers questions based on the provided context from Confluence documentation and other knowledge sources.

Context:
{context}

Question: {query}

Please provide a comprehensive answer based on the context provided. If the context doesn't contain enough information to answer the question completely, please say so and provide what information you can based on the available context.
