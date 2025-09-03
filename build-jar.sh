#!/bin/bash

# Confluence RAG Chatbot - JAR Build Script (No AWS Required)
# This script builds only the Confluence app JAR without requiring AWS CLI

set -e

echo "🔨 Building Confluence RAG Chatbot JAR..."

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v mvn &> /dev/null; then
    echo "❌ Maven is not installed. Please install Maven 3.6+ first."
    echo "   Download from: https://maven.apache.org/download.cgi"
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo "❌ Java is not installed. Please install Java 11+ first."
    echo "   Download from: https://adoptium.net/"
    exit 1
fi

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1-2)
if [ "${JAVA_VERSION}" \< "11" ]; then
    echo "❌ Java 11+ is required. Current version: ${JAVA_VERSION}"
    exit 1
fi

echo "✅ Maven: $(mvn -version | head -n 1)"
echo "✅ Java: $(java -version 2>&1 | head -n 1)"

# Build Confluence App
echo "🔨 Building Confluence app..."
cd confluence-app

# Clean and build
echo "📦 Running Maven clean package..."
mvn clean package -q

if [ -f "target/confluence-rag-chatbot-1.0.0.jar" ]; then
    echo "✅ Confluence app built successfully!"
    echo ""
    echo "📁 JAR location: confluence-app/target/confluence-rag-chatbot-1.0.0.jar"
    echo "📏 File size: $(du -h target/confluence-rag-chatbot-1.0.0.jar | cut -f1)"
    echo ""
    echo "🎉 Ready for installation!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Upload the JAR file to your Confluence Data Center:"
    echo "   - Go to Confluence Administration → Manage Apps"
    echo "   - Click 'Upload app'"
    echo "   - Select: confluence-app/target/confluence-rag-chatbot-1.0.0.jar"
    echo ""
    echo "2. Configure the app:"
    echo "   - Go to Administration → RAG Chatbot Configuration"
    echo "   - Enter your AWS credentials and endpoints"
    echo "   - Add knowledge sources (Confluence sites, PDFs, websites)"
    echo ""
    echo "3. Test the installation:"
    echo "   - Add the /rag macro to any Confluence page"
    echo "   - Or use the chat widget in the sidebar"
    echo ""
    echo "📖 For AWS infrastructure setup (optional):"
    echo "   - If you need AWS infrastructure, install AWS CLI first"
    echo "   - Then run: ./deploy.sh for full deployment"
    echo ""
    echo "🔧 Manual AWS setup:"
    echo "   - You can set up AWS resources manually via console"
    echo "   - Configure the app with your AWS endpoints in the admin interface"
else
    echo "❌ Failed to build Confluence app"
    echo "Check the Maven output above for errors"
    exit 1
fi

cd ..
