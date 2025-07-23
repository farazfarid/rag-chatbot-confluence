import AWS from 'aws-sdk';

// Configure AWS
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';
const S3_BUCKET = process.env.S3_BUCKET_NAME || 'confluence-rag-documents';
const OPENSEARCH_ENDPOINT = process.env.OPENSEARCH_ENDPOINT;
const BEDROCK_MODEL_ID = process.env.BEDROCK_MODEL_ID || 'anthropic.claude-3-sonnet-20240229-v1:0';

AWS.config.update({
    region: AWS_REGION,
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

const s3 = new AWS.S3();
const opensearch = new AWS.OpenSearchServerless();
const bedrock = new AWS.BedrockRuntime();

class AWSServices {
    // S3 Operations
    static async uploadToS3(key, body, contentType = 'application/octet-stream') {
        try {
            const params = {
                Bucket: S3_BUCKET,
                Key: key,
                Body: body,
                ContentType: contentType,
                ServerSideEncryption: 'AES256'
            };
            
            const result = await s3.upload(params).promise();
            return result;
        } catch (error) {
            console.error('S3 Upload Error:', error);
            throw error;
        }
    }

    static async getFromS3(key) {
        try {
            const params = {
                Bucket: S3_BUCKET,
                Key: key
            };
            
            const result = await s3.getObject(params).promise();
            return result.Body;
        } catch (error) {
            console.error('S3 Get Error:', error);
            throw error;
        }
    }

    static async deleteFromS3(key) {
        try {
            const params = {
                Bucket: S3_BUCKET,
                Key: key
            };
            
            await s3.deleteObject(params).promise();
            return true;
        } catch (error) {
            console.error('S3 Delete Error:', error);
            throw error;
        }
    }

    static async listS3Objects(prefix = '') {
        try {
            const params = {
                Bucket: S3_BUCKET,
                Prefix: prefix
            };
            
            const result = await s3.listObjectsV2(params).promise();
            return result.Contents || [];
        } catch (error) {
            console.error('S3 List Error:', error);
            throw error;
        }
    }

    // OpenSearch Operations
    static async indexDocument(index, id, document) {
        try {
            const client = this.getOpenSearchClient();
            const response = await client.index({
                index: index,
                id: id,
                body: document
            });
            return response;
        } catch (error) {
            console.error('OpenSearch Index Error:', error);
            throw error;
        }
    }

    static async searchDocuments(index, query, size = 10) {
        try {
            const client = this.getOpenSearchClient();
            const searchParams = {
                index: index,
                body: {
                    query: {
                        multi_match: {
                            query: query,
                            fields: ['content', 'title', 'summary'],
                            fuzziness: 'AUTO'
                        }
                    },
                    highlight: {
                        fields: {
                            content: {},
                            title: {}
                        }
                    },
                    size: size
                }
            };
            
            const response = await client.search(searchParams);
            return response.body.hits;
        } catch (error) {
            console.error('OpenSearch Search Error:', error);
            throw error;
        }
    }

    static async vectorSearch(index, vector, size = 5) {
        try {
            const client = this.getOpenSearchClient();
            const searchParams = {
                index: index,
                body: {
                    query: {
                        knn: {
                            vector_field: {
                                vector: vector,
                                k: size
                            }
                        }
                    },
                    size: size
                }
            };
            
            const response = await client.search(searchParams);
            return response.body.hits;
        } catch (error) {
            console.error('OpenSearch Vector Search Error:', error);
            throw error;
        }
    }

    static getOpenSearchClient() {
        const { Client } = require('@opensearch-project/opensearch');
        const { AwsSigv4Signer } = require('@opensearch-project/opensearch/aws');
        
        return new Client({
            ...AwsSigv4Signer({
                region: AWS_REGION,
                service: 'es',
                getCredentials: () =>
                    new Promise((resolve) => {
                        AWS.config.getCredentials((err, credentials) => {
                            if (err) {
                                console.error(err);
                                return;
                            }
                            resolve(credentials);
                        });
                    }),
            }),
            node: OPENSEARCH_ENDPOINT,
        });
    }

    // Bedrock AI Operations
    static async generateEmbedding(text) {
        try {
            const params = {
                modelId: 'amazon.titan-embed-text-v1',
                contentType: 'application/json',
                accept: 'application/json',
                body: JSON.stringify({
                    inputText: text
                })
            };
            
            const response = await bedrock.invokeModel(params).promise();
            const responseBody = JSON.parse(response.body.toString());
            return responseBody.embedding;
        } catch (error) {
            console.error('Bedrock Embedding Error:', error);
            throw error;
        }
    }

    static async generateResponse(prompt, context = '') {
        try {
            const fullPrompt = context 
                ? `Context: ${context}\n\nQuestion: ${prompt}\n\nPlease provide a helpful answer based on the context provided.`
                : prompt;

            const params = {
                modelId: BEDROCK_MODEL_ID,
                contentType: 'application/json',
                accept: 'application/json',
                body: JSON.stringify({
                    anthropic_version: 'bedrock-2023-05-31',
                    max_tokens: 2000,
                    messages: [
                        {
                            role: 'user',
                            content: fullPrompt
                        }
                    ]
                })
            };
            
            const response = await bedrock.invokeModel(params).promise();
            const responseBody = JSON.parse(response.body.toString());
            return responseBody.content[0].text;
        } catch (error) {
            console.error('Bedrock Generation Error:', error);
            throw error;
        }
    }

    // Lambda Operations
    static async invokeLambda(functionName, payload) {
        try {
            const lambda = new AWS.Lambda();
            const params = {
                FunctionName: functionName,
                Payload: JSON.stringify(payload),
                InvocationType: 'RequestResponse'
            };
            
            const result = await lambda.invoke(params).promise();
            return JSON.parse(result.Payload);
        } catch (error) {
            console.error('Lambda Invoke Error:', error);
            throw error;
        }
    }
}

export default AWSServices;
