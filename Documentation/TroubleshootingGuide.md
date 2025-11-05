# Logic Apps Standard - Troubleshooting Guide

## Issue: Getting 404 Error when Testing with Postman

### Root Cause
The 404 error occurs because Azure Logic Apps Standard workflows need to be run using the **Azure Logic Apps (Standard) extension in VS Code**, not the regular Azure Functions Core Tools.

## ✅ **Solution Steps**

### Step 1: Install Required Extensions in VS Code

1. **Open VS Code**
2. **Install Azure Logic Apps (Standard) Extension**:
   - Press `Ctrl+Shift+X` to open Extensions
   - Search for "Azure Logic Apps (Standard)"
   - Install the extension by Microsoft
   - Also install "Azure Account" extension if not already installed

### Step 2: Open Project Correctly

1. **Open the Logic App Project**:
   ```
   File > Open Folder > c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee
   ```

2. **Verify Project Structure**:
   ```
   UpsertEmployee/
   ├── UpsertEmployee/
   │   ├── workflow.json           ✅
   │   └── workflow.parameters.json ✅
   ├── connections.json            ✅
   ├── host.json                   ✅
   ├── local.settings.json         ✅
   └── workflow-designtime/        ✅
   ```

### Step 3: Start the Logic App

#### Method A: Using VS Code Debug (Recommended)
1. **Press F5** or go to **Run > Start Debugging**
2. **Select "Attach to Logic App"** if prompted
3. **Wait for the Logic App to start** (it may take 30-60 seconds)
4. **Look for the endpoint URL** in the debug console

#### Method B: Using VS Code Command Palette
1. **Press Ctrl+Shift+P**
2. **Type "Azure Logic Apps: Start"**
3. **Select your Logic App project**

### Step 4: Get the Correct Endpoint URL

When the Logic App starts successfully, you should see output like:

```
Azure Functions Core Tools
Core Tools Version: 4.x.x
Function Runtime Version: 4.x.x

The following 1 functions were found:
UpsertEmployee: [GET,POST] http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2020-05-01-preview&code={code}

For detailed output, run func with --verbose flag.
[2024-11-04T06:30:00.000Z] Host lock lease acquired by instance ID '00000000000000000000000000000000'.
[2024-11-04T06:30:00.000Z] Host started
```

### Step 5: Test with Postman

1. **Copy the full URL** from the VS Code output (including the code parameter)
2. **Update Postman collection**:
   - Import `Postman/EmployeeUpsert_TestCollection.json`
   - Update the `logicAppUrl` variable with the complete URL from step 4
3. **Run the first test**: "Insert New Employee - Complete Data"

## 🔧 **Alternative Testing Methods**

### Quick Test with curl
```powershell
# Replace {YOUR_ENDPOINT_URL} with the actual URL from VS Code
curl -X POST "{YOUR_ENDPOINT_URL}" `
  -H "Content-Type: application/json" `
  -d '{
    "EmployeeID": 5001,
    "FirstName": "Test",
    "LastName": "User",
    "Department": "IT",
    "Position": "Developer",
    "Salary": 70000.00,
    "Email": "test.user@company.com"
  }'
```

### Test with PowerShell
```powershell
$endpoint = "YOUR_ENDPOINT_URL_HERE"
$body = @{
    EmployeeID = 5001
    FirstName = "Test"
    LastName = "User"
    Department = "IT"
    Position = "Developer"
    Salary = 70000.00
    Email = "test.user@company.com"
} | ConvertTo-Json

Invoke-RestMethod -Uri $endpoint -Method POST -Body $body -ContentType "application/json"
```

## 🚨 **Common Issues and Solutions**

### Issue 1: "No functions found"
**Cause**: Using regular Azure Functions Core Tools instead of Logic Apps extension
**Solution**: Use VS Code with Azure Logic Apps (Standard) extension

### Issue 2: "Port 7071 is unavailable"
**Cause**: Another process is using the port
**Solution**: 
```powershell
# Stop all func processes
Stop-Process -Name "func" -Force
# Then restart using VS Code F5
```

### Issue 3: Database connection errors
**Cause**: LocalDB not running or connection string incorrect
**Solution**:
```powershell
# Start LocalDB
sqllocaldb start MSSQLLocalDB
# Verify database exists
sqlcmd -S "(localdb)\MSSQLLocalDB" -Q "SELECT name FROM sys.databases WHERE name = 'EmployeeDB'"
```

### Issue 4: JSON schema validation errors
**Cause**: Missing required fields in the request
**Solution**: Ensure your JSON includes:
```json
{
  "EmployeeID": 1001,      // Required: Integer > 0
  "FirstName": "John",     // Required: Non-empty string  
  "LastName": "Doe"        // Required: Non-empty string
}
```

## 📝 **Expected Success Response**

When everything works correctly, you should get:

```json
{
  "status": "success",
  "message": "Employee record processed successfully",
  "data": {
    "employeeID": 5001,
    "operation": "INSERT",
    "timestamp": "2024-11-04T10:30:00Z",
    "runId": "08584693315927374810665216732CU00"
  }
}
```

## 🎯 **Next Steps After Success**

1. **Run all Postman test scenarios**
2. **Verify data in the database**:
   ```sql
   SELECT * FROM dbo.vw_ActiveEmployees ORDER BY ModifiedDate DESC;
   ```
3. **Check the Logic App run history** in VS Code
4. **Review logs** for any warnings or errors

## 📞 **If Still Getting 404**

1. **Check VS Code Output Panel**: Look for any error messages
2. **Verify local.settings.json**: Ensure all settings are correct
3. **Check Database**: Ensure LocalDB is running and EmployeeDB exists
4. **Restart VS Code**: Sometimes a fresh start helps
5. **Check Extensions**: Ensure Azure Logic Apps (Standard) extension is enabled

---

**Remember**: Logic Apps Standard is different from regular Azure Functions. Always use the VS Code Azure Logic Apps extension for local development and testing.