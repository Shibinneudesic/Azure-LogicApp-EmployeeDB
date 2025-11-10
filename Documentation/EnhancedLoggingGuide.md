# Enhanced Logging Guide - wf-employee-upsert

## Overview
The workflow now includes comprehensive logging at every stage to provide detailed insights for debugging, monitoring, and performance analysis.

## Log Levels

| Level | Usage | Description |
|-------|-------|-------------|
| **INFO** | Normal operations | Successful operations, workflow progress |
| **WARN** | Partial failures | Some operations failed but workflow continues |
| **ERROR** | Operation failures | Individual employee processing failed |
| **CRITICAL** | Workflow failures | Entire workflow terminated due to error |

## Enhanced Log Fields

### Standard Fields (All Logs)
Every log entry now includes:
- `logLevel` - Severity level (INFO/WARN/ERROR/CRITICAL)
- `timestamp` - ISO 8601 timestamp
- `message` - Human-readable description
- `workflowName` - Name of the Logic App workflow
- `runId` - Unique execution ID
- `correlationId` - Full correlation ID for tracking

## Detailed Logging Points

### 1. Workflow Start (`Log_Workflow_Start`)
**Level:** INFO

**Additional Fields:**
```json
{
  "triggerTime": "2025-11-10T10:30:00Z",
  "requestCount": 5,
  "requestSize": 1234,
  "hasRequestBody": true,
  "triggerType": "When_a_HTTP_request_is_received"
}
```

**Use Cases:**
- Track when requests arrive
- Monitor request sizes
- Identify trigger types
- Baseline for performance metrics

---

### 2. Schema Validation Success (`Log_Schema_Valid`)
**Level:** INFO

**Additional Fields:**
```json
{
  "employeeCount": 5,
  "employeeIds": "[1,2,3,4,5]",
  "validationDuration": "2025-11-10T10:30:01Z",
  "schemaVersion": "employee-upsert-v1.0",
  "allRequiredFieldsPresent": true
}
```

**Use Cases:**
- Confirm validation passed
- Track employee IDs in batch
- Schema version tracking
- Validation performance monitoring

---

### 3. Schema Validation Failure (`Log_Schema_Validation_Error`)
**Level:** ERROR

**Additional Fields:**
```json
{
  "actionName": "Parse_And_Validate_Request",
  "errorCode": "InvalidJSONSchema",
  "errorMessage": "Required property 'firstName' is missing",
  "errorDetails": { /* full error object */ },
  "actionStatus": "Failed",
  "requestBodySize": 1234,
  "requestBodyPreview": "{ employees: { employee: [{ id: 1... [truncated]",
  "validationFailureReason": "Request does not match expected schema structure or field requirements"
}
```

**Use Cases:**
- Debug invalid requests
- Identify missing/invalid fields
- Review request structure issues
- Client-side validation improvements

---

### 4. Processing Start (`Log_Starting_Processing`)
**Level:** INFO

**Additional Fields:**
```json
{
  "employeeCount": 5,
  "employeeIdList": "[{id:1,...},{id:2,...}]",
  "processingMode": "Batch",
  "targetDatabase": "SQL Server",
  "operation": "Upsert (Insert/Update)",
  "estimatedDuration": "10 seconds"
}
```

**Use Cases:**
- Track batch processing start
- Monitor database operations
- Performance estimation
- Capacity planning

---

### 5. Individual Employee Processing (`Log_Processing_Employee`)
**Level:** INFO

**Additional Fields:**
```json
{
  "employeeId": 1,
  "employeeName": "John Doe",
  "employeeData": {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "department": "IT",
    "position": "Developer",
    "salary": "75000",
    "email": "john.doe@example.com"
  },
  "operation": "Executing stored procedure usp_Employee_Upsert",
  "currentProgress": "1 of 5"
}
```

**Use Cases:**
- Track individual employee processing
- Debug specific employee data issues
- Monitor real-time progress
- Audit data changes

---

### 6. Employee Upsert Success (`Log_Employee_Success`)
**Level:** INFO

**Additional Fields:**
```json
{
  "employeeId": 1,
  "employeeName": "John Doe",
  "actionName": "Upsert_Employee",
  "actionStatus": "Succeeded",
  "databaseResponse": { /* SQL response */ },
  "executionDuration": "PT2.5S",
  "sqlOperation": "usp_Employee_Upsert",
  "recordsAffected": 1,
  "successCount": 1
}
```

**Use Cases:**
- Confirm successful database operations
- Track execution duration
- Monitor database performance
- Validate records affected

---

### 7. Employee Upsert Failure (`Log_Employee_Error`)
**Level:** ERROR

**Additional Fields:**
```json
{
  "employeeId": 1,
  "employeeName": "John Doe",
  "employeeData": { /* full employee object */ },
  "actionName": "Upsert_Employee",
  "actionStatus": "Failed",
  "errorCode": "ServiceUnavailable",
  "errorMessage": "Connection timeout",
  "errorDetails": { /* full error object */ },
  "sqlQuery": "EXEC usp_Employee_Upsert with parameters",
  "failureType": "DatabaseError",
  "retryable": true,
  "failedCount": 1,
  "troubleshooting": "Check database connectivity, SQL query syntax, and employee data validity"
}
```

**Use Cases:**
- Debug database connection issues
- Identify data validation errors
- Determine if retry is possible
- Root cause analysis
- Troubleshooting guidance

---

### 8. Processing Complete (`Log_Processing_Complete`)
**Level:** INFO

**Additional Fields:**
```json
{
  "totalRequested": 5,
  "totalProcessed": 4,
  "totalFailed": 1,
  "successRate": "80%",
  "failureRate": "20%",
  "processingStatus": "Partial Success",
  "failedEmployeeIds": "5",
  "executionStartTime": "2025-11-10T10:30:00Z",
  "executionEndTime": "2025-11-10T10:30:15Z",
  "totalDuration": "2025-11-10T10:30:15Z"
}
```

**Use Cases:**
- Summary of batch processing
- Calculate success/failure rates
- Performance analysis
- Capacity planning
- SLA monitoring

---

### 9. Complete Success Response (`Log_Complete_Success`)
**Level:** INFO

**Additional Fields:**
```json
{
  "responseCode": 200,
  "totalProcessed": 5,
  "requestedCount": 5,
  "successRate": "100%",
  "failureCount": 0,
  "executionStartTime": "2025-11-10T10:30:00Z",
  "executionEndTime": "2025-11-10T10:30:15Z",
  "performanceMetrics": {
    "employeesPerSecond": 0.33,
    "avgProcessingTime": "3 seconds per employee"
  }
}
```

**Use Cases:**
- Performance benchmarking
- Throughput analysis
- SLA compliance validation
- Success rate monitoring

---

### 10. Partial Success Response (`Log_Partial_Success`)
**Level:** WARN

**Additional Fields:**
```json
{
  "responseCode": 207,
  "totalRequested": 5,
  "successfulOperations": 4,
  "failedOperations": 1,
  "successRate": "80%",
  "failedEmployeesCount": 1,
  "failedEmployeeIds": "[{id:5,error:'...',timestamp:'...'}]",
  "recommendedAction": "Review failed employees and retry individually"
}
```

**Use Cases:**
- Identify partial failures
- Track which employees failed
- Retry guidance
- Alert on degraded performance

---

### 11. Critical Workflow Error (`Log_Critical_Error`)
**Level:** CRITICAL

**Additional Fields:**
```json
{
  "executionStartTime": "2025-11-10T10:30:00Z",
  "failureTime": "2025-11-10T10:30:15Z",
  "failedScope": "Try",
  "failedActions": [
    {
      "action": "Parse_And_Validate_Request",
      "errorCode": "InvalidJSON",
      "errorMessage": "Unexpected token...",
      "status": "Failed"
    }
  ],
  "errorCount": 1,
  "firstError": { /* first error details */ },
  "allErrorMessages": "InvalidJSON; ConnectionTimeout",
  "triggerType": "When_a_HTTP_request_is_received",
  "requestBodySize": 1234,
  "impactedEmployees": 5,
  "recoveryAction": "Review error details, fix issues, and retry the request",
  "alertSeverity": "High",
  "requiresInvestigation": true
}
```

**Use Cases:**
- Critical failure alerts
- Root cause investigation
- Impact assessment
- Incident response
- Recovery planning

---

## Log Analysis Queries

### Azure Log Analytics / Application Insights KQL Queries

#### 1. Success Rate Over Time
```kusto
traces
| where message contains "Processing completed"
| extend successRate = todouble(customDimensions.successRate)
| summarize AvgSuccessRate = avg(successRate) by bin(timestamp, 1h)
| render timechart
```

#### 2. Failed Employees
```kusto
traces
| where customDimensions.logLevel == "ERROR"
| where message contains "Failed to upsert employee"
| project timestamp, employeeId=customDimensions.employeeId, 
          employeeName=customDimensions.employeeName, 
          errorMessage=customDimensions.errorMessage
| order by timestamp desc
```

#### 3. Performance Metrics
```kusto
traces
| where message contains "All employees processed successfully"
| extend employeesPerSecond = todouble(customDimensions.performanceMetrics.employeesPerSecond)
| summarize AvgThroughput = avg(employeesPerSecond), 
            MaxThroughput = max(employeesPerSecond),
            MinThroughput = min(employeesPerSecond)
```

#### 4. Error Distribution
```kusto
traces
| where customDimensions.logLevel in ("ERROR", "CRITICAL")
| summarize Count = count() by ErrorType=customDimensions.failureType
| render piechart
```

#### 5. Workflow Duration Analysis
```kusto
traces
| where message contains "Workflow execution started"
| join kind=inner (
    traces
    | where message contains "Processing completed"
) on $left.customDimensions.runId == $right.customDimensions.runId
| extend duration = datetime_diff('second', timestamp1, timestamp)
| summarize AvgDuration = avg(duration), MaxDuration = max(duration)
```

#### 6. Schema Validation Failures
```kusto
traces
| where customDimensions.logLevel == "ERROR"
| where message contains "schema validation failed"
| project timestamp, runId=customDimensions.runId,
          errorMessage=customDimensions.errorMessage,
          requestPreview=customDimensions.requestBodyPreview
| order by timestamp desc
| take 100
```

---

## Monitoring & Alerting Recommendations

### Critical Alerts
1. **Workflow Failures** - Alert when logLevel = "CRITICAL"
2. **High Failure Rate** - Alert when failureRate > 20%
3. **Schema Validation Failures** - Alert on pattern of validation errors
4. **Database Connectivity** - Alert on repeated connection timeouts

### Warning Alerts
1. **Partial Success** - Alert when successRate < 90%
2. **Slow Performance** - Alert when executionDuration > threshold
3. **Individual Failures** - Alert when failedCount increases

### Dashboards
1. **Success Rate Trend** - Line chart over time
2. **Processing Volume** - Bar chart by hour/day
3. **Error Distribution** - Pie chart by error type
4. **Performance Metrics** - Gauge for throughput
5. **Failed Employees** - Table with retry status

---

## Benefits of Enhanced Logging

### 1. **Debugging**
- Detailed context at every step
- Full employee data in error logs
- Request/response correlation

### 2. **Monitoring**
- Real-time progress tracking
- Success/failure rates
- Performance metrics

### 3. **Troubleshooting**
- Specific error messages
- Recommended actions
- Retry guidance

### 4. **Performance Analysis**
- Execution duration tracking
- Throughput calculation
- Bottleneck identification

### 5. **Audit & Compliance**
- Complete data trail
- Operation tracking
- Change history

### 6. **Capacity Planning**
- Volume trends
- Performance baselines
- Resource utilization

---

## Best Practices

1. **Structured Logging** - All logs use JSON format for easy parsing
2. **Correlation IDs** - Every log includes runId and correlationId
3. **Context Preservation** - Employee data included in relevant logs
4. **Performance Tracking** - Duration and throughput metrics captured
5. **Error Details** - Full error objects preserved for analysis
6. **Actionable Insights** - Troubleshooting guidance included

---

## Log Retention

### Recommendations
- **INFO logs** - 30 days retention
- **WARN logs** - 60 days retention
- **ERROR logs** - 90 days retention
- **CRITICAL logs** - 1 year retention

### Storage Considerations
With enhanced logging, expect ~2-5 KB per employee processed. For 1000 employees/day:
- Daily: ~2-5 MB
- Monthly: ~60-150 MB
- Yearly: ~730 MB - 1.8 GB

---

## Summary

The enhanced logging provides:
✅ **Complete visibility** into workflow execution
✅ **Detailed error context** for troubleshooting
✅ **Performance metrics** for optimization
✅ **Audit trail** for compliance
✅ **Actionable insights** for operations teams
✅ **Real-time monitoring** capabilities
