# Enhanced Logging Quick Reference

## Log Fields Summary

### 🔵 Workflow Start
```json
{
  "logLevel": "INFO",
  "message": "Workflow execution started",
  "workflowName": "wf-employee-upsert",
  "runId": "08585329112...",
  "correlationId": "/runs/08585329112.../",
  "triggerTime": "2025-11-10T10:30:00Z",
  "requestCount": 5,
  "requestSize": 1234,
  "hasRequestBody": true,
  "triggerType": "When_a_HTTP_request_is_received"
}
```
**Key Metrics:** requestCount, requestSize, triggerTime

---

### ✅ Schema Validation Success
```json
{
  "logLevel": "INFO",
  "message": "Request schema validation passed",
  "employeeCount": 5,
  "employeeIds": "[1,2,3,4,5]",
  "schemaVersion": "employee-upsert-v1.0",
  "allRequiredFieldsPresent": true
}
```
**Key Metrics:** employeeCount, schemaVersion

---

### ❌ Schema Validation Failure
```json
{
  "logLevel": "ERROR",
  "message": "JSON schema validation failed",
  "errorCode": "InvalidJSONSchema",
  "errorMessage": "Required property 'firstName' is missing",
  "requestBodySize": 1234,
  "requestBodyPreview": "{ employees: { employee: [...]",
  "validationFailureReason": "Request does not match expected schema"
}
```
**Key Metrics:** errorCode, errorMessage, requestBodyPreview

---

### 🚀 Processing Start
```json
{
  "logLevel": "INFO",
  "message": "Starting employee processing",
  "employeeCount": 5,
  "processingMode": "Batch",
  "targetDatabase": "SQL Server",
  "operation": "Upsert (Insert/Update)",
  "estimatedDuration": "10 seconds"
}
```
**Key Metrics:** employeeCount, estimatedDuration

---

### 👤 Employee Processing
```json
{
  "logLevel": "INFO",
  "message": "Processing employee upsert",
  "employeeId": 1,
  "employeeName": "John Doe",
  "employeeData": { /* all fields */ },
  "operation": "Executing stored procedure usp_Employee_Upsert",
  "currentProgress": "1 of 5"
}
```
**Key Metrics:** employeeId, employeeData, currentProgress

---

### ✅ Employee Success
```json
{
  "logLevel": "INFO",
  "message": "Employee upserted successfully",
  "employeeId": 1,
  "employeeName": "John Doe",
  "actionStatus": "Succeeded",
  "executionDuration": "PT2.5S",
  "recordsAffected": 1,
  "successCount": 1
}
```
**Key Metrics:** executionDuration, recordsAffected, successCount

---

### ❌ Employee Failure
```json
{
  "logLevel": "ERROR",
  "message": "Failed to upsert employee",
  "employeeId": 1,
  "employeeName": "John Doe",
  "errorCode": "ServiceUnavailable",
  "errorMessage": "Connection timeout",
  "failureType": "DatabaseError",
  "retryable": true,
  "troubleshooting": "Check database connectivity..."
}
```
**Key Metrics:** errorCode, failureType, retryable

---

### 🏁 Processing Complete
```json
{
  "logLevel": "INFO",
  "message": "Employee processing completed",
  "totalRequested": 5,
  "totalProcessed": 4,
  "totalFailed": 1,
  "successRate": "80%",
  "failureRate": "20%",
  "processingStatus": "Partial Success"
}
```
**Key Metrics:** successRate, totalProcessed, totalFailed

---

### 🎯 Complete Success
```json
{
  "logLevel": "INFO",
  "message": "All employees processed successfully - 100% success rate",
  "responseCode": 200,
  "successRate": "100%",
  "performanceMetrics": {
    "employeesPerSecond": 0.33,
    "avgProcessingTime": "3 seconds per employee"
  }
}
```
**Key Metrics:** successRate, employeesPerSecond

---

### ⚠️ Partial Success
```json
{
  "logLevel": "WARN",
  "message": "Partial success - Some employees failed to process",
  "responseCode": 207,
  "successfulOperations": 4,
  "failedOperations": 1,
  "successRate": "80%",
  "failedEmployeeIds": "[{id:5,...}]",
  "recommendedAction": "Review failed employees and retry individually"
}
```
**Key Metrics:** successRate, failedOperations, failedEmployeeIds

---

### 🔴 Critical Error
```json
{
  "logLevel": "CRITICAL",
  "message": "Critical error in workflow execution - Workflow terminated",
  "failedScope": "Try",
  "errorCount": 1,
  "impactedEmployees": 5,
  "alertSeverity": "High",
  "requiresInvestigation": true,
  "recoveryAction": "Review error details, fix issues, and retry the request"
}
```
**Key Metrics:** errorCount, impactedEmployees, alertSeverity

---

## Log Level Priority

| Level | Icon | Usage | Alert |
|-------|------|-------|-------|
| INFO | 🔵 | Normal operations | No |
| WARN | ⚠️ | Partial failures | Optional |
| ERROR | ❌ | Operation failures | Yes |
| CRITICAL | 🔴 | Workflow terminated | Immediate |

---

## Common KQL Queries

### Find all errors for a specific runId
```kusto
traces
| where customDimensions.runId == "YOUR_RUN_ID"
| where customDimensions.logLevel in ("ERROR", "CRITICAL")
| project timestamp, message, customDimensions
```

### Calculate average success rate (last 24 hours)
```kusto
traces
| where timestamp > ago(24h)
| where message contains "Processing completed"
| extend successRate = todouble(customDimensions.successRate)
| summarize AvgSuccessRate = avg(successRate)
```

### Find failed employees
```kusto
traces
| where customDimensions.logLevel == "ERROR"
| where message contains "Failed to upsert employee"
| project timestamp, 
          employeeId=customDimensions.employeeId, 
          error=customDimensions.errorMessage
| order by timestamp desc
```

### Monitor performance
```kusto
traces
| where message contains "Processing completed"
| extend duration = todouble(customDimensions.totalDuration)
| summarize AvgDuration = avg(duration), MaxDuration = max(duration)
```

---

## Troubleshooting Guide

### Issue: High Failure Rate
**Look for:**
- `Log_Employee_Error` entries
- `errorCode` and `errorMessage` fields
- `failureType` (DatabaseError, Timeout, etc.)
- `retryable` flag

**Action:**
- Check database connectivity
- Review error patterns
- Retry failed employees individually

---

### Issue: Schema Validation Failures
**Look for:**
- `Log_Schema_Validation_Error` entries
- `requestBodyPreview` field
- `errorMessage` for specific validation issues

**Action:**
- Validate request format
- Check required fields (id, firstName, lastName)
- Ensure field types are correct

---

### Issue: Slow Performance
**Look for:**
- `executionDuration` in success logs
- `employeesPerSecond` metric
- `avgProcessingTime` in complete success logs

**Action:**
- Review database performance
- Check network latency
- Consider batch size optimization

---

### Issue: Workflow Termination
**Look for:**
- `Log_Critical_Error` entries
- `failedActions` array
- `firstError` details

**Action:**
- Review error details
- Check workflow configuration
- Validate connections and permissions

---

## Response Codes

| Code | Status | Meaning |
|------|--------|---------|
| 200 | ✅ Success | All employees processed |
| 207 | ⚠️ Partial | Some succeeded, some failed |
| 400 | ❌ Error | Validation failure |
| 500 | 🔴 Critical | Workflow failure |

---

## Key Correlation Fields

Use these to track across logs:
- `runId` - Unique execution identifier
- `correlationId` - Full correlation path
- `employeeId` - Individual employee tracking
- `timestamp` - Chronological ordering
