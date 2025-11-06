# Check Workflow Version and Content
# This script verifies what version of the workflow is actually running in Azure

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Workflow Version Checker" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "upsert-employee"
$workflowName = "UpsertEmployee"

Write-Host "[1] Checking Logic App Status..." -ForegroundColor Yellow
$appStatus = az logicapp show --name $logicAppName --resource-group $resourceGroup --query "{name:name, state:state, enabled:enabledState}" -o json | ConvertFrom-Json
Write-Host "  Name: $($appStatus.name)" -ForegroundColor White
Write-Host "  State: $($appStatus.state)" -ForegroundColor White
Write-Host "  Enabled: $($appStatus.enabled)" -ForegroundColor White

Write-Host "`n[2] Checking Workflow Registration..." -ForegroundColor Yellow
$workflows = az rest --method get --uri "/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows?api-version=2023-12-01" 2>&1

if ($workflows -match "ERROR" -or $workflows -match "NotFound") {
    Write-Host "  ✗ No workflows registered yet" -ForegroundColor Red
    Write-Host "  Status: Workflow still initializing..." -ForegroundColor Yellow
} else {
    $workflowList = $workflows | ConvertFrom-Json
    if ($workflowList.value.Count -gt 0) {
        Write-Host "  ✓ Workflows found: $($workflowList.value.Count)" -ForegroundColor Green
        foreach ($wf in $workflowList.value) {
            Write-Host "    - $($wf.name) (State: $($wf.properties.state))" -ForegroundColor White
        }
    } else {
        Write-Host "  ✗ No workflows in list" -ForegroundColor Red
    }
}

Write-Host "`n[3] Testing Workflow Endpoint..." -ForegroundColor Yellow
$testUrl = "https://upsert-employee.azurewebsites.net/api/UpsertEmployee/triggers/When_a_HTTP_request_is_received/invoke?api-version=2023-12-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=nIF4LOphUwoSWZi4hHarFSJBTZqdWpKH7fwoYbF-huM"

$testBody = @{
    employees = @{
        employee = @(
            @{
                id = 9999
                firstName = "Version"
                lastName = "Check"
                department = "Test"
            }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $testUrl -Method Post -Body $testBody -ContentType "application/json" -ErrorAction Stop
    Write-Host "  ✓ Workflow responded!" -ForegroundColor Green
    Write-Host "`n  Response Code: $($response.code)" -ForegroundColor Cyan
    Write-Host "  Status: $($response.status)" -ForegroundColor Cyan
    Write-Host "  Message: $($response.message)" -ForegroundColor White
    
    # Check if it's using UpsertEmployeeSimple (new version) or UpsertEmployee (old version)
    Write-Host "`n[4] Version Detection:" -ForegroundColor Yellow
    if ($response.code -eq 200) {
        Write-Host "  ✓ Using NEW version (UpsertEmployeeSimple)" -ForegroundColor Green
        Write-Host "  - Response format has 'code' field" -ForegroundColor White
        Write-Host "  - No OUTPUT parameter errors" -ForegroundColor White
    } else {
        Write-Host "  ? Response code: $($response.code)" -ForegroundColor Yellow
    }
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Status Code: $statusCode" -ForegroundColor Yellow
    
    if ($statusCode -eq 404) {
        Write-Host "`n  Diagnosis: Workflow not initialized yet" -ForegroundColor Yellow
        Write-Host "  Solution: Wait 5-10 more minutes and run this script again" -ForegroundColor Cyan
    } elseif ($statusCode -eq 502) {
        Write-Host "`n  Diagnosis: OLD version still running (with OUTPUT parameters bug)" -ForegroundColor Red
        Write-Host "  Solution: Need to force redeploy or clear cache" -ForegroundColor Cyan
    }
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
