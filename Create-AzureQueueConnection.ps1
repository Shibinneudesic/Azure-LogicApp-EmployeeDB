# Create Azure Queue Storage Connection for Logic App
# This creates the managed API connection for Azure Storage Queues

$resourceGroup = "AIS_Training_Shibin"
$location = "canadacentral"
$connectionName = "azurequeues"
$storageAccountName = "aistrainingshibinbf12"
$subscriptionId = "cbb1dbec-731f-4479-a084-bdaec5e54fd4"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Creating Azure Queue Connection" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Get storage account resource ID
Write-Host "Getting storage account details..." -ForegroundColor Yellow
$storageAccountId = az storage account show `
  --name $storageAccountName `
  --resource-group $resourceGroup `
  --query id `
  --output tsv

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get storage account" -ForegroundColor Red
    exit 1
}

Write-Host "Storage Account ID: $storageAccountId" -ForegroundColor Gray

# Create the connection using ARM template
Write-Host "`nCreating Azure Queue connection..." -ForegroundColor Yellow

$connectionJson = @{
    properties = @{
        displayName = $connectionName
        statuses = @(
            @{
                status = "Connected"
            }
        )
        customParameterValues = @{}
        nonSecretParameterValues = @{
            storageaccount = $storageAccountName
        }
        parameterValueType = "Alternative"
        alternativeParameterValues = @{
            storageaccount = $storageAccountName
        }
        api = @{
            name = "azurequeues"
            displayName = "Azure Queues"
            description = "Azure Queue storage provides cloud messaging between application components. Queue storage also supports managing asynchronous tasks and building process work flows."
            iconUri = "https://connectoricons-prod.azureedge.net/releases/v1.0.1697/1.0.1697.3786/azurequeues/icon.png"
            brandColor = "#0072C6"
            id = "/subscriptions/$subscriptionId/providers/Microsoft.Web/locations/$location/managedApis/azurequeues"
            type = "Microsoft.Web/locations/managedApis"
        }
    }
    location = $location
} | ConvertTo-Json -Depth 10

# Save to temp file
$tempFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tempFile -Value $connectionJson

# Create connection
az resource create `
  --resource-group $resourceGroup `
  --resource-type "Microsoft.Web/connections" `
  --name $connectionName `
  --properties "@$tempFile" `
  --location $location

Remove-Item $tempFile -Force

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Azure Queue connection created successfully!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Failed to create connection" -ForegroundColor Red
    Write-Host "`nAlternative: Create manually in Azure Portal:" -ForegroundColor Yellow
    Write-Host "1. Go to Logic App → Connections" -ForegroundColor White
    Write-Host "2. Click '+ Add'" -ForegroundColor White
    Write-Host "3. Search for 'Azure Queues'" -ForegroundColor White
    Write-Host "4. Select 'Use Managed Identity' authentication" -ForegroundColor White
    Write-Host "5. Select storage account: $storageAccountName" -ForegroundColor White
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Next Step: Grant Permissions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nYou need to ask your Azure admin to grant these permissions:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Service Principal: ais-training-la" -ForegroundColor White
Write-Host "Principal ID: 99ded633-38c2-4f05-a41c-7ba48aed3285" -ForegroundColor White
Write-Host ""
Write-Host "Required Role Assignments:" -ForegroundColor Cyan
Write-Host "1. Azure Service Bus Data Owner" -ForegroundColor White
Write-Host "   Scope: /subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ServiceBus/namespaces/sb-flatfile-processing" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Storage Queue Data Contributor" -ForegroundColor White
Write-Host "   Scope: /subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName" -ForegroundColor Gray
Write-Host ""
Write-Host "Commands for admin:" -ForegroundColor Yellow
Write-Host @"
# Service Bus permissions
az role assignment create \
  --assignee 99ded633-38c2-4f05-a41c-7ba48aed3285 \
  --role "Azure Service Bus Data Owner" \
  --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ServiceBus/namespaces/sb-flatfile-processing

# Storage Queue permissions
az role assignment create \
  --assignee 99ded633-38c2-4f05-a41c-7ba48aed3285 \
  --role "Storage Queue Data Contributor" \
  --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName
"@ -ForegroundColor Gray

Write-Host "`n========================================`n" -ForegroundColor Cyan
