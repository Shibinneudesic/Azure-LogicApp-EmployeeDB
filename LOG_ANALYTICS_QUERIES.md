# 🔍 LOG ANALYTICS WORKSPACE QUERIES
## Request Body, Response Body & Error Details

**Workspace ID**: `8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c`  
**Workspace Name**: LAStd-UpsertEmployee-Logs

---

## ⚠️ IMPORTANT FINDINGS

### What IS Available in Log Analytics:
- ✅ Tracked Properties (logLevel, message, runId, employeeId, etc.)
- ✅ Action execution timeline
- ✅ Error messages and codes
- ✅ Status codes (Succeeded, Failed, Skipped)
- ✅ Duration metrics
- ✅ Workflow run metadata

### What is NOT Available:
- ❌ **HTTP Request Body** (input JSON sent to workflow)
- ❌ **HTTP Response Body** (output JSON sent to client)
- ❌ **Compose Action Outputs** (unless using trackedProperties)
- ❌ **Variable Values**

**Reason**: Logic Apps Standard **does not log request/response bodies** to Log Analytics or Application Insights by default for security and performance reasons.

---

## 📊 AVAILABLE QUERIES

### 1️⃣ View Tracked Properties (Custom Logging)

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'wf-employee-upsert' and Message contains 'action ends'
| extend Props = todynamic(Properties)
| extend 
    ActionName = tostring(Props.prop__actionName),
    FlowRunId = tostring(Props.prop__flowRunSequenceId),
    PropsJson = todynamic(Props.prop__properties)
| extend TrackedProps = PropsJson.trackedProperties
| where isnotnull(TrackedProps)
| extend
    LogLevel = tostring(TrackedProps.logLevel),
    MessageType = tostring(TrackedProps.message),
    EmployeeId = tostring(TrackedProps.employeeId),
    EmployeeName = tostring(TrackedProps.employeeName),
    EmployeeCount = toint(TrackedProps.employeeCount)
| project 
    TimeGenerated,
    FlowRunId,
    ActionName,
    LogLevel,
    MessageType,
    EmployeeId,
    EmployeeName,
    EmployeeCount
| order by TimeGenerated asc
```

### 2️⃣ View All Errors with Details

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'wf-employee-upsert'
| where Message contains 'Failed' or Message contains 'error' 
| where Message !contains 'Skipped'
| extend Props = todynamic(Properties)
| extend 
    ActionName = tostring(Props.prop__actionName),
    FlowRunId = tostring(Props.prop__flowRunSequenceId),
    Status = tostring(Props.prop__status),
    PropsJson = todynamic(Props.prop__properties)
| extend 
    ErrorObject = PropsJson.error,
    ErrorCode = tostring(ErrorObject.code),
    ErrorMessage = tostring(ErrorObject.message)
| project 
    TimeGenerated,
    FlowRunId,
    ActionName,
    Status,
    ErrorCode,
    ErrorMessage,
    FullMessage = Message
| order by TimeGenerated desc
```

### 3️⃣ View Workflow Execution Timeline

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'wf-employee-upsert'
| extend Props = todynamic(Properties)
| extend 
    ActionName = tostring(Props.prop__actionName),
    FlowRunId = tostring(Props.prop__flowRunSequenceId),
    Status = tostring(Props.prop__status),
    Duration = toint(Props.prop__durationInMilliseconds)
| where FlowRunId == 'YOUR_RUN_ID_HERE'
| where Message contains 'action ends' or Message contains 'Workflow run'
| project 
    TimeGenerated,
    ActionName,
    Status,
    Duration,
    MessageType = iff(Message contains 'action ends', 'ActionEnd', 'WorkflowEnd')
| order by TimeGenerated asc
```

### 4️⃣ View Response Action Status (200/500)

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'wf-employee-upsert'
| where Message contains 'Return_Success' or Message contains 'Return_Error'
| where Message contains 'action ends'
| extend Props = todynamic(Properties)
| extend 
    ActionName = tostring(Props.prop__actionName),
    FlowRunId = tostring(Props.prop__flowRunSequenceId),
    Status = tostring(Props.prop__status),
    StatusCode = tostring(Props.prop__statusCode),
    Duration = toint(Props.prop__durationInMilliseconds)
| project 
    TimeGenerated,
    FlowRunId,
    ActionName,
    Status,
    StatusCode,
    Duration
| order by TimeGenerated desc
```

### 5️⃣ View SQL Execution Errors

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'Upsert_Employee'
| where Message contains 'Failed' or (Message contains 'error' and Message !contains 'Skipped')
| extend Props = todynamic(Properties)
| extend 
    FlowRunId = tostring(Props.prop__flowRunId),
    PropsJson = todynamic(Props.prop__properties)
| extend 
    ErrorObject = PropsJson.error,
    ErrorCode = tostring(ErrorObject.code),
    ErrorMessage = tostring(ErrorObject.message)
| project 
    TimeGenerated,
    FlowRunId,
    ErrorCode,
    ErrorMessage,
    FullMessage = Message
| order by TimeGenerated desc
```

### 6️⃣ View Catch Block Executions

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'wf-employee-upsert'
| where Message contains 'Catch' and Message contains 'action'
| extend Props = todynamic(Properties)
| extend 
    ActionName = tostring(Props.prop__actionName),
    FlowRunId = tostring(Props.prop__flowRunSequenceId),
    Status = tostring(Props.prop__status),
    StatusCode = tostring(Props.prop__statusCode)
| project 
    TimeGenerated,
    FlowRunId,
    ActionName,
    Status,
    StatusCode,
    Message
| order by TimeGenerated desc
```

### 7️⃣ View Workflow Run Summary

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'wf-employee-upsert'
| where Message contains 'Workflow run ends'
| extend Props = todynamic(Properties)
| extend 
    FlowRunId = tostring(Props.prop__flowRunSequenceId),
    Status = tostring(Props.prop__status),
    Duration = toint(Props.prop__durationInMilliseconds)
| project 
    TimeGenerated,
    FlowRunId,
    Status,
    Duration_ms = Duration,
    Duration_sec = round(Duration / 1000.0, 2)
| order by TimeGenerated desc
```

### 8️⃣ Performance Analysis by Action

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'wf-employee-upsert' and Message contains 'action ends'
| extend Props = todynamic(Properties)
| extend 
    ActionName = tostring(Props.prop__actionName),
    Status = tostring(Props.prop__status),
    Duration = toint(Props.prop__durationInMilliseconds)
| where isnotnull(Duration) and Duration >= 0
| summarize 
    Count = count(),
    AvgDuration = avg(Duration),
    MinDuration = min(Duration),
    MaxDuration = max(Duration),
    SuccessCount = countif(Status == 'Succeeded'),
    FailCount = countif(Status == 'Failed')
    by ActionName
| extend SuccessRate = round((SuccessCount * 100.0) / Count, 2)
| project 
    ActionName,
    Count,
    SuccessRate,
    AvgDuration = round(AvgDuration, 2),
    MinDuration,
    MaxDuration
| order by AvgDuration desc
```

### 9️⃣ Success vs Failure Rate

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'Workflow run ends'
| extend Props = todynamic(Properties)
| extend Status = tostring(Props.prop__status)
| summarize 
    Total = count(),
    Success = countif(Status == 'Succeeded'),
    Failed = countif(Status == 'Failed')
| extend SuccessRate = round((Success * 100.0) / Total, 2)
| project Total, Success, Failed, SuccessRate
```

### 🔟 Latest 10 Workflow Runs

```kql
AppTraces
| where TimeGenerated > ago(24h)
| where Message contains 'Log_Workflow_Start' and Message contains 'action ends'
| extend Props = todynamic(Properties)
| extend 
    FlowRunId = tostring(Props.prop__flowRunSequenceId),
    PropsJson = todynamic(Props.prop__properties)
| extend TrackedProps = PropsJson.trackedProperties
| extend EmployeeCount = toint(TrackedProps.employeeCount)
| project 
    TimeGenerated,
    FlowRunId,
    EmployeeCount
| order by TimeGenerated desc
| take 10
```

---

## 💡 HOW TO VIEW REQUEST/RESPONSE BODY

Since **request and response bodies are NOT logged** in Log Analytics or Application Insights, here are alternatives:

### Option 1: Enable Diagnostic Logging (Not Available in Standard)
Logic Apps **Consumption** tier supports this, but **Standard tier does NOT** log request/response bodies to diagnostics.

### Option 2: Use Compose Actions with trackedProperties
Log specific fields you need:

```json
{
  "type": "Compose",
  "inputs": {
    "requestBody": "@triggerBody()",
    "parsedData": "@body('Parse_And_Validate_Request')"
  },
  "trackedProperties": {
    "logLevel": "INFO",
    "message": "Request_Received",
    "employeeCount": "@length(triggerBody()?['employees']?['employee'])",
    "firstEmployeeId": "@triggerBody()?['employees']?['employee'][0]?['id']"
  }
}
```

### Option 3: Capture Response Directly
Call the workflow endpoint and capture the response:

```powershell
$response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
$response | ConvertTo-Json -Depth 10 | Out-File "response.json"
```

### Option 4: Use Azure Portal Run History
1. Go to **Logic App** → **wf-employee-upsert** → **Overview**
2. Click on a **Run** from the list
3. View **Inputs** and **Outputs** for each action
4. **Note**: Portal shows last 30 days of run history

---

## 🎯 QUICK ACCESS

### Azure Portal Links:
- **Log Analytics Workspace**: https://portal.azure.com → Log Analytics workspaces → LAStd-UpsertEmployee-Logs
- **Logic App Run History**: https://portal.azure.com → Logic Apps → ais-training-la → wf-employee-upsert → Overview

### Query in Azure Portal:
1. Navigate to **Log Analytics Workspace** → LAStd-UpsertEmployee-Logs
2. Click **Logs** in left menu
3. Copy any query above
4. Replace `YOUR_RUN_ID_HERE` with actual runId
5. Click **Run**

---

## 📋 WHAT YOU CAN SEE

| Data Type | Available in Logs | How to Access |
|-----------|-------------------|---------------|
| Tracked Properties | ✅ Yes | AppTraces queries above |
| Action Status | ✅ Yes | AppTraces queries above |
| Error Messages | ✅ Yes | AppTraces queries above |
| Duration/Performance | ✅ Yes | AppTraces queries above |
| HTTP Status Codes | ✅ Yes | AppTraces queries above |
| Request Body | ❌ No | Portal Run History or Capture directly |
| Response Body | ❌ No | Portal Run History or Capture directly |
| Compose Outputs | ❌ No | Use trackedProperties |
| Variable Values | ❌ No | Not used in current workflow |

---

## ✅ BEST PRACTICES

1. **Use Tracked Properties**: Log only what you need (IDs, counts, key fields)
2. **Don't Log Sensitive Data**: Avoid logging PII, passwords, tokens in tracked properties
3. **Use Run History**: For detailed input/output inspection, use Azure Portal
4. **Monitor Errors**: Set up alerts on AppTraces for error patterns
5. **Performance Tracking**: Use duration metrics to identify slow actions

---

## 🚀 TESTED WITH

- **Workspace**: LAStd-UpsertEmployee-Logs
- **Latest RunId**: 08584388281328701344570158559CU00
- **Status**: ✅ All queries working
- **Timestamp**: 2025-11-10 12:45:56 UTC

All Log Analytics queries verified and production-ready! 🎉
