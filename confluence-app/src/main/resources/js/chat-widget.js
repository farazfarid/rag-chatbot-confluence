/**
 * RAG Chatbot JavaScript functionality
 */
(function ($) {
  'use strict';

  window.RagChatWidget = {

    sessionId: null,
    isOpen: false,
    baseUrl: null,

    init: function () {
      this.baseUrl = AJS.Meta.get('base-url');
      this.sessionId = this.generateSessionId();
      this.bindEvents();
      this.loadChatHistory();
    },

    generateSessionId: function () {
      return 'session_' + Math.random().toString(36).substr(2, 9) + '_' + Date.now();
    },

    bindEvents: function () {
      var self = this;

      // Toggle chat panel
      $('#rag-chat-toggle').on('click', function (e) {
        e.preventDefault();
        self.toggleChat();
      });

      // Handle form submission
      $('#rag-chat-form').on('submit', function (e) {
        e.preventDefault();
        self.sendMessage();
      });

      // Handle enter key in input
      $('#rag-chat-input').on('keypress', function (e) {
        if (e.which === 13 && !e.shiftKey) {
          e.preventDefault();
          self.sendMessage();
        }
      });
    },

    toggleChat: function () {
      var panel = $('#rag-chat-panel');

      if (this.isOpen) {
        panel.slideUp(300);
        this.isOpen = false;
      } else {
        panel.slideDown(300, function () {
          $('#rag-chat-input').focus();
        });
        this.isOpen = true;
      }
    },

    sendMessage: function () {
      var input = $('#rag-chat-input');
      var message = input.val().trim();

      if (!message) {
        return;
      }

      // Clear input and disable while processing
      input.val('').prop('disabled', true);
      $('#rag-chat-send').prop('disabled', true);

      // Add user message to chat
      this.addMessage(message, 'user');

      // Show typing indicator
      this.showTypingIndicator();

      // Send to API
      this.callChatAPI(message);
    },

    addMessage: function (content, type) {
      var messagesContainer = $('#rag-chat-messages');
      var messageClass = type === 'user' ? 'rag-chat-user-message' : 'rag-chat-bot-message';

      var messageHtml = '<div class="rag-chat-message ' + messageClass + '">' +
        '<div class="rag-chat-message-content">' +
        '<p>' + this.escapeHtml(content) + '</p>' +
        '</div>' +
        '</div>';

      messagesContainer.append(messageHtml);
      this.scrollToBottom();
    },

    showTypingIndicator: function () {
      var messagesContainer = $('#rag-chat-messages');
      var typingHtml = '<div class="rag-chat-message rag-chat-bot-message rag-typing-indicator" id="typing-indicator">' +
        '<div class="rag-chat-message-content">' +
        '<div class="rag-typing-dots">' +
        '<span></span><span></span><span></span>' +
        '</div>' +
        '</div>' +
        '</div>';

      messagesContainer.append(typingHtml);
      this.scrollToBottom();
    },

    hideTypingIndicator: function () {
      $('#typing-indicator').remove();
    },

    callChatAPI: function (message) {
      var self = this;

      var requestData = {
        message: message,
        sessionId: this.sessionId,
        userId: AJS.Meta.get('remote-user'),
        spaceKey: AJS.Meta.get('space-key')
      };

      $.ajax({
        url: this.baseUrl + '/rest/rag/1.0/chat',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(requestData),
        timeout: 30000,
        success: function (response) {
          self.handleChatResponse(response);
        },
        error: function (xhr, status, error) {
          self.handleChatError(xhr, status, error);
        },
        complete: function () {
          // Re-enable input
          $('#rag-chat-input').prop('disabled', false);
          $('#rag-chat-send').prop('disabled', false);
          self.hideTypingIndicator();
        }
      });
    },

    handleChatResponse: function (response) {
      if (response.error) {
        this.addMessage('Sorry, I encountered an error: ' + response.error, 'bot');
      } else if (response.response) {
        this.addMessage(response.response, 'bot');

        // Show sources if available
        if (response.sources && response.sources.length > 0) {
          this.addSourcesMessage(response.sources);
        }
      } else {
        this.addMessage('Sorry, I didn\'t receive a response. Please try again.', 'bot');
      }
    },

    handleChatError: function (xhr, status, error) {
      var errorMessage = 'Sorry, I\'m having trouble connecting. Please try again later.';

      if (xhr.status === 400) {
        errorMessage = 'Please check your message and try again.';
      } else if (xhr.status === 503) {
        errorMessage = 'The AI service is temporarily unavailable. Please try again later.';
      }

      this.addMessage(errorMessage, 'bot');
    },

    addSourcesMessage: function (sources) {
      var messagesContainer = $('#rag-chat-messages');
      var sourcesHtml = '<div class="rag-chat-message rag-chat-bot-message rag-sources-message">' +
        '<div class="rag-chat-message-content">' +
        '<p><strong>Sources:</strong></p>' +
        '<ul>';

      sources.forEach(function (source, index) {
        sourcesHtml += '<li>' + this.escapeHtml(source.substring(0, 100)) + '...</li>';
      }.bind(this));

      sourcesHtml += '</ul></div></div>';

      messagesContainer.append(sourcesHtml);
      this.scrollToBottom();
    },

    scrollToBottom: function () {
      var messagesContainer = $('#rag-chat-messages');
      messagesContainer.animate({
        scrollTop: messagesContainer[0].scrollHeight
      }, 300);
    },

    escapeHtml: function (text) {
      var div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    },

    loadChatHistory: function () {
      // In a real implementation, you might load chat history from localStorage or server
      // For now, we'll just show the welcome message
    }
  };

})(AJS.$);
