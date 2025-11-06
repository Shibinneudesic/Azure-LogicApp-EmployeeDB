# SOLUTION: Recreation of Logic App Required

## Problem
The workflow has an "InvalidFlowKind" error:  
**"The existing workflow 'UpsertEmployee' cannot be changed from '<null>' to 'Stateful' kind."**

This error occurs when a workflow was created without a proper `kind` specification, and Azure Logic Apps does not allow changing the kind of an existing workflow.

## Solution: Recreate the Logic App

### Option 1: Delete and Recreate via Azure Portal (Recommended)

1. **Delete the Logic App**:
   - Go to Azure Portal → Resource Group: `AIS_Training_Shibin`
   - Find Logic App: `upsert-employee`
   - Click "Delete" and confirm

2. **Recreate using Bicep**:
   ```powershell
   cd c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee
   az deployment group create `
     --name "logicapp-recreate-$(Get-Date -Format 'yyyyMMddHHmmss')" `
     --resource-group "AIS_Training_Shibin" `
     --template-file "infra/main.bicep"
   ```

3. **Deploy Workflow**:
   ```powershell
   func azure functionapp publish upsert-employee
   ```

4. **Grant SQL Permissions** (run in Azure SQL Query Editor):
   ```sql
   -- The user already exists, just grant permissions
   ALTER ROLE db_datareader ADD MEMBER [upsert-employee];
   ALTER ROLE db_datawriter ADD MEMBER [upsert-employee];
   GRANT EXECUTE TO [upsert-employee];
   GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [upsert-employee];
   ```

5. **Test**:
   ```powershell
   $url = az rest --method post `
     --uri "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/upsert-employee/hostruntime/runtime/webhooks/workflow/api/management/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2023-12-01" `
     --query "value" --output tsv
   
   $body = @'
   {
     "employees": {
       "employee": [
         {
           "id": 3001,
           "firstName": "Test",
           "lastName": "User",
           "department": "IT",
           "position": "Engineer",
           "salary": 90000,
           "email": "test@example.com"
         }
       ]
     }
   }
'@
   
   Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
   ```

### Option 2: Automated Script

Run this PowerShell script:

```powershell
$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "upsert-employee"

# Delete Logic App
Write-Host "Deleting existing Logic App..." -ForegroundColor Yellow
az functionapp delete --name $logicAppName --resource-group $resourceGroup --yes

# Wait for deletion
Write-Host "Waiting for deletion to complete..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Recreate infrastructure
Write-Host "Recreating Logic App infrastructure..." -ForegroundColor Green
az deployment group create `
  --name "logicapp-fix-$(Get-Date -Format 'yyyyMMddHHmmss')" `
  --resource-group $resourceGroup `
  --template-file "infra/main.bicep"

# Wait for creation
Write-Host "Waiting for Logic App to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Deploy workflow
Write-Host "Deploying workflow..." -ForegroundColor Green
func azure functionapp publish $logicAppName

# Get callback URL
Write-Host "`nGetting callback URL..." -ForegroundColor Cyan
$url = az rest --method post `
  --uri "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/hostruntime/runtime/webhooks/workflow/api/management/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2023-12-01" `
  --query "value" --output tsv

Write-Host "`nCallback URL:" -ForegroundColor Yellow
Write-Host $url

Write-Host "`nLogic App recreated successfully!" -ForegroundColor Green
Write-Host "Don't forget to grant SQL permissions if needed!" -ForegroundColor Yellow
```

## Why This Happens

This issue occurs because:
1. The workflow was initially deployed without a `kind` property or with a null kind
2. Azure Logic Apps treats the kind as immutable once set
3. Subsequent deployments trying to set `kind: "Stateful"` fail

## Prevention

Always ensure your `workflow.json` includes:
```json
{
  "definition": { ... },
  "kind": "Stateful"
}
```

The workflow in this project already has this, but the initial deployment may have had issues.
