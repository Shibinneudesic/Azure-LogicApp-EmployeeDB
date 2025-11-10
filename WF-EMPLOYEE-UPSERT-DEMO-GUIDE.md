# WF-Employee-Upsert Workflow - Complete Demo Guide

## 🎯 Overview
**Purpose**: HTTP-triggered workflow that receives employee data in JSON format and upserts (insert or update) them into Azure SQL Database using a stored procedure.

**Key Features**:
- ✅ Request validation at schema and field level
- ✅ Batch processing of multiple employees
- ✅ Try/Catch error handling for resilience
- ✅ Comprehensive logging at every step
- ✅ SQL injection prevention
- ✅ Partial success handling (207 status)
- ✅ Detailed error tracking per employee

---

## 📋 Workflow Architecture

### **Execution Flow**:
```
HTTP Request 
    ↓
Initialize Variables (5 tracking variables)
    ↓
Log Workflow Start
    ↓
Try Scope (Main Logic)
    ├─ Schema Validation
    ├─ Field Validation Loop
    ├─ Processing Loop
    └─ Response Logic
    ↓
Catch Scope (Error Handler)
```

---

## 🔢 Phase 1: Variable Initialization

**Why 5 Variables?** Each serves a specific tracking purpose:

### 1. **ValidationErrors** (Array)
```json
Purpose: Store all employees that fail validation
Type: Array of objects
Example: [
  {
    "id": "null",
    "firstName": "John",
    "lastName": "",
    "error": "Invalid or missing required fields"
  }
]
```
**Demo Point**: "We collect ALL validation errors before responding - this gives API consumers complete feedback instead of failing on first error."

### 2. **HasErrors** (Boolean)
```json
Purpose: Flag to determine if validation failed
Type: Boolean (true/false)
Initial Value: false
```
**Demo Point**: "This is our validation checkpoint - if ANY employee fails validation, we set this to true and return a 400 error BEFORE touching the database."

### 3. **ProcessedCount** (Integer)
```json
Purpose: Count successfully processed employees
Type: Integer
Initial Value: 0
Incremented: After each successful SQL upsert
```
**Demo Point**: "Success counter - this tells us exactly how many employees were saved to the database."

### 4. **FailedCount** (Integer)
```json
Purpose: Count employees that failed during SQL operations
Type: Integer
Initial Value: 0
Incremented: When Try_Upsert_Employee scope fails
```
**Demo Point**: "Failure counter - even if SQL fails for some employees, we continue processing others and track the failures."

### 5. **FailedEmployees** (Array)
```json
Purpose: Store details of employees that failed SQL operations
Type: Array of objects with error details
Example: [
  {
    "id": 2010,
    "firstName": "John",
    "lastName": "Doe",
    "error": "Cannot insert duplicate key",
    "timestamp": "2025-11-10T10:30:00Z"
  }
]
```
**Demo Point**: "Detailed failure tracking - we capture WHICH employees failed and WHY, so the calling system can retry specific records."

---

## 🔍 Phase 2: Schema Validation (First Gate)

### **Validation Logic** (Parse_Request_Schema):
```javascript
Condition (AND logic):
1. triggerBody()?['employees'] IS NOT null
2. triggerBody()?['employees']?['employee'] IS NOT null
3. length(triggerBody()?['employees']?['employee']) > 0
```

### **Expected JSON Structure**:
```json
{
  "employees": {
    "employee": [
      { "id": 2010, "firstName": "John", "lastName": "Doe", ... },
      { "id": 2011, "firstName": "Jane", "lastName": "Smith", ... }
    ]
  }
}
```

### **Why This Structure?**
**Demo Point**: "This matches XML-to-JSON conversion patterns from enterprise systems. The 'employees' wrapper and 'employee' array structure is common in SOAP-to-REST migrations."

### **What Happens on Failure?**
- **Log_Schema_Invalid**: Records the invalid request body
- **Return_Schema_Error**: Returns 400 with clear message:
```json
{
  "status": "error",
  "code": 400,
  "message": "Invalid request structure. Expected: { employees: { employee: [array] } }",
  "timestamp": "2025-11-10T10:30:00Z",
  "runId": "08584722852632621051231315CU00"
}
```

**Demo Point**: "We STOP immediately if the schema is wrong - no point processing individual records if the entire structure is invalid."

---

## ✅ Phase 3: Field Validation (Second Gate)

### **Loop_And_Validate_Each_Employee** Action:
Iterates through `@triggerBody()?['employees']?['employee']` array.

### **Check_Fields Condition** (OR Logic):
Any ONE of these conditions triggers validation failure:

#### **1. ID Validation**:
```javascript
// Check 1: ID is null
@items('Loop_And_Validate_Each_Employee')?['id'] = null

// Check 2: ID is zero or negative
@coalesce(items('Loop_And_Validate_Each_Employee')?['id'], 0) <= 0
```
**Demo Point**: "ID must exist and be positive - it's our primary key. We use coalesce to handle null safely."

#### **2. FirstName Validation**:
```javascript
// Check 1: firstName is null
@items('Loop_And_Validate_Each_Employee')?['firstName'] = null

// Check 2: firstName is empty/whitespace after trimming
@trim(string(coalesce(items('Loop_And_Validate_Each_Employee')?['firstName'], ''))) = ""
```
**Demo Point**: "We don't accept just spaces - trim() removes whitespace, string() handles type conversion, coalesce() handles null. This prevents '   ' being accepted as a valid name."

#### **3. LastName Validation**:
```javascript
// Same logic as firstName
@items('Loop_And_Validate_Each_Employee')?['lastName'] = null
OR
@trim(string(coalesce(items('Loop_And_Validate_Each_Employee')?['lastName'], ''))) = ""
```

### **Why These 3 Fields Only?**
**Demo Point**: "ID, FirstName, LastName are REQUIRED in our database (NOT NULL constraints). Department, Position, Salary, Email are optional - we use coalesce() to handle nulls gracefully when inserting."

### **What Happens When Validation Fails?**

#### **Action 1: Log_Validation_Error**
```json
{
  "logLevel": "WARN",
  "timestamp": "2025-11-10T10:30:00Z",
  "message": "Employee validation failed",
  "employeeId": "null",
  "firstName": "John",
  "lastName": ""
}
```
**Demo Point**: "WARN level because it's not a system error - it's invalid data from the caller."

#### **Action 2: Add_To_Validation_Errors**
```json
Appends to ValidationErrors array:
{
  "id": "null",
  "firstName": "John",
  "lastName": "",
  "error": "Invalid or missing required fields"
}
```
**Demo Point**: "We collect ALL errors - if 5 out of 10 employees are invalid, we return all 5 errors in one response."

#### **Action 3: Set_Error_Flag**
```javascript
HasErrors = true
```
**Demo Point**: "This flag prevents us from proceeding to database operations."

### **Check_If_Validation_Failed** Branch:

#### **IF HasErrors = true**:
- **Log_Returning_Validation_Error**: Records error count
- **Return_Validation_Error**: Returns 400 status with ALL validation errors:
```json
{
  "status": "error",
  "code": 400,
  "message": "Employee validation failed",
  "details": {
    "errors": [
      { "id": "null", "firstName": "John", "lastName": "", "error": "Invalid or missing required fields" },
      { "id": "0", "firstName": "", "lastName": "Smith", "error": "Invalid or missing required fields" }
    ],
    "totalErrors": 2
  },
  "timestamp": "2025-11-10T10:30:00Z",
  "runId": "08584722852632621051231315CU00"
}
```

**Demo Point**: "Workflow STOPS here if validation fails. We don't hit the database at all. This is efficient and safe."

#### **ELSE (All Valid)**: Proceed to processing...

---

## 💾 Phase 4: Database Processing (Main Logic)

### **Loop_And_Process_Valid_Employees**:
Only executes if ALL employees passed validation.

### **For Each Employee**: Two Scopes (Try/Catch Pattern)

---

### **🟢 Try_Upsert_Employee Scope** (Happy Path):

#### **Step 1: Log_Processing_Employee**
```json
{
  "logLevel": "INFO",
  "timestamp": "2025-11-10T10:30:00Z",
  "message": "Processing employee",
  "employeeId": 2010,
  "employeeName": "John Doe"
}
```
**Demo Point**: "We log BEFORE attempting SQL - this helps trace which employee caused an issue."

#### **Step 2: Upsert_Employee** (SQL Service Provider Action)

**SQL Query Generated**:
```sql
EXEC usp_Employee_Upsert 
  @ID=2010,
  @FirstName='John',
  @LastName='Doe',
  @Department='IT',
  @Position='Developer',
  @Salary=75000,
  @Email='john.doe@example.com'
```

### **🔒 SQL Injection Prevention**:
```javascript
Expression: '@{replace(items('Loop_And_Process_Valid_Employees')?['firstName'],'''','''''')}'

Example:
Input:  O'Brien
Output: O''Brien (escaped single quote)
```

**Demo Point**: "The replace() function doubles up single quotes - this is standard SQL escaping. Combined with the stored procedure's @parameters, we're protected against SQL injection."

### **NULL Handling for Optional Fields**:
```javascript
// Department (string)
@Department='@{replace(coalesce(items('Loop_And_Process_Valid_Employees')?['department'],''),'''','''''')}'

// Salary (numeric)
@Salary=@{coalesce(items('Loop_And_Process_Valid_Employees')?['salary'],'NULL')}
```

**Demo Point**: 
- "For strings: coalesce to empty string, then escape quotes"
- "For numbers: coalesce to SQL keyword 'NULL' (no quotes)"

### **Connection Configuration**:
```json
{
  "connectionName": "sql",
  "operationId": "executeQuery",
  "serviceProviderId": "/serviceProviders/sql"
}
```
**Demo Point**: "Uses Azure SQL service provider with Managed Identity authentication - no passwords in code!"

#### **Step 3: Log_Employee_Success**
```json
{
  "logLevel": "INFO",
  "timestamp": "2025-11-10T10:30:00Z",
  "message": "Employee upserted successfully",
  "employeeId": 2010,
  "employeeName": "John Doe"
}
```

#### **Step 4: Increment_ProcessCount**
```javascript
ProcessedCount = ProcessedCount + 1
```
**Demo Point**: "Success counter increments - this is how we track partial success scenarios."

---

### **🔴 Catch_Upsert_Error Scope** (Error Path):

**Triggered When**: Try_Upsert_Employee has status: Failed, Skipped, or TimedOut

#### **Step 1: Log_Employee_Error**
```json
{
  "logLevel": "ERROR",
  "timestamp": "2025-11-10T10:30:00Z",
  "message": "Failed to upsert employee",
  "employeeId": 2010,
  "employeeName": "John Doe",
  "error": { 
    "code": "SqlError",
    "message": "Cannot insert duplicate key"
  },
  "errorMessage": "Cannot insert duplicate key"
}
```

**Demo Point**: "We capture the EXACT error from SQL using result() function - this shows the actual database error."

#### **Step 2: Add_To_Failed_Employees**
```json
Appends to FailedEmployees array:
{
  "id": 2010,
  "firstName": "John",
  "lastName": "Doe",
  "error": "Cannot insert duplicate key",
  "timestamp": "2025-11-10T10:30:00Z"
}
```

#### **Step 3: Increment_FailedCount**
```javascript
FailedCount = FailedCount + 1
```

**Demo Point**: "Even though THIS employee failed, the workflow continues to the NEXT employee. This is batch processing resilience."

---

## 📊 Phase 5: Response Logic (Smart Status Codes)

### **Log_Processing_Complete**:
```json
{
  "logLevel": "INFO",
  "timestamp": "2025-11-10T10:30:00Z",
  "message": "Employee processing completed",
  "totalProcessed": 8,
  "totalFailed": 2,
  "totalRequested": 10
}
```

**Demo Point**: "This summary log shows the big picture - useful for monitoring dashboards."

---

### **Check_Any_Failures** Branch:

#### **IF FailedCount > 0** (Partial Success):

**Return_Partial_Success** - HTTP 207 (Multi-Status):
```json
{
  "status": "partial_success",
  "code": 207,
  "message": "Some employees processed successfully, others failed",
  "details": {
    "totalRequested": 10,
    "successfulOperations": 8,
    "failedOperations": 2,
    "failedEmployees": [
      {
        "id": 2010,
        "firstName": "John",
        "lastName": "Doe",
        "error": "Cannot insert duplicate key",
        "timestamp": "2025-11-10T10:30:00Z"
      },
      {
        "id": 2015,
        "firstName": "Jane",
        "lastName": "Smith",
        "error": "Violation of UNIQUE KEY constraint",
        "timestamp": "2025-11-10T10:30:00Z"
      }
    ]
  },
  "timestamp": "2025-11-10T10:30:00Z",
  "runId": "08584722852632621051231315CU00"
}
```

**Demo Point**: "HTTP 207 is specifically for batch operations where some succeed and some fail. The calling system knows EXACTLY which records to retry."

#### **ELSE (Complete Success)**: 

**Return_Success** - HTTP 200:
```json
{
  "status": "success",
  "code": 200,
  "message": "All employees processed successfully",
  "details": {
    "totalProcessed": 10,
    "requestedCount": 10
  },
  "timestamp": "2025-11-10T10:30:00Z",
  "runId": "08584722852632621051231315CU00"
}
```

**Demo Point**: "Clean 200 response when everything succeeds - simple and standard."

---

## 🚨 Phase 6: Global Error Handler (Catch Scope)

**Triggered When**: The entire "Try" scope fails (not individual employee errors - those are handled in Catch_Upsert_Error)

### **Filter_Try_Scope_Errors**:
```javascript
Query: Find all actions in Try scope with status = 'Failed'
Result: Array of failed action details
```

### **Format_Errors**:
```json
Transforms error objects into readable format:
[
  {
    "action": "Upsert_Employee",
    "errorCode": "SqlTimeout",
    "errorMessage": "Connection timeout expired",
    "status": "Failed"
  }
]
```

### **Log_Critical_Error**:
```json
{
  "logLevel": "CRITICAL",
  "timestamp": "2025-11-10T10:30:00Z",
  "message": "Critical error in workflow execution",
  "errors": [...],
  "runId": "08584722852632621051231315CU00"
}
```

**Demo Point**: "CRITICAL level for system failures (not data validation issues). This alerts the ops team."

### **Terminate**:
```json
{
  "runStatus": "Failed",
  "runError": {
    "code": "500",
    "message": "One or more errors occurred while processing the request:\n\n[formatted errors]"
  }
}
```

**Demo Point**: "Terminate action stops the workflow and marks the run as Failed in Azure. This shows up in monitoring dashboards."

---

## 🎯 HTTP Status Code Strategy

| Status | Scenario | Response Body |
|--------|----------|---------------|
| **200** | All employees processed successfully | success, totalProcessed |
| **207** | Some succeeded, some failed | partial_success, successfulOperations, failedOperations, failedEmployees[] |
| **400** | Schema validation failed OR field validation failed | error, validation errors array |
| **500** | System/workflow failure (database down, connection timeout) | Via Terminate action |

**Demo Point**: "This follows REST API best practices - 2xx for success, 4xx for client errors (bad data), 5xx for server errors."

---

## 📝 Logging Strategy (5 Levels)

### **Log Levels Used**:

| Level | When Used | Example |
|-------|-----------|---------|
| **INFO** | Normal operations, tracking | "Workflow execution started", "Processing employee", "Employee upserted successfully" |
| **WARN** | Invalid data (not system error) | "Employee validation failed" |
| **ERROR** | Operation failure (SQL error) | "Failed to upsert employee" |
| **CRITICAL** | System-level failure | "Critical error in workflow execution" |

### **Why Compose Actions for Logging?**
```json
{
  "logLevel": "INFO",
  "timestamp": "@utcNow()",
  "message": "Processing employee",
  "employeeId": 2010,
  "employeeName": "John Doe"
}
```

**Demo Point**: 
1. "Compose outputs go to Application Insights automatically"
2. "Structured JSON makes Log Analytics queries powerful"
3. "Including runId correlates all logs for a single execution"
4. "Timestamps are in UTC for consistency across regions"

---

## 🔄 Test Scenarios for Demo

### **Scenario 1: Complete Success (200)**
```json
{
  "employees": {
    "employee": [
      { "id": 2010, "firstName": "John", "lastName": "Doe", "department": "IT", "position": "Developer", "salary": 75000, "email": "john.doe@example.com" },
      { "id": 2011, "firstName": "Jane", "lastName": "Smith", "department": "HR", "position": "Manager", "salary": 85000, "email": "jane.smith@example.com" }
    ]
  }
}
```
**Expected**: HTTP 200, both employees in database

### **Scenario 2: Schema Validation Failure (400)**
```json
{
  "employees": []
}
```
**Expected**: HTTP 400, "Invalid request structure" error

### **Scenario 3: Field Validation Failure (400)**
```json
{
  "employees": {
    "employee": [
      { "id": 0, "firstName": "John", "lastName": "Doe" },
      { "id": 2011, "firstName": "", "lastName": "Smith" }
    ]
  }
}
```
**Expected**: HTTP 400, validation errors for both employees

### **Scenario 4: Partial Success (207)**
```json
{
  "employees": {
    "employee": [
      { "id": 2010, "firstName": "John", "lastName": "Doe" },
      { "id": 2010, "firstName": "John", "lastName": "Doe" },
      { "id": 2012, "firstName": "Alice", "lastName": "Johnson" }
    ]
  }
}
```
**Expected**: HTTP 207 (first succeeds, second fails duplicate, third succeeds)

### **Scenario 5: SQL Injection Attempt (Prevented)**
```json
{
  "employees": {
    "employee": [
      { "id": 2010, "firstName": "John'; DROP TABLE Employees; --", "lastName": "Doe" }
    ]
  }
}
```
**Expected**: HTTP 200, name stored as "John''; DROP TABLE Employees; --" (escaped)

---

## 🎤 Demo Script Outline

### **1. Introduction (2 minutes)**
- "This is an enterprise-grade employee upsert API with production-ready patterns"
- Show workflow in Azure Portal designer
- Explain stateful workflow vs stateless

### **2. Architecture Walkthrough (3 minutes)**
- Variables: "5 tracking variables for comprehensive monitoring"
- Try/Catch: "Global error handler for system failures"
- Nested Try/Catch: "Per-employee error handling for batch resilience"

### **3. Validation Demo (5 minutes)**
- Show schema validation (send invalid structure)
- Show field validation (send missing firstName)
- Show Application Insights logs
- Query: `AppTraces | where Message contains "validation"`

### **4. Success Scenario (3 minutes)**
- Send valid 2-employee request
- Show 200 response
- Check SQL database: `SELECT * FROM Employees WHERE ID IN (2010, 2011)`
- Show logs in Application Insights

### **5. Partial Success (5 minutes)**
- Send duplicate ID in request
- Show 207 response
- Explain failedEmployees array
- Show ERROR level logs in Application Insights

### **6. Security Features (3 minutes)**
- Explain SQL injection prevention (replace function)
- Show Managed Identity authentication (no passwords)
- Explain coalesce() for NULL handling

### **7. Monitoring Deep Dive (5 minutes)**
- Show Log Analytics workspace
- Run KQL query: 
```kql
AppTraces 
| where TimeGenerated > ago(1h)
| project TimeGenerated, Message, SeverityLevel, Properties.employeeId
| order by TimeGenerated desc
```
- Show workflow performance metrics
- Demonstrate error alerting possibilities

### **8. Q&A and Best Practices (4 minutes)**
- Why 207 status code?
- Why validate before database operations?
- How to scale (concurrent processing)?
- Integration patterns (Event Grid, Service Bus)

---

## 🔧 Key Design Decisions Explained

### **1. Why Nested Scopes (Try/Catch inside ForEach)?**
**Decision**: Each employee upsert is wrapped in Try_Upsert_Employee scope

**Why**:
- Individual employee failures don't stop the batch
- We capture error details per employee
- Allows partial success handling

**Alternative**: Single try/catch for entire loop
**Problem**: One failure would stop processing remaining employees

---

### **2. Why Two Validation Phases?**
**Decision**: Schema validation THEN field validation

**Why**:
- Schema validation is cheap (structure check)
- Field validation is expensive (loop through array)
- Fail fast on malformed requests
- Clear error messages for different failure types

**Alternative**: Single validation step
**Problem**: Mixed error messages, harder to debug

---

### **3. Why Compose for Logging?**
**Decision**: Use Compose actions instead of Application Insights connector

**Why**:
- Compose outputs are automatically sent to Application Insights
- No need for separate connector/connection
- Structured JSON for better queries
- Zero additional cost

**Alternative**: HTTP calls to Application Insights API
**Problem**: More complex, requires authentication, harder to maintain

---

### **4. Why Variables Instead of Responses Array?**
**Decision**: Track counts and failed employees in separate variables

**Why**:
- Can't build complex objects in ForEach easily
- Variables are mutable and efficient
- Clear separation of concerns

**Alternative**: Build JSON object manually
**Problem**: Complex expressions, harder to read

---

### **5. Why Upsert Instead of Separate Insert/Update?**
**Decision**: Single stored procedure handles both insert and update

**Why**:
- Simpler calling code
- Atomic operation (transaction)
- Database handles existence check efficiently
- Idempotent (safe to retry)

**Alternative**: Check if exists, then insert OR update
**Problem**: Race conditions, two database roundtrips, more complex

---

## 📚 Related Documentation

- **MONITORING_TROUBLESHOOTING_GUIDE.md** - Application Insights queries
- **LOG_ANALYTICS_KQL_QUERIES.md** - Log Analytics queries for demo
- **test-request.json** - Sample valid request
- **test-invalid-request.json** - Sample validation failure
- **Scripts/Deploy-usp_Employee_Upsert-Azure.sql** - Stored procedure code

---

## ✅ Pre-Demo Checklist

- [ ] Logic App is running in Azure
- [ ] Test with valid request (verify 200 response)
- [ ] Test with invalid schema (verify 400 response)
- [ ] Test with validation failure (verify 400 with errors array)
- [ ] SQL database has data (query Employees table)
- [ ] Application Insights is receiving logs
- [ ] Log Analytics workspace queries work
- [ ] Have endpoint URL and test commands ready
- [ ] Browser tabs open: Azure Portal, Log Analytics, Application Insights

---

**Demo Duration**: 30 minutes (including Q&A)
**Complexity Level**: Advanced (Production-Ready Enterprise Workflow)
**Key Takeaway**: "This workflow demonstrates enterprise patterns: validation gates, batch resilience, comprehensive logging, security best practices, and smart HTTP status codes."
