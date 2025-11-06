# Grant Managed Identity Permissions to Azure SQL

## Issue
The Logic App managed identity needs permissions on the Azure SQL database to execute the `UpsertEmployeeSimple` stored procedure.

**Managed Identity Details:**
- Name: `upsert-employee`
- Principal ID: `5ffec447-4565-454b-be4d-946997ee0554`
- Tenant ID: `687f51c3-0c5d-4905-84f8-97c683a5b9d1`

**Azure SQL Details:**
- Server: `aistrainingserver.database.windows.net`
- Database: `empdb`

## Solution Steps

### Option 1: Using Azure Portal Query Editor (Recommended)

1. **Open Azure Portal** and navigate to:
   - SQL Database → `empdb` on server `aistrainingserver`

2. **Open Query Editor**:
   - Click on "Query editor (preview)" in the left menu
   - Sign in with your Azure AD credentials

3. **Execute the following SQL script**:

```sql
-- Create user for Logic App managed identity
CREATE USER [upsert-employee] FROM EXTERNAL PROVIDER;

-- Grant database roles for read/write access
ALTER ROLE db_datareader ADD MEMBER [upsert-employee];
ALTER ROLE db_datawriter ADD MEMBER [upsert-employee];

-- Grant EXECUTE permission for stored procedures
GRANT EXECUTE TO [upsert-employee];

-- Grant specific permissions on Employee table
GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [upsert-employee];

-- Verify the setup
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    dp.create_date AS CreatedDate
FROM sys.database_principals dp
WHERE dp.name = 'upsert-employee';
```

4. **Verify Output**: You should see a result showing:
   - PrincipalName: `upsert-employee`
   - PrincipalType: `EXTERNAL_USER`
   - CreatedDate: (current timestamp)

### Option 2: Using SQL Server Management Studio (SSMS)

1. **Connect to SQL Server**:
   - Server: `aistrainingserver.database.windows.net`
   - Authentication: Azure Active Directory - Universal with MFA
   - Database: `empdb`

2. **Execute the SQL script** from Option 1 above

3. **Verify** by running:
```sql
SELECT * FROM sys.database_principals WHERE name = 'upsert-employee';
```

### Option 3: Using Azure CLI with Query

1. Run this command:
```bash
az sql db query \
  --server aistrainingserver \
  --database empdb \
  --query "CREATE USER [upsert-employee] FROM EXTERNAL PROVIDER; ALTER ROLE db_datareader ADD MEMBER [upsert-employee]; ALTER ROLE db_datawriter ADD MEMBER [upsert-employee]; GRANT EXECUTE TO [upsert-employee];"
```

## After Granting Permissions

Once permissions are granted, test the workflow:

```powershell
$url = "https://upsert-employee.azurewebsites.net/api/UpsertEmployee/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=nIF4LOphUwoSWZi4hHarFSJBTZqdWpKH7fwoYbF-huM"

$body = @'
{
  "employees": {
    "employee": [
      {
        "id": 2010,
        "firstName": "John",
        "lastName": "Doe",
        "department": "Engineering",
        "position": "Senior Developer",
        "salary": 95000,
        "email": "john.doe@example.com"
      }
    ]
  }
}
'@

Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
```

## Expected Result

After permissions are granted, you should receive:
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

## Troubleshooting

If you still see errors:
1. Check that the managed identity is enabled: `az functionapp identity show --name upsert-employee --resource-group AIS_Training_Shibin`
2. Verify SQL firewall allows Azure services: In Azure Portal → SQL Server → Firewalls and virtual networks → "Allow Azure services and resources to access this server" should be ON
3. Check Logic App logs in Azure Portal → Logic App → Workflow → Runs history
