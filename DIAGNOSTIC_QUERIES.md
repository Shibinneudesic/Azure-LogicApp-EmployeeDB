# 🔍 DIAGNOSTIC QUERIES FOR TRACKED PROPERTIES
# Run these queries in Application Insights > Logs
# Latest Test RunId: 08584388281328701344570158559CU00

---

## ⚠️ CRITICAL: Wait 2-3 minutes after workflow execution!

---

## 🎯 STEP-BY-STEP DIAGNOSTIC APPROACH

### STEP 1: Verify Application Insights is Receiving Data
**Purpose**: Confirm basic connectivity

```kql
dependencies
| where timestamp > ago(2h)
| where cloud_RoleName contains 'ais-training-la'
| take 10
```

**Expected Result**: Should see some rows
**If Empty**: Application Insights may not be connected or no workflows ran recently


---

### STEP 2: Check for Workflow Requests
**Purpose**: Verify workflow actually executed

```kql
requests
| where timestamp > ago(2h)
| where cloud_RoleName contains 'ais-training-la'
| where name contains 'wf-employee-upsert'
| project timestamp, name, resultCode, duration, customDimensions
| order by timestamp desc
```

**Expected Result**: Should see HTTP requests with 200/500 status codes
**If Empty**: Workflow didn't execute or wrong time range


---

### STEP 3: Find Dependencies for Specific Run
**Purpose**: Get raw dependency data for your runId

Replace `YOUR_RUN_ID` with actual runId from response (e.g., 08584388281328701344570158559CU00)

```kql
dependencies
| where timestamp > ago(2h)
| where cloud_RoleName contains 'ais-training-la'
| extend workflowRunId = tostring(customDimensions.['Workflow run id'])
| where workflowRunId == 'YOUR_RUN_ID'
| project 
    timestamp, 
    name, 
    type,
    target,
    data,
    customDimensions
| order by timestamp asc
```

**Expected Result**: Should see multiple rows (workflow actions)
**If Empty**: 
- Check runId is correct
- Try wider time range: `ago(24h)`
- Workflow may have failed before tracking


---

### STEP 4: Inspect Custom Dimensions
**Purpose**: See what's actually in customDimensions

```kql
dependencies
| where timestamp > ago(2h)
| extend workflowRunId = tostring(customDimensions.['Workflow run id'])
| where workflowRunId == 'YOUR_RUN_ID'
| extend 
    trackedPropsExists = isnotempty(customDimensions.trackedProperties),
    trackedPropsRaw = tostring(customDimensions.trackedProperties)
| project 
    timestamp,
    name,
    trackedPropsExists,
    trackedPropsRaw,
    allCustomDimensions = customDimensions
| order by timestamp asc
```

**Expected Result**: 
- `trackedPropsExists` = true for Log_Workflow_Start and Upsert_Employee
- `trackedPropsRaw` = JSON string like {"logLevel":"INFO",...}

**If trackedPropsExists = false**: Tracked properties not configured on that action


---

### STEP 5: Parse and Display Tracked Properties
**Purpose**: Final view of all tracked data

```kql
dependencies
| where timestamp > ago(2h)
| extend workflowRunId = tostring(customDimensions.['Workflow run id'])
| where workflowRunId == 'YOUR_RUN_ID'
| extend trackedPropsRaw = tostring(customDimensions.trackedProperties)
| where isnotempty(trackedPropsRaw)
| extend trackedProps = parse_json(trackedPropsRaw)
| extend
    logLevel = tostring(trackedProps.logLevel),
    message = tostring(trackedProps.message),
    runId = tostring(trackedProps.runId),
    employeeId = tostring(trackedProps.employeeId),
    employeeName = tostring(trackedProps.employeeName),
    employeeCount = tostring(trackedProps.employeeCount)
| project 
    timestamp,
    actionName = name,
    logLevel,
    message,
    employeeId,
    employeeName,
    employeeCount
| order by timestamp asc
```

**Expected Result**:
```
timestamp               | actionName        | logLevel | message              | employeeId | employeeName | employeeCount
------------------------|-------------------|----------|----------------------|------------|--------------|---------------
2025-11-10 12:45:56     | Log_Workflow_Start| INFO     | Workflow_Started     | null       | null         | 1
2025-11-10 12:45:57     | Upsert_Employee   | INFO     | Processing_Employee  | 1001       | John Smith   | null
```


---

## 🔧 ALTERNATIVE: Check All Recent Runs

```kql
dependencies
| where timestamp > ago(24h)
| where cloud_RoleName contains 'ais-training-la'
| extend 
    workflowRunId = tostring(customDimensions.['Workflow run id']),
    trackedPropsRaw = tostring(customDimensions.trackedProperties)
| where isnotempty(trackedPropsRaw)
| extend trackedProps = parse_json(trackedPropsRaw)
| extend
    message = tostring(trackedProps.message),
    employeeId = tostring(trackedProps.employeeId)
| summarize 
    Actions = count(),
    Messages = make_set(message)
    by workflowRunId, timestamp = bin(timestamp, 1m)
| order by timestamp desc
| take 20
```

**Purpose**: See all recent runs that have tracked properties


---

## 📊 VERIFICATION CHECKLIST

- [ ] Step 1 returns rows → Application Insights connected ✅
- [ ] Step 2 returns rows → Workflow executing ✅  
- [ ] Step 3 returns rows → Dependencies logged for runId ✅
- [ ] Step 4 shows `trackedPropsExists = true` → Tracked properties configured ✅
- [ ] Step 5 shows parsed data → Fully working ✅

If any step fails, that's where the issue is!


---

## 🎯 QUICK TEST QUERIES

### Check Last 10 Workflow Runs
```kql
requests
| where timestamp > ago(24h)
| where name contains 'wf-employee-upsert'
| project 
    timestamp,
    resultCode,
    runId = tostring(customDimensions.['Workflow run id']),
    duration
| order by timestamp desc
| take 10
```

### Count Tracked Properties by Message Type
```kql
dependencies
| where timestamp > ago(24h)
| where cloud_RoleName contains 'ais-training-la'
| extend trackedProps = parse_json(tostring(customDimensions.trackedProperties))
| extend message = tostring(trackedProps.message)
| where isnotempty(message)
| summarize Count = count() by message
```

Expected:
- Workflow_Started: X
- Processing_Employee: Y (where Y = total employees processed)


---

## 💡 COMMON ISSUES

### Issue: "No results found from the specified time range"

**Solutions**:
1. Change `ago(24h)` to `ago(2h)` or `ago(7d)`
2. Wait 2-3 minutes after test
3. Verify runId is correct (copy from response JSON)
4. Check Application Insights workspace (may be in different workspace)

### Issue: Step 1 works but Step 3 returns nothing

**Cause**: Wrong runId or workflow didn't complete
**Solution**: 
- Copy exact runId from workflow response
- Check requests table to see if workflow ran
- Verify workflow didn't fail early (before tracked actions)

### Issue: Step 4 shows `trackedPropsExists = false`

**Cause**: Tracked properties not configured on actions
**Solution**: 
- Verify workflow.json has `trackedProperties` on actions
- Redeploy workflow
- Clear browser cache when viewing workflow in portal


---

## 🚀 CURRENT TEST DATA

**Latest RunId**: `08584388281328701344570158559CU00`
**Test Time**: 2025-11-10 12:45:56 UTC
**Expected Logs**:
- 1x Workflow_Started (employeeCount: 1)
- 1x Processing_Employee (employeeId: 1001, employeeName: John Smith)

Use this runId in the queries above!
