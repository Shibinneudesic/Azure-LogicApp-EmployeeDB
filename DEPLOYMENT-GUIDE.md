# Azure Deployment - Quick Reference

## ✅ What Was Deployed

### 1. Logic App Workflow
- **Name**: upsert-employee
- **Status**: Running
- **Files Uploaded**: 90.25 KB
- **Location**: upsert-employee.azurewebsites.net

### 2. Database Components
- **Stored Procedure**: UpsertEmployeeSimple
- **Database**: aistrainingserver.database.windows.net/empdb
- **Connection**: Azure AD Authentication
- **Status**: Deployed and verified

### 3. Configuration
- **Connections**: Using connections.azure.json (Azure SQL)
- **Response Format**: 
  - Success: `{"status": "success", "code": 200, ...}`
  - Error: `{"status": "error", "code": 400, ...}`

## 🧪 Testing Instructions

### Wait Period
**IMPORTANT**: Wait 10-15 minutes after deployment for the workflow to fully initialize.

### Option 1: Run Test Script
```powershell
.\Test-AzureWorkflow.ps1
```

This script will:
- Get the latest callback URL automatically
- Run 4 comprehensive tests:
  1. Valid employee insert/update (2 employees)
  2. Validation error test (missing required field)
  3. Schema error test (invalid structure)
  4. Batch insert test (5 employees)
- Show detailed pass/fail results

### Option 2: Manual Testing via Azure Portal
1. Go to: https://portal.azure.com
2. Navigate to: **AIS_Training_Shibin** → **upsert-employee**
3. Click: **Workflows** → **UpsertEmployee**
4. Click: **Overview** → Get the HTTP POST URL
5. Use Postman/curl to test

### Option 3: PowerShell Manual Test
```powershell
# Get the callback URL
$url = az rest --method post `
    --uri "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/upsert-employee/hostruntime/runtime/webhooks/workflow/api/management/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2023-12-01" `
    --query "value" -o tsv

# Test with sample data
$body = @'
{
  "employees": {
    "employee": [
      {
        "id": 9999,
        "firstName": "Test",
        "lastName": "User",
        "department": "IT",
        "position": "Developer",
        "salary": 75000,
        "email": "test@company.com"
      }
    ]
  }
}
'@

Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
```

## 📊 Expected Responses

### Success (200)
```json
{
  "status": "success",
  "code": 200,
  "message": "Employee upsert completed successfully",
  "details": {
    "totalProcessed": 1,
    "requestedCount": 1
  },
  "timestamp": "2025-11-06T...",
  "runId": "..."
}
```

### Validation Error (400)
```json
{
  "status": "error",
  "code": 400,
  "message": "Employee validation failed",
  "details": {
    "errors": [
      {
        "id": 123,
        "firstName": "null",
        "lastName": "Test",
        "error": "Invalid or missing required fields"
      }
    ]
  },
  "timestamp": "2025-11-06T...",
  "runId": "..."
}
```

### Schema Error (400)
```json
{
  "status": "error",
  "code": 400,
  "message": "Invalid request structure",
  "timestamp": "2025-11-06T...",
  "runId": "..."
}
```

## 🔗 Important Links

### Azure Portal
- **Logic App Overview**: https://portal.azure.com/#@neudesic.onmicrosoft.com/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/upsert-employee

- **Workflows Page**: https://portal.azure.com/#@neudesic.onmicrosoft.com/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/upsert-employee/logicApps

- **SQL Database**: https://portal.azure.com/#@neudesic.onmicrosoft.com/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Sql/servers/aistrainingserver/databases/empdb

## 🔍 Troubleshooting

### Getting 404 Error?
- **Cause**: Workflow still initializing
- **Solution**: Wait 10-15 minutes and try again

### Getting 502 Error?
- **Cause**: Stored procedure missing or connection issue
- **Solution**: Verify stored procedure exists:
  ```powershell
  $token = (az account get-access-token --resource https://database.windows.net --query accessToken -o tsv)
  Invoke-Sqlcmd -ServerInstance "aistrainingserver.database.windows.net" -Database "empdb" -AccessToken $token -Query "SELECT name FROM sys.objects WHERE type = 'P' AND name = 'UpsertEmployeeSimple'"
  ```

### Workflow Not Showing in Portal?
- **Solution**: Re-deploy using:
  ```powershell
  func azure functionapp publish upsert-employee --force
  ```

## 📝 Local vs Azure Configuration

### Local Development
- **Connections**: connections.local.json (LocalDB)
- **Database**: (localdb)\MSSQLLocalDB/EmployeeDB
- **Run**: F5 in VS Code or `func start`

### Azure Production
- **Connections**: connections.azure.json (Azure SQL)
- **Database**: aistrainingserver.database.windows.net/empdb
- **Deploy**: `func azure functionapp publish upsert-employee`

### Switch Back to Local
```powershell
Copy-Item "connections.local.json" "connections.json" -Force
```

## ✅ Deployment Checklist

- [x] Logic App deployed to Azure
- [x] Stored procedure (UpsertEmployeeSimple) deployed to Azure SQL
- [x] Azure SQL connections configured
- [x] Response format includes "code" field (200/400)
- [x] Schema validation implemented
- [x] Field validation implemented
- [x] Test script created (Test-AzureWorkflow.ps1)
- [ ] Wait 10-15 minutes for initialization
- [ ] Run test script
- [ ] Verify in Azure Portal
