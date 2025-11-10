# 🎯 QUICK REFERENCE - View Logs in Application Insights

## ⚡ Fastest Way to View Your Logs

### Open Application Insights
**Portal**: https://portal.azure.com  
**Navigate**: Application Insights → `ais-training-la` → Logs

---

## 📊 COPY-PASTE QUERIES

### 1️⃣ View Specific Run (Replace YOUR_RUN_ID)

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert' and message contains 'action ends'
| extend properties = parse_json(tostring(customDimensions.prop__properties))
| extend trackedProps = properties.trackedProperties, runId = tostring(customDimensions.prop__flowRunSequenceId)
| where runId == 'YOUR_RUN_ID_HERE' and isnotempty(trackedProps)
| extend logLevel = tostring(trackedProps.logLevel), msg = tostring(trackedProps.message), empId = tostring(trackedProps.employeeId), empName = tostring(trackedProps.employeeName)
| project timestamp, action=tostring(customDimensions.prop__actionName), logLevel, msg, empId, empName
| order by timestamp asc
```

---

### 2️⃣ Last 10 Workflows

```kql
traces
| where timestamp > ago(24h) and message contains 'Log_Workflow_Start' and message contains 'action ends'
| extend properties = parse_json(tostring(customDimensions.prop__properties)), trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| project timestamp, runId=tostring(customDimensions.prop__flowRunSequenceId), employeeCount=toint(trackedProps.employeeCount)
| order by timestamp desc | take 10
```

---

### 3️⃣ All Recent Employee Processing

```kql
traces
| where timestamp > ago(24h) and message contains 'Upsert_Employee' and message contains 'action ends'
| extend properties = parse_json(tostring(customDimensions.prop__properties)), trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| project timestamp, runId=tostring(customDimensions.prop__flowRunSequenceId), empId=tostring(trackedProps.employeeId), empName=tostring(trackedProps.employeeName)
| order by timestamp desc | take 20
```

---

## 🎯 Latest Test Data

**RunId**: `08584388281328701344570158559CU00`  
**Time**: 2025-11-10 12:45:53 UTC  
**Result**: ✅ 200 SUCCESS

**Logged Data:**
- ✅ Workflow_Started (employeeCount: 1)
- ✅ Processing_Employee (employeeId: 1001, employeeName: John Smith)

---

## 💡 Pro Tips

1. **Wait 2-3 minutes** after workflow runs
2. **Change time range** if needed: `ago(2h)`, `ago(7d)`
3. **Get runId** from workflow HTTP response JSON
4. **Table**: Always use `traces` (NOT dependencies)
5. **Filter**: Must include `'action ends'`

---

## ✅ Working Configuration

**Application Insights**: ais-training-la  
**Connection**: ✅ Connected  
**Tracked Actions**:
- Log_Workflow_Start
- Upsert_Employee

**Tracked Properties**:
- logLevel, message, runId, employeeCount, employeeId, employeeName

---

## 📁 More Details

See: `FINAL_TRACKED_PROPERTIES_SOLUTION.md` for full documentation
