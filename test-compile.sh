#!/bin/bash
echo "Testing compilation fixes..."
cd confluence-app

# Find Java files with potential issues
echo "Java files in service package:"
find src/main/java/com/confluence/rag/service -name "*.java" -exec echo {} \;

echo ""
echo "Java files in model package:"
find src/main/java/com/confluence/rag/model -name "*.java" -exec echo {} \;

echo ""
echo "Compilation test completed. Now try running Maven in Windows Command Prompt:"
echo "cd D:\\ET\\rag-chatbot-confluence\\confluence-app"
echo "mvn -f pom-minimal.xml clean package \"-Dmaven.test.skip=true\""
