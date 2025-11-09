# Logic App Log Query Guide

## Configuration Summary
- **Application Insights**: ais-training-la
- **Instrumentation Key**: 714a6b4e-1c59-40c2-aba0-5d9f4ccd220d
- **Log Analytics Workspace**: LAStd-UpsertEmployee-Logs
- **Workspace ID**: 8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c

---

## Getting Run ID from Azure Portal

### Method 1: From Logic App Overview
1. Go to Azure Portal → Logic Apps → ais-training-la
2. Click **Workflows** → **wf-employee-upsert**
3. Click **Overview** → **Run History**
4. Click on any run → Copy the **Run ID** from the URL or properties

### Method 2: From Workflow Designer
1. Go to workflow designer
2. Click **Run History** at the top
3. Select a run to see its **Run ID**

---

## Application Insights Queries (Recommended)

Application Insights has faster query response and better UI.

### Query 1: Recent Workflow Requests (Last 24 Hours)
```bash
az monitor app-insights query \
  --app ais-training-la \
  --resource-group AIS_Training_Shibin \
  --analytics-query "requests | where timestamp > ago(24h) | project timestamp, name, resultCode, duration, url | order by timestamp desc | take 20" \
  -o table
```

### Query 2: Custom Traces (Our Workflow Logs)
```bash
az monitor app-insights query \
  --app ais-training-la \
  --resource-group AIS_Training_Shibin \
  --analytics-query "traces | where timestamp > ago(24h) | project timestamp, message, severityLevel | order by timestamp desc | take 50" \
  -o table
```

### Query 3: Find Exceptions/Errors
```bash
az monitor app-insights query \
  --app ais-training-la \
  --resource-group AIS_Training_Shibin \
  --analytics-query "exceptions | where timestamp > ago(24h) | project timestamp, type, outerMessage, innermostMessage | order by timestamp desc | take 20" \
  -o table
```

### Query 4: Search by Specific Text (e.g., Employee ID)
```bash
az monitor app-insights query \
  --app ais-training-la \
  --resource-group AIS_Training_Shibin \
  --analytics-query "traces | where timestamp > ago(24h) | where message contains '2001' | project timestamp, message | order by timestamp desc" \
  -o table
```

### Query 5: Dependencies (SQL Calls)
```bash
az monitor app-insights query \
  --app ais-training-la \
  --resource-group AIS_Training_Shibin \
  --analytics-query "dependencies | where timestamp > ago(24h) | where type == 'SQL' | project timestamp, name, data, duration, resultCode, success | order by timestamp desc | take 20" \
  -o table
```

---

## Log Analytics Queries (Detailed Workflow Runtime)

Log Analytics has more detailed workflow execution data but may take 2-5 minutes to populate.

### Query 1: Recent Workflow Runs
```bash
az monitor log-analytics query \
  --workspace 8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c \
  --analytics-query "AzureDiagnostics | where Category == 'WorkflowRuntime' | where TimeGenerated > ago(24h) | summarize by RunId=runId_s, TimeGenerated, Status=status_s | order by TimeGenerated desc | take 20" \
  -o table
```

### Query 2: Get Run Details by Run ID
```bash
# Replace YOUR_RUN_ID with actual run ID
az monitor log-analytics query \
  --workspace 8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c \
  --analytics-query "AzureDiagnostics | where Category == 'WorkflowRuntime' | where runId_s == 'YOUR_RUN_ID' | project TimeGenerated, OperationName, status_s, error_message_s | order by TimeGenerated asc" \
  -o table
```

### Query 3: Find Failed Runs
```bash
az monitor log-analytics query \
  --workspace 8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c \
  --analytics-query "AzureDiagnostics | where Category == 'WorkflowRuntime' | where TimeGenerated > ago(24h) | where status_s == 'Failed' | project TimeGenerated, runId_s, workflowName_s, error_message_s | order by TimeGenerated desc | take 20" \
  -o table
```

### Query 4: Function App Logs (Application Logs)
```bash
az monitor log-analytics query \
  --workspace 8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c \
  --analytics-query "AzureDiagnostics | where Category == 'FunctionAppLogs' | where TimeGenerated > ago(24h) | project TimeGenerated, Level, Message | order by TimeGenerated desc | take 50" \
  -o table
```

---

## Azure Portal - Visual Query Editor (Easiest)

### For Application Insights:
1. Go to Azure Portal
2. Navigate to: **Application Insights → ais-training-la**
3. Click **Logs** in the left menu
4. Use these KQL queries:

#### Recent Requests:
```kql
requests
| where timestamp > ago(24h)
| project timestamp, name, resultCode, duration, url
| order by timestamp desc
```

#### Custom Traces with Details:
```kql
traces
| where timestamp > ago(24h)
| extend 
    RunId = tostring(customDimensions["prop__runId"]),
    WorkflowName = tostring(customDimensions["prop__workflowName"]),
    ActionName = tostring(customDimensions["prop__actionName"])
| project timestamp, message, severityLevel, RunId, WorkflowName, ActionName
| order by timestamp desc
```

#### Search by Run ID:
```kql
union requests, traces, dependencies, exceptions
| where timestamp > ago(24h)
| extend RunId = tostring(customDimensions["prop__runId"])
| where RunId == "YOUR_RUN_ID"
| project timestamp, itemType, message, name, resultCode
| order by timestamp asc
```

#### Failed Requests:
```kql
requests
| where timestamp > ago(24h)
| where resultCode >= 400
| project timestamp, name, resultCode, duration, url
| order by timestamp desc
```

### For Log Analytics Workspace:
1. Go to Azure Portal
2. Navigate to: **Log Analytics Workspaces → LAStd-UpsertEmployee-Logs**
3. Click **Logs** in the left menu
4. Use these KQL queries:

#### Workflow Runtime Logs:
```kql
AzureDiagnostics
| where Category == "WorkflowRuntime"
| where TimeGenerated > ago(24h)
| project TimeGenerated, OperationName, runId_s, status_s, error_message_s
| order by TimeGenerated desc
```

#### Function App Logs:
```kql
AzureDiagnostics
| where Category == "FunctionAppLogs"
| where TimeGenerated > ago(24h)
| project TimeGenerated, Level, Message
| order by TimeGenerated desc
```

---

## PowerShell Script for Quick Checks

### Check Recent Runs:
```powershell
# Get last 10 requests
az monitor app-insights query `
  --app ais-training-la `
  --resource-group AIS_Training_Shibin `
  --analytics-query "requests | where timestamp > ago(1h) | project timestamp, name, resultCode, duration | order by timestamp desc | take 10" `
  -o table
```

### Check for Errors:
```powershell
# Get last 10 errors
az monitor app-insights query `
  --app ais-training-la `
  --resource-group AIS_Training_Shibin `
  --analytics-query "union traces, exceptions | where timestamp > ago(1h) | where severityLevel >= 3 | project timestamp, itemType, message | order by timestamp desc | take 10" `
  -o table
```

### Search by Employee ID:
```powershell
# Replace 2001 with actual ID
$employeeId = "2001"
az monitor app-insights query `
  --app ais-training-la `
  --resource-group AIS_Training_Shibin `
  --analytics-query "traces | where timestamp > ago(1h) | where message contains '$employeeId' | project timestamp, message" `
  -o table
```

---

## Monitoring Workflow Input/Output

### View Request Body (Input):
The HTTP request body is captured in Application Insights:
```kql
requests
| where timestamp > ago(24h)
| where name contains "wf-employee-upsert"
| extend RequestBody = tostring(customDimensions["RequestBody"])
| project timestamp, name, RequestBody, resultCode
| order by timestamp desc
```

### View SQL Query Parameters:
SQL dependencies capture the query:
```kql
dependencies
| where timestamp > ago(24h)
| where type == "SQL"
| project timestamp, name, data, duration, success, resultCode
| order by timestamp desc
```

---

## Understanding Severity Levels

- **0** = Verbose (detailed trace)
- **1** = Information (INFO)
- **2** = Warning (WARN)
- **3** = Error (ERROR)
- **4** = Critical (CRITICAL - triggers Terminate)

### Filter by Severity:
```kql
traces
| where timestamp > ago(24h)
| where severityLevel >= 3  // Only errors and critical
| project timestamp, message, severityLevel
| order by timestamp desc
```

---

## Testing the Logging Setup

### Send Test Request:
```bash
curl --location 'https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net:443/api/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=WeV6SfqxPui2Pgi2i4NJDulJFNnI0ftCxNnoZBCFxvE' \
--header 'Content-Type: application/json' \
--data-raw '{
  "employees": {
    "employee": [
      {
        "id": 9999,
        "firstName": "Test",
        "lastName": "Logging"
      }
    ]
  }
}'
```

### Check Logs (wait 30-60 seconds):
```bash
az monitor app-insights query \
  --app ais-training-la \
  --resource-group AIS_Training_Shibin \
  --analytics-query "requests | where timestamp > ago(5m) | project timestamp, name, resultCode" \
  -o table
```

---

## Common Troubleshooting Queries

### 1. No Logs Appearing
Check if Application Insights is receiving data:
```bash
az monitor app-insights query \
  --app ais-training-la \
  --resource-group AIS_Training_Shibin \
  --analytics-query "union requests, traces | where timestamp > ago(1h) | count" \
  -o table
```

### 2. Find Slow Requests (>5 seconds)
```kql
requests
| where timestamp > ago(24h)
| where duration > 5000
| project timestamp, name, duration, resultCode
| order by duration desc
```

### 3. SQL Connection Errors
```kql
dependencies
| where timestamp > ago(24h)
| where type == "SQL"
| where success == false
| project timestamp, name, data, resultCode
| order by timestamp desc
```

### 4. Authentication Failures
```kql
traces
| where timestamp > ago(24h)
| where message contains "Login failed" or message contains "authentication"
| project timestamp, message, severityLevel
| order by timestamp desc
```

---

## Quick Reference

| Need | Use This Query |
|------|---------------|
| Recent runs | `requests \| where timestamp > ago(1h)` |
| Find errors | `exceptions \| where timestamp > ago(1h)` |
| Search by ID | `traces \| where message contains 'YOUR_ID'` |
| SQL queries | `dependencies \| where type == 'SQL'` |
| Slow requests | `requests \| where duration > 5000` |
| By Run ID | `union requests, traces \| where customDimensions.prop__runId == 'RUN_ID'` |

---

## Notes

- **Logs take 2-5 minutes** to appear after workflow execution
- **Application Insights** is faster and easier to query than Log Analytics
- **Run IDs** are available in Azure Portal workflow run history
- **Custom dimensions** in App Insights contain workflow metadata (RunId, ActionName, etc.)
- Use **Azure Portal Logs UI** for the best query experience with autocomplete and schema browsing
