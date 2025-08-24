# Azure Web App + Key Vault (Public) with Azure DevOps CI/CD

This sample creates:
- **Azure App Service (Linux, Node.js)** publicly accessible.
- **Azure Key Vault** with **public network access enabled** (for demo; restrict in production).
- **System-assigned managed identity** on the Web App with **Secrets get/list** permission on the Key Vault.
- A **Node.js** app that reads a secret (`app-message`) at runtime from Key Vault.
- An **Azure DevOps pipeline** to provision infra (Bicep) and deploy the app.

## Repo structure

```
infra/
  main.bicep     # subscription-scope: creates RG and deploys rg.bicep
  rg.bicep       # resource-group scope: plan, web app (with MSI), key vault, secret
app/
  package.json
  server.js      # Express app uses DefaultAzureCredential + SecretClient
azure-pipelines.yml
```

## Prerequisites

- Azure subscription with permissions to deploy resources at **subscription scope**.
- Azure DevOps project with an **Azure Resource Manager** service connection (name it `sc-azure` or change the YAML).
- Either free-hosted agent parallelism or a **self-hosted** agent.
- Node 18+ only for local testing (optional).

## Configure Azure DevOps

1. Create a **Service connection** → Azure Resource Manager → use automatic SP creation → name it `sc-azure`.
2. Create a new Pipeline from this repo.
3. In pipeline **Variables**, add:
   - `appMessage` (secret) → set any message you want the app to display.
   - (Optional) customize: `location`, `rgName`, `planName`, `appName`, `kvName`, `secretName`.
4. Run the pipeline.

The infra stage will:
- Create resource group `rgName` in `location`.
- Create **App Service plan** and **Web App** (Linux Node 18), enable **Managed Identity**.
- Create **Key Vault** with **public access enabled**, allow `AzureServices`, and set **access policy** for the web app identity (secrets get/list).
- Create the initial secret `secretName` with value from pipeline variable `appMessage`.

The deploy stage will push the Node app and you can browse it at:

```
https://<appName>.azurewebsites.net/
```

Expected response: `Hello! Secret "app-message" value is: <your message>`

## Local test (optional)

```bash
cd app
npm install
# For local test, you need Azure CLI login and `az account get-access-token` or Azure Developer CLI/Managed Identity.
# Or set environment variables and use a Service Principal with permissions.
# Typically you'd test in App Service since MSI is enabled there.
npm start
```

## Notes

- **Public access** to Key Vault is intentionally enabled for this demo:
  - `publicNetworkAccess: Enabled`
  - `networkAcls.defaultAction: Allow` (and `bypass: AzureServices`)
- For **production**, tighten network rules (e.g., `defaultAction: Deny`, Private Endpoint, or trusted services only).
- The Web App uses **Managed Identity** → no secrets or credentials in code.
- The Bicep templates are idempotent — re-running will update resources in place.
# SalesWebapps
