import React, { useState, useEffect, useRef } from 'react';
import ForgeReconciler, { Box, Text, TextField, Button, Stack, Avatar, Spinner, Badge } from '@forge/react';
import { invoke } from '@forge/bridge';

const ChatbotMain = () => {
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [conversationId, setConversationId] = useState(null);
  const [settings, setSettings] = useState(null);
  const messagesEndRef = useRef(null);

  useEffect(() => {
    // Load settings and initial setup
    loadSettings();
    loadConversation();
  }, []);

  useEffect(() => {
    // Scroll to bottom when new messages are added
    scrollToBottom();
  }, [messages]);

  const loadSettings = async () => {
    try {
      const response = await invoke('getSettings');
      if (response.success) {
        setSettings(response.settings);
        
        // Add welcome message if no conversation exists
        if (!conversationId) {
          setMessages([{
            role: 'assistant',
            content: response.settings.welcomeMessage,
            timestamp: new Date().toISOString(),
            isWelcome: true
          }]);
        }
      }
    } catch (error) {
      console.error('Error loading settings:', error);
    }
  };

  const loadConversation = async () => {
    if (!conversationId) return;
    
    try {
      const response = await invoke('getConversation', { conversationId });
      if (response.success && response.messages.length > 0) {
        setMessages(response.messages);
      }
    } catch (error) {
      console.error('Error loading conversation:', error);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSendMessage = async () => {
    if (!inputMessage.trim() || isLoading) return;

    const userMessage = {
      role: 'user',
      content: inputMessage,
      timestamp: new Date().toISOString()
    };

    setMessages(prev => [...prev, userMessage]);
    setInputMessage('');
    setIsLoading(true);

    try {
      const response = await invoke('sendMessage', {
        message: inputMessage,
        conversationId
      });

      if (response.success) {
        const assistantMessage = {
          role: 'assistant',
          content: response.response,
          timestamp: new Date().toISOString(),
          sources: response.sources
        };

        setMessages(prev => [...prev, assistantMessage]);
        setConversationId(response.conversationId);
      } else {
        const errorMessage = {
          role: 'assistant',
          content: `Sorry, I encountered an error: ${response.error}`,
          timestamp: new Date().toISOString(),
          isError: true
        };
        setMessages(prev => [...prev, errorMessage]);
      }
    } catch (error) {
      console.error('Error sending message:', error);
      const errorMessage = {
        role: 'assistant',
        content: 'Sorry, I\'m having trouble connecting right now. Please try again.',
        timestamp: new Date().toISOString(),
        isError: true
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (event) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      handleSendMessage();
    }
  };

  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };

  const MessageBubble = ({ message }) => {
    const isUser = message.role === 'user';
    const isError = message.isError;
    const isWelcome = message.isWelcome;
    
    return (
      <Box
        xcss={{
          display: 'flex',
          flexDirection: isUser ? 'row-reverse' : 'row',
          alignItems: 'flex-start',
          gap: '8px',
          marginBottom: '16px',
          maxWidth: '100%'
        }}
      >
        <Avatar
          size="small"
          appearance={isUser ? 'circle' : 'square'}
          name={isUser ? 'You' : (settings?.chatbotName || 'AI')}
        />
        
        <Box
          xcss={{
            maxWidth: '70%',
            display: 'flex',
            flexDirection: 'column',
            gap: '4px'
          }}
        >
          <Box
            xcss={{
              padding: '12px 16px',
              borderRadius: '18px',
              backgroundColor: isUser 
                ? (settings?.theme?.primaryColor || '#1976d2')
                : isError 
                  ? '#ffebee'
                  : isWelcome
                    ? '#e3f2fd'
                    : '#f5f5f5',
              color: isUser 
                ? (settings?.theme?.secondaryColor || '#ffffff')
                : isError
                  ? '#c62828'
                  : (settings?.theme?.textColor || '#333333'),
              border: isError ? '1px solid #ffcdd2' : 'none',
              wordWrap: 'break-word',
              whiteSpace: 'pre-wrap'
            }}
          >
            <Text>{message.content}</Text>
          </Box>
          
          {message.sources && message.sources.length > 0 && (
            <Box xcss={{ display: 'flex', flexWrap: 'wrap', gap: '4px', marginTop: '4px' }}>
              {message.sources.map((source, index) => (
                <Badge key={index} appearance="primary">
                  {source.title}
                </Badge>
              ))}
            </Box>
          )}
          
          <Text
            xcss={{
              fontSize: '12px',
              color: '#666666',
              alignSelf: isUser ? 'flex-end' : 'flex-start'
            }}
          >
            {formatTimestamp(message.timestamp)}
          </Text>
        </Box>
      </Box>
    );
  };

  return (
    <Box
      xcss={{
        height: '600px',
        maxWidth: '800px',
        margin: '0 auto',
        backgroundColor: settings?.theme?.backgroundColor || '#ffffff',
        borderRadius: '12px',
        boxShadow: '0 4px 20px rgba(0, 0, 0, 0.1)',
        display: 'flex',
        flexDirection: 'column',
        border: `1px solid ${settings?.theme?.primaryColor || '#1976d2'}20`
      }}
    >
      {/* Header */}
      <Box
        xcss={{
          padding: '20px',
          backgroundColor: settings?.theme?.primaryColor || '#1976d2',
          color: settings?.theme?.secondaryColor || '#ffffff',
          borderRadius: '12px 12px 0 0',
          textAlign: 'center'
        }}
      >
        <Text xcss={{ fontSize: '18px', fontWeight: 'bold' }}>
          {settings?.chatbotName || 'AI Knowledge Assistant'}
        </Text>
        <Text xcss={{ fontSize: '14px', opacity: 0.9, marginTop: '4px' }}>
          Powered by AWS AI Services
        </Text>
      </Box>

      {/* Messages Container */}
      <Box
        xcss={{
          flex: 1,
          padding: '20px',
          overflowY: 'auto',
          display: 'flex',
          flexDirection: 'column'
        }}
      >
        {messages.map((message, index) => (
          <MessageBubble key={index} message={message} />
        ))}
        
        {isLoading && (
          <Box
            xcss={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              marginBottom: '16px'
            }}
          >
            <Avatar size="small" appearance="square" name="AI" />
            <Box
              xcss={{
                padding: '12px 16px',
                borderRadius: '18px',
                backgroundColor: '#f5f5f5',
                display: 'flex',
                alignItems: 'center',
                gap: '8px'
              }}
            >
              <Spinner size="small" />
              <Text>Thinking...</Text>
            </Box>
          </Box>
        )}
        
        <div ref={messagesEndRef} />
      </Box>

      {/* Input Container */}
      <Box
        xcss={{
          padding: '20px',
          borderTop: '1px solid #e0e0e0',
          backgroundColor: '#fafafa',
          borderRadius: '0 0 12px 12px'
        }}
      >
        <Stack space="medium">
          <TextField
            value={inputMessage}
            onChange={setInputMessage}
            onKeyPress={handleKeyPress}
            placeholder="Ask me anything about your knowledge base..."
            isMultiline
            rows={2}
            appearance="standard"
            isDisabled={isLoading}
          />
          
          <Box xcss={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Text xcss={{ fontSize: '12px', color: '#666666' }}>
              Press Enter to send, Shift+Enter for new line
            </Text>
            
            <Button
              onClick={handleSendMessage}
              appearance="primary"
              isDisabled={!inputMessage.trim() || isLoading}
            >
              {isLoading ? 'Sending...' : 'Send'}
            </Button>
          </Box>
        </Stack>
      </Box>
    </Box>
  );
};

ForgeReconciler.render(
  <React.StrictMode>
    <ChatbotMain />
  </React.StrictMode>
);

export default ChatbotMain;


