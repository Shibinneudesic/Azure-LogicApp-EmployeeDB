# Azure Resources - Current Configuration
**Updated**: November 10, 2025

## Logic App Standard
- **Name**: `ais-training-la`
- **Resource Group**: `AIS_Training_Shibin`
- **Location**: Canada Central
- **State**: Running
- **Kind**: functionapp,workflowapp
- **URL**: `https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net`

## App Service Plan
- **Name**: `ASP-AISTrainingShibin-b7e4`
- **SKU**: WS1 (WorkflowStandard)
- **Tier**: WorkflowStandard
- **Location**: Canada Central
- **Resource ID**: `/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/serverfarms/ASP-AISTrainingShibin-b7e4`

## Alternative App Service Plan (Available)
- **Name**: `LogicAppServicePlan`
- **SKU**: P1v3
- **Tier**: PremiumV3
- **Location**: Canada Central

## Storage Account (Single Account for Everything)
- **Name**: `aistrainingshibinbf12`
- **SKU**: Standard_LRS
- **Location**: Canada Central
- **Usage**: 
  - Logic App runtime storage
  - File share for Logic App content
  - Storage queues for flat file processing (XML and JSON queues)

**Note**: You only need ONE storage account. The same storage account handles Logic App runtime AND the flat file processing queues.

## Monitoring & Logging

### Log Analytics Workspace
- **Name**: `LAStd-UpsertEmployee-Logs`
- **SKU**: PerGB2018
- **Location**: Canada Central
- **Workspace ID**: `8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c`
- **Retention**: 30 days

### Application Insights
- **Name**: `ais-training-la`
- **Type**: web
- **Location**: Canada Central
- **Instrumentation Key**: `714a6b4e-1c59-40c2-aba0-5d9f4ccd220d`
- **Connection String**: `InstrumentationKey=714a6b4e-1c59-40c2-aba0-5d9f4ccd220d;IngestionEndpoint=https://canadacentral-1.in.applicationinsights.azure.com/;LiveEndpoint=https://canadacentral.livediagnostics.monitor.azure.com/;ApplicationId=4aedfd7f-b888-4b64-96ff-92e453c0d91f`
- **Linked to**: LAStd-UpsertEmployee-Logs workspace
- **Ingestion Mode**: LogAnalytics

**Configuration in Logic App**:
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Full connection string
- `APPINSIGHTS_INSTRUMENTATIONKEY` - Instrumentation key for legacy support

## Subscription Details
- **Subscription ID**: `cbb1dbec-731f-4479-a084-bdaec5e54fd4`
- **Resource Group**: `AIS_Training_Shibin`
- **Location**: Canada Central

## Existing Workflows
- `wf-employee-upsert` - Employee upsert workflow (existing)

## New Workflows (Ready to Deploy)
- `wf-flatfile-pickup` - File ingestion and validation
- `wf-flatfile-transformation` - CSV to XML/JSON transformation

## Configuration Files Updated
✅ `infra/main.parameters.json` - Updated App Service Plan name
✅ `infra/main.bicep` - Updated App Service Plan name
✅ `infra/main.json` - Updated App Service Plan name

## Next Steps for Deployment

### 1. Create Required Azure Resources

#### Service Bus Namespace
```powershell
$resourceGroup = "AIS_Training_Shibin"
$location = "canadacentral"
$serviceBusNamespace = "sb-flatfile-processing"

# Create Service Bus Namespace
az servicebus namespace create `
  --resource-group $resourceGroup `
  --name $serviceBusNamespace `
  --location $location `
  --sku Standard

# Create queues
az servicebus queue create `
  --resource-group $resourceGroup `
  --namespace-name $serviceBusNamespace `
  --name flatfile-processing-queue

az servicebus queue create `
  --resource-group $resourceGroup `
  --namespace-name $serviceBusNamespace `
  --name flatfile-deadletter-queue
```

#### Storage Queues (Use Existing Storage Account)
```powershell
# Use the SAME storage account as Logic App runtime
$storageAccountName = "aistrainingshibinbf12"

# Create queues for flat file processing
az storage queue create `
  --name flatfile-xml-queue `
  --account-name $storageAccountName

az storage queue create `
  --name flatfile-json-queue `
  --account-name $storageAccountName
```

### 2. Deploy Workflows to Logic App

#### Option A: VS Code Deployment
1. Open project in VS Code
2. Install Azure Logic Apps (Standard) extension
3. Right-click on project → Deploy to Logic App
4. Select `ais-training-la`

#### Option B: Azure CLI ZIP Deployment
```powershell
cd "c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee"

# Create deployment package (exclude git, tests, etc.)
$exclude = @('.git', '.vscode', 'node_modules', 'TestFiles', 'Documentation')
Compress-Archive -Path * -DestinationPath flatfile-workflows.zip -Force

# Deploy
az logicapp deployment source config-zip `
  --name ais-training-la `
  --resource-group AIS_Training_Shibin `
  --src flatfile-workflows.zip
```

### 3. Configure Connections

#### Update Application Settings
```powershell
az logicapp config appsettings set `
  --name ais-training-la `
  --resource-group AIS_Training_Shibin `
  --settings `
    SERVICE_BUS_CONNECTION_STRING="<get-from-service-bus>" `
    ONPREMISE_FILE_USERNAME="<domain\username>" `
    ONPREMISE_FILE_PASSWORD="<password>" `
    ONPREMISE_GATEWAY_ID="/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/connectionGateways/<gateway-name>"
```

#### Assign Managed Identity Roles
```powershell
# Get Logic App Managed Identity
$principalId = az logicapp identity show `
  --name ais-training-la `
  --resource-group AIS_Training_Shibin `
  --query principalId `
  --output tsv

# Service Bus roles
az role assignment create `
  --assignee $principalId `
  --role "Azure Service Bus Data Sender" `
  --scope "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.ServiceBus/namespaces/sb-flatfile-processing"

az role assignment create `
  --assignee $principalId `
  --role "Azure Service Bus Data Receiver" `
  --scope "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.ServiceBus/namespaces/sb-flatfile-processing"

# Storage Queue roles (same storage account as Logic App)
az role assignment create `
  --assignee $principalId `
  --role "Storage Queue Data Contributor" `
  --scope "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Storage/storageAccounts/aistrainingshibinbf12"
```

## Files Ready for Deployment
- ✅ wf-flatfile-pickup/workflow.json
- ✅ wf-flatfile-transformation/workflow.json
- ✅ Artifacts/Maps/EmployeeCSVToXML.xslt
- ✅ Artifacts/Maps/EmployeeCSVToJSON.liquid
- ✅ Artifacts/employees.csv (sample data)
- ✅ connections.json (configured)

---
**Status**: Configuration updated, ready for Azure resource creation and deployment
