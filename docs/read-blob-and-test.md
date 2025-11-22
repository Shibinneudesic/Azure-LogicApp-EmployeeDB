# Read blob and test locally

This document shows commands to download a flatfile from Azure Blob Storage using Azure CLI and how to test the existing Logic App workflow transformation locally.

Prerequisites:
- Azure CLI installed and logged in: `az login`
- You have access to the storage account and container
- `jq` or PowerShell built-ins can be used to parse JSON

1. Download blob to local file

```powershell
# Variables - replace these with your values
$storageAccount = "<storage-account-name>"
$container = "<container-name>"
$blobName = "<path/to/blob.csv>"
$localFile = "C:\temp\downloaded-flatfile.csv"

# Get storage account key (if using account key auth)
$accountKey = az storage account keys list --account-name $storageAccount --resource-group <resource-group> --query "[0].value" -o tsv

# Download the blob
az storage blob download `
  --account-name $storageAccount `
  --account-key $accountKey `
  --container-name $container `
  --name $blobName `
  --file $localFile

# If using Managed Identity / Azure AD auth, use:
# az storage blob download --account-name $storageAccount --container-name $container --name $blobName --file $localFile --auth-mode login

# Quick view
Get-Content $localFile -TotalCount 20
```

2. Example: simulate trigger payload used by `wf-flatfile-transformation/workflow.json`

```powershell
# Build a ServiceBus-like trigger body that holds the file content base64 encoded
$content = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($localFile))
$triggerPayload = @(
  @{
    properties = @{ FileName = $blobName }
    contentData = @{ "$content" = $content }
    messageId = "local-test"
    lockToken = "local-lock"
  }
) | ConvertTo-Json -Depth 10

$triggerPayload | Out-File -FilePath C:\temp\trigger-payload.json -Encoding utf8
```

3. Notes
- If your Logic App will be updated to read directly from Blob Storage, you'll replace the ServiceBus trigger and use a blob trigger and a `Get blob content` action. The `workflow.json` file is the ARM definition and must reference an existing managed connection (e.g., `azureblob`).
- Use MSI / Managed Identity where possible.
