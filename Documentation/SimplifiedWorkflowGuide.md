# Simplified Production-Level Workflow Guide

## Overview
This document describes the simplified, production-ready workflow for the Employee Upsert Logic App. The workflow has been redesigned following best practices for enterprise-level applications.

## Architecture

### **Workflow Structure**
```
Trigger: HTTP Request
│
├─ Try Scope (Main Processing)
│  ├─ Log Workflow Start
│  ├─ Schema Validation
│  │  ├─ Validate Request Structure
│  │  │  └─ If Invalid → Return Schema Error (400)
│  │  │
│  │  └─ If Valid
│  │     ├─ Initialize Variables
│  │     ├─ Validate Each Employee Record
│  │     ├─ Check Validation Results
│  │     │  ├─ If Errors → Return Validation Error (400)
│  │     │  │
│  │     │  └─ If No Errors
│  │     │     ├─ Build Employee JSON Array
│  │     │     ├─ Execute Batch Upsert SP
│  │     │     ├─ Log Success
│  │     │     └─ Return Success Response (200)
│  │
│  └─ (Any errors caught by Catch Scope)
│
└─ Catch Scope (Error Handling)
   ├─ Log Exception
   └─ Return Error Response (500)
```

## Key Features

### ✅ **1. Single Schema Validation Step**
- **Structural Validation**: Checks if `employees` and `employees.employee` objects exist and the array is non-empty
- **Field Validation**: Validates each employee record for:
  - `id`: Must be a positive integer (> 0)
  - `firstName`: Required, non-empty string
  - `lastName`: Required, non-empty string
  - Optional fields: `department`, `position`, `salary`, `email`

### ✅ **2. Try-Catch Pattern**
- **Try Scope**: Contains all main workflow logic
- **Catch Scope**: Catches any unhandled exceptions from Try Scope
- Ensures no unhandled errors reach the caller

### ✅ **3. Centralized Logging**
All operations are logged with consistent structure:
```json
{
  "logLevel": "INFO|ERROR",
  "timestamp": "2025-11-06T...",
  "message": "Description of action",
  "additionalData": {...}
}
```

**Log Points:**
- Workflow start
- Schema validation (pass/fail)
- Database call start
- Database call success
- Validation errors
- Exceptions

### ✅ **4. Centralized Response Format**
All responses follow a consistent structure:

#### Success Response (200)
```json
{
  "status": "success",
  "errorCode": null,
  "message": "Employee batch upsert completed successfully",
  "details": {
    "totalProcessed": 5,
    "totalInserted": 2,
    "totalUpdated": 3,
    "requestedCount": 5
  },
  "timestamp": "2025-11-06T...",
  "runId": "..."
}
```

#### Validation Error Response (400)
```json
{
  "status": "error",
  "errorCode": "VALIDATION_ERROR",
  "message": "Employee data validation failed",
  "details": {
    "validationErrors": [...],
    "errorCount": 2,
    "totalEmployees": 5
  },
  "timestamp": "2025-11-06T...",
  "runId": "..."
}
```

#### Schema Error Response (400)
```json
{
  "status": "error",
  "errorCode": "INVALID_SCHEMA",
  "message": "Request body does not match expected schema",
  "details": {
    "expectedStructure": {...},
    "errors": [...]
  },
  "timestamp": "2025-11-06T...",
  "runId": "..."
}
```

#### Server Error Response (500)
```json
{
  "status": "error",
  "errorCode": "INTERNAL_SERVER_ERROR",
  "message": "An error occurred while processing the employee batch",
  "details": {
    "error": "...",
    "technicalDetails": {...}
  },
  "timestamp": "2025-11-06T...",
  "runId": "..."
}
```

### ✅ **5. Batch Processing with Stored Procedure**
- Uses `UpsertEmployeeBatch` stored procedure
- Processes all employees in a single database transaction
- Returns aggregated results (total processed, inserted, updated)
- Better performance than individual upserts
- Transactional consistency (all-or-nothing)

## Request Schema

### Valid Request Example
```json
{
  "employees": {
    "employee": [
      {
        "id": 1001,
        "firstName": "John",
        "lastName": "Doe",
        "department": "IT",
        "position": "Software Engineer",
        "salary": 75000.00,
        "email": "john.doe@company.com"
      },
      {
        "id": 1002,
        "firstName": "Jane",
        "lastName": "Smith",
        "department": "HR",
        "position": "HR Manager",
        "salary": 80000.00,
        "email": "jane.smith@company.com"
      }
    ]
  }
}
```

### Field Requirements
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| id | integer | Yes | Must be > 0 |
| firstName | string | Yes | Cannot be empty or whitespace |
| lastName | string | Yes | Cannot be empty or whitespace |
| department | string | No | Optional |
| position | string | No | Optional |
| salary | decimal | No | Optional |
| email | string | No | Optional |

## Error Codes

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `INVALID_SCHEMA` | 400 | Request structure doesn't match expected schema |
| `VALIDATION_ERROR` | 400 | One or more employee records failed field validation |
| `INTERNAL_SERVER_ERROR` | 500 | Unexpected error during processing (database errors, etc.) |

## Database Setup

### Prerequisites
1. Run `Scripts/CreateEmployeeTable.sql` to create the base table and original stored procedure
2. Run `Scripts/UpsertEmployeeBatch.sql` to create the batch processing stored procedure
3. Grant appropriate permissions to the Logic App's managed identity or service account

### Stored Procedure: UpsertEmployeeBatch
- **Input**: Table-valued parameter with employee array
- **Output Parameters**:
  - `@TotalProcessed`: Total number of employees processed
  - `@TotalInserted`: Number of new employees inserted
  - `@TotalUpdated`: Number of existing employees updated
  - `@ErrorMessage`: Error message if operation failed
- **Transaction**: All operations in a single transaction (ACID compliant)

## Testing

### Test Case 1: Valid Request
```powershell
# See test-request.json for sample payload
Invoke-RestMethod -Method Post -Uri "http://localhost:7071/api/UpsertEmployee/triggers/When_a_HTTP_request_is_received/invoke" `
  -ContentType "application/json" `
  -InFile "test-request.json"
```

**Expected**: HTTP 200 with success response

### Test Case 2: Schema Validation Error
```json
{
  "employees": {
    "employee": []
  }
}
```
**Expected**: HTTP 400 with `INVALID_SCHEMA` error code

### Test Case 3: Field Validation Error
```json
{
  "employees": {
    "employee": [
      {
        "id": 0,
        "firstName": "",
        "lastName": "Doe"
      }
    ]
  }
}
```
**Expected**: HTTP 400 with `VALIDATION_ERROR` error code

### Test Case 4: Database Error
- Simulate by disconnecting database or using invalid credentials
**Expected**: HTTP 500 with `INTERNAL_SERVER_ERROR` error code

## Improvements Over Previous Version

| Aspect | Before | After |
|--------|--------|-------|
| **Structure** | Multiple nested conditions | Single validation step with Try-Catch |
| **Processing** | Individual SP calls per employee | Single batch SP call |
| **Logging** | Scattered throughout workflow | Centralized with consistent format |
| **Error Handling** | Inline in each action | Catch scope handles all errors |
| **Response Format** | Different structures | Standardized across all responses |
| **Database Calls** | N calls for N employees | 1 call for N employees |
| **Transaction Safety** | Individual transactions | Single atomic transaction |
| **Performance** | Lower (multiple round trips) | Higher (single round trip) |
| **Maintainability** | Complex, hard to modify | Simple, easy to extend |

## Production Considerations

### ✅ **Monitoring**
- Enable Application Insights for the Logic App
- Monitor run history and failure rates
- Set up alerts for:
  - High error rates (>5%)
  - Long execution times (>30 seconds)
  - Failed runs

### ✅ **Security**
- Use Managed Identity for SQL connection
- Enable HTTPS only for webhook endpoint
- Implement API key authentication if exposing publicly
- Use Key Vault for connection strings

### ✅ **Performance**
- Current design: ~50-100 employees per request optimal
- For larger batches (>500), consider:
  - Implementing pagination
  - Async processing with Service Bus
  - Chunking into smaller batches

### ✅ **Scalability**
- Logic Apps automatically scale
- Ensure database can handle concurrent connections
- Consider read replicas for reporting

### ✅ **Disaster Recovery**
- Enable backup for database
- Document restore procedures
- Test failover scenarios

## Maintenance

### Adding New Fields
1. Update database table schema
2. Update `EmployeeTableType` in SQL
3. Update stored procedure to include new field
4. Update workflow trigger schema
5. Update documentation

### Modifying Validation Rules
- All validation logic is in the `Validate_Each_Employee` loop
- Centralized location makes changes easier
- Test thoroughly after modifications

## Support

For issues or questions:
1. Check Logic App run history
2. Review log outputs in each action
3. Verify database connectivity and permissions
4. Consult troubleshooting guide: `Documentation/TroubleshootingGuide.md`
