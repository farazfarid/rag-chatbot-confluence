import json
import boto3
import os
from typing import Dict, Any, List
import requests
from opensearchpy import OpenSearch, RequestsHttpConnection
from aws_requests_auth.aws_auth import AWSRequestsAuth
import PyPDF2
import io
import hashlib

# Initialize AWS clients
bedrock = boto3.client('bedrock-runtime', region_name=os.environ['BEDROCK_REGION'])
s3 = boto3.client('s3')

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

def chunk_text(text: str, chunk_size: int = 1000, overlap: int = 200) -> List[str]:
    """Split text into overlapping chunks"""
    chunks = []
    start = 0
    
    while start < len(text):
        end = start + chunk_size
        chunk = text[start:end]
        
        # Try to break at sentence boundary
        if end < len(text):
            last_period = chunk.rfind('.')
            last_newline = chunk.rfind('\n')
            break_point = max(last_period, last_newline)
            
            if break_point > start + chunk_size // 2:
                chunk = text[start:break_point + 1]
                end = break_point + 1
        
        chunks.append(chunk.strip())
        start = end - overlap
        
        if start >= len(text):
            break
    
    return chunks

def process_pdf(file_content: bytes) -> str:
    """Extract text from PDF"""
    try:
        pdf_reader = PyPDF2.PdfReader(io.BytesIO(file_content))
        text = ""
        for page in pdf_reader.pages:
            text += page.extract_text() + "\n"
        return text
    except Exception as e:
        print(f"Error processing PDF: {str(e)}")
        return ""

def store_document_chunks(document_id: str, chunks: List[str], metadata: Dict[str, Any]):
    """Store document chunks in OpenSearch"""
    index_name = "confluence-rag-documents"
    
    # Create index if it doesn't exist
    if not opensearch_client.indices.exists(index=index_name):
        index_mapping = {
            "mappings": {
                "properties": {
                    "document_id": {"type": "keyword"},
                    "chunk_id": {"type": "keyword"},
                    "content": {"type": "text"},
                    "embedding": {
                        "type": "knn_vector",
                        "dimension": 1536,
                        "method": {
                            "name": "hnsw",
                            "space_type": "cosinesimil",
                            "engine": "nmslib"
                        }
                    },
                    "metadata": {"type": "object"},
                    "timestamp": {"type": "date"}
                }
            }
        }
        opensearch_client.indices.create(index=index_name, body=index_mapping)
    
    # Store each chunk
    for i, chunk in enumerate(chunks):
        if not chunk.strip():
            continue
            
        embedding = get_embeddings(chunk)
        if not embedding:
            continue
            
        chunk_id = f"{document_id}_chunk_{i}"
        doc = {
            "document_id": document_id,
            "chunk_id": chunk_id,
            "content": chunk,
            "embedding": embedding,
            "metadata": metadata,
            "timestamp": "2024-01-01T00:00:00Z"
        }
        
        opensearch_client.index(
            index=index_name,
            id=chunk_id,
            body=doc
        )

def handler(event, context):
    """Lambda handler for document processing"""
    try:
        body = json.loads(event.get('body', '{}'))
        
        if 'document_url' in body:
            # Process document from URL
            url = body['document_url']
            response = requests.get(url)
            content = response.content
            
            if url.endswith('.pdf'):
                text = process_pdf(content)
            else:
                text = response.text
                
        elif 's3_key' in body:
            # Process document from S3
            s3_key = body['s3_key']
            bucket = os.environ['S3_BUCKET']
            
            obj = s3.get_object(Bucket=bucket, Key=s3_key)
            content = obj['Body'].read()
            
            if s3_key.endswith('.pdf'):
                text = process_pdf(content)
            else:
                text = content.decode('utf-8')
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'No document source provided'})
            }
        
        # Generate document ID
        document_id = hashlib.md5(text.encode()).hexdigest()
        
        # Chunk the text
        chunks = chunk_text(text)
        
        # Prepare metadata
        metadata = {
            'source': body.get('source', 'unknown'),
            'title': body.get('title', 'Untitled'),
            'type': body.get('type', 'document')
        }
        
        # Store in OpenSearch
        store_document_chunks(document_id, chunks, metadata)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'document_id': document_id,
                'chunks_processed': len(chunks),
                'message': 'Document processed successfully'
            })
        }
        
    except Exception as e:
        print(f"Error processing document: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
