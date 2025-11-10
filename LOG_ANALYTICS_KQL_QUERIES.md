# Log Analytics Workspace - KQL Queries for Logic Apps

## ✅ Correct Table Names

Log Analytics uses **App*** tables when Application Insights is linked:
- `AppRequests` - HTTP requests and workflow triggers
- `AppTraces` - Application logs and traces
- `AppExceptions` - Exceptions
- `AppDependencies` - External dependencies (SQL, Service Bus, etc.)
- `AppMetrics` - Performance metrics
- `AppPerformanceCounters` - System performance

## 📝 Query 1: View All Errors (Last Hour)

```kql
AppTraces
| where TimeGenerated > ago(1h)
| where SeverityLevel >= 3  // 3=Warning, 4=Error
| project 
    TimeGenerated,
    Message,
    SeverityLevel,
    Properties
| order by TimeGenerated desc
| take 50
```

## 📝 Query 2: SQL Login Errors

```kql
AppTraces
| where TimeGenerated > ago(1h)
| where Message contains "Login failed for user"
| extend 
    ErrorNumber = tostring(Properties.prop__exception)
| project 
    TimeGenerated,
    Message,
    ErrorNumber,
    Properties
| order by TimeGenerated desc
```

## 📝 Query 3: View Failed Workflow Runs

```kql
AppRequests
| where TimeGenerated > ago(1h)
| where Success == false
| project 
    TimeGenerated,
    Name,
    ResultCode,
    DurationMs,
    Properties
| order by TimeGenerated desc
| take 20
```

## 📝 Query 4: View Successful Requests

```kql
AppRequests
| where TimeGenerated > ago(1h)
| where Success == true
| project 
    TimeGenerated,
    Name,
    ResultCode,
    DurationMs
| order by TimeGenerated desc
| take 20
```

## 📝 Query 5: SQL Exceptions with Stack Trace

```kql
AppTraces
| where TimeGenerated > ago(1h)
| where Message contains "SqlException"
| extend
    ErrorMessage = extract("message='([^']+)'", 1, Message),
    ErrorNumber = extract("Error Number:(\\d+)", 1, Message),
    ClientConnectionId = extract("ClientConnectionId:([a-f0-9\\-]+)", 1, Message)
| project
    TimeGenerated,
    ErrorMessage,
    ErrorNumber,
    ClientConnectionId,
    Message
| order by TimeGenerated desc
```

## 📝 Query 6: Database Availability Errors

```kql
AppTraces
| where TimeGenerated > ago(1h)
| where Message contains "Database" and Message contains "not currently available"
| project
    TimeGenerated,
    Message,
    Properties
| order by TimeGenerated desc
```

## 📝 Query 7: Error Summary (Group by Error Type)

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where SeverityLevel >= 3
| extend ErrorType = case(
    Message contains "Login failed", "SQL Login Failed",
    Message contains "Database" and Message contains "not currently available", "Database Unavailable",
    Message contains "ServiceProviderActionFailed", "Service Provider Failed",
    "Other Error"
)
| summarize ErrorCount = count() by ErrorType
| order by ErrorCount desc
```

## 📝 Query 8: Workflow Performance Analysis

```kql
AppRequests
| where TimeGenerated > ago(24h)
| where Name contains "wf-employee-upsert"
| summarize
    TotalRequests = count(),
    FailedRequests = countif(Success == false),
    AvgDurationMs = avg(DurationMs),
    MaxDurationMs = max(DurationMs),
    MinDurationMs = min(DurationMs)
    by bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

## 📝 Query 9: SQL Operation Details

```kql
AppTraces
| where TimeGenerated > ago(1h)
| where Message contains "executeQuery" or Message contains "Upsert_Employee"
| extend
    EmployeeId = extract("@ID=(\\d+)", 1, Message),
    Operation = extract("(executeQuery|Upsert_Employee)", 1, Message)
| project
    TimeGenerated,
    Operation,
    EmployeeId,
    Message
| order by TimeGenerated desc
```

## 📝 Query 10: Invocation Timeline

```kql
AppTraces
| where TimeGenerated > ago(1h)
| where Properties has "InvocationId"
| extend
    InvocationId = tostring(Properties.InvocationId),
    ActionName = extract("wf-employee-upsert\\.([^.]+)", 1, Message)
| project
    TimeGenerated,
    InvocationId,
    ActionName,
    Message
| order by TimeGenerated asc
```

## 🎯 How to Use in Azure Portal

### **Step 1: Navigate to Log Analytics Workspace**

```
https://portal.azure.com/#@/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.OperationalInsights/workspaces/LAStd-UpsertEmployee-Logs/logs
```

### **Step 2: Run Query**

1. Click **"Logs"** in left menu
2. Paste one of the KQL queries above
3. Click **"Run"** button
4. View results in table or chart format

### **Step 3: Export Results**

- Click **"Export"** → Download as CSV/Excel
- Or click **"Pin to dashboard"** for monitoring

## 💡 PowerShell Commands

### **Query errors via CLI:**

```powershell
# View errors in last hour
az monitor log-analytics query `
  --workspace "8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c" `
  --analytics-query "AppTraces | where TimeGenerated > ago(1h) | where SeverityLevel >= 3 | project TimeGenerated, Message | order by TimeGenerated desc | take 20" `
  --output table
```

### **View failed requests:**

```powershell
az monitor log-analytics query `
  --workspace "8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c" `
  --analytics-query "AppRequests | where TimeGenerated > ago(1h) | where Success == false | project TimeGenerated, Name, ResultCode | order by TimeGenerated desc | take 20" `
  --output table
```

### **Count tables with data:**

```powershell
az monitor log-analytics query `
  --workspace "8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c" `
  --analytics-query "search * | where TimeGenerated > ago(1h) | summarize count() by Type | order by count_ desc" `
  --output table
```

## 📊 Common Error Patterns Found

Based on your logs, here are the errors you're seeing:

### **1. Login Failed**
```
'Login failed for user '<token-identified principal>'.'
Error Number: 18456
```
**Solution**: Run SQL permission script (already resolved)

### **2. Database Unavailable**
```
'Database 'empdb' on server 'aistrainingserver.database.windows.net' is not currently available.'
Error Number: 40613
```
**Solution**: Temporary Azure SQL issue, workflow will retry automatically

### **3. Service Provider Failed**
```
ServiceProviderActionFailed - ServiceOperationFailed
```
**Solution**: Usually transient, check SQL connection and permissions

## 🔍 Real-Time Monitoring

### **Live Metrics Stream:**

Portal → Application Insights → Live Metrics

Shows:
- Real-time requests
- Real-time failures
- Server performance
- Sample telemetry

## 📈 Create Alert

```powershell
# Alert on workflow failures
az monitor metrics alert create `
  --name "WorkflowFailureAlert" `
  --resource-group "AIS_Training_Shibin" `
  --scopes "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/ais-training-la" `
  --condition "count requests/failed > 5" `
  --window-size 5m `
  --evaluation-frequency 1m
```

---

**Save this guide for your demo!** 📚
