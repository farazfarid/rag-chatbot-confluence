#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { ConfluenceRagStack } from '../lib/confluence-rag-stack';
import { LambdaStack } from '../lib/lambda-stack';
import { OpenSearchStack } from '../lib/opensearch-stack';

const app = new cdk.App();

const region = app.node.tryGetContext('region') || 'us-east-1';
const env = { region };

// Core infrastructure stack
const ragStack = new ConfluenceRagStack(app, 'ConfluenceRagStack', {
  env,
  description: 'Core infrastructure for Confluence RAG chatbot'
});

// OpenSearch stack for vector database
const openSearchStack = new OpenSearchStack(app, 'ConfluenceRagOpenSearchStack', {
  env,
  description: 'OpenSearch cluster for vector embeddings',
  vpc: ragStack.vpc
});

// Lambda functions stack
const lambdaStack = new LambdaStack(app, 'ConfluenceRagLambdaStack', {
  env,
  description: 'Lambda functions for document processing and chat',
  vpc: ragStack.vpc,
  openSearchDomain: openSearchStack.domain,
  s3Bucket: ragStack.documentBucket
});

// Add dependencies
openSearchStack.addDependency(ragStack);
lambdaStack.addDependency(ragStack);
lambdaStack.addDependency(openSearchStack);
