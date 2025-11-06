# Script to fix the unhealthy workflow in Azure Logic App

Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Azure Logic App Workflow Fix Script" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "upsert-employee"
$workflowName = "UpsertEmployee"

# Step 1: Stop the Logic App
Write-Host "[1/5] Stopping Logic App..." -ForegroundColor Yellow
az functionapp stop --name $logicAppName --resource-group $resourceGroup
Start-Sleep -Seconds 5

# Step 2: Get publishing credentials
Write-Host "[2/5] Getting Kudu credentials..." -ForegroundColor Yellow
$creds = az webapp deployment list-publishing-credentials --name $logicAppName --resource-group $resourceGroup | ConvertFrom-Json
$user = $creds.publishingUserName
$pass = $creds.publishingPassword
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${user}:${pass}"))
$headers = @{Authorization=("Basic {0}" -f $base64AuthInfo)}

# Step 3: Delete workflow metadata via Kudu
Write-Host "[3/5] Cleaning workflow metadata..." -ForegroundColor Yellow
try {
    # Try to delete the workflow folder
    Invoke-RestMethod -Uri "https://$logicAppName.scm.azurewebsites.net/api/vfs/data/workflows/$workflowName/" -Headers $headers -Method Delete -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  ✓ Metadata cleared" -ForegroundColor Green
} catch {
    Write-Host "  ℹ No metadata to clean (this is OK)" -ForegroundColor Gray
} finally {
    Start-Sleep -Seconds 2
}

# Step 4: Redeploy
Write-Host "[4/5] Deploying workflow..." -ForegroundColor Yellow
func azure functionapp publish $logicAppName --force

# Step 5: Start and sync
Write-Host "[5/5] Starting Logic App..." -ForegroundColor Yellow
az functionapp start --name $logicAppName --resource-group $resourceGroup
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Syncing triggers..." -ForegroundColor Yellow
az rest --method post --uri "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/syncfunctiontriggers?api-version=2023-12-01"
Start-Sleep -Seconds 10

# Check health
Write-Host ""
Write-Host "Checking workflow health..." -ForegroundColor Cyan
$health = az rest --method get --uri "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/hostruntime/runtime/webhooks/workflow/api/management/workflows/$workflowName?api-version=2023-12-01" | ConvertFrom-Json

if ($health.health.state -eq "Healthy") {
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ✓ Workflow is now HEALTHY!" -ForegroundColor Green
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
    
    # Get callback URL
    Write-Host ""
    Write-Host "Getting callback URL..." -ForegroundColor Cyan
    $callbackUrl = az rest --method post --uri "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/hostruntime/runtime/webhooks/workflow/api/management/workflows/$workflowName/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2023-12-01" --query "value" --output tsv
    
    Write-Host ""
    Write-Host "Callback URL:" -ForegroundColor Yellow
    Write-Host $callbackUrl -ForegroundColor White
    Write-Host ""
    
    # Test it
    Write-Host "Testing workflow..." -ForegroundColor Cyan
    $testData = @'
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
    
    try {
        $response = Invoke-RestMethod -Uri $callbackUrl -Method Post -Body $testData -ContentType "application/json"
        Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "  ✓ TEST SUCCESSFUL!" -ForegroundColor Green
        Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "  ✗ Test failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Red
    }
} else {
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  ✗ Workflow is still unhealthy" -ForegroundColor Red
    Write-Host "══════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "Error: $($health.health.errorMessage.error.message)" -ForegroundColor Yellow
}
