@echo off
echo === Confluence RAG Chatbot - Windows CMD Tools ===
echo.
echo Available commands:
echo.
echo 🧹 CLEANUP AND VALIDATION:
echo   cleanup-project.bat      - Clean up empty files and analyze project
echo   validate-dependencies.bat - Check Maven, Java files, and dependencies
echo.
echo 🔨 BUILD COMMANDS:
echo   build-basic.bat          - Build the JAR file (with validation)
echo   build-basic.bat skip     - Build without pre-validation
echo   build-basic.bat skip verbose - Build with detailed output
echo.
echo 📦 ANALYSIS TOOLS:
echo   analyze-jar.bat          - Analyze the built JAR file
echo   analyze-jar.bat detailed - Show all JAR contents
echo   test-plugin.bat          - Test plugin configuration
echo.
echo 🚀 QUICK COMMANDS:
echo   quick-build.bat          - Complete build pipeline (validate + build + analyze)
echo.
echo 🖥️  UI PREVIEW:
echo   ui-preview.html          - Open in browser to see interfaces
echo.
echo 📝 USAGE EXAMPLES:
echo   cleanup-project.bat                 - Check and clean project
echo   validate-dependencies.bat           - Validate everything
echo   build-basic.bat                     - Standard build
echo   analyze-jar.bat detailed            - Full JAR analysis
echo   quick-build.bat                     - Complete pipeline
echo.
echo 💡 TYPICAL WORKFLOW:
echo   1. cleanup-project.bat
echo   2. validate-dependencies.bat  
echo   3. build-basic.bat
echo   4. analyze-jar.bat
echo   5. Open ui-preview.html
echo   6. Install JAR in Confluence
echo.
pause
