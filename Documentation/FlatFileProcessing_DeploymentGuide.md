# Flat File Processing Workflows - Deployment Guide

## Overview
This solution implements asynchronous flat file (CSV) processing using Azure Logic Apps Standard with two workflows:

### Architecture
```
File Server (CSV) → On-Premise Gateway → Workflow 1 (Validation) → Service Bus Queue 
                                                                           ↓
                                                                    Workflow 2 (Transform)
                                                                           ↓
                                                        ┌──────────────────┴──────────────────┐
                                                        ↓                                      ↓
                                            Storage Queue (XML)                   Storage Queue (JSON)
```

## Workflows

### Workflow 1: wf-flatfile-pickup
**Purpose**: File ingestion, validation, and Service Bus queuing  
**Trigger**: File System connector (when CSV file is created)  
**Key Features**:
- Monitors on-premise file server via Data Gateway
- Validates file size (1 byte - 10 MB)
- Sends valid files to Service Bus queue
- Implements error handling with dead-letter queue
- Uses Scopes for transaction management

### Workflow 2: wf-flatfile-transformation
**Purpose**: Transform CSV to XML and JSON, send to Storage Queues  
**Trigger**: Service Bus queue message received  
**Key Features**:
- Parallel transformation (XSLT for XML, Liquid for JSON)
- Sends transformed messages to separate Storage queues
- Message completion/dead-lettering
- Comprehensive error handling
- Correlation ID tracking across workflows

## Prerequisites

### Azure Resources Required
1. **Logic App Standard** (existing: ais-training-la)
2. **Service Bus Namespace** with queues:
   - `flatfile-processing-queue` (main processing)
   - `flatfile-deadletter-queue` (error handling)
3. **Storage Account** with queues:
   - `flatfile-xml-queue`
   - `flatfile-json-queue`
4. **On-Premise Data Gateway** (installed on file server)
5. **Integration Account** (optional, for sharing maps across workflows)
6. **File Server** with folder: `C:\EmployeeFiles` (or configured path)

### Required Permissions
- Logic App Managed Identity needs:
  - Service Bus Data Sender/Receiver roles
  - Storage Queue Data Contributor role
  - Data Gateway access

## Deployment Steps

### Step 1: Create Azure Resources

#### 1.1 Create Service Bus Namespace and Queues
```powershell
# Set variables
$resourceGroup = "AIS_Training_Shibin"
$location = "canadacentral"
$serviceBusNamespace = "sb-flatfile-processing"
$subscriptionId = "cbb1dbec-731f-4479-a084-bdaec5e54fd4"

# Create Service Bus Namespace (Standard tier for message sessions)
az servicebus namespace create `
  --resource-group $resourceGroup `
  --name $serviceBusNamespace `
  --location $location `
  --sku Standard

# Create queues
az servicebus queue create `
  --resource-group $resourceGroup `
  --namespace-name $serviceBusNamespace `
  --name flatfile-processing-queue `
  --max-size 1024 `
  --default-message-time-to-live P14D `
  --lock-duration PT5M `
  --max-delivery-count 10

az servicebus queue create `
  --resource-group $resourceGroup `
  --namespace-name $serviceBusNamespace `
  --name flatfile-deadletter-queue `
  --max-size 1024 `
  --default-message-time-to-live P14D

# Get connection string
$connectionString = az servicebus namespace authorization-rule keys list `
  --resource-group $resourceGroup `
  --namespace-name $serviceBusNamespace `
  --name RootManageSharedAccessKey `
  --query primaryConnectionString `
  --output tsv

Write-Host "Service Bus Connection String: $connectionString"
```

#### 1.2 Create Storage Queues
```powershell
# Set variables
$storageAccountName = "stflatfileprocessing"

# Create storage account
az storage account create `
  --name $storageAccountName `
  --resource-group $resourceGroup `
  --location $location `
  --sku Standard_LRS `
  --kind StorageV2

# Get connection string
$storageConnectionString = az storage account show-connection-string `
  --name $storageAccountName `
  --resource-group $resourceGroup `
  --query connectionString `
  --output tsv

# Create queues
az storage queue create `
  --name flatfile-xml-queue `
  --connection-string $storageConnectionString

az storage queue create `
  --name flatfile-json-queue `
  --connection-string $storageConnectionString

Write-Host "Storage Connection String: $storageConnectionString"
```

### Step 2: Install and Configure On-Premise Data Gateway

#### 2.1 Install Gateway
1. Download from: https://aka.ms/on-premises-data-gateway
2. Install on Windows machine with access to file server
3. Sign in with Azure credentials
4. Register gateway with name: `gateway-flatfile-processing`

#### 2.2 Create Gateway Resource in Azure
```powershell
$gatewayName = "gateway-flatfile-processing"
$gatewayLocation = "canadacentral"

# Note: Gateway resource is created through the portal after installation
# Navigate to: Azure Portal → Create Resource → On-premises data gateway
```

### Step 3: Configure Logic App Settings

Update `local.settings.json` for local development:
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet",
    "SERVICE_BUS_CONNECTION_STRING": "<your-service-bus-connection-string>",
    "STORAGE_ACCOUNT_CONNECTION_STRING": "<your-storage-connection-string>",
    "ONPREMISE_FILE_USERNAME": "<domain\\username>",
    "ONPREMISE_FILE_PASSWORD": "<password>",
    "ONPREMISE_GATEWAY_ID": "<gateway-resource-id>"
  }
}
```

For Azure deployment, add Application Settings:
```powershell
$logicAppName = "ais-training-la"

az logicapp config appsettings set `
  --name $logicAppName `
  --resource-group $resourceGroup `
  --settings `
    SERVICE_BUS_CONNECTION_STRING="<connection-string>" `
    STORAGE_ACCOUNT_CONNECTION_STRING="<connection-string>" `
    ONPREMISE_FILE_USERNAME="<username>" `
    ONPREMISE_FILE_PASSWORD="<password>" `
    ONPREMISE_GATEWAY_ID="/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/connectionGateways/$gatewayName"
```

### Step 4: Assign Managed Identity Permissions

```powershell
$logicAppName = "ais-training-la"
$serviceBusNamespace = "sb-flatfile-processing"
$storageAccountName = "stflatfileprocessing"

# Get Logic App Managed Identity
$logicAppIdentity = az logicapp identity show `
  --name $logicAppName `
  --resource-group $resourceGroup `
  --query principalId `
  --output tsv

# Assign Service Bus roles
az role assignment create `
  --assignee $logicAppIdentity `
  --role "Azure Service Bus Data Sender" `
  --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ServiceBus/namespaces/$serviceBusNamespace"

az role assignment create `
  --assignee $logicAppIdentity `
  --role "Azure Service Bus Data Receiver" `
  --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ServiceBus/namespaces/$serviceBusNamespace"

# Assign Storage Queue roles
az role assignment create `
  --assignee $logicAppIdentity `
  --role "Storage Queue Data Contributor" `
  --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
```

### Step 5: Upload Maps to Logic App

Maps are located in `Artifacts/Maps/`:
- `EmployeeCSVToXML.xslt` - XSLT transformation for XML
- `EmployeeCSVToJSON.liquid` - Liquid template for JSON

For Logic Apps Standard, maps are deployed with the application in the Artifacts folder.

### Step 6: Deploy Logic App

#### Option 1: Visual Studio Code
1. Open project in VS Code
2. Install Azure Logic Apps (Standard) extension
3. Right-click on project → Deploy to Logic App
4. Select subscription and Logic App resource

#### Option 2: Azure CLI with ZIP deployment
```powershell
# Navigate to project directory
cd "c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee"

# Create deployment package
Compress-Archive -Path * -DestinationPath flatfile-workflows.zip -Force

# Deploy to Logic App
az logicapp deployment source config-zip `
  --name $logicAppName `
  --resource-group $resourceGroup `
  --src flatfile-workflows.zip
```

### Step 7: Enable Workflows

After deployment:
1. Go to Azure Portal → Logic App → Workflows
2. Enable workflows:
   - `wf-flatfile-pickup`
   - `wf-flatfile-transformation`
3. Verify connections are authenticated

## Configuration

### File System Configuration
- **Folder Path**: `C:\EmployeeFiles` (configurable in workflow)
- **File Pattern**: `*.csv`
- **Polling Interval**: Every 5 minutes

### Service Bus Configuration
- **Queue**: `flatfile-processing-queue`
- **Max Delivery Count**: 10
- **Lock Duration**: 5 minutes
- **Message TTL**: 14 days

### Storage Queue Configuration
- **XML Queue**: `flatfile-xml-queue`
- **JSON Queue**: `flatfile-json-queue`
- **Message Encoding**: Base64

## Testing

### Test Workflow 1 (File Pickup)
```powershell
# 1. Prepare test CSV file
$testFile = "c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee\Artifacts\employees.csv"

# 2. Copy to monitored folder (via file server or mapped drive)
Copy-Item $testFile "\\<file-server>\EmployeeFiles\test-$(Get-Date -Format 'yyyyMMddHHmmss').csv"

# 3. Check workflow runs in Azure Portal
# Logic App → wf-flatfile-pickup → Run History

# 4. Verify message in Service Bus queue
az servicebus queue show `
  --resource-group $resourceGroup `
  --namespace-name $serviceBusNamespace `
  --name flatfile-processing-queue `
  --query messageCount
```

### Test Workflow 2 (Transformation)
```powershell
# Check workflow runs
# Logic App → wf-flatfile-transformation → Run History

# Verify messages in Storage Queues
az storage queue list `
  --connection-string $storageConnectionString `
  --query "[].{Name:name, Count:metadata.approximateMessageCount}"

# Peek at XML queue message
az storage message peek `
  --queue-name flatfile-xml-queue `
  --connection-string $storageConnectionString `
  --num-messages 1

# Peek at JSON queue message
az storage message peek `
  --queue-name flatfile-json-queue `
  --connection-string $storageConnectionString `
  --num-messages 1
```

## Monitoring and Troubleshooting

### Application Insights Queries

#### Recent Workflow Runs
```kql
requests
| where timestamp > ago(24h)
| where name contains "wf-flatfile"
| project timestamp, name, resultCode, duration
| order by timestamp desc
```

#### Transformation Errors
```kql
traces
| where timestamp > ago(24h)
| where message contains "Transform" or message contains "Error"
| project timestamp, message, severityLevel
| order by timestamp desc
```

#### Service Bus Message Flow
```kql
dependencies
| where timestamp > ago(24h)
| where type == "Azure Service Bus"
| project timestamp, name, data, duration, success
| order by timestamp desc
```

### Common Issues

#### Issue 1: File Not Picked Up
**Symptoms**: File created but workflow doesn't trigger  
**Solutions**:
- Verify Data Gateway is running
- Check file path matches workflow configuration
- Ensure file extension is `.csv`
- Check Gateway connection in Logic App

#### Issue 2: Service Bus Connection Failed
**Symptoms**: "Unauthorized" or connection errors  
**Solutions**:
- Verify connection string in app settings
- Check Managed Identity has proper roles
- Ensure Service Bus namespace is accessible
- Verify queue names match configuration

#### Issue 3: Transformation Failed
**Symptoms**: Messages in dead-letter queue  
**Solutions**:
- Check CSV format matches expected schema
- Verify XSLT/Liquid maps are deployed
- Check map syntax errors
- Review error message in dead-letter queue

#### Issue 4: Storage Queue Not Receiving Messages
**Symptoms**: Transformation succeeds but queues empty  
**Solutions**:
- Verify Storage Queue connection string
- Check Managed Identity permissions
- Ensure queue names are correct
- Check for throttling in Storage Account

## Naming Conventions (2025 Best Practices)

### Resources
- Logic App: `la-<purpose>-<env>`
- Service Bus: `sb-<purpose>-<env>`
- Storage Account: `st<purpose><env>` (no dashes, lowercase)
- Queues: `<purpose>-<type>-queue` (kebab-case)
- Gateway: `gateway-<purpose>-<env>`

### Workflows
- Prefix: `wf-` (workflow)
- Purpose: Clear, descriptive name
- Example: `wf-flatfile-pickup`, `wf-flatfile-transformation`

### Variables
- PascalCase: `CorrelationId`, `ErrorMessage`
- Descriptive: Avoid abbreviations

### Scopes
- Prefix: `Scope_`
- Purpose: `Scope_FileProcessing`, `Scope_ErrorHandling`

## Maintenance

### Regular Tasks
1. **Monitor dead-letter queues** - Review failed messages weekly
2. **Check logs** - Review Application Insights for errors
3. **Gateway updates** - Keep Data Gateway updated
4. **Performance tuning** - Adjust polling intervals based on volume
5. **Clean up queues** - Archive old messages

### Scaling Considerations
- **High Volume**: Increase Logic App plan to Premium
- **Larger Files**: Adjust file size limits in validation
- **Parallel Processing**: Enable workflow parallelism
- **Geographic Distribution**: Deploy to multiple regions

## Best Practices Applied

1. ✅ **Asynchronous Processing**: Service Bus decouples workflows
2. ✅ **Error Handling**: Scopes with try-catch pattern
3. ✅ **Retry Policies**: Built-in connector retry mechanisms
4. ✅ **Dead-Lettering**: Failed messages sent to DLQ for analysis
5. ✅ **Correlation Tracking**: CorrelationId passed between workflows
6. ✅ **Parallel Execution**: XML and JSON transformations run concurrently
7. ✅ **Idempotency**: Message completion prevents duplicate processing
8. ✅ **Secure Connections**: Managed Identity for Azure resources
9. ✅ **Monitoring**: Application Insights integration
10. ✅ **Validation**: File size and content checks before processing

## Support and Documentation

- **Azure Logic Apps Docs**: https://learn.microsoft.com/en-us/azure/logic-apps/
- **Service Bus Docs**: https://learn.microsoft.com/en-us/azure/service-bus-messaging/
- **Data Gateway Docs**: https://learn.microsoft.com/en-us/data-integration/gateway/
- **XSLT Reference**: https://www.w3.org/TR/xslt-30/
- **Liquid Reference**: https://shopify.github.io/liquid/

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-09 | 1.0 | Initial creation with 2025 best practices |

---
**Created by**: GitHub Copilot  
**Date**: November 9, 2025  
**Logic App**: ais-training-la  
**Resource Group**: AIS_Training_Shibin
