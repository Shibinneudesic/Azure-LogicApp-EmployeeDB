# Application Insights / Log Analytics Query Guide

## How to Access Logs

### Option 1: Application Insights
1. Go to Azure Portal → `ais-training-la` Application Insights
2. Click **Logs** in left menu
3. Run KQL queries below

### Option 2: Log Analytics Workspace
1. Go to Azure Portal → `LAStd-UpsertEmployee-Logs` workspace
2. Click **Logs** in left menu
3. Run KQL queries below

---

## 📊 Query Examples

### 1. View All Workflow Executions (Last 24 hours)
```kql
traces
| where cloud_RoleName == 'ais-training-la'
| where timestamp > ago(24h)
| extend logData = parse_json(message)
| extend logLevel = tostring(logData.logLevel)
| extend runId = tostring(logData.runId)
| extend logMessage = tostring(logData.message)
| where isnotempty(runId)
| project timestamp, logLevel, logMessage, runId
| order by timestamp desc
```

### 2. View Complete Request/Response for Specific Run
```kql
traces
| where cloud_RoleName == 'ais-training-la'
| extend logData = parse_json(message)
| extend runId = tostring(logData.runId)
| where runId == 'YOUR_RUN_ID_HERE'  // Replace with actual runId
| extend logLevel = tostring(logData.logLevel)
| extend logMessage = tostring(logData.message)
| extend requestBody = logData.requestBody
| extend employeeData = logData.employeeData
| extend errorMessage = logData.errorMessage
| project 
    timestamp, 
    logLevel, 
    logMessage, 
    requestBody,
    employeeData,
    errorMessage,
    fullLogData = logData
| order by timestamp asc
```

### 3. View All Errors with Request Details
```kql
traces
| where cloud_RoleName == 'ais-training-la'
| where timestamp > ago(24h)
| extend logData = parse_json(message)
| extend logLevel = tostring(logData.logLevel)
| where logLevel == 'ERROR'
| extend runId = tostring(logData.runId)
| extend errorMessage = tostring(logData.errorMessage)
| extend failedAction = tostring(logData.failedAction)
| extend errorCode = tostring(logData.errorCode)
| extend requestBody = logData.requestBody
| extend requestedEmployeeCount = toint(logData.requestedEmployeeCount)
| project 
    timestamp, 
    runId, 
    errorMessage, 
    failedAction, 
    errorCode,
    requestedEmployeeCount,
    requestBody
| order by timestamp desc
```

### 4. View Successful Runs with Processing Details
```kql
traces
| where cloud_RoleName == 'ais-training-la'
| where timestamp > ago(24h)
| extend logData = parse_json(message)
| extend logLevel = tostring(logData.logLevel)
| extend logMessage = tostring(logData.message)
| where logMessage == 'All employees processed successfully'
| extend runId = tostring(logData.runId)
| extend totalProcessed = toint(logData.totalProcessed)
| project timestamp, runId, totalProcessed, logData
| order by timestamp desc
```

### 5. Track Individual Employee Processing
```kql
traces
| where cloud_RoleName == 'ais-training-la'
| where timestamp > ago(24h)
| extend logData = parse_json(message)
| extend logMessage = tostring(logData.message)
| where logMessage in ('Processing employee', 'Employee upserted successfully')
| extend runId = tostring(logData.runId)
| extend employeeId = toint(logData.employeeId)
| extend employeeName = tostring(logData.employeeName)
| extend employeeData = logData.employeeData
| project timestamp, runId, logMessage, employeeId, employeeName, employeeData
| order by timestamp desc
```

### 6. View Validation Failures
```kql
traces
| where cloud_RoleName == 'ais-training-la'
| where timestamp > ago(24h)
| extend logData = parse_json(message)
| extend logLevel = tostring(logData.logLevel)
| where logLevel == 'ERROR'
| extend runId = tostring(logData.runId)
| extend failedAction = tostring(logData.failedAction)
| where failedAction == 'Parse_And_Validate_Request'
| extend requestBody = logData.requestBody
| extend errorMessage = tostring(logData.errorMessage)
| project timestamp, runId, errorMessage, requestBody
| order by timestamp desc
```

### 7. Performance Monitoring - Count by Status
```kql
traces
| where cloud_RoleName == 'ais-training-la'
| where timestamp > ago(24h)
| extend logData = parse_json(message)
| extend logLevel = tostring(logData.logLevel)
| extend logMessage = tostring(logData.message)
| where logMessage in ('Workflow execution started', 'All employees processed successfully') or logLevel == 'ERROR'
| extend status = case(
    logLevel == 'ERROR', 'Failed',
    logMessage == 'All employees processed successfully', 'Success',
    'Started'
)
| summarize count() by status
| render piechart
```

### 8. View Request and Response Together
```kql
let workflowRuns = traces
| where cloud_RoleName == 'ais-training-la'
| where timestamp > ago(24h)
| extend logData = parse_json(message)
| extend runId = tostring(logData.runId)
| where isnotempty(runId)
| summarize any(logData) by runId;
traces
| where cloud_RoleName == 'ais-training-la'
| where timestamp > ago(24h)
| extend logData = parse_json(message)
| extend runId = tostring(logData.runId)
| extend logMessage = tostring(logData.message)
| where logMessage in ('Workflow execution started', 'All employees processed successfully') or tostring(logData.logLevel) == 'ERROR'
| extend 
    requestBody = logData.requestBody,
    totalProcessed = toint(logData.totalProcessed),
    errorMessage = tostring(logData.errorMessage),
    status = case(
        tostring(logData.logLevel) == 'ERROR', 'FAILED',
        logMessage == 'All employees processed successfully', 'SUCCESS',
        'STARTED'
    )
| project timestamp, runId, status, requestBody, totalProcessed, errorMessage
| order by runId, timestamp asc
```

---

## 🎯 Quick Access to Your Specific Scenario

### Query: Validation Error with Request/Response
```kql
traces
| where cloud_RoleName == 'ais-training-la'
| where timestamp > ago(1h)
| extend logData = parse_json(message)
| extend runId = tostring(logData.runId)
| extend logLevel = tostring(logData.logLevel)
| extend logMessage = tostring(logData.message)
| extend requestBody = logData.requestBody
| extend errorMessage = tostring(logData.errorMessage)
| where logLevel == 'ERROR' or logMessage == 'Workflow execution started'
| project 
    timestamp, 
    runId, 
    logLevel,
    logMessage,
    request = requestBody,
    error = errorMessage
| order by runId, timestamp asc
```

---

## 📝 Log Fields Available

### Workflow Start Log
- `logLevel`: INFO
- `message`: "Workflow execution started"
- `workflowName`: wf-employee-upsert
- `runId`: Unique run identifier
- `requestCount`: Number of employees in request
- `requestBody`: Full request payload

### Validation Success Log
- `logLevel`: INFO
- `message`: "Request validation successful"
- `runId`: Run identifier
- `employeeCount`: Number of employees
- `employees`: Array of employee objects

### Processing Employee Log
- `logLevel`: INFO
- `message`: "Processing employee"
- `runId`: Run identifier
- `employeeId`: Employee ID
- `employeeName`: Employee full name
- `employeeData`: Full employee object

### Employee Success Log
- `logLevel`: INFO
- `message`: "Employee upserted successfully"
- `runId`: Run identifier
- `employeeId`: Employee ID
- `employeeName`: Employee full name

### All Success Log
- `logLevel`: INFO
- `message`: "All employees processed successfully"
- `runId`: Run identifier
- `totalProcessed`: Total count
- `status`: SUCCESS

### Error Log
- `logLevel`: ERROR
- `message`: "Workflow execution failed"
- `runId`: Run identifier
- `failedAction`: Name of failed action
- `errorCode`: Error code
- `errorMessage`: Detailed error message
- `requestBody`: Full request that caused error
- `requestedEmployeeCount`: Count from failed request

---

## 🔍 How to Use

1. **Copy any query above**
2. **Go to Azure Portal**:
   - Application Insights: `ais-training-la` → Logs
   - OR Log Analytics: `LAStd-UpsertEmployee-Logs` → Logs
3. **Paste query and click Run**
4. **Replace placeholders** (like `YOUR_RUN_ID_HERE`) with actual values from error responses

---

## 💡 Pro Tips

- Logs appear within **1-2 minutes** in Application Insights
- Use `runId` from error responses to trace complete execution
- `requestBody` field shows exactly what was sent
- `errorMessage` shows what went wrong
- All timestamps are in UTC
