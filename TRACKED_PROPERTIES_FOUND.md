# ✅ TRACKED PROPERTIES ARE WORKING!

## 🎉 Discovery: Tracked Properties Location

The tracked properties ARE being logged, but they're in the `properties` field within the `traces` table, NOT in the `dependencies` or `customDimensions.trackedProperties` like we expected!

## 📊 CORRECTED QUERY - Use This Instead!

### Query 1: View All Tracked Properties for a Specific Run

```kql
traces
| where timestamp > ago(2h)
| where message contains 'wf-employee-upsert'
| where message contains 'action ends'
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

### Query 2: View Latest Test Run (08584388281328701344570158559CU00)

```kql
traces
| where timestamp > ago(2h)
| where message contains 'wf-employee-upsert'
| where message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| where runId == '08584388281328701344570158559CU00'
| extend trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| extend
    logLevel = tostring(trackedProps.logLevel),
    message_type = tostring(trackedProps.message),
    employeeCount = toint(trackedProps.employeeCount)
| project 
    timestamp,
    actionName,
    logLevel,
    message_type,
    employeeCount,
    fullTrackedProps = trackedProps
| order by timestamp asc
```

### Query 3: View All Recent Workflow Runs with Tracked Properties

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| extend trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| extend
    message_type = tostring(trackedProps.message)
| summarize 
    TrackedActions = count(),
    Actions = make_list(actionName),
    Messages = make_set(message_type)
    by runId, bin(timestamp, 1m)
| order by timestamp desc
```

### Query 4: Employee Processing Details

```kql
traces
| where timestamp > ago(24h)
| where message contains 'wf-employee-upsert'
| where message contains 'action ends'
| extend 
    properties = parse_json(tostring(customDimensions.prop__properties)),
    actionName = tostring(customDimensions.prop__actionName),
    runId = tostring(customDimensions.prop__flowRunSequenceId)
| where actionName == 'Upsert_Employee'
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

## 🔍 Example Output for RunId: 08584388281328701344570158559CU00

```
timestamp                | actionName          | logLevel | message_type        | employeeCount
------------------------|---------------------|----------|---------------------|---------------
2025-11-10 12:45:53     | Log_Workflow_Start  | INFO     | Workflow_Started    | 1
```

The tracked properties ARE working! They show:
- ✅ logLevel: INFO
- ✅ message: Workflow_Started
- ✅ runId: 08584388281328701344570158559CU00
- ✅ employeeCount: 1

## 📋 Key Findings

1. **Location**: Tracked properties are in `traces` table → `customDimensions.prop__properties` → `trackedProperties`
2. **Action Filter**: Look for "action ends" messages (not "action starts")
3. **RunId Field**: Use `customDimensions.prop__flowRunSequenceId` (not 'Workflow run id')
4. **Tables**: Use `traces` (NOT `dependencies` or `requests`)

## ✅ Correct Approach

| What We Thought | Reality |
|-----------------|---------|
| dependencies table | **traces table** |
| customDimensions.trackedProperties | **customDimensions.prop__properties.trackedProperties** |
| Workflow run id | **prop__flowRunSequenceId** |
| Available immediately | Still takes 2-3 minutes |

## 🚀 Quick Test

Run this now in Application Insights:

```kql
traces
| where timestamp > ago(1h)
| where message contains 'Log_Workflow_Start'
| where message contains 'action ends'
| extend properties = parse_json(tostring(customDimensions.prop__properties))
| extend trackedProps = properties.trackedProperties
| where isnotempty(trackedProps)
| project timestamp, trackedProps
| order by timestamp desc
| take 5
```

You should see your tracked properties! 🎉
