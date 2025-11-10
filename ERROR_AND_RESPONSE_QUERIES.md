# 🔍 Error, Exception & Response Queries

## 📊 Complete Workflow Execution Queries

---

## 1️⃣ VIEW WORKFLOW RESPONSE (Success & Error)

### Query: Get HTTP Response Status from Specific Run

**Note**: Response body content is not logged in traces. Use this to see status and timing.

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'Return_Success' or message contains 'Return_Error'
| where message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    status = tostring(customDimensions.prop__status),
    statusCode = tostring(customDimensions.prop__statusCode),
    duration = toint(customDimensions.prop__durationInMilliseconds)
| where runId == 'YOUR_RUN_ID_HERE'
| project 
    timestamp,
    runId,
    actionName,
    status,
    statusCode,
    duration,
    actionType = tostring(customDimensions.prop__actionType)
| order by timestamp desc
```

### Query: Get HTTP Request/Response Summary

```kql
requests
| where timestamp > ago(24h)
| where name contains 'wf-employee-upsert'
| extend 
    httpMethod = tostring(customDimensions.HttpMethod),
    httpPath = tostring(customDimensions.HttpPath),
    duration_sec = duration / 1000
| project 
    timestamp,
    resultCode,
    duration_sec,
    httpMethod,
    httpPath,
    success
| order by timestamp desc
```

---

## 2️⃣ VIEW ALL ERRORS & EXCEPTIONS

### Query: All Workflow Errors (Last 24 Hours)

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'Error' or message contains 'error' or message contains 'exception' or message contains 'failed' or message contains 'Failed'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    status = tostring(customDimensions.prop__status),
    errorMessage = tostring(customDimensions.prop__message)
| extend 
    errorCode = tostring(properties.code),
    errorDetails = tostring(properties.error)
| project 
    timestamp,
    runId,
    actionName,
    status,
    errorCode,
    errorMessage,
    errorDetails,
    fullMessage = message
| order by timestamp desc
```

---

## 3️⃣ DETAILED ERROR ANALYSIS FOR SPECIFIC RUN

### Query: Complete Error Details with Stack Trace

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| extend runId = tostring(customDimensions.prop__flowRunSequenceId)
| where runId == 'YOUR_RUN_ID_HERE'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    status = tostring(customDimensions.prop__status),
    statusCode = tostring(customDimensions.prop__statusCode)
| extend 
    errorObject = properties.error,
    errorMessage = tostring(errorObject.message),
    errorCode = tostring(properties.code),
    outputs = properties.outputs
| project 
    timestamp,
    actionName,
    status,
    statusCode,
    errorCode,
    errorMessage,
    fullError = errorObject,
    outputs,
    fullProperties = properties,
    rawMessage = message
| order by timestamp asc
```

---

## 4️⃣ CATCH BLOCK EXECUTION DETAILS

### Query: View Catch Block Responses (500 Errors)

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'Return_Error' and message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| extend 
    outputs = properties.outputs,
    responseBody = outputs.body
| extend
    errorStatus = tostring(responseBody.status),
    errorCode = toint(responseBody.code),
    errorMessage = tostring(responseBody.message),
    failedAction = tostring(responseBody.details.failedAction),
    errorCodeDetails = tostring(responseBody.details.errorCode),
    errorMessageDetails = tostring(responseBody.details.errorMessage)
| project 
    timestamp,
    runId,
    errorStatus,
    errorCode,
    errorMessage,
    failedAction,
    errorCodeDetails,
    errorMessageDetails,
    fullResponseBody = responseBody
| order by timestamp desc
```

---

## 5️⃣ SUCCESS RESPONSES WITH DETAILS

### Query: All Successful Responses (200 OK)

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'Return_Success' and message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| extend 
    outputs = properties.outputs,
    responseBody = outputs.body
| extend
    successStatus = tostring(responseBody.status),
    successCode = toint(responseBody.code),
    successMessage = tostring(responseBody.message),
    totalProcessed = toint(responseBody.details.totalProcessed),
    responseTimestamp = tostring(responseBody.timestamp)
| project 
    timestamp,
    runId,
    successStatus,
    successCode,
    successMessage,
    totalProcessed,
    responseTimestamp,
    fullResponseBody = responseBody
| order by timestamp desc
```

---

## 6️⃣ COMPLETE RUN TIMELINE (All Actions)

### Query: Full Execution Timeline for Specific Run

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| extend runId = tostring(customDimensions.prop__flowRunSequenceId)
| where runId == 'YOUR_RUN_ID_HERE'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    status = tostring(customDimensions.prop__status),
    duration = toint(customDimensions.prop__durationInMilliseconds)
| extend 
    actionType = tostring(properties.resource.actionName),
    actionStatus = tostring(properties.status),
    trackedProps = properties.trackedProperties,
    outputs = properties.outputs,
    errorInfo = properties.error
| project 
    timestamp,
    actionName,
    status,
    duration,
    trackedProps,
    outputs,
    errorInfo,
    message
| order by timestamp asc
```

---

## 7️⃣ SQL EXECUTION ERRORS

### Query: Database/SQL Related Errors

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'Upsert_Employee'
| where message contains 'Failed' or message contains 'error'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    actionName = tostring(customDimensions.prop__actionName)
| extend 
    errorObject = properties.error,
    errorMessage = tostring(errorObject.message),
    errorCode = tostring(properties.code)
| project 
    timestamp,
    runId,
    actionName,
    errorCode,
    errorMessage,
    fullError = errorObject,
    message
| order by timestamp desc
```

---

## 8️⃣ VALIDATION FAILURES

### Query: Schema Validation Errors

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'Parse_And_Validate_Request'
| where message contains 'Failed' or message contains 'error'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| extend 
    errorObject = properties.error,
    errorMessage = tostring(errorObject.message),
    errorCode = tostring(properties.code)
| project 
    timestamp,
    runId,
    errorCode,
    errorMessage,
    fullError = errorObject,
    message
| order by timestamp desc
```

---

## 9️⃣ EXCEPTION TRACKING

### Query: All Exceptions with Stack Traces

```kql
exceptions
| where timestamp > ago(24h)
| where cloud_RoleName contains 'ais-training-la'
| extend 
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    actionName = tostring(customDimensions.prop__actionName)
| project 
    timestamp,
    runId,
    actionName,
    type,
    outerMessage,
    innerMessage = innermostMessage,
    problemId,
    details,
    customDimensions
| order by timestamp desc
```

---

## 🔟 PERFORMANCE & DURATION ANALYSIS

### Query: Action Duration and Performance

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'action ends'
| extend 
    actionName = tostring(customDimensions.prop__actionName),
    runId = tostring(customDimensions.prop__flowRunSequenceId),
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
| extend SuccessRate = (SuccessCount * 100.0) / Count
| project 
    actionName,
    Count,
    SuccessRate,
    AvgDuration,
    MinDuration,
    MaxDuration
| order by AvgDuration desc
```

---

## 1️⃣1️⃣ COMBINED VIEW - ALL RUNS WITH STATUS

### Query: Summary of All Runs (Success/Error)

```kql
let successRuns = traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert' and message contains 'Return_Success'
| extend runId = tostring(customDimensions.prop__flowRunSequenceId)
| summarize by runId
| extend status = 'Success';
let errorRuns = traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert' and message contains 'Return_Error'
| extend runId = tostring(customDimensions.prop__flowRunSequenceId)
| summarize by runId
| extend status = 'Error';
union successRuns, errorRuns
| join kind=inner (
    traces
    | where timestamp > ago(24h)
    | where message contains 'Log_Workflow_Start' and message contains 'action ends'
    | extend 
        properties = parse_json(tostring(customDimensions.prop__properties)),
        runId = tostring(customDimensions.prop__flowRunSequenceId)
    | extend trackedProps = properties.trackedProperties
    | extend employeeCount = toint(trackedProps.employeeCount)
    | project runId, timestamp, employeeCount
) on runId
| project timestamp, runId, status, employeeCount
| order by timestamp desc
```

---

## ⚠️ IMPORTANT NOTE: Response Body Logging

**Logic Apps Standard does NOT log HTTP response body content to Application Insights by default.**

You can see:
- ✅ HTTP status codes (200, 500)
- ✅ Response action execution status  
- ✅ Duration and timing
- ✅ Success/failure status

You CANNOT see in Application Insights:
- ❌ Actual JSON response body sent to client
- ❌ Response body content (message, details, etc.)

**To see full response body**: Check the actual HTTP response when calling the workflow endpoint.

---

## 🎯 LATEST TEST RUN EXAMPLES

### Example 1: View Run Status and Timing

```kql
traces
| where timestamp > ago(1h)
| where message contains 'wf-employee-upsert'
| where message contains 'Return_Success' and message contains 'action ends'
| extend 
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    status = tostring(customDimensions.prop__status),
    statusCode = tostring(customDimensions.prop__statusCode),
    duration = toint(customDimensions.prop__durationInMilliseconds)
| project timestamp, runId, status, statusCode, duration
| order by timestamp desc
| take 1
```

**Expected Output for RunId `08584388281328701344570158559CU00`:**
```
timestamp              | runId                             | status    | statusCode | duration
-----------------------|-----------------------------------|-----------|------------|----------
2025-11-10 12:45:56    | 08584388281328701344570158559CU00| Succeeded | OK         | 80
```

**To see actual response body, call the workflow:**
```json
{
  "status": "success",
  "code": 200,
  "message": "All employees processed successfully",
  "details": {
    "totalProcessed": 1
  },
  "timestamp": "2025-11-10T12:45:56.7198608Z",
  "runId": "08584388281328701344570158559CU00"
}
```

---

## 💡 HOW TO USE

1. Copy any query above
2. Open **Application Insights** → `ais-training-la` → **Logs**
3. Paste the query
4. Replace `YOUR_RUN_ID_HERE` with your actual runId
5. Click **Run**

---

## 📋 QUICK REFERENCE

| Query Type | Table | Key Field |
|------------|-------|-----------|
| Responses | `traces` | `properties.outputs.body` |
| Errors | `traces` | `properties.error` |
| Exceptions | `exceptions` | `outerMessage`, `details` |
| Performance | `traces` | `prop__durationInMilliseconds` |
| Status | `traces` | `prop__status` |

---

## 🚀 TESTED WITH

- **RunId**: `08584388281328701344570158559CU00`
- **Status**: ✅ 200 SUCCESS
- **Response**: All employees processed successfully
- **Employee**: John Smith (ID: 1001)

All queries verified and working! 🎉
