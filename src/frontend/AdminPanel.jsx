import React, { useState, useEffect } from 'react';
import ForgeReconciler, { Box, Text, Stack, TextField, Button, Table, Row, Cell, Dropdown, Option, Spinner } from '@forge/react';
import { invoke } from '@forge/bridge';

const AdminPanel = () => {
  const [settings, setSettings] = useState(null);
  const [documents, setDocuments] = useState([]);
  const [websites, setWebsites] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [newDocument, setNewDocument] = useState({ name: '', type: 'pdf', content: '', file: null });
  const [newWebsite, setNewWebsite] = useState({ url: '', title: '' });
  const [isUpdatingSettings, setIsUpdatingSettings] = useState(false);

  useEffect(() => {
    loadSettings();
    loadDocuments();
  }, []);

  const loadSettings = async () => {
    try {
      const response = await invoke('getSettings');
      if (response.success) {
        setSettings(response.settings);
      }
    } catch (error) {
      console.error('Error loading settings:', error);
    }
  };

  const loadDocuments = async () => {
    try {
      const response = await invoke('getDocuments');
      if (response.success) {
        setDocuments(response.documents);
        setWebsites(response.websites);
      }
    } catch (error) {
      console.error('Error loading documents:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const updateSettings = async () => {
    setIsUpdatingSettings(true);
    try {
      const response = await invoke('updateSettings', { settings });
      if (response.success) {
        alert('Settings updated successfully');
      }
    } catch (error) {
      console.error('Error updating settings:', error);
    } finally {
      setIsUpdatingSettings(false);
    }
  };

  const uploadDocument = async () => {
    if (!newDocument.name || !newDocument.file) return alert('Please provide document name and file');

    try {
      const fileReader = new FileReader();

      fileReader.onload = async (e) => {
        const base64Content = e.target.result.split(',')[1];
        const response = await invoke('uploadDocument', {
          file: base64Content,
          title: newDocument.name,
          type: newDocument.type,
          source: 'Admin Upload'
        });

        if (response.success) {
          alert('Document uploaded successfully');
          loadDocuments();
        }
      };

      fileReader.readAsDataURL(newDocument.file);
    } catch (error) {
      console.error('Error uploading document:', error);
    }
  };

  const addWebsite = async () => {
    if (!newWebsite.url || !newWebsite.title) return alert('Please provide website URL and title');

    try {
      const response = await invoke('addWebsite', newWebsite);
      if (response.success) {
        alert('Website added successfully');
        loadDocuments();
      }
    } catch (error) {
      console.error('Error adding website:', error);
    }
  };

  const handleFileChange = (event) => {
    const file = event.target.files[0];
    setNewDocument((prev) => ({ ...prev, file }));
  };

  const deleteDocument = async (id, type) => {
    try {
      const shouldDelete = confirm('Are you sure you want to delete this item?');
      if (!shouldDelete) return;

      const response = await invoke('deleteDocument', { documentId: id, type });
      if (response.success) {
        alert('Document deleted successfully');
        loadDocuments();
      }
    } catch (error) {
      console.error('Error deleting document:', error);
    }
  };

  return (
    <Box xcss={{ padding: '20px', maxWidth: '800px', margin: '0 auto' }}>
      <Text xcss={{ fontSize: '24px', fontWeight: 'bold', marginBottom: '12px' }}>Admin Panel</Text>

      {/* Chatbot Settings */}
      <Box xcss={{ marginBottom: '24px' }}>
        <Text xcss={{ fontSize: '18px', fontWeight: 'bold' }}>Chatbot Settings</Text>

        {settings ? (
          <Stack space="medium">
            <TextField
              label="Chatbot Name"
              value={settings.chatbotName}
              onChange={(value) => setSettings((prev) => ({ ...prev, chatbotName: value }))}
            />

            <TextField
              label="Welcome Message"
              value={settings.welcomeMessage}
              onChange={(value) =>
                setSettings((prev) => ({ ...prev, welcomeMessage: value }))
              }
            />

            <TextField
              label="Primary Color"
              value={settings.theme.primaryColor}
              onChange={(value) =>
                setSettings((prev) => ({ ...prev, theme: { ...prev.theme, primaryColor: value } }))
              }
            />

            <Button
              isLoading={isUpdatingSettings}
              appearance="primary"
              onClick={updateSettings}
            >
              Update Settings
            </Button>
          </Stack>
        ) : (
          <Spinner size="large" />
        )}
      </Box>

      {/* Document Management */}
      <Box xcss={{ marginBottom: '24px' }}>
        <Text xcss={{ fontSize: '18px', fontWeight: 'bold' }}>Document Management</Text>

        <Stack space="medium">
          <Box xcss={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <TextField
              label="Document Name"
              value={newDocument.name}
              onChange={(value) => setNewDocument((prev) => ({ ...prev, name: value }))}
            />
            <Dropdown
              label="Document Type"
              value={newDocument.type}
              onChange={(value) => setNewDocument((prev) => ({ ...prev, type: value }))}
            >
              <Option label="PDF" value="pdf" />
              <Option label="Word Document" value="docx" />
              <Option label="Text" value="txt" />
            </Dropdown>
            <input type="file" onChange={handleFileChange} />
            <Button appearance="primary" onClick={uploadDocument}>
              Upload Document
            </Button>
          </Box>

          <Table>
            <Row>
              <Cell header>Title</Cell>
              <Cell header>Type</Cell>
              <Cell header>Source</Cell>
              <Cell header>Actions</Cell>
            </Row>
            {!isLoading ? (
              documents.map((doc) => (
                <Row key={doc.id}>
                  <Cell>{doc.title}</Cell>
                  <Cell>{doc.type}</Cell>
                  <Cell>{doc.source}</Cell>
                  <Cell>
                    <Button onClick={() => deleteDocument(doc.id, 'document')}>Delete</Button>
                  </Cell>
                </Row>
              ))
            ) : (
              <Spinner size="large" />
            )}
          </Table>
        </Stack>
      </Box>

      {/* Website Management */}
      <Box>
        <Text xcss={{ fontSize: '18px', fontWeight: 'bold' }}>Website Management</Text>

        <Stack space="medium">
          <TextField
            label="Website URL"
            value={newWebsite.url}
            onChange={(value) => setNewWebsite((prev) => ({ ...prev, url: value }))}
          />
          <TextField
            label="Website Title"
            value={newWebsite.title}
            onChange={(value) => setNewWebsite((prev) => ({ ...prev, title: value }))}
          />
          <Button appearance="primary" onClick={addWebsite}>
            Add Website
          </Button>

          <Table>
            <Row>
              <Cell header>Title</Cell>
              <Cell header>URL</Cell>
              <Cell header>Actions</Cell>
            </Row>
            {!isLoading ? (
              websites.map((site) => (
                <Row key={site.id}>
                  <Cell>{site.title}</Cell>
                  <Cell>{site.source}</Cell>
                  <Cell>
                    <Button onClick={() => deleteDocument(site.id, 'website')}>Delete</Button>
                  </Cell>
                </Row>
              ))
            ) : (
              <Spinner size="large" />
            )}
          </Table>
        </Stack>
      </Box>
    </Box>
  );
};

ForgeReconciler.render(
  <React.StrictMode>
    <AdminPanel />
  </React.StrictMode>
);

export default AdminPanel;

