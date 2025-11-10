# Pre-Deployment Configuration Checklist

✅ = Completed and Verified  
⏳ = Pending  

## Azure Resources Status

### ✅ Storage
- [x] Single storage account: `aistrainingshibinbf12`
- [x] Unused storage accounts deleted (4 removed)
- [x] Configuration updated in all files

### ✅ Monitoring & Logging
- [x] Log Analytics Workspace: `LAStd-UpsertEmployee-Logs`
- [x] Application Insights: `ais-training-la`
- [x] Duplicate Application Insights deleted
- [x] Application Insights linked to Log Analytics workspace
- [x] Connection strings configured in Azure Logic App
- [x] Connection strings configured in local.settings.json

### ✅ Logic App Infrastructure
- [x] Logic App: `ais-training-la` (running)
- [x] App Service Plan: `ASP-AISTrainingShibin-b7e4`
- [x] Runtime storage configured
- [x] Monitoring configured

### ✅ Infrastructure as Code
- [x] main.bicep updated with monitoring resources
- [x] main.parameters.json updated with correct values
- [x] All resource names match Azure Portal

## Local Configuration Status

### ✅ Application Settings (local.settings.json)
```json
✅ AzureWebJobsStorage (set to UseDevelopmentStorage for local)
✅ WEBSITE_CONTENTAZUREFILECONNECTIONSTRING (set to UseDevelopmentStorage)
✅ APPLICATIONINSIGHTS_CONNECTION_STRING (configured)
✅ APPINSIGHTS_INSTRUMENTATIONKEY (configured)
✅ LOG_ANALYTICS_WORKSPACE_ID (configured)
✅ LOG_ANALYTICS_PRIMARY_KEY (configured)
✅ AZURE_SQL_CONNECTION_STRING (configured)
✅ WORKFLOWS_SUBSCRIPTION_ID (configured)
✅ WORKFLOWS_RESOURCE_GROUP_NAME (configured)
✅ WORKFLOWS_LOGIC_APP_NAME (configured)
```

### ✅ Workflow Files
```
✅ wf-employee-upsert/workflow.json (existing - not modified)
✅ wf-flatfile-pickup/workflow.json (new - ready for deployment)
✅ wf-flatfile-transformation/workflow.json (new - ready for deployment)
```

### ✅ Transformation Maps
```
✅ Artifacts/Maps/EmployeeCSVToXML.xslt (11-field schema)
✅ Artifacts/Maps/EmployeeCSVToJSON.liquid (11-field schema)
```

### ✅ Connection Configuration
```
✅ connections.json (serviceBus, FileSystem, azurequeues configured)
```

## Azure Configuration Status

### ✅ Logic App Settings (Production)
Verified these settings in `ais-training-la`:
```
✅ AzureWebJobsStorage → aistrainingshibinbf12
✅ WEBSITE_CONTENTAZUREFILECONNECTIONSTRING → aistrainingshibinbf12
✅ APPLICATIONINSIGHTS_CONNECTION_STRING → Correct connection string
✅ APPINSIGHTS_INSTRUMENTATIONKEY → 714a6b4e-1c59-40c2-aba0-5d9f4ccd220d
```

## Pending Azure Resources (Required Before Deployment)

### ⏳ Service Bus Namespace
**Status**: Not yet created  
**Required for**: wf-flatfile-pickup and wf-flatfile-transformation workflows

**Action Required**:
```powershell
# Create Service Bus Namespace
az servicebus namespace create `
  --name "sb-flatfile-processing" `
  --resource-group "AIS_Training_Shibin" `
  --location "canadacentral" `
  --sku Standard

# Create queues
az servicebus queue create `
  --namespace-name "sb-flatfile-processing" `
  --resource-group "AIS_Training_Shibin" `
  --name "flatfile-processing-queue" `
  --max-size 1024

az servicebus queue create `
  --namespace-name "sb-flatfile-processing" `
  --resource-group "AIS_Training_Shibin" `
  --name "flatfile-deadletter-queue" `
  --max-size 1024

# Get connection string
az servicebus namespace authorization-rule keys list `
  --namespace-name "sb-flatfile-processing" `
  --resource-group "AIS_Training_Shibin" `
  --name RootManageSharedAccessKey `
  --query primaryConnectionString -o tsv
```

### ⏳ Storage Queues
**Status**: Not yet created  
**Required for**: wf-flatfile-transformation workflow output

**Action Required**:
```powershell
# Create queues in existing storage account
az storage queue create `
  --name flatfile-xml-queue `
  --account-name aistrainingshibinbf12

az storage queue create `
  --name flatfile-json-queue `
  --account-name aistrainingshibinbf12
```

### ⏳ On-Premise Data Gateway
**Status**: Not yet configured  
**Required for**: wf-flatfile-pickup workflow (File System connector)

**Action Required**:
1. Install On-Premise Data Gateway on file server
2. Register gateway in Azure
3. Update connections.json with gateway ID
4. Grant Logic App managed identity access to gateway

### ⏳ Managed Identity Permissions
**Status**: Not yet assigned  
**Required for**: Service Bus and Storage Queue access

**Action Required**:
```powershell
# Get Logic App principal ID
$principalId = az logicapp identity show `
  --name "ais-training-la" `
  --resource-group "AIS_Training_Shibin" `
  --query principalId -o tsv

# Service Bus roles
az role assignment create `
  --assignee $principalId `
  --role "Azure Service Bus Data Sender" `
  --scope "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.ServiceBus/namespaces/sb-flatfile-processing"

az role assignment create `
  --assignee $principalId `
  --role "Azure Service Bus Data Receiver" `
  --scope "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.ServiceBus/namespaces/sb-flatfile-processing"

# Storage Queue roles
az role assignment create `
  --assignee $principalId `
  --role "Storage Queue Data Contributor" `
  --scope "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Storage/storageAccounts/aistrainingshibinbf12"
```

## Deployment Readiness

### ✅ Ready for Local Development
- All local settings configured
- Storage emulator can be used
- Workflows can be edited and tested locally (with limitations)

### ⏳ Ready for Azure Deployment
**Prerequisites**:
1. Create Service Bus namespace and queues
2. Create Storage Queues
3. Configure On-Premise Data Gateway
4. Assign Managed Identity permissions
5. Deploy workflows to Azure

**After Prerequisites Completed**:
```powershell
# Option 1: Deploy via VS Code
# Right-click on workflow folder → Deploy to Logic App

# Option 2: Deploy via Azure CLI
cd c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee
Compress-Archive -Path * -DestinationPath deploy.zip -Force

az logicapp deployment source config-zip `
  --name "ais-training-la" `
  --resource-group "AIS_Training_Shibin" `
  --src deploy.zip
```

## Documentation Status

### ✅ Created Documentation
- [x] AZURE_RESOURCES_CONFIG.md - Complete Azure configuration guide
- [x] MONITORING_CONFIG_SUMMARY.md - Monitoring and logging setup
- [x] PRE_DEPLOYMENT_CHECKLIST.md - This file
- [x] FLATFILE_TESTING_SUMMARY.md - Testing documentation
- [x] Documentation/FlatFileProcessing_DeploymentGuide.md - Deployment guide

## Next Steps

1. **Create Service Bus Resources** (15 minutes)
   - Run Service Bus creation commands
   - Copy connection string to connections.json

2. **Create Storage Queues** (5 minutes)
   - Run queue creation commands
   - Verify queues exist

3. **Configure On-Premise Gateway** (30 minutes)
   - Install gateway software
   - Register in Azure
   - Update connections

4. **Assign Permissions** (10 minutes)
   - Grant Service Bus roles
   - Grant Storage Queue roles

5. **Deploy Workflows** (10 minutes)
   - Deploy to Logic App
   - Verify deployment
   - Test workflows

**Total Time Estimate**: ~1.5 hours

## Verification Commands

After deployment, use these commands to verify:

```powershell
# Check Logic App status
az logicapp show --name "ais-training-la" --resource-group "AIS_Training_Shibin" --query "{Name:name, State:state, DefaultHostName:defaultHostName}"

# List workflows
az logicapp workflow list --name "ais-training-la" --resource-group "AIS_Training_Shibin" --query "[].{Name:name, State:properties.state}"

# Check Service Bus queues
az servicebus queue list --namespace-name "sb-flatfile-processing" --resource-group "AIS_Training_Shibin" --query "[].{Name:name, MessageCount:messageCount}"

# Check Storage Queues
az storage queue list --account-name aistrainingshibinbf12 --query "[].{Name:name}"

# View recent logs
az monitor app-insights query --app ais-training-la --analytics-query "requests | order by timestamp desc | take 10"
```

## Summary

### ✅ Completed Today
- Cleaned up 4 unused storage accounts
- Deleted duplicate Application Insights resource
- Configured monitoring and logging properly
- Updated all configuration files
- Verified Azure and local settings match
- Created comprehensive documentation

### ⏳ Ready for Next Session
- All prerequisites documented
- Step-by-step commands provided
- Clear deployment path defined
- Testing strategy documented
