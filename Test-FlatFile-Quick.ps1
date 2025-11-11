# Simple Test Script - Upload file and monitor Azure workflow locally
# This uploads a file to C:\EmployeeFiles and monitors the Azure workflow execution

param(
    [int]$WaitSeconds = 120
)

$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "ais-training-la"
$subscriptionId = "cbb1dbec-731f-4479-a084-bdaec5e54fd4"
$serviceBusNamespace = "sb-flatfile-processing"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Flat File Pickup - Test from Local" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Upload test file
Write-Host "Step 1: Uploading test file" -ForegroundColor Cyan
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$testFile = "employees_test_$timestamp.csv"
$targetPath = "C:\EmployeeFiles\$testFile"

if (-not (Test-Path "C:\EmployeeFiles")) {
    New-Item -ItemType Directory -Path "C:\EmployeeFiles" -Force | Out-Null
}

Copy-Item ".\Artifacts\employees.csv" $targetPath -Force
Write-Host "  ✓ File uploaded: $testFile" -ForegroundColor Green
Write-Host "  Location: $targetPath" -ForegroundColor Gray
Write-Host ""

# Step 2: Wait for processing
Write-Host "Step 2: Waiting for Azure workflow to process" -ForegroundColor Cyan
Write-Host "  Waiting $WaitSeconds seconds..." -ForegroundColor Yellow
Write-Host ""

for ($i = 1; $i -le $WaitSeconds; $i++) {
    if ($i % 10 -eq 0) {
        Write-Host "  [$i/$WaitSeconds sec] Monitoring..." -ForegroundColor Gray
    }
    Start-Sleep -Seconds 1
}

Write-Host ""

# Step 3: Check workflow runs
Write-Host "Step 3: Checking workflow execution" -ForegroundColor Cyan

$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows/wf-flatfile-pickup/runs?api-version=2022-03-01"

try {
    $result = az rest --method GET --uri $uri --output json 2>$null
    if ($result) {
        $runs = $result | ConvertFrom-Json
        
        if ($runs.value -and $runs.value.Count -gt 0) {
            Write-Host "  ✓ Found workflow runs!" -ForegroundColor Green
            Write-Host ""
            
            $latestRuns = $runs.value | Select-Object -First 3
            foreach ($run in $latestRuns) {
                $runId = $run.name.Split('/')[-1]
                $status = $run.properties.status
                $startTime = $run.properties.startTime
                
                $statusColor = switch ($status) {
                    "Succeeded" { "Green" }
                    "Failed" { "Red" }
                    "Running" { "Yellow" }
                    default { "Gray" }
                }
                
                Write-Host "  Run ID: $runId" -ForegroundColor Gray
                Write-Host "  Status: $status" -ForegroundColor $statusColor
                Write-Host "  Start Time: $startTime" -ForegroundColor Gray
                Write-Host ""
            }
        }
        else {
            Write-Host "  ✗ No workflow runs found" -ForegroundColor Red
            Write-Host "  The workflow may not be enabled or configured correctly" -ForegroundColor Yellow
            Write-Host ""
        }
    }
}
catch {
    Write-Host "  ✗ Failed to check workflow runs: $_" -ForegroundColor Red
    Write-Host ""
}

# Step 4: Check Service Bus queue
Write-Host "Step 4: Checking Service Bus queue" -ForegroundColor Cyan

try {
    $result = az servicebus queue show `
        --resource-group $resourceGroup `
        --namespace-name $serviceBusNamespace `
        --name flatfile-processing-queue `
        --query "countDetails" `
        --output json 2>$null | ConvertFrom-Json
    
    if ($result) {
        Write-Host "  Processing Queue:" -ForegroundColor Gray
        Write-Host "    Active Messages: $($result.activeMessageCount)" -ForegroundColor $(if($result.activeMessageCount -gt 0){"Green"}else{"Gray"})
        Write-Host "    Dead Letters: $($result.deadLetterMessageCount)" -ForegroundColor $(if($result.deadLetterMessageCount -gt 0){"Red"}else{"Gray"})
        Write-Host ""
    }
}
catch {
    Write-Host "  Could not check Service Bus queue" -ForegroundColor Yellow
    Write-Host ""
}

# Summary
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "File uploaded to: $targetPath" -ForegroundColor White
Write-Host ""
Write-Host "To verify the workflow is working:" -ForegroundColor Yellow
Write-Host "1. Open Azure Portal and check workflow run history" -ForegroundColor White
Write-Host "2. Check if messages appear in Service Bus queue" -ForegroundColor White
Write-Host "3. Run full test: .\Test-FlatFile-Simple.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Portal Link:" -ForegroundColor Yellow
Write-Host "https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows/wf-flatfile-pickup/overview" -ForegroundColor Gray
Write-Host ""
