# Employee Upsert Logic App - Azure Logic Apps Standard

## Overview

This project implements a comprehensive Employee Upsert solution using Azure Logic Apps Standard with the following features:

- **HTTP Trigger**: RESTful API endpoint for receiving employee data
- **Input Validation**: Comprehensive validation with detailed error responses
- **Database Upsert**: Insert new employees or update existing ones based on EmployeeID
- **Error Handling**: Try-catch blocks with detailed logging and proper error responses
- **Custom Logging**: Extensive logging throughout the workflow for monitoring and debugging
- **Local Development**: Full LocalDB setup for local development and testing
- **Azure Deployment**: Complete deployment scripts and documentation for Azure

## Architecture

```
HTTP Request → Input Validation → Database Check → Upsert Operation → Response
                     ↓                ↓              ↓
                Error Response    Logging       Success Response
```

## Features

### ✅ Core Requirements
- [x] **Azure Logic Apps Standard** - Stateful workflow implementation
- [x] **Azure SQL Database** - Employee table with proper schema and constraints
- [x] **Upsert Operations** - Insert or update based on record existence
- [x] **Try-Catch Error Handling** - Comprehensive error handling with detailed logging
- [x] **Success/Failure Responses** - Proper HTTP responses for both scenarios
- [x] **Postman Testing** - Complete test collection with multiple scenarios

### ✅ Enhanced Features
- [x] **Input Validation** - Required field validation with detailed error messages
- [x] **Custom Logging** - Comprehensive logging throughout the workflow
- [x] **Local Development** - LocalDB setup for local testing
- [x] **Deployment Scripts** - Automated Azure resource deployment
- [x] **Managed Identity** - Secure authentication using Azure Managed Identity
- [x] **Performance Optimization** - Proper indexing and stored procedures
- [x] **Security Best Practices** - Parameterized queries and secure connections

## Project Structure

```
UpsertEmployee/
├── UpsertEmployee/
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
│   └── EmployeeUpsert_TestCollection.json # Postman test collection
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
   - Import `Postman/EmployeeUpsert_TestCollection.json`
   - Update the `logicAppUrl` variable with your local endpoint
   - Run test scenarios

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
POST /api/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/invoke
```

### Request Schema
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

### Success Response (200)
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

### Validation Error Response (400)
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

The Postman collection includes comprehensive testing scenarios:

### Success Scenarios
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
1. **Connection Failures**: Check managed identity permissions
2. **SQL Timeouts**: Review query performance and connection strings
3. **Validation Errors**: Check request schema and required fields
4. **Deployment Failures**: Verify Azure CLI authentication and permissions

### Diagnostic Tools
- Azure Portal Logic App run history
- Application Insights logs and metrics
- SQL Database query store
- Azure Monitor alerts

### Getting Help
- Review the deployment guide: `Documentation/DeploymentGuide.md`
- Check Azure Logic Apps documentation
- Create support tickets in Azure Portal
- Monitor Azure Service Health

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