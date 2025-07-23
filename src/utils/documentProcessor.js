import cheerio from 'cheerio';
import axios from 'axios';
import mammoth from 'mammoth';
import pdfParse from 'pdf-parse';
import { v4 as uuidv4 } from 'uuid';
import AWSServices from './awsServices.js';

class DocumentProcessor {
    
    /**
     * Process a document based on its type
     * @param {Buffer|string} content - Document content
     * @param {string} type - Document type (pdf, docx, html, txt, url)
     * @param {string} title - Document title
     * @param {string} source - Source URL or filename
     * @returns {Object} Processed document with chunks
     */
    static async processDocument(content, type, title, source) {
        try {
            let extractedText = '';
            let metadata = {
                id: uuidv4(),
                title,
                source,
                type,
                processedAt: new Date().toISOString(),
                chunks: []
            };

            switch (type.toLowerCase()) {
                case 'pdf':
                    extractedText = await this.processPDF(content);
                    break;
                case 'docx':
                case 'doc':
                    extractedText = await this.processWord(content);
                    break;
                case 'html':
                    extractedText = await this.processHTML(content);
                    break;
                case 'txt':
                case 'text':
                    extractedText = content.toString();
                    break;
                case 'url':
                    const webContent = await this.scrapeWebsite(content);
                    extractedText = webContent.text;
                    metadata.title = webContent.title || title;
                    break;
                case 'confluence':
                    extractedText = await this.processConfluencePage(content);
                    break;
                default:
                    throw new Error(`Unsupported document type: ${type}`);
            }

            // Create chunks from extracted text
            metadata.chunks = this.createChunks(extractedText, metadata);
            
            // Generate embeddings for each chunk
            for (let chunk of metadata.chunks) {
                chunk.embedding = await AWSServices.generateEmbedding(chunk.content);
            }

            return metadata;
        } catch (error) {
            console.error('Document processing error:', error);
            throw error;
        }
    }

    /**
     * Process PDF files
     */
    static async processPDF(buffer) {
        try {
            const data = await pdfParse(buffer);
            return data.text;
        } catch (error) {
            console.error('PDF processing error:', error);
            throw error;
        }
    }

    /**
     * Process Word documents
     */
    static async processWord(buffer) {
        try {
            const result = await mammoth.extractRawText({ buffer });
            return result.value;
        } catch (error) {
            console.error('Word processing error:', error);
            throw error;
        }
    }

    /**
     * Process HTML content
     */
    static async processHTML(htmlContent) {
        try {
            const $ = cheerio.load(htmlContent);
            
            // Remove script and style elements
            $('script, style, nav, footer, header').remove();
            
            // Extract main content
            let text = $('main, article, .content, #content, .post-content').text();
            
            // If no main content area found, get body text
            if (!text.trim()) {
                text = $('body').text();
            }
            
            // Clean up whitespace
            return text.replace(/\\s+/g, ' ').trim();
        } catch (error) {
            console.error('HTML processing error:', error);
            throw error;
        }
    }

    /**
     * Scrape website content
     */
    static async scrapeWebsite(url) {
        try {
            const response = await axios.get(url, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (compatible; RAG-Chatbot/1.0)',
                },
                timeout: 30000
            });

            const $ = cheerio.load(response.data);
            const title = $('title').text().trim() || 'Untitled';
            
            // Remove unwanted elements
            $('script, style, nav, footer, header, .advertisement, .sidebar').remove();
            
            // Try to find main content
            let content = $('main, article, .content, #content, .post-content, .entry-content').text();
            
            if (!content.trim()) {
                content = $('body').text();
            }
            
            // Clean up text
            const cleanText = content.replace(/\\s+/g, ' ').trim();
            
            return {
                title,
                text: cleanText,
                url
            };
        } catch (error) {
            console.error('Website scraping error:', error);
            throw error;
        }
    }

    /**
     * Process Confluence page content
     */
    static async processConfluencePage(pageData) {
        try {
            // If pageData is a URL, fetch the content
            if (typeof pageData === 'string' && pageData.startsWith('http')) {
                const confluenceContent = await this.scrapeConfluencePage(pageData);
                return confluenceContent;
            }
            
            // If it's already processed page data
            return pageData.body || pageData.content || pageData;
        } catch (error) {
            console.error('Confluence processing error:', error);
            throw error;
        }
    }

    /**
     * Scrape Confluence page
     */
    static async scrapeConfluencePage(url) {
        try {
            const response = await axios.get(url, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (compatible; RAG-Chatbot/1.0)',
                },
                timeout: 30000
            });

            const $ = cheerio.load(response.data);
            
            // Remove Confluence-specific unwanted elements
            $('script, style, .aui-header, .footer, .navigation, .sidebar, .comments').remove();
            
            // Extract main content from Confluence
            let content = $('#main-content, .wiki-content, .page-content').text();
            
            if (!content.trim()) {
                content = $('body').text();
            }
            
            return content.replace(/\\s+/g, ' ').trim();
        } catch (error) {
            console.error('Confluence scraping error:', error);
            throw error;
        }
    }

    /**
     * Create chunks from text content
     */
    static createChunks(text, metadata, chunkSize = 1000, overlap = 200) {
        const chunks = [];
        const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
        
        let currentChunk = '';
        let chunkIndex = 0;
        
        for (let sentence of sentences) {
            const trimmedSentence = sentence.trim();
            
            if (currentChunk.length + trimmedSentence.length > chunkSize && currentChunk.length > 0) {
                // Create chunk
                chunks.push({
                    id: `${metadata.id}-chunk-${chunkIndex}`,
                    content: currentChunk.trim(),
                    chunkIndex,
                    documentId: metadata.id,
                    title: metadata.title,
                    source: metadata.source,
                    type: metadata.type
                });
                
                // Start new chunk with overlap
                const words = currentChunk.split(' ');
                const overlapWords = words.slice(-Math.floor(overlap / 6)); // Approximate word count for overlap
                currentChunk = overlapWords.join(' ') + ' ' + trimmedSentence;
                chunkIndex++;
            } else {
                currentChunk += (currentChunk ? ' ' : '') + trimmedSentence;
            }
        }
        
        // Add final chunk if it has content
        if (currentChunk.trim()) {
            chunks.push({
                id: `${metadata.id}-chunk-${chunkIndex}`,
                content: currentChunk.trim(),
                chunkIndex,
                documentId: metadata.id,
                title: metadata.title,
                source: metadata.source,
                type: metadata.type
            });
        }
        
        return chunks;
    }

    /**
     * Batch process multiple documents
     */
    static async processDocuments(documents) {
        const results = [];
        
        for (let doc of documents) {
            try {
                const processed = await this.processDocument(
                    doc.content,
                    doc.type,
                    doc.title,
                    doc.source
                );
                results.push({ success: true, data: processed });
            } catch (error) {
                results.push({ 
                    success: false, 
                    error: error.message,
                    document: { title: doc.title, source: doc.source }
                });
            }
        }
        
        return results;
    }

    /**
     * Extract metadata from various document types
     */
    static extractMetadata(content, type, filename) {
        const metadata = {
            filename,
            type,
            size: Buffer.isBuffer(content) ? content.length : content.length,
            createdAt: new Date().toISOString()
        };

        // Add type-specific metadata
        switch (type.toLowerCase()) {
            case 'pdf':
                // PDF-specific metadata could be extracted here
                break;
            case 'docx':
                // Word document metadata
                break;
            case 'html':
                // HTML metadata like meta tags
                break;
        }

        return metadata;
    }
}

export default DocumentProcessor;
