# SQL Permission Setup for Recreated Logic App

## Issue
After recreating the Logic App `ais-training-la`, the managed identity changed (new Principal ID: `99ded633-38c2-4f05-a41c-7ba48aed3285`), so SQL permissions need to be granted again.

## Option 1: Using Azure Portal Query Editor (RECOMMENDED)

1. Go to Azure Portal: https://portal.azure.com
2. Navigate to **SQL databases** → `empdb`
3. Click **Query editor (preview)** in the left menu
4. **Login** using your Azure AD account (should auto-login as `Shibin.Sam@neudesic.com`)
5. **Copy and paste** the contents of `Scripts/Grant-Permissions-Recreated-LogicApp.sql`
6. Click **Run**
7. Verify you see success messages

## Option 2: Using SQL Server Management Studio (SSMS)

1. Open **SQL Server Management Studio**
2. Connect to server: `aistrainingserver.database.windows.net`
   - **Authentication**: Azure Active Directory - Universal with MFA
   - **User name**: Shibin.Sam@neudesic.com
   - **Database**: empdb
3. Click **Connect**
4. Open the file: `Scripts/Grant-Permissions-Recreated-LogicApp.sql`
5. Make sure `empdb` is selected in the database dropdown
6. Click **Execute** (F5)
7. Verify success messages in the Messages tab

## Option 3: Using Azure Data Studio

1. Open **Azure Data Studio**
2. Create new connection:
   - **Server**: aistrainingserver.database.windows.net
   - **Authentication type**: Azure Active Directory - Universal with MFA Support
   - **Account**: Shibin.Sam@neudesic.com
   - **Database**: empdb
3. Click **Connect**
4. Open the file: `Scripts/Grant-Permissions-Recreated-LogicApp.sql`
5. Click **Run** (F5)
6. Verify success messages

## What the Script Does

The script `Grant-Permissions-Recreated-LogicApp.sql` will:

1. ✅ Create user `ais-training-la` from EXTERNAL PROVIDER (if doesn't exist)
2. ✅ Grant CONNECT permission
3. ✅ Grant EXECUTE on `dbo.usp_Employee_Upsert_Batch` stored procedure
4. ✅ Grant EXECUTE on `dbo.EmployeeTableType` table type
5. ✅ Grant SELECT on `dbo.Employees` table
6. ✅ Grant INSERT on `dbo.Employees` table
7. ✅ Grant UPDATE on `dbo.Employees` table
8. ✅ Display verification queries showing all granted permissions

## After Running the Script

Once permissions are granted, test the Azure workflow:

```powershell
# Get callback URL
$url = az rest --method post --uri "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/ais-training-la/hostruntime/runtime/webhooks/workflow/api/management/workflows/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2022-03-01" --query "value" --output tsv

# Test with 3 employees
$body = Get-Content "test-batch-3-employees.json" -Raw
Invoke-WebRequest -Uri $url -Method Post -Body $body -ContentType "application/json"
```

## Verify Permissions (Optional)

After granting permissions, you can verify by running `Scripts/Check-Permissions.sql` in the same way.

Expected output:
- User: ais-training-la (type: EXTERNAL_USER)
- Permissions on usp_Employee_Upsert_Batch: EXECUTE
- Permissions on EmployeeTableType: EXECUTE  
- Permissions on Employees table: SELECT, INSERT, UPDATE

## Current Status

- ✅ Workflow deployed to Azure (Version 5.2.0.0)
- ✅ Workflow is Healthy
- ✅ Callback URL retrieved successfully
- ⏳ **PENDING**: SQL permissions need to be granted
- ⏳ **PENDING**: Test workflow after permissions granted
