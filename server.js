const express = require('express');
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');

const app = express();
const port = process.env.PORT || 3000;

// Expect KEYVAULT_URI like "https://<kv-name>.vault.azure.net/"
const keyVaultUri = process.env.KEYVAULT_URI;
const secretName = process.env.SECRET_NAME || 'app-message';

if (!keyVaultUri) {
  console.warn('KEYVAULT_URI is not set. The app will still run but cannot fetch secrets.');
}

const credential = new DefaultAzureCredential();

app.get('/healthz', (req, res) => res.status(200).send('OK'));

app.get('/', async (req, res) => {
  try {
    if (!keyVaultUri) {
      return res
        .status(500)
        .send('KEYVAULT_URI environment variable is not set on the Web App.');
    }
    const client = new SecretClient(keyVaultUri, credential);
    const latestSecret = await client.getSecret(secretName);
    res.send(`Hello! Secret "${secretName}" value is: ${latestSecret.value}`);
  } catch (err) {
    console.error('Error fetching secret:', err.message);
    res.status(500).send(`Error fetching secret "${secretName}": ${err.message}`);
  }
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
