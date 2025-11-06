# Employee Batch Upsert Logic App - Azure Logic Apps Standard

## Overview

This project implements a comprehensive Employee Batch Upsert solution using Azure Logic Apps Standard with the following features:

- **HTTP Trigger**: RESTful API endpoint for receiving multiple employee records
- **Batch Processing**: Process multiple employees in a single request with individual error handling
- **Input Validation**: Comprehensive validation with detailed error responses for each employee
- **Database Upsert**: Insert new employees or update existing ones based on EmployeeID
- **Error Handling**: Try-catch blocks with detailed logging and proper error responses
- **Custom Logging**: Extensive logging throughout the workflow for monitoring and debugging
- **Local Development**: Full LocalDB setup for local development and testing
- **Azure Deployment**: Complete deployment scripts and documentation for Azure

## Architecture

```
HTTP Request → Validate Payload → For Each Employee → Database Check → Upsert Operation → Aggregate Results → Response
                      ↓                    ↓                ↓              ↓
                Error Response      Individual Validation   Logging    Success/Error Collection
```

## Features

### ✅ Core Requirements
- [x] **Azure Logic Apps Standard** - Stateful workflow implementation
- [x] **Batch Processing** - Handle multiple employees in single request
- [x] **Azure SQL Database** - Employee table with proper schema and constraints
- [x] **Upsert Operations** - Insert or update based on record existence
- [x] **Try-Catch Error Handling** - Comprehensive error handling with detailed logging
- [x] **Granular Responses** - Individual success/failure tracking for each employee
- [x] **Postman Testing** - Complete test collection with batch scenarios

### ✅ Enhanced Features
- [x] **Input Validation** - Required field validation per employee with detailed error messages
- [x] **Partial Success Handling** - Continue processing valid employees when some fail
- [x] **Custom Logging** - Comprehensive logging throughout the workflow
- [x] **Local Development** - LocalDB setup for local testing
- [x] **Deployment Scripts** - Automated Azure resource deployment
- [x] **Managed Identity** - Secure authentication using Azure Managed Identity
- [x] **Performance Optimization** - Proper indexing and efficient batch operations
- [x] **Security Best Practices** - Parameterized queries and secure connections

## Project Structure

```
UpsertEmployee/
├── UpsertEmployeeV2/              # Workflow folder (renamed from UpsertEmployee)
│   ├── workflow.json              # Main Logic App workflow definition
│   └── workflow.parameters.json   # Workflow parameters
├── connections.json               # Connection configurations
├── host.json                     # Host configuration
├── local.settings.json           # Local development settings
├── Scripts/
│   ├── CreateEmployeeTable_LocalDB.sql    # LocalDB database setup
│   ├── CreateEmployeeTable.sql            # Azure SQL database setup
│   ├── ConfigureManagedIdentity.sql       # Managed identity configuration
│   └── Deploy-AzureResources.ps1          # Azure deployment script
├── Postman/
│   ├── EmployeeUpsert_TestCollection.json      # Original single employee test collection
│   └── EmployeeUpsert_BatchTestCollection.json # New batch processing test collection
└── Documentation/
    └── DeploymentGuide.md                  # Comprehensive deployment guide
```

## Quick Start

### Local Development

1. **Setup LocalDB Database**
   ```powershell
   sqlcmd -S "(localdb)\\MSSQLLocalDB" -i "Scripts\\CreateEmployeeTable_LocalDB.sql"
   ```

2. **Start Logic App Locally**
   ```powershell
   func host start
   ```

3. **Test with Postman**
   - Import `Postman/EmployeeUpsert_BatchTestCollection.json` for batch testing
   - Import `Postman/EmployeeUpsert_TestCollection.json` for single employee testing (legacy)
   - Update the `logicAppUrl` variable with your local endpoint
   - Run test scenarios

> **Note**: The workflow folder is named `UpsertEmployeeV2` (updated from `UpsertEmployee` to resolve Azure deployment issues). Update your endpoints accordingly.

### Azure Deployment

1. **Deploy Azure Resources**
   ```powershell
   .\Scripts\Deploy-AzureResources.ps1 -SubscriptionId "your-subscription-id"
   ```

2. **Configure Database**
   - Run `Scripts/CreateEmployeeTable.sql` on Azure SQL Database
   - Run `Scripts/ConfigureManagedIdentity.sql` for managed identity permissions

3. **Deploy Logic App Code**
   ```powershell
   func azure functionapp publish your-logic-app-name
   ```

## API Documentation

### Endpoint
```
POST /api/workflows/UpsertEmployeeV2/triggers/When_a_HTTP_request_is_received/invoke
```

> **Note**: Workflow name was changed from `UpsertEmployee` to `UpsertEmployeeV2` to resolve Azure deployment issues. See [Troubleshooting](#5-workflow-health-error-invalidflowkind-critical) for details.

### Request Schema (New Batch Format)
```json
{
  "employees": {
    "employee": [
      {
        "id": 2001,                   // Required: Integer > 0
        "firstName": "Shibin",        // Required: Non-empty string
        "lastName": "Sam",            // Required: Non-empty string
        "department": "Quality Assurance",  // Optional: String
        "position": "Senior QA Engineer",   // Optional: String
        "salary": 82000,             // Optional: Number
        "email": "shibin.sam@example.com"  // Optional: String
      },
      {
        "id": 2002,
        "firstName": "Anjali",
        "lastName": "Nair",
        "department": "Software Development",
        "position": "Full Stack Developer",
        "salary": 95000,
        "email": "anjali.nair@example.com"
      }
    ]
  }
}
```

### Legacy Single Employee Schema (Still Supported)
```json
{
  "EmployeeID": 1001,           // Required: Integer > 0
  "FirstName": "John",          // Required: Non-empty string
  "LastName": "Doe",            // Required: Non-empty string
  "Department": "IT",           // Optional: String
  "Position": "Engineer",       // Optional: String
  "Salary": 75000.00,          // Optional: Number
  "Email": "john@company.com"   // Optional: String
}
```

### Batch Success Response (200)
```json
{
  "status": "success",
  "message": "All employees processed successfully",
  "summary": {
    "totalEmployees": 3,
    "successfulOperations": 3,
    "failedOperations": 0,
    "timestamp": "2024-11-05T10:30:00Z",
    "runId": "08584693315927374810665216732CU00"
  },
  "results": {
    "successful": [
      {
        "employeeID": 2001,
        "firstName": "Shibin",
        "lastName": "Sam",
        "operation": "INSERT",
        "status": "success",
        "timestamp": "2024-11-05T10:30:00Z"
      },
      {
        "employeeID": 2002,
        "firstName": "Anjali",
        "lastName": "Nair",
        "operation": "UPDATE",
        "status": "success",
        "timestamp": "2024-11-05T10:30:01Z"
      }
    ],
    "failed": []
  }
}
```

### Partial Success Response (207)
```json
{
  "status": "partial_success",
  "message": "Some employees processed successfully, others failed",
  "summary": {
    "totalEmployees": 3,
    "successfulOperations": 2,
    "failedOperations": 1,
    "timestamp": "2024-11-05T10:30:00Z",
    "runId": "08584693315927374810665216732CU00"
  },
  "results": {
    "successful": [
      {
        "employeeID": 2001,
        "firstName": "Shibin",
        "lastName": "Sam",
        "operation": "INSERT",
        "status": "success",
        "timestamp": "2024-11-05T10:30:00Z"
      }
    ],
    "failed": [
      {
        "employeeID": null,
        "firstName": "Invalid",
        "lastName": "Employee",
        "status": "validation_error",
        "errors": ["EmployeeID is required"],
        "timestamp": "2024-11-05T10:30:01Z"
      }
    ]
  }
}
```

### Legacy Success Response (200)
```json
{
  "status": "success",
  "message": "Employee record processed successfully",
  "data": {
    "employeeID": 1001,
    "operation": "UPDATE",
    "timestamp": "2024-11-04T10:30:00Z",
    "runId": "08584693315927374810665216732CU00"
  }
}
```

### Batch Validation Error Response (400)
```json
{
  "status": "validation_error",
  "message": "Input validation failed. Please check the required structure: { \"employees\": { \"employee\": [array of employee objects] } }",
  "data": {
    "errors": ["employees object is required"],
    "expectedStructure": {
      "employees": {
        "employee": [
          {
            "id": "integer (required)",
            "firstName": "string (required)",
            "lastName": "string (required)",
            "department": "string (optional)",
            "position": "string (optional)",
            "salary": "number (optional)",
            "email": "string (optional)"
          }
        ]
      }
    },
    "timestamp": "2024-11-05T10:30:00Z",
    "runId": "08584693315927374810665216732CU00"
  }
}
```

### Legacy Validation Error Response (400)
```json
{
  "status": "validation_error",
  "message": "Input validation failed. Please check the required fields.",
  "data": {
    "errors": ["EmployeeID is required", "FirstName is required"],
    "timestamp": "2024-11-04T10:30:00Z",
    "runId": "08584693315927374810665216732CU00"
  }
}
```

### Server Error Response (500)
```json
{
  "status": "error",
  "message": "An error occurred while processing the employee record",
  "data": {
    "employeeID": 1001,
    "errorCode": "SqlException",
    "errorMessage": "Connection timeout",
    "timestamp": "2024-11-04T10:30:00Z",
    "runId": "08584693315927374810665216732CU00"
  }
}
```

## Database Schema

### Employee Table
```sql
CREATE TABLE dbo.Employee (
    EmployeeID INT NOT NULL PRIMARY KEY,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Department NVARCHAR(100) NULL,
    Position NVARCHAR(100) NULL,
    Salary DECIMAL(18,2) NULL,
    Email NVARCHAR(255) NULL,
    CreatedDate DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    ModifiedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    IsActive BIT NOT NULL DEFAULT 1,
    RowVersion ROWVERSION NOT NULL
);
```

### Stored Procedure
```sql
EXEC dbo.UpsertEmployee 
    @EmployeeID = 1001,
    @FirstName = 'John',
    @LastName = 'Doe',
    @Department = 'IT',
    @Position = 'Engineer',
    @Salary = 75000.00,
    @Email = 'john@company.com'
```

## Testing Scenarios

The Postman collections include comprehensive testing scenarios:

### Batch Processing Scenarios (New)
- Process multiple employees with complete data
- Process single employee using batch format
- Process employees with minimal required data
- Mixed valid and invalid employees (partial success)
- Large batch processing (10+ employees)
- Empty employee array validation
- Missing employees object validation

### Individual Employee Scenarios
- Special characters in employee names
- Very high salary values
- Large employee ID values
- Edge cases and boundary testing

### Legacy Single Employee Scenarios
- Insert new employee with complete data
- Insert new employee with minimal required data
- Update existing employee
- Update employee with partial data

### Validation Error Scenarios
- Missing EmployeeID
- Missing FirstName/LastName
- Empty required fields
- Invalid EmployeeID values (zero, negative)

### Edge Cases
- Very long text fields
- Special characters and Unicode
- High salary values
- Malformed JSON

### Performance Tests
- Large EmployeeID values
- Concurrent requests (manual testing)

## Monitoring and Logging

### Custom Logging Events
- Workflow start/completion
- Database operation start/completion
- Validation failures
- Error details with stack traces
- Performance metrics

### Azure Monitoring
- Application Insights integration
- Logic App run history
- SQL Database query performance
- Custom telemetry and alerts

## Security Features

### Authentication & Authorization
- Managed Identity for Azure SQL access
- No hardcoded credentials
- Principle of least privilege

### Data Protection
- Parameterized SQL queries (SQL injection prevention)
- Input validation and sanitization
- Encryption in transit and at rest
- Audit logging

### Network Security
- Azure SQL firewall rules
- Logic App access restrictions
- VNet integration (optional)

## Performance Optimization

### Database
- Proper indexing on frequently queried columns
- Stored procedures for complex operations
- Connection pooling
- Query performance monitoring

### Logic App
- Efficient workflow design
- Proper error handling to prevent infinite loops
- Timeout configurations
- Parallel actions where appropriate

## Cost Optimization

### Development
- LocalDB for local development (free)
- Azure SQL Basic tier for testing
- Logic App Consumption plan for low volume

### Production
- Appropriate SQL Database tier based on usage
- Logic App Standard plan for predictable costs
- Resource monitoring and scaling

## Support and Troubleshooting

### Common Issues

#### 1. **Connection Failures**
**Issue**: Logic App cannot connect to Azure SQL Database  
**Solution**: Check managed identity permissions
```sql
-- Grant permissions to the Logic App managed identity
CREATE USER [your-logic-app-name] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [your-logic-app-name];
ALTER ROLE db_datawriter ADD MEMBER [your-logic-app-name];
GRANT EXECUTE TO [your-logic-app-name];
```

#### 2. **SQL Timeouts**
**Issue**: Database queries timing out  
**Solution**: Review query performance and connection strings, check database tier

#### 3. **Validation Errors**
**Issue**: 400 Bad Request with validation errors  
**Solution**: Check request schema and required fields (id, firstName, lastName)

#### 4. **Deployment Failures**
**Issue**: `func azure functionapp publish` fails  
**Solution**: Verify Azure CLI authentication and permissions

#### 5. **Workflow Health Error: "InvalidFlowKind" (CRITICAL)**

**Issue**: After deployment, workflow shows as "Unhealthy" with error:
```
"The existing workflow 'WorkflowName' cannot be changed from '<null>' to 'Stateful' kind."
```

**Symptoms**:
- HTTP trigger returns `404 Not Found`
- Workflow visible in Azure Portal but cannot execute
- Deployment succeeds but workflow health check fails
- Error persists even after redeployment

**Root Cause**: 
This occurs when a workflow was initially deployed without a proper `kind` specification (or with null kind). Azure Logic Apps treats the workflow kind as immutable once set, preventing any changes to the kind property.

**Solution**: **Rename the workflow folder** and redeploy

```powershell
# Step 1: Rename the workflow folder
Rename-Item "UpsertEmployee" "UpsertEmployeeV2" -Force

# Step 2: Deploy with new workflow name
func azure functionapp publish your-logic-app-name

# Step 3: Get new callback URL
az rest --method post `
  --uri "/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.Web/sites/{logic-app-name}/hostruntime/runtime/webhooks/workflow/api/management/workflows/UpsertEmployeeV2/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2023-12-01" `
  --query "value" --output tsv

# Step 4: Re-grant SQL permissions (Managed Identity changes after recreation)
# Run in Azure SQL Query Editor:
# DROP USER IF EXISTS [your-logic-app-name];
# CREATE USER [your-logic-app-name] FROM EXTERNAL PROVIDER;
# ALTER ROLE db_datareader ADD MEMBER [your-logic-app-name];
# ALTER ROLE db_datawriter ADD MEMBER [your-logic-app-name];
# GRANT EXECUTE TO [your-logic-app-name];

# Step 5: Test the workflow
Invoke-RestMethod -Uri $newCallbackUrl -Method Post -Body $testData -ContentType "application/json"
```

**Alternative Solution** (if renaming doesn't work):
- Delete the entire Logic App resource in Azure Portal
- Redeploy using Bicep template
- Deploy workflow code
- Reconfigure SQL permissions (managed identity changes)

**Prevention**:
- Always ensure `workflow.json` includes `"kind": "Stateful"` at the root level
- Use infrastructure-as-code (Bicep/ARM) for consistent deployments
- Test workflow health after each deployment: 
  ```powershell
  az rest --method get --uri ".../workflows/WorkflowName?api-version=2023-12-01" --query "health.state"
  ```

**Important Notes**:
- When Logic App is recreated, the Managed Identity Principal ID changes
- SQL permissions MUST be re-granted after recreation
- Update Postman collections and documentation with new workflow name
- Old workflow name will show as "Unhealthy" indefinitely; ignore it or contact Azure Support to remove

### Diagnostic Tools
- Azure Portal Logic App run history
- Application Insights logs and metrics
- SQL Database query store
- Azure Monitor alerts
- Workflow health check: `az rest --method get --uri ".../workflows/WorkflowName?api-version=2023-12-01"`

### Getting Help
- Review the deployment guide: `Documentation/DeploymentGuide.md`
- Check Azure Logic Apps documentation
- Create support tickets in Azure Portal
- Monitor Azure Service Health
- For "InvalidFlowKind" errors, see troubleshooting section above

---

## Contributing

When making changes to this project:

1. Test locally using LocalDB first
2. Update the Postman collection with new test cases
3. Update documentation for any API changes
4. Test deployment scripts in a development environment
5. Update version numbers and changelog

## License

This project is provided as a sample implementation for educational and demonstration purposes.

---

**Note**: Remember to update configuration values (connection strings, resource names, etc.) when deploying to different environments.