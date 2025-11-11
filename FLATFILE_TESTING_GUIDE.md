# Flat File Processing Workflows - Testing Guide

## Overview
This guide explains how to test the asynchronous flat file processing workflows locally and in Azure.

## Architecture

### Workflow 1: wf-flatfile-pickup
**Purpose**: Monitor file server, validate files, send to Service Bus queue

**Trigger**: File System trigger - monitors `C:\EmployeeFiles` folder
**Actions**:
1. Get file content
2. Validate file size (1 byte - 10 MB)
3. Send to Service Bus queue: `flatfile-processing-queue`
4. Error handling → Dead letter queue: `flatfile-deadletter-queue`

### Workflow 2: wf-flatfile-transformation  
**Purpose**: Transform CSV to XML and JSON, send to storage queues

**Trigger**: Service Bus queue trigger - `flatfile-processing-queue`
**Actions**:
1. Parse CSV content
2. **Parallel transformations**:
   - XSLT transformation → XML → `flatfile-xml-queue` (Storage Queue)
   - Liquid transformation → JSON → `flatfile-json-queue` (Storage Queue)
3. Complete Service Bus message
4. Error handling → Dead letter the message

## Azure Resources Required

### Already Deployed:
✅ Logic App: `ais-training-la`
✅ Service Bus Namespace: `sb-flatfile-processing`
✅ Service Bus Queues:
   - `flatfile-processing-queue`
   - `flatfile-deadletter-queue`
✅ Storage Account: `aistrainingshibinbf12`
✅ Storage Queues:
   - `flatfile-xml-queue`
   - `flatfile-json-queue`
✅ On-Premise Gateway: `AIS-Training-Standard-Gateway`

### Integration Account Artifacts:
✅ XSLT Map: `Artifacts/Maps/EmployeeCSVToXML.xslt`
✅ Liquid Map: `Artifacts/Maps/EmployeeCSVToJSON.liquid`
✅ Sample CSV: `Artifacts/employees.csv`

## Local Testing Setup

### Prerequisites:
1. **Azurite** - Storage emulator
2. **Azure Functions Core Tools** - Run Logic Apps locally
3. **Azure CLI** - Manage Azure resources
4. **Service Bus connection** - Use Azure Service Bus (required for local testing)

### Setup Steps:

#### 1. Run Setup Script
```powershell
.\Setup-Local.ps1
```

This script:
- Gets Service Bus connection string from Azure
- Updates `local.settings.json` with SERVICE_BUS_CONNECTION_STRING
- Creates test directory: `C:\EmployeeFiles`
- Starts Azurite (if not running)

#### 2. Start Azurite (if not running)
```powershell
azurite --silent --location . --debug azurite.log
```

#### 3. Restart Func Host
```powershell
# Stop current func host
Get-Process -Name "func" | Stop-Process -Force

# Start func host in a new terminal
func start
```

#### 4. Run Local Test
```powershell
.\Test-FlatFile-Local.ps1
```

### What Happens Locally:

1. **Test file uploaded** → `C:\EmployeeFiles\employees_local_YYYYMMDD_HHMMSS.csv`
2. **Workflow 1** (wf-flatfile-pickup) detects file within 1-3 minutes
   - Reads file content
   - Validates file size
   - Sends to **Azure Service Bus** queue (not local!)
3. **Workflow 2** (wf-flatfile-transformation) triggered by Service Bus message
   - Transforms CSV to XML and JSON
   - Sends to **local Azurite** storage queues

### Monitoring Local Execution:

**Check Func Host Terminal:**
Look for log messages like:
```
[2025-11-11T09:00:00.000Z] Executing 'Functions.wf-flatfile-pickup' ...
[2025-11-11T09:00:05.000Z] Executed 'Functions.wf-flatfile-pickup' (Succeeded)
[2025-11-11T09:00:10.000Z] Executing 'Functions.wf-flatfile-transformation' ...
```

**Check Storage Queues:**
```powershell
# Use Azure Storage Explorer
# Connect to: UseDevelopmentStorage=true
# Navigate to: Queues → flatfile-xml-queue / flatfile-json-queue
```

## Azure Testing

### Prerequisites:
- Workflows deployed to Azure Logic App
- On-premise gateway configured
- File server accessible via gateway

### Test Steps:

#### 1. Upload Test File
```powershell
.\Test-FlatFile-Simple.ps1
```

This script:
- Copies test file to `C:\EmployeeFiles\`
- Monitors Service Bus queues
- Checks Storage queues for transformed data

#### 2. Monitor Execution

**Azure Portal - Logic App:**
```
https://portal.azure.com → Logic App → ais-training-la
→ wf-flatfile-pickup → Runs History
→ wf-flatfile-transformation → Runs History
```

**Service Bus Queues:**
```powershell
# Check queue message counts
.\Test-FlatFile-Simple.ps1 -CheckQueuesOnly
```

**Storage Queues:**
```powershell
# Check storage queue messages
.\Test-FlatFile-Simple.ps1 -CheckStorageQueues
```

### Verification Checklist:

✅ **Workflow 1** (File Pickup):
- [ ] File detected in `C:\EmployeeFiles\`
- [ ] Workflow run shows "Succeeded"
- [ ] Message sent to `flatfile-processing-queue`
- [ ] No messages in dead letter queue

✅ **Workflow 2** (Transformation):
- [ ] Triggered by Service Bus message
- [ ] Workflow run shows "Succeeded"
- [ ] XML message in `flatfile-xml-queue`
- [ ] JSON message in `flatfile-json-queue`
- [ ] Service Bus message completed (removed from queue)

## Troubleshooting

### Issue: Workflow 1 not detecting files

**Solution**:
- Check on-premise gateway is running and connected
- Verify file path is correct: `C:\EmployeeFiles\`
- Check gateway credentials in `connections.json`
- For local testing: Remove gateway requirement from connections

### Issue: Workflow 2 not triggered

**Solution**:
- Check Service Bus connection string in `local.settings.json`
- Verify queue name: `flatfile-processing-queue`
- Check Service Bus namespace is accessible
- View func host logs for error messages

### Issue: Transformations failing

**Solution**:
- Verify XSLT and Liquid maps are in `Artifacts/Maps/` folder
- Check CSV format matches expected schema
- Review transformation logic in maps
- Check func host logs for detailed error messages

### Issue: Storage queues not receiving messages

**Solution**:
- For local: Ensure Azurite is running
- For Azure: Verify storage account connection
- Check managed identity has Storage Queue Data Contributor role
- Review workflow run history for errors

## Log Analytics Queries

### View Workflow Runs:
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.WEB"
| where ResourceType == "SITES"
| where Category == "WorkflowRuntime"
| where workflowName_s in ("wf-flatfile-pickup", "wf-flatfile-transformation")
| project TimeGenerated, workflowName_s, status_s, error_message_s
| order by TimeGenerated desc
```

### View Errors:
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.WEB"
| where Category == "WorkflowRuntime"
| where status_s == "Failed"
| project TimeGenerated, workflowName_s, error_code_s, error_message_s
| order by TimeGenerated desc
```

## Test Scripts

| Script | Purpose |
|--------|---------|
| `Setup-Local.ps1` | Configure local testing environment |
| `Test-FlatFile-Local.ps1` | Test workflows locally |
| `Test-FlatFile-Simple.ps1` | Test workflows in Azure |
| `Monitor-FlatFileWorkflows.ps1` | Monitor workflow execution |

## Next Steps

1. ✅ Local testing complete
2. Deploy workflows to Azure
3. Configure on-premise gateway
4. Run Azure end-to-end test
5. Monitor and validate results
6. Review Application Insights for performance metrics

## Support

For issues or questions:
- Check func host terminal logs
- Review Azure Portal workflow run history
- Query Log Analytics for detailed diagnostics
- Check Service Bus and Storage queue message counts
