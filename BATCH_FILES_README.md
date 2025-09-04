# Windows Batch Files - Confluence RAG Chatbot

This project now includes comprehensive Windows batch (.bat) files for reliable building and deployment on Windows systems.

## 🚀 Quick Start

```cmd
# Complete build pipeline
quick-build.bat

# Or step by step:
cleanup-project.bat
validate-dependencies.bat
build-basic.bat
analyze-jar.bat
```

## 📋 Available Batch Files

### 🧹 Project Management
- **`cleanup-project.bat`** - Analyze and clean up empty/duplicate files
- **`validate-dependencies.bat`** - Validate Maven, Java files, and dependencies
- **`help.bat`** - Show all available commands and usage

### 🔨 Build Commands
- **`build-basic.bat`** - Enhanced build with validation
- **`build-basic.bat skip`** - Build without pre-validation
- **`build-basic.bat skip verbose`** - Build with detailed Maven output
- **`quick-build.bat`** - Complete pipeline (validate → build → analyze)

### 📦 Analysis Tools
- **`analyze-jar.bat`** - Analyze the built JAR file
- **`analyze-jar.bat detailed`** - Show all JAR contents in detail
- **`test-plugin.bat`** - Test plugin configuration and URLs

## 🔧 Prerequisites

All batch files will check for required tools:

- **Java 11+** - Download from [Adoptium](https://adoptium.net/)
- **Maven 3.6+** - Download from [Apache Maven](https://maven.apache.org/download.cgi)

## 📖 Usage Examples

### Basic Workflow
```cmd
# 1. Check project health
cleanup-project.bat

# 2. Validate everything
validate-dependencies.bat

# 3. Build the JAR
build-basic.bat

# 4. Analyze results
analyze-jar.bat
```

### Quick Build
```cmd
# One command for everything
quick-build.bat
```

### Detailed Analysis
```cmd
# See all JAR contents
analyze-jar.bat detailed

# Build with verbose Maven output
build-basic.bat skip verbose
```

### Troubleshooting
```cmd
# Check what's wrong
validate-dependencies.bat

# Clean up project
cleanup-project.bat

# Force build without validation
build-basic.bat skip
```

## 🎯 Output Files

After successful build:
- **JAR file**: `confluence-app\target\confluence-rag-chatbot-1.0.0.jar`
- **UI Preview**: `ui-preview.html` (open in browser)

## 🔍 Features

### Error Handling
- ✅ Automatic prerequisite checking
- ✅ Clear error messages
- ✅ Graceful failure handling
- ✅ Troubleshooting suggestions

### Validation
- ✅ Maven installation check
- ✅ Java file compilation test
- ✅ Dependency resolution verification
- ✅ Resource file existence check
- ✅ Empty file detection

### Analysis
- ✅ JAR content inspection
- ✅ Class file counting
- ✅ Manifest analysis
- ✅ File size reporting
- ✅ Installation instructions

## 🆚 Why Batch Files vs PowerShell?

| Feature | Batch Files | PowerShell |
|---------|-------------|------------|
| **Compatibility** | ✅ Works everywhere | ⚠️ Execution policy issues |
| **Reliability** | ✅ Always available | ⚠️ May be disabled |
| **Permissions** | ✅ No special permissions | ❌ May require admin |
| **Simplicity** | ✅ Simple syntax | ⚠️ Complex for basic tasks |

## 🔧 Customization

### Build Options
```cmd
# Skip validation (faster)
build-basic.bat skip

# Verbose output (debugging)
build-basic.bat skip verbose

# Custom JAR analysis
analyze-jar.bat detailed
```

### Environment Variables
The scripts will automatically detect:
- `JAVA_HOME` - Java installation
- `MAVEN_HOME` - Maven installation
- `PATH` - Command availability

## 🎯 Installation Process

After building:

1. **Upload to Confluence**:
   - Go to Administration → Manage Apps
   - Click "Upload App"
   - Select: `confluence-app\target\confluence-rag-chatbot-1.0.0.jar`

2. **Configure**:
   - Go to: `{confluence-url}/plugins/servlet/rag-admin`
   - Enter AWS credentials and endpoints
   - Add knowledge sources

3. **Test**:
   - Add `{rag-chat}` macro to any page
   - Use REST API: `{confluence-url}/rest/rag/1.0/chat`

## 🆘 Troubleshooting

### Common Issues

**Maven not found**:
```cmd
# Download and install Maven
# Add to PATH: C:\path\to\maven\bin
```

**Java not found**:
```cmd
# Download and install Java 11+
# Set JAVA_HOME environment variable
```

**Build fails**:
```cmd
# Check detailed output
validate-dependencies.bat
build-basic.bat skip verbose
```

**Empty JAR**:
```cmd
# Clean and rebuild
cleanup-project.bat
quick-build.bat
```

## 🔄 Migration from PowerShell

If you were using PowerShell scripts:

| Old PowerShell | New Batch File |
|----------------|----------------|
| `.\build-basic.ps1` | `build-basic.bat` |
| `.\validate-dependencies.ps1` | `validate-dependencies.bat` |
| `.\analyze-jar.ps1` | `analyze-jar.bat` |
| `.\cleanup-project.ps1` | `cleanup-project.bat` |

All functionality has been preserved and enhanced in the batch versions.
