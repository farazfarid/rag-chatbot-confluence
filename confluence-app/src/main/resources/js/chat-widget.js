/**
 * RAG Chatbot JavaScript functionality
 */
(function ($) {
  'use strict';

  window.RagChatWidget = {

    sessionId: null,
    isOpen: false,
    baseUrl: null,
    securityPatterns: [
      /(?:du bist|you are|act as|pretend|rolle|spielen|verhalten|imagine)/i,
      /(?:ignore|vergiss|vergessen|previous|früher|vorherig|instruction|anweisung)/i,
      /(?:system|admin|administrator|root|sudo|execute|ausführen|befehle|commands)/i,
      /(?:tell me|sag mir|erzähl|berichte).+(?:about|über|von).+(?:yourself|sich|dir|ihnen)/i,
      /(?:password|passwort|key|schlüssel|token|credential|anmelde|login|secret|geheim)/i,
      /(?:python|javascript|java|sql|bash|shell|cmd|powershell|exec)/i,
      /(?:but first|aber zuerst|however|jedoch|actually|eigentlich|instead|stattdessen)/i
    ],
    maxQueryLength: 500,

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

      // CLIENT-SIDE SECURITY VALIDATION
      var securityCheck = this.validateMessageSecurity(message);
      if (!securityCheck.valid) {
        this.addMessage(securityCheck.error, 'bot');
        input.val('');
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
        this.addMessage('Entschuldigung, ich bin auf einen Fehler gestoßen: ' + response.error, 'bot');
      } else if (response.response) {
        this.addMessage(response.response, 'bot');

        // Show sources if available
        if (response.sources && response.sources.length > 0) {
          this.addSourcesMessage(response.sources);
        }
      } else {
        this.addMessage('Entschuldigung, ich habe keine Antwort erhalten. Bitte versuchen Sie es erneut.', 'bot');
      }
    },

    handleChatError: function (xhr, status, error) {
      var errorMessage = 'Entschuldigung, ich habe Probleme beim Verbinden. Bitte versuchen Sie es später erneut.';

      if (xhr.status === 400) {
        errorMessage = 'Bitte überprüfen Sie Ihre Nachricht und versuchen Sie es erneut.';
      } else if (xhr.status === 503) {
        errorMessage = 'Der KI-Service ist vorübergehend nicht verfügbar. Bitte versuchen Sie es später erneut.';
      }

      this.addMessage(errorMessage, 'bot');
    },

    addSourcesMessage: function (sources) {
      var messagesContainer = $('#rag-chat-messages');
      var sourcesHtml = '<div class="rag-chat-message rag-chat-bot-message rag-sources-message">' +
        '<div class="rag-chat-message-content">' +
        '<p><strong>Quellen:</strong></p>' +
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

    validateMessageSecurity: function (message) {
      // Check message length
      if (message.length > this.maxQueryLength) {
        return {
          valid: false,
          error: 'Ihre Nachricht ist zu lang. Bitte halten Sie sich an ' + this.maxQueryLength + ' Zeichen.'
        };
      }

      // Check for jailbreak patterns
      for (var i = 0; i < this.securityPatterns.length; i++) {
        if (this.securityPatterns[i].test(message)) {
          return {
            valid: false,
            error: 'Ihre Nachricht enthält nicht erlaubte Inhalte. Bitte stellen Sie nur Fragen zu Ihrer Wissensdatenbank.'
          };
        }
      }

      // Check for basic topic relevance (client-side pre-filter)
      var knowledgeTerms = [
        'dokument', 'dokumentation', 'handbuch', 'anleitung', 'hilfe', 'wiki', 'confluence',
        'seite', 'inhalt', 'information', 'wissen', 'tutorial', 'guide', 'konfiguration',
        'einstellung', 'setup', 'installation', 'verwendung', 'funktion', 'problem',
        'lösung', 'fehler', 'support', 'frage', 'antwort', 'erklärung', 'aws', 'cloud',
        'server', 'service', 'dienst', 'api', 'system', 'datenbank', 'sicherheit'
      ];

      var hasRelevantTerm = false;
      var messageLower = message.toLowerCase();
      for (var j = 0; j < knowledgeTerms.length; j++) {
        if (messageLower.includes(knowledgeTerms[j])) {
          hasRelevantTerm = true;
          break;
        }
      }

      if (!hasRelevantTerm) {
        return {
          valid: false,
          error: 'Ihre Frage scheint nicht mit Ihrer Wissensdatenbank zusammenzuhängen. Bitte stellen Sie Fragen zu Ihren Dokumenten, Confluence-Seiten oder konfigurierten Wissensquellen.'
        };
      }

      return { valid: true };
    },

    loadChatHistory: function () {
      // In a real implementation, you might load chat history from localStorage or server
      // For now, we'll just show the welcome message
    },

    // S3 Logging Configuration Functions
    configureS3Logging: function (bucketName, region, accessKey, secretKey) {
      var self = this;

      var configData = {
        bucketName: bucketName,
        region: region,
        accessKey: accessKey,
        secretKey: secretKey,
        loggingEnabled: true
      };

      $.ajax({
        url: this.baseUrl + '/rest/rag/1.0/admin/s3-logging',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(configData),
        success: function (response) {
          if (response.success) {
            AJS.flag({
              type: 'success',
              title: 'S3 Logging konfiguriert',
              body: 'Die S3-Logging-Konfiguration wurde erfolgreich gespeichert. Bucket: ' + bucketName
            });
          } else {
            AJS.flag({
              type: 'error',
              title: 'Konfigurationsfehler',
              body: 'Fehler beim Konfigurieren des S3-Loggings: ' + (response.error || 'Unbekannter Fehler')
            });
          }
        },
        error: function (xhr, status, error) {
          AJS.flag({
            type: 'error',
            title: 'Verbindungsfehler',
            body: 'Fehler beim Speichern der S3-Konfiguration: ' + error
          });
        }
      });
    },

    toggleS3Logging: function (enabled) {
      var self = this;

      $.ajax({
        url: this.baseUrl + '/rest/rag/1.0/admin/s3-logging/toggle',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ enabled: enabled }),
        success: function (response) {
          if (response.success) {
            var status = enabled ? 'aktiviert' : 'deaktiviert';
            AJS.flag({
              type: 'success',
              title: 'S3 Logging ' + status,
              body: 'Das S3-Logging wurde erfolgreich ' + status + '.'
            });
          }
        },
        error: function (xhr, status, error) {
          AJS.flag({
            type: 'error',
            title: 'Fehler',
            body: 'Fehler beim Ändern der Logging-Einstellungen: ' + error
          });
        }
      });
    },

    getS3LoggingStats: function (callback) {
      $.ajax({
        url: this.baseUrl + '/rest/rag/1.0/admin/s3-logging/stats',
        type: 'GET',
        success: function (response) {
          if (callback) callback(response);
        },
        error: function (xhr, status, error) {
          console.error('Error fetching S3 logging stats:', error);
          if (callback) callback(null);
        }
      });
    },

    testS3Connection: function (callback) {
      $.ajax({
        url: this.baseUrl + '/rest/rag/1.0/admin/s3-logging/test',
        type: 'POST',
        success: function (response) {
          if (response.success) {
            AJS.flag({
              type: 'success',
              title: 'S3-Verbindung erfolgreich',
              body: 'Die Verbindung zu AWS S3 wurde erfolgreich getestet.'
            });
          } else {
            AJS.flag({
              type: 'error',
              title: 'S3-Verbindungstest fehlgeschlagen',
              body: 'Die S3-Verbindung konnte nicht hergestellt werden: ' + (response.error || 'Unbekannter Fehler')
            });
          }
          if (callback) callback(response.success);
        },
        error: function (xhr, status, error) {
          AJS.flag({
            type: 'error',
            title: 'Verbindungsfehler',
            body: 'Fehler beim Testen der S3-Verbindung: ' + error
          });
          if (callback) callback(false);
        }
      });
    },

    // Admin panel helper functions
    showS3ConfigDialog: function () {
      var dialogHtml = `
        <section role="dialog" id="s3-config-dialog" class="aui-layer aui-dialog2 aui-dialog2-medium" aria-hidden="true">
          <header class="aui-dialog2-header">
            <h2 class="aui-dialog2-header-main">S3 Logging Konfiguration</h2>
            <a class="aui-dialog2-header-close">
              <span class="aui-icon aui-icon-small aui-iconfont-close-dialog">Close</span>
            </a>
          </header>
          <div class="aui-dialog2-content">
            <form class="aui" id="s3-config-form">
              <div class="field-group">
                <label for="s3-bucket-name">S3 Bucket Name <span class="aui-icon icon-required">required</span></label>
                <input class="text" type="text" id="s3-bucket-name" name="bucketName" placeholder="confluence-rag-logs">
                <div class="description">Der S3-Bucket für Log-Dateien (wird automatisch erstellt, falls nicht vorhanden)</div>
              </div>
              <div class="field-group">
                <label for="s3-region">AWS Region <span class="aui-icon icon-required">required</span></label>
                <select class="select" id="s3-region" name="region">
                  <option value="eu-central-1">Europe (Frankfurt) - eu-central-1</option>
                  <option value="us-east-1">US East (N. Virginia) - us-east-1</option>
                  <option value="eu-west-1">Europe (Ireland) - eu-west-1</option>
                  <option value="us-west-2">US West (Oregon) - us-west-2</option>
                </select>
              </div>
              <div class="field-group">
                <label for="s3-access-key">AWS Access Key ID <span class="aui-icon icon-required">required</span></label>
                <input class="text" type="text" id="s3-access-key" name="accessKey" placeholder="AKIAIOSFODNN7EXAMPLE">
              </div>
              <div class="field-group">
                <label for="s3-secret-key">AWS Secret Access Key <span class="aui-icon icon-required">required</span></label>
                <input class="password" type="password" id="s3-secret-key" name="secretKey" placeholder="Ihr AWS Secret Key">
              </div>
              <div class="field-group">
                <input class="checkbox" type="checkbox" id="enable-logging" name="enableLogging" checked>
                <label for="enable-logging">S3-Logging aktivieren</label>
                <div class="description">Protokolliert alle Chat-Interaktionen und Sicherheitsereignisse</div>
              </div>
            </form>
          </div>
          <footer class="aui-dialog2-footer">
            <div class="aui-dialog2-footer-actions">
              <button id="s3-config-save" class="aui-button aui-button-primary">Speichern</button>
              <button id="s3-config-test" class="aui-button">Verbindung testen</button>
              <button id="s3-config-cancel" class="aui-button aui-button-link">Abbrechen</button>
            </div>
          </footer>
        </section>
      `;

      $('body').append(dialogHtml);

      // Show dialog
      AJS.dialog2('#s3-config-dialog').show();

      // Bind events
      var self = this;

      $('#s3-config-save').on('click', function () {
        var bucketName = $('#s3-bucket-name').val();
        var region = $('#s3-region').val();
        var accessKey = $('#s3-access-key').val();
        var secretKey = $('#s3-secret-key').val();

        if (!bucketName || !region || !accessKey || !secretKey) {
          AJS.flag({
            type: 'error',
            title: 'Eingabefehler',
            body: 'Bitte füllen Sie alle erforderlichen Felder aus.'
          });
          return;
        }

        self.configureS3Logging(bucketName, region, accessKey, secretKey);
        AJS.dialog2('#s3-config-dialog').hide();
      });

      $('#s3-config-test').on('click', function () {
        self.testS3Connection();
      });

      $('#s3-config-cancel').on('click', function () {
        AJS.dialog2('#s3-config-dialog').hide();
      });

      // Close dialog when clicking the X
      $('.aui-dialog2-header-close').on('click', function () {
        AJS.dialog2('#s3-config-dialog').hide();
      });
    }
  };

})(AJS.$);
