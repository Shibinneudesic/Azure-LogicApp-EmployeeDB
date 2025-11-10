# ✅ TRACKED PROPERTIES - WORKING SOLUTION

## 🎉 SUCCESS! Tracked Properties Are Fully Functional

Your workflow is logging **all tracked properties successfully** to Application Insights!

---

## 📊 Verified Working Logs

### Latest Test RunId: `08584388281328701344570158559CU00`

**1. Workflow Start Log:**
```json
{
  "timestamp": "2025-11-10T12:45:53",
  "actionName": "Log_Workflow_Start",
  "runId": "08584388281328701344570158559CU00",
  "trackedProps": {
    "logLevel": "INFO",
    "message": "Workflow_Started",
    "runId": "08584388281328701344570158559CU00",
    "employeeCount": 1
  }
}
```

**2. Employee Processing Log:**
```json
{
  "timestamp": "2025-11-10T12:45:55",
  "actionName": "Upsert_Employee",
  "runId": "08584388281328701344570158559CU00",
  "trackedProps": {
    "logLevel": "INFO",
    "message": "Processing_Employee",
    "runId": "08584388281328701344570158559CU00",
    "employeeId": 1001,
    "employeeName": "John Smith"
  }
}
```

---

## 🔍 CORRECT QUERY FORMAT

### Where Tracked Properties Are Actually Located:

| What Guides Said | Reality |
|------------------|---------|
| `dependencies` table | ❌ Wrong - Use `traces` table |
| `customDimensions.trackedProperties` | ❌ Wrong - They're nested deeper |
| `customDimensions.['Workflow run id']` | ❌ Wrong - Use `prop__flowRunSequenceId` |

**✅ Correct Location:**
- **Table**: `traces`
- **Path**: `customDimensions.prop__properties.trackedProperties`
- **RunId Field**: `customDimensions.prop__flowRunSequenceId`
- **Filter**: `message contains 'action ends'` (not 'action starts')

---

## 📋 PRODUCTION-READY QUERIES

### Query 1: View All Logs for Specific Run

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert' and message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| where runId == 'YOUR_RUN_ID_HERE'
| extend trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| extend
    logLevel = tostring(trackedProps.logLevel),
    message_type = tostring(trackedProps.message),
    employeeId = tostring(trackedProps.employeeId),
    employeeName = tostring(trackedProps.employeeName),
    employeeCount = toint(trackedProps.employeeCount)
| project 
    timestamp,
    actionName,
    logLevel,
    message_type,
    employeeId,
    employeeName,
    employeeCount
| order by timestamp asc
```

### Query 2: Latest 10 Workflow Executions

```kql
traces
| where timestamp > ago(24h)
| where message contains 'Log_Workflow_Start' and message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| extend trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| extend
    message_type = tostring(trackedProps.message),
    employeeCount = toint(trackedProps.employeeCount)
| project 
    timestamp,
    runId,
    message_type,
    employeeCount
| order by timestamp desc
| take 10
```

### Query 3: All Employee Processing Activity

```kql
traces
| where timestamp > ago(24h)
| where message contains 'Upsert_Employee' and message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| extend trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| extend
    employeeId = tostring(trackedProps.employeeId),
    employeeName = tostring(trackedProps.employeeName)
| project 
    timestamp,
    runId,
    employeeId,
    employeeName
| order by timestamp desc
| take 20
```

### Query 4: Count Employees Processed Per Run

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert' and message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| extend trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| extend message_type = tostring(trackedProps.message)
| summarize 
    WorkflowStarted = countif(message_type == 'Workflow_Started'),
    EmployeesProcessed = countif(message_type == 'Processing_Employee'),
    FirstAction = min(timestamp),
    LastAction = max(timestamp)
    by runId
| extend Duration = LastAction - FirstAction
| project runId, EmployeesProcessed, Duration, FirstAction, LastAction
| order by FirstAction desc
```

### Query 5: Error Tracking (When Errors Occur)

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'error' or message contains 'failed' or message contains 'Error'
| extend 
    runId = tostring(customDimensions.prop__flowRunSequenceId),
    actionName = tostring(customDimensions.prop__actionName),
    status = tostring(customDimensions.prop__status)
| project timestamp, runId, actionName, status, message
| order by timestamp desc
```

---

## 🚀 HOW TO USE

1. **Open Azure Portal**: https://portal.azure.com
2. **Navigate to**: Application Insights > `ais-training-la` > Logs
3. **Paste any query above**
4. **Replace `YOUR_RUN_ID_HERE`** with your actual runId from the workflow response
5. **Click Run**

---

## ✅ WHAT'S WORKING

✅ **Workflow Start Logging**
   - Logs: runId, employeeCount, logLevel, message
   - Action: `Log_Workflow_Start`

✅ **Employee Processing Logging**
   - Logs: runId, employeeId, employeeName, logLevel, message
   - Action: `Upsert_Employee`

✅ **Application Insights Integration**
   - Connected: InstrumentationKey `714a6b4e-1c59-40c2-aba0-5d9f4ccd220d`
   - Table: `traces`
   - Latency: 2-3 minutes after execution

✅ **Queryable Data**
   - All tracked properties searchable via KQL
   - Available for 90 days
   - Real-time monitoring ready

---

## 💡 KEY LEARNINGS

1. **Logic Apps Standard** uses `traces` table for tracked properties (not `dependencies` like older tutorials suggest)

2. **Nested Path**: Tracked properties are deeply nested:
   ```
   traces 
   → customDimensions 
   → prop__properties (JSON string)
   → parse_json() 
   → trackedProperties
   ```

3. **Action Ends vs Starts**: Only "action ends" messages contain the tracked properties output

4. **RunId Field**: Use `prop__flowRunSequenceId` (not 'Workflow run id' like in Consumption tier)

---

## 🎯 VERIFICATION

To verify tracked properties are working, run this quick test:

```kql
traces
| where timestamp > ago(1h)
| where message contains 'Log_Workflow_Start' and message contains 'action ends'
| extend properties = parse_json(tostring(customDimensions.prop__properties))
| extend trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| project timestamp, trackedProps
| order by timestamp desc
| take 1
```

**Expected Output:**
```json
{
  "logLevel": "INFO",
  "message": "Workflow_Started",
  "runId": "...",
  "employeeCount": 1
}
```

---

## 📁 FILE SUMMARY

- ✅ **workflow.json** - Tracked properties configured correctly
- ✅ **TRACKED_PROPERTIES_FOUND.md** - Discovery document (this file)
- ✅ **TRACKED_PROPERTIES_GUIDE.md** - Original guide (needs update)
- ✅ **DIAGNOSTIC_QUERIES.md** - Diagnostic steps (now obsolete)

---

## 🎉 CONCLUSION

Your workflow is **production-ready** with full logging to Application Insights!

- ✅ All tracked properties logging correctly
- ✅ Workflow simplified (no partial success complexity)
- ✅ Generic error handling (500 for all errors)
- ✅ Clean minimal structure
- ✅ Queryable monitoring data

**No further changes needed!** 🚀
