# 📊 How to View Logs in Application Insights

## ✅ Tracked Properties Are Now Enabled!

The workflow now uses **trackedProperties** which automatically send custom data to Application Insights.

---

## 🔍 Where Tracked Properties Are Logged

### Tracked Actions:
1. **Log_Workflow_Start** - Logs when workflow starts
   - `logLevel`: INFO
   - `message`: Workflow_Started
   - `runId`: Workflow run identifier
   - `employeeCount`: Number of employees in request

2. **Upsert_Employee** - Logs each employee being processed
   - `logLevel`: INFO
   - `message`: Processing_Employee  
   - `runId`: Workflow run identifier
   - `employeeId`: Employee ID
   - `employeeName`: Employee full name

---

## 📋 Application Insights Queries

### 1. View All Workflow Runs with Tracked Properties
```kql
dependencies
| where timestamp > ago(24h)
| where cloud_RoleName contains 'ais-training-la'
| where name contains 'wf-employee-upsert'
| extend 
    workflowRunId = tostring(customDimensions.['Workflow run id']),
    trackedProps = customDimensions.trackedProperties
| where isnotempty(trackedProps)
| project 
    timestamp, 
    name, 
    workflowRunId,
    trackedProperties = trackedProps
| order by timestamp desc
```

### 2. View Specific Run with All Tracked Data

**⚠️ IMPORTANT: Wait 2-3 minutes after workflow execution for data to appear!**

**Step 1: First verify data exists**
```kql
dependencies
| where timestamp > ago(2h)
| where cloud_RoleName contains 'ais-training-la'
| extend workflowRunId = tostring(customDimensions.['Workflow run id'])
| where workflowRunId == 'YOUR_RUN_ID_HERE'
| project timestamp, name, customDimensions
| take 20
```

**Step 2: Extract and parse tracked properties**
```kql
dependencies
| where timestamp > ago(2h)
| extend workflowRunId = tostring(customDimensions.['Workflow run id'])
| where workflowRunId == 'YOUR_RUN_ID_HERE'
| extend trackedPropsRaw = tostring(customDimensions.trackedProperties)
| where isnotempty(trackedPropsRaw)
| extend trackedProps = parse_json(trackedPropsRaw)
| extend
    logLevel = tostring(trackedProps.logLevel),
    message = tostring(trackedProps.message),
    runId = tostring(trackedProps.runId),
    employeeId = tostring(trackedProps.employeeId),
    employeeName = tostring(trackedProps.employeeName),
    employeeCount = toint(trackedProps.employeeCount)
| project 
    timestamp,
    name,
    logLevel,
    message,
    runId,
    employeeId,
    employeeName,
    employeeCount
| order by timestamp asc
```

### 3. View All Employee Processing Logs
```kql
dependencies
| where timestamp > ago(24h)
| where cloud_RoleName contains 'ais-training-la'
| extend trackedProps = parse_json(tostring(customDimensions.trackedProperties))
| where tostring(trackedProps.message) == 'Processing_Employee'
| extend
    runId = tostring(trackedProps.runId),
    employeeId = tostring(trackedProps.employeeId),
    employeeName = tostring(trackedProps.employeeName)
| project 
    timestamp,
    runId,
    employeeId,
    employeeName
| order by timestamp desc
```

### 4. View Workflow Start Logs Only
```kql
dependencies
| where timestamp > ago(24h)
| where cloud_RoleName contains 'ais-training-la'
| extend trackedProps = parse_json(tostring(customDimensions.trackedProperties))
| where tostring(trackedProps.message) == 'Workflow_Started'
| extend
    runId = tostring(trackedProps.runId),
    employeeCount = toint(trackedProps.employeeCount)
| project 
    timestamp,
    runId,
    employeeCount
| order by timestamp desc
```

### 5. Count Employees Processed Per Run
```kql
dependencies
| where timestamp > ago(24h)
| where cloud_RoleName contains 'ais-training-la'
| extend trackedProps = parse_json(tostring(customDimensions.trackedProperties))
| where tostring(trackedProps.message) == 'Processing_Employee'
| extend runId = tostring(trackedProps.runId)
| summarize 
    EmployeesProcessed = count(),
    FirstEmployee = min(timestamp),
    LastEmployee = max(timestamp)
    by runId
| extend ProcessingDuration = LastEmployee - FirstEmployee
| project runId, EmployeesProcessed, ProcessingDuration, FirstEmployee, LastEmployee
| order by FirstEmployee desc
```

### 6. View Complete Run History (Requests + Tracked Data)
```kql
let runs = requests
| where timestamp > ago(24h)
| where cloud_RoleName contains 'ais-training-la'
| where name contains 'wf-employee-upsert'
| extend workflowRunId = tostring(customDimensions.['Workflow run id'])
| project timestamp, workflowRunId, resultCode, duration;
dependencies
| where timestamp > ago(24h)
| where cloud_RoleName contains 'ais-training-la'
| extend 
    workflowRunId = tostring(customDimensions.['Workflow run id']),
    trackedProps = parse_json(tostring(customDimensions.trackedProperties))
| extend
    message = tostring(trackedProps.message),
    employeeId = tostring(trackedProps.employeeId),
    employeeName = tostring(trackedProps.employeeName)
| join kind=inner runs on workflowRunId
| project 
    timestamp,
    workflowRunId,
    resultCode,
    message,
    employeeId,
    employeeName
| order by workflowRunId, timestamp asc
```

---

## 🎯 Quick Access Steps

1. **Go to Azure Portal**
2. Navigate to: **Application Insights** → `ais-training-la`
3. Click **Logs** in the left menu
4. Copy any query above and paste it
5. Replace `YOUR_RUN_ID_HERE` with the `runId` from your response
6. Click **Run**

---

## 💡 What You'll See

### For Successful Runs:
- ✅ **Workflow_Started** log with employee count
- ✅ **Processing_Employee** log for each employee with ID and name
- ✅ HTTP request with 200 status code

### For Failed Runs:
- ❌ **Workflow_Started** log
- ❌ HTTP request with 500 status code
- ❌ Error details in the request customDimensions

---

## ⏱️ Log Availability

- **Tracked Properties** appear in Application Insights within **2-3 minutes**
- Data is available for **90 days** by default
- All tracked data is searchable and queryable

### ⚠️ Troubleshooting "No Results Found"

If you see no results:

1. **Wait Time**: Increase from `ago(24h)` to `ago(2h)` or even `ago(7d)` to widen search
2. **Check Basic Connectivity**: Run this first to verify Application Insights is receiving data:
   ```kql
   dependencies
   | where timestamp > ago(2h)
   | where cloud_RoleName contains 'ais-training-la'
   | take 10
   ```
3. **Check Requests**: Verify workflow executed:
   ```kql
   requests
   | where timestamp > ago(2h)
   | where name contains 'wf-employee-upsert'
   | project timestamp, name, resultCode, customDimensions
   ```
4. **Verify Connection**: Check that `APPLICATIONINSIGHTS_CONNECTION_STRING` is configured in Logic App settings

---

## 📝 Tracked Properties vs Regular Logs

| Feature | Tracked Properties | Compose Logs |
|---------|-------------------|--------------|
| Automatically sent to App Insights | ✅ Yes | ❌ No |
| Queryable in KQL | ✅ Yes | ❌ No |
| Available in Portal | ✅ Yes | ❌ No |
| Performance impact | ⚡ Minimal | ⚡ Minimal |
| Best for | Production monitoring | Debugging only |

---

## 🚀 Example: View Your Last Test Run

Use this runId from your last successful test:
`08584388283971817799443779527CU00`

```kql
dependencies
| where customDimensions.['Workflow run id'] == '08584388283971817799443779527CU00'
| extend trackedProps = parse_json(tostring(customDimensions.trackedProperties))
| extend
    message = tostring(trackedProps.message),
    employeeId = tostring(trackedProps.employeeId),
    employeeName = tostring(trackedProps.employeeName)
| project timestamp, name, message, employeeId, employeeName, trackedProps
| order by timestamp asc
```

You should see:
1. **Workflow_Started** with employeeCount = 1
2. **Processing_Employee** with employeeId = 1001, employeeName = "John Smith"

---

## ✅ Summary

Your workflow now has **production-grade logging** with:
- ✅ Automatic tracking to Application Insights
- ✅ Queryable logs with KQL
- ✅ Employee-level processing details
- ✅ Run correlation with runId
- ✅ No extra cost or performance overhead

All logs are available in **Application Insights → Logs** using the queries above!
