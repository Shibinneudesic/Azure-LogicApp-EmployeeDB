# Monitoring and Troubleshooting Guide - Azure Logic Apps

## 📊 View Logs in Azure Portal

### **Option 1: Logic App Run History (Quickest)**

1. **Navigate to Logic App**:
   - Go to: https://portal.azure.com
   - Search for: `ais-training-la`
   - Click on the Logic App

2. **View Workflows**:
   - Click **"Workflows"** in left menu
   - Click **"wf-employee-upsert"**

3. **View Run History**:
   - Click **"Overview"** or **"Run History"**
   - You'll see all workflow executions with status (Succeeded, Failed, Running)
   - **Red = Failed**, **Green = Succeeded**, **Yellow = Running**

4. **View Run Details**:
   - Click on any run to see:
     - Input/Output of each action
     - Execution timeline
     - Error messages
     - Duration of each step

**Direct Link**:
```
https://portal.azure.com/#@/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/ais-training-la/workflowRunHistory
```

---

### **Option 2: Application Insights (Best for Analysis)**

#### **Using Azure Portal UI:**

1. **Navigate to Application Insights**:
   - Go to: https://portal.azure.com
   - Search for: `ais-training-la` (Application Insights resource)
   - Or navigate from Logic App → Monitoring → Application Insights

2. **View Failed Requests**:
   - Click **"Failures"** in left menu
   - Shows all failed operations
   - Click on any failure to see details

3. **View All Requests**:
   - Click **"Performance"** in left menu
   - Shows all requests with duration
   - Filter by status code

4. **Custom Queries** (Most Powerful):
   - Click **"Logs"** in left menu
   - Use KQL (Kusto Query Language) queries

**Direct Link to Application Insights**:
```
https://portal.azure.com/#@/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/microsoft.insights/components/ais-training-la/overview
```

---

## 📝 KQL Queries for Application Insights

### **Query 1: View All Failed Requests**

```kql
requests
| where cloud_RoleName == "ais-training-la"
| where success == false
| project 
    timestamp,
    name,
    resultCode,
    duration,
    customDimensions
| order by timestamp desc
| take 50
```

### **Query 2: View Failed Requests with Details**

```kql
requests
| where cloud_RoleName == "ais-training-la"
| where success == false
| extend 
    workflowName = tostring(customDimensions.workflowName),
    runId = tostring(customDimensions.runId),
    errorMessage = tostring(customDimensions.errorMessage)
| project 
    timestamp,
    name,
    resultCode,
    duration,
    workflowName,
    runId,
    errorMessage
| order by timestamp desc
| take 50
```

### **Query 3: View Exceptions with Stack Trace**

```kql
exceptions
| where cloud_RoleName == "ais-training-la"
| project 
    timestamp,
    type,
    outerMessage,
    innermostMessage,
    details,
    customDimensions
| order by timestamp desc
| take 50
```

### **Query 4: View Traces (Application Logs)**

```kql
traces
| where cloud_RoleName == "ais-training-la"
| where severityLevel >= 3  // 3=Warning, 4=Error
| project 
    timestamp,
    message,
    severityLevel,
    customDimensions
| order by timestamp desc
| take 100
```

### **Query 5: View Failed Employee Processing**

```kql
traces
| where cloud_RoleName == "ais-training-la"
| where message contains "Failed to upsert employee" or message contains "ERROR"
| extend 
    employeeId = tostring(customDimensions.employeeId),
    employeeName = tostring(customDimensions.employeeName),
    errorMessage = tostring(customDimensions.errorMessage)
| project 
    timestamp,
    message,
    employeeId,
    employeeName,
    errorMessage
| order by timestamp desc
| take 100
```

### **Query 6: View All Workflow Runs (Success + Failed)**

```kql
customEvents
| where cloud_RoleName == "ais-training-la"
| where name contains "workflow"
| extend 
    status = tostring(customDimensions.status),
    runId = tostring(customDimensions.runId)
| project 
    timestamp,
    name,
    status,
    runId,
    customDimensions
| order by timestamp desc
| take 50
```

### **Query 7: Performance Analysis**

```kql
requests
| where cloud_RoleName == "ais-training-la"
| summarize 
    TotalRequests = count(),
    FailedRequests = countif(success == false),
    AvgDuration = avg(duration),
    MaxDuration = max(duration),
    MinDuration = min(duration)
    by bin(timestamp, 5m), name
| order by timestamp desc
```

### **Query 8: Error Summary by Type**

```kql
exceptions
| where cloud_RoleName == "ais-training-la"
| where timestamp > ago(24h)
| summarize ErrorCount = count() by type, outerMessage
| order by ErrorCount desc
```

---

## 📊 Log Analytics Workspace Queries

### **Navigate to Log Analytics**:

1. Go to: https://portal.azure.com
2. Search for: `LAStd-UpsertEmployee-Logs`
3. Click **"Logs"** in left menu

**Direct Link**:
```
https://portal.azure.com/#@/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.OperationalInsights/workspaces/LAStd-UpsertEmployee-Logs/logs
```

### **Query 1: View Function App Logs (Logic App)**

```kql
FunctionAppLogs
| where Category == "Function.wf-employee-upsert"
| where Level == "Error" or Level == "Warning"
| project 
    TimeGenerated,
    Level,
    Message,
    ExceptionMessage,
    ExceptionType
| order by TimeGenerated desc
| take 100
```

### **Query 2: View All Logic App Diagnostics**

```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.WEB"
| where ResourceType == "SITES"
| where Resource == "AIS-TRAINING-LA"
| where Category == "FunctionAppLogs"
| project 
    TimeGenerated,
    Level,
    OperationName,
    Message,
    CorrelationId
| order by TimeGenerated desc
| take 100
```

### **Query 3: SQL Connection Errors**

```kql
traces
| where cloud_RoleName == "ais-training-la"
| where message contains "SQL" or message contains "database" or message contains "Login failed"
| project 
    timestamp,
    message,
    severityLevel,
    customDimensions
| order by timestamp desc
| take 50
```

---

## 🔍 PowerShell Commands to Query Logs

### **Query Application Insights via CLI:**

```powershell
# Get all failed requests in last 24 hours
az monitor app-insights query `
  --app "ais-training-la" `
  --resource-group "AIS_Training_Shibin" `
  --analytics-query "requests | where success == false | where timestamp > ago(24h) | project timestamp, name, resultCode, duration | order by timestamp desc | take 20" `
  --output table
```

### **Get exceptions:**

```powershell
az monitor app-insights query `
  --app "ais-training-la" `
  --resource-group "AIS_Training_Shibin" `
  --analytics-query "exceptions | where timestamp > ago(24h) | project timestamp, type, outerMessage | order by timestamp desc | take 20" `
  --output table
```

### **Get traces (logs):**

```powershell
az monitor app-insights query `
  --app "ais-training-la" `
  --resource-group "AIS_Training_Shibin" `
  --analytics-query "traces | where severityLevel >= 3 | where timestamp > ago(1h) | project timestamp, message, severityLevel | order by timestamp desc | take 20" `
  --output table
```

### **Query Log Analytics Workspace:**

```powershell
# Get workspace ID
$workspaceId = "8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c"

# Query logs
az monitor log-analytics query `
  --workspace $workspaceId `
  --analytics-query "FunctionAppLogs | where Level == 'Error' | where TimeGenerated > ago(1h) | project TimeGenerated, Message | order by TimeGenerated desc | take 20" `
  --output table
```

---

## 📱 Create Alert Rules (Optional)

### **Create alert for failed workflow runs:**

```powershell
# Create action group (for email notifications)
az monitor action-group create `
  --name "LogicApp-Alerts" `
  --resource-group "AIS_Training_Shibin" `
  --short-name "LA-Alert" `
  --email-receiver "admin" "shibin.sam@neudesic.com"

# Create alert rule for failures
az monitor metrics alert create `
  --name "LogicApp-FailureAlert" `
  --resource-group "AIS_Training_Shibin" `
  --scopes "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/ais-training-la" `
  --condition "total requests/failed > 5" `
  --window-size 5m `
  --evaluation-frequency 1m `
  --action "LogicApp-Alerts"
```

---

## 🎯 Quick Access Summary

### **1. Run History (Visual)**
- Portal → Logic App → Workflows → wf-employee-upsert → Run History
- Best for: Quick visual overview

### **2. Application Insights Logs**
- Portal → Application Insights → Logs
- Best for: Detailed queries and analysis

### **3. Log Analytics Workspace**
- Portal → Log Analytics → Logs
- Best for: Cross-resource queries

### **4. Live Metrics (Real-time)**
- Portal → Application Insights → Live Metrics
- Best for: Real-time monitoring during testing

---

## 📋 Common Troubleshooting Queries

### **Find runs with SQL errors:**

```kql
traces
| where message contains "ServiceProviderActionFailed" or message contains "Login failed"
| project timestamp, message, customDimensions
| order by timestamp desc
```

### **Find slow requests (> 5 seconds):**

```kql
requests
| where duration > 5000
| project timestamp, name, duration, resultCode
| order by duration desc
```

### **Find requests by employee ID:**

```kql
traces
| where customDimensions.employeeId == "2001"
| project timestamp, message, customDimensions
| order by timestamp desc
```

---

## 🚀 Test and Monitor Workflow

### **Run test and view logs:**

```powershell
# 1. Run test
$response = Invoke-RestMethod -Uri "https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net:443/api/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=AaY1Rk_qyhnCKcSjK2YdSgSNEpVS4J92JDniY_34gvQ" -Method Post -Body (Get-Content "test-request.json" -Raw) -ContentType "application/json"

# 2. Get the run ID
$runId = $response.runId
Write-Host "Run ID: $runId"

# 3. Wait a few seconds for logs to be ingested
Start-Sleep -Seconds 10

# 4. Query logs for this specific run
az monitor app-insights query `
  --app "ais-training-la" `
  --resource-group "AIS_Training_Shibin" `
  --analytics-query "traces | where customDimensions.runId == '$runId' | project timestamp, message, severityLevel | order by timestamp asc" `
  --output table
```

---

**Save this guide for future reference!** 📚
