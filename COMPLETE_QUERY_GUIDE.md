# 🎯 COMPLETE APPLICATION INSIGHTS QUERY GUIDE

## 📋 Table of Contents

1. [Tracked Properties Queries](#tracked-properties)
2. [Error & Exception Queries](#errors-and-exceptions)
3. [Response Status Queries](#responses)
4. [Performance Queries](#performance)
5. [Quick Reference](#quick-reference)

---

## 🏷️ Tracked Properties

### View All Tracked Properties for Specific Run

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert' and message contains 'action ends'
| extend properties = parse_json(tostring(customDimensions.prop__properties))
| extend trackedProps = properties.trackedProperties, runId = tostring(customDimensions.prop__flowRunSequenceId)
| where runId == 'YOUR_RUN_ID_HERE' and isnotempty(trackedProps)
| extend 
    logLevel = tostring(trackedProps.logLevel), 
    msg = tostring(trackedProps.message), 
    empId = tostring(trackedProps.employeeId), 
    empName = tostring(trackedProps.employeeName),
    empCount = toint(trackedProps.employeeCount)
| project timestamp, action=tostring(customDimensions.prop__actionName), logLevel, msg, empId, empName, empCount
| order by timestamp asc
```

### View Last 10 Workflow Executions

```kql
traces
| where timestamp > ago(24h) and message contains 'Log_Workflow_Start' and message contains 'action ends'
| extend properties = parse_json(tostring(customDimensions.prop__properties)), trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| project 
    timestamp, 
    runId=tostring(customDimensions.prop__flowRunSequenceId), 
    employeeCount=toint(trackedProps.employeeCount)
| order by timestamp desc 
| take 10
```

---

## ❌ Errors and Exceptions

### All Workflow Errors

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where (message contains 'Error' or message contains 'exception' or message contains 'failed') 
    and not(message contains 'Skipped')
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    status = tostring(customDimensions.prop__status)
| extend errorObject = properties.error
| extend
    errorCode = tostring(errorObject.code),
    errorMessage = tostring(errorObject.message)
| project 
    timestamp,
    runId,
    actionName,
    status,
    errorCode,
    errorMessage
| order by timestamp desc
```

### Catch Block Executions (500 Errors)

```kql
traces
| where timestamp > ago(24h)
| where message contains 'Return_Error' and message contains 'action ends'
| extend 
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    status = tostring(customDimensions.prop__status),
    statusCode = tostring(customDimensions.prop__statusCode)
| where status == 'Succeeded'
| project 
    timestamp,
    runId,
    status,
    statusCode,
    message
| order by timestamp desc
```

### SQL Execution Errors

```kql
traces
| where timestamp > ago(24h)
| where message contains 'Upsert_Employee'
| where message contains 'Failed' or (message contains 'error' and not(message contains 'Skipped'))
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| extend errorObject = properties.error
| extend
    errorCode = tostring(errorObject.code),
    errorMessage = tostring(errorObject.message)
| project 
    timestamp,
    runId,
    errorCode,
    errorMessage,
    fullMessage = message
| order by timestamp desc
```

---

## ✅ Responses

### HTTP Request Summary (Success/Failure)

```kql
requests
| where timestamp > ago(24h)
| where name contains 'wf-employee-upsert'
| extend duration_sec = duration / 1000
| project 
    timestamp,
    resultCode,
    success,
    duration_sec,
    httpMethod = tostring(customDimensions.HttpMethod)
| order by timestamp desc
```

### Response Action Status

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where (message contains 'Return_Success' or message contains 'Return_Error') and message contains 'action ends'
| extend 
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    actionName = tostring(customDimensions.prop__actionName),
    status = tostring(customDimensions.prop__status),
    statusCode = tostring(customDimensions.prop__statusCode),
    duration = toint(customDimensions.prop__durationInMilliseconds)
| project 
    timestamp,
    runId,
    actionName,
    status,
    statusCode,
    duration
| order by timestamp desc
```

---

## ⚡ Performance

### Action Duration Analysis

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert' and message contains 'action ends'
| extend 
    actionName = tostring(customDimensions.prop__actionName),
    duration = toint(customDimensions.prop__durationInMilliseconds),
    status = tostring(customDimensions.prop__status)
| where isnotempty(duration) and duration >= 0
| summarize 
    Count = count(),
    AvgDuration = avg(duration),
    MinDuration = min(duration),
    MaxDuration = max(duration),
    SuccessCount = countif(status == 'Succeeded'),
    FailCount = countif(status == 'Failed')
    by actionName
| extend SuccessRate = round((SuccessCount * 100.0) / Count, 2)
| project 
    actionName,
    Count,
    SuccessRate,
    AvgDuration = round(AvgDuration, 2),
    MinDuration,
    MaxDuration
| order by AvgDuration desc
```

### Workflow Execution Duration

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'Workflow run ends'
| extend 
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    duration = toint(customDimensions.prop__durationInMilliseconds),
    status = tostring(customDimensions.prop__status)
| project 
    timestamp,
    runId,
    status,
    duration_ms = duration,
    duration_sec = round(duration / 1000.0, 2)
| order by timestamp desc
```

---

## 📊 Complete Run Timeline

### All Actions for Specific Run

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| extend runId = tostring(customDimensions.prop__flowRunSequenceId)
| where runId == 'YOUR_RUN_ID_HERE'
| extend 
    actionName = tostring(customDimensions.prop__actionName),
    status = tostring(customDimensions.prop__status),
    statusCode = tostring(customDimensions.prop__statusCode),
    duration = toint(customDimensions.prop__durationInMilliseconds),
    actionType = tostring(customDimensions.prop__actionType)
| where message contains 'action ends' or message contains 'action starts'
| extend isEnd = iff(message contains 'action ends', 'End', 'Start')
| project 
    timestamp,
    actionName,
    isEnd,
    status,
    statusCode,
    duration,
    actionType
| order by timestamp asc
```

---

## 🎯 Quick Reference

### Copy-Paste Queries

#### 1. Latest Workflow Run
```kql
traces | where timestamp > ago(1h) and message contains 'Log_Workflow_Start' and message contains 'action ends' | extend properties = parse_json(tostring(customDimensions.prop__properties)), trackedProps = properties.trackedProperties | where isnotempty(trackedProps) | project timestamp, runId=tostring(customDimensions.prop__flowRunSequenceId), employeeCount=toint(trackedProps.employeeCount) | order by timestamp desc | take 1
```

#### 2. Latest Errors
```kql
traces | where timestamp > ago(24h) and message contains 'wf-employee-upsert' and message contains 'Failed' | extend runId = tostring(customDimensions.prop__flowRunSequenceId), actionName = tostring(customDimensions.prop__actionName) | project timestamp, runId, actionName, message | order by timestamp desc | take 5
```

#### 3. Success Rate Last 24 Hours
```kql
requests | where timestamp > ago(24h) and name contains 'wf-employee-upsert' | summarize Total = count(), Success = countif(success == true), Failed = countif(success == false) | extend SuccessRate = round((Success * 100.0) / Total, 2) | project Total, Success, Failed, SuccessRate
```

---

## ⚠️ Important Notes

### What You CAN See:
- ✅ Tracked properties (logLevel, message, runId, employeeId, etc.)
- ✅ Action execution status (Succeeded, Failed, Skipped)
- ✅ HTTP status codes (200, 500)
- ✅ Duration and performance metrics
- ✅ Error codes and messages
- ✅ Workflow execution timeline

### What You CANNOT See:
- ❌ HTTP response body content (JSON sent to client)
- ❌ Compose action outputs (unless tracked)
- ❌ Variable values (workflow doesn't use variables)

### To See Response Body:
Call the workflow endpoint and check the actual HTTP response:
```powershell
Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
```

---

## 📁 Related Documentation

- **FINAL_TRACKED_PROPERTIES_SOLUTION.md** - Complete tracked properties guide
- **QUICK_REFERENCE_LOGS.md** - Quick copy-paste reference
- **ERROR_AND_RESPONSE_QUERIES.md** - Detailed error queries

---

## 🚀 Tested With

- **Application Insights**: ais-training-la
- **Latest RunId**: 08584388281328701344570158559CU00
- **Status**: ✅ All queries working
- **Timestamp**: 2025-11-10 12:45:56 UTC

All queries verified and production-ready! 🎉
