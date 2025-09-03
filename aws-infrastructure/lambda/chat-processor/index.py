import json
import boto3
import os
from typing import Dict, Any, List

# Initialize AWS clients
bedrock = boto3.client('bedrock-runtime', region_name=os.environ['BEDROCK_REGION'])

def generate_response(query: str, context: str) -> str:
    """Generate response using AWS Bedrock Claude"""
    prompt = f"""Human: You are a helpful assistant that answers questions based on the provided context from Confluence documentation and other knowledge sources.

Context:
{context}

Question: {query}

Please provide a comprehensive answer based on the context provided. If the context doesn't contain enough information to answer the question completely, please say so and provide what information you can based on the available context.
