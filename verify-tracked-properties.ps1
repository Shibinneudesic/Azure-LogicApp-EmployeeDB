# Verify Tracked Properties in Application Insights
# This script provides step-by-step instructions to verify tracked properties

param(
    [string]$RunId = "08584388281328701344570158559CU00"
)

Write-Host @"

====================================================================
📊 VERIFY TRACKED PROPERTIES IN APPLICATION INSIGHTS
====================================================================

Latest RunId: $RunId
Time: $(Get-Date)

IMPORTANT: Wait 2-3 minutes after workflow execution for data to appear!

====================================================================
🔍 VERIFICATION STEPS
====================================================================

1. Open Azure Portal: https://portal.azure.com

2. Navigate to: Application Insights > ais-training-la > Logs

3. Run these queries in order:

====================================================================
QUERY 1: Check if ANY dependencies exist (Basic connectivity test)
====================================================================

dependencies
| where timestamp > ago(1h)
| where cloud_RoleName contains 'ais-training-la'
| take 10

Expected: Should see some dependencies logged by Logic App

====================================================================
QUERY 2: Check for workflow-specific dependencies
====================================================================

dependencies
| where timestamp > ago(1h)
| where cloud_RoleName contains 'ais-training-la'
| extend workflowRunId = tostring(customDimensions.['Workflow run id'])
| where workflowRunId == '$RunId'
| project timestamp, name, customDimensions

Expected: Should see dependencies with your specific runId

====================================================================
QUERY 3: Extract tracked properties (IF Query 2 returns results)
====================================================================

dependencies
| where timestamp > ago(1h)
| extend workflowRunId = tostring(customDimensions.['Workflow run id'])
| where workflowRunId == '$RunId'
| extend trackedProps = tostring(customDimensions.trackedProperties)
| project timestamp, name, trackedProps
| order by timestamp asc

Expected: Should see trackedProperties JSON string

====================================================================
QUERY 4: Parse tracked properties (Final verification)
====================================================================

dependencies
| where timestamp > ago(1h)
| extend workflowRunId = tostring(customDimensions.['Workflow run id'])
| where workflowRunId == '$RunId'
| extend trackedPropsRaw = tostring(customDimensions.trackedProperties)
| where isnotempty(trackedPropsRaw)
| extend trackedProps = parse_json(trackedPropsRaw)
| extend
    logLevel = tostring(trackedProps.logLevel),
    message = tostring(trackedProps.message),
    employeeId = tostring(trackedProps.employeeId)
| project 
    timestamp,
    name,
    logLevel,
    message,
    employeeId,
    allTrackedProps = trackedPropsRaw
| order by timestamp asc

Expected: Should see parsed values like "INFO", "Workflow_Started", etc.

====================================================================
📋 TROUBLESHOOTING
====================================================================

If NO RESULTS:

1. ⏰ Wait Time
   - Tracked properties take 2-3 minutes to appear
   - Try increasing time range: ago(2h) or ago(24h)

2. 🔍 Check Requests Table
   dependencies
   | where timestamp > ago(1h)
   | take 100
   
   If empty: Application Insights may not be receiving ANY data

3. 🔧 Check Application Insights Connection
   - Verify APPLICATIONINSIGHTS_CONNECTION_STRING in App Settings
   - Check if Application Insights is enabled in Logic App

4. 📊 Alternative: Check Requests Table
   requests
   | where timestamp > ago(1h)
   | where name contains 'wf-employee-upsert'
   | project timestamp, name, resultCode, customDimensions

====================================================================
✅ SUCCESS INDICATORS
====================================================================

You should see:
- ✅ Workflow_Started with employeeCount
- ✅ Processing_Employee with employeeId and employeeName
- ✅ Both entries with same runId: $RunId

====================================================================

"@ -ForegroundColor White

Write-Host "💡 TIP: Copy the queries above one at a time into Application Insights" -ForegroundColor Yellow
Write-Host ""
