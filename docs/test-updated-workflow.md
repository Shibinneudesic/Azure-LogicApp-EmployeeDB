# Test Updated wf-flatfile-transformation Workflow (Blob-read)

This guide helps you test the modified `wf-flatfile-transformation/workflow.json` which now supports direct reads from Azure Blob Storage while retaining the Service Bus trigger as a fallback.

Prerequisites:
- Azure CLI installed and logged in: `az login`
- Required permissions to the Logic App and Storage Account
- The Logic App `connections` include a managed connection named `azureblob` (or update to your connection name in the workflow)

1. Verify the `azureblob` connection exists

```powershell
# List connections for the resource group/logic app's site
az webapp connection show --name <logicapp-name> --resource-group <resource-group> -o json
# Or check connections.json files in repo for default names: 'azureblob' expected
Get-Content .\connections.azure.json
```

2. Download a blob locally (use this to simulate payloads)

```powershell
$storageAccount = "<storage-account>"
$resourceGroup = "<rg>"
$container = "<container>"
$blobName = "<path/to/blob.csv>"
$localFile = "C:\temp\downloaded-flatfile.csv"

# If using Azure AD auth
az storage blob download --account-name $storageAccount --container-name $container --name $blobName --file $localFile --auth-mode login

# Quick preview
Get-Content $localFile -TotalCount 20
```

3. Simulate Service Bus trigger payload (local test)

```powershell
$content = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($localFile))
$payload = @(
  @{
    properties = @{ FileName = $blobName }
    contentData = @{ "$content" = $content }
    messageId = "local-test"
    lockToken = "local-lock"
  }
) | ConvertTo-Json -Depth 10

$payload | Out-File C:\temp\trigger-payload.json -Encoding utf8
```

4. Deploy updated workflow (ARM deployment) - replace placeholders

```powershell
$rg = "<resource-group>"
$templateFile = "wf-flatfile-transformation/workflow.json"
az deployment group create --resource-group $rg --template-file $templateFile --parameters connections_azureblob_name=azureblob
```

5. Triggering the Logic App
- If using blob trigger, upload the blob to the container specified in your logic app connections and the managed ApiConnection should trigger the workflow.
- For local testing, you can POST the simulated Service Bus payload to the Logic App run trigger endpoint (if enabled) or use the Logic App run->Trigger history in the portal.

6. Verify outputs
- Check run history in Azure Portal -> Logic App -> Runs history
- Inspect `Debug_ContentData_Check` compose output to see whether `hasBlobContentOutput` is true or fallback used

7. Troubleshooting
- If `azureblob` connection not available, create it using `Create-AzureQueues-Connection.ps1` pattern but for blob, or create managed connector in portal.
- Ensure the Logic App has Managed Identity and the Storage Account grants it `Storage Blob Data Reader` role.


If you want, I can also:
- Update the workflow to use a specific connection name other than `azureblob`.
- Replace the Service Bus trigger entirely with a blob trigger (requires confirming trigger semantics).
