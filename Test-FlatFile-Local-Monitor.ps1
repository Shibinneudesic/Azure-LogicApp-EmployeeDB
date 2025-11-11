# Local Monitoring Script for Flat File Pickup Workflow
# This script tests the Azure workflow by uploading a file locally and monitoring the Azure execution

param(
    [int]$MonitorDurationSeconds = 180,
    [switch]$ContinuousMonitoring
)

$ErrorActionPreference = "Continue"

# Configuration
$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "ais-training-la"
$subscriptionId = "cbb1dbec-731f-4479-a084-bdaec5e54fd4"
$serviceBusNamespace = "sb-flatfile-processing"
$localFilePath = "C:\EmployeeFiles"
$sourceFile = ".\Artifacts\employees.csv"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Flat File Pickup - Local Test Monitor" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script tests the Azure workflow from your local machine" -ForegroundColor Yellow
Write-Host ""

# Function: Get latest workflow run
function Get-LatestWorkflowRun {
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows/wf-flatfile-pickup/runs?api-version=2022-03-01"
    
    try {
        $result = az rest --method GET --uri $uri --output json 2>$null
        if ($result) {
            $runs = $result | ConvertFrom-Json
            return $runs.value | Select-Object -First 1
        }
    }
    catch {
        return $null
    }
}

# Function: Get workflow run details
function Get-WorkflowRunDetails {
    param($runName)
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows/wf-flatfile-pickup/runs/$runName`?api-version=2022-03-01"
    
    try {
        $result = az rest --method GET --uri $uri --output json 2>$null | ConvertFrom-Json
        return $result
    }
    catch {
        return $null
    }
}

# Function: Check Service Bus queue
function Check-ServiceBusQueue {
    try {
        $result = az servicebus queue show `
            --resource-group $resourceGroup `
            --namespace-name $serviceBusNamespace `
            --name flatfile-processing-queue `
            --query "countDetails.activeMessageCount" `
            --output tsv 2>$null
        
        return [int]$result
    }
    catch {
        return 0
    }
}

# Step 1: Get baseline
Write-Host "Step 1: Getting baseline status" -ForegroundColor Cyan
Write-Host ""

$baselineRun = Get-LatestWorkflowRun
$baselineRunId = if ($baselineRun) { $baselineRun.name.Split('/')[-1] } else { $null }
$baselineMessages = Check-ServiceBusQueue

Write-Host "  Latest Run ID: $(if($baselineRunId){"$baselineRunId"}else{"None"})" -ForegroundColor Gray
Write-Host "  Service Bus Messages: $baselineMessages" -ForegroundColor Gray
Write-Host ""

# Step 2: Upload test file
Write-Host "Step 2: Uploading test file" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $sourceFile)) {
    Write-Host "  ERROR: Source file not found: $sourceFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $localFilePath)) {
    New-Item -ItemType Directory -Path $localFilePath -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$testFileName = "employees_test_$timestamp.csv"
$testFilePath = Join-Path $localFilePath $testFileName

try {
    Copy-Item $sourceFile $testFilePath -Force
    Write-Host "  File uploaded: $testFileName" -ForegroundColor Green
    Write-Host "  Location: $testFilePath" -ForegroundColor Gray
    Write-Host "  Size: $((Get-Item $testFilePath).Length) bytes" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "  ERROR: Failed to upload file: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Monitor for workflow execution
Write-Host "Step 3: Monitoring workflow execution" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Monitoring for $MonitorDurationSeconds seconds..." -ForegroundColor Yellow
Write-Host "  Press Ctrl+C to stop monitoring" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date
$newRunDetected = $false
$workflowCompleted = $false
$checkInterval = 10
$lastCheckTime = $startTime

while (((Get-Date) - $startTime).TotalSeconds -lt $MonitorDurationSeconds) {
    $elapsed = [int]((Get-Date) - $startTime).TotalSeconds
    
    # Check every 10 seconds
    if (((Get-Date) - $lastCheckTime).TotalSeconds -ge $checkInterval) {
        $lastCheckTime = Get-Date
        
        # Check for new workflow run
        $currentRun = Get-LatestWorkflowRun
        $currentRunId = if ($currentRun) { $currentRun.name.Split('/')[-1] } else { $null }
        
        if ($currentRunId -and $currentRunId -ne $baselineRunId) {
            if (-not $newRunDetected) {
                Write-Host "  ✓ New workflow run detected!" -ForegroundColor Green
                Write-Host "    Run ID: $currentRunId" -ForegroundColor Gray
                $newRunDetected = $true
            }
            
            # Get run details
            $runDetails = Get-WorkflowRunDetails -runName $currentRunId
            
            if ($runDetails) {
                $status = $runDetails.properties.status
                $statusColor = switch ($status) {
                    "Succeeded" { "Green" }
                    "Failed" { "Red" }
                    "Running" { "Yellow" }
                    default { "Gray" }
                }
                
                Write-Host "    Status: $status" -ForegroundColor $statusColor
                
                if ($status -eq "Succeeded") {
                    Write-Host "    ✓ Workflow completed successfully!" -ForegroundColor Green
                    $workflowCompleted = $true
                    
                    # Check Service Bus
                    Start-Sleep -Seconds 5
                    $currentMessages = Check-ServiceBusQueue
                    
                    if ($currentMessages -gt $baselineMessages) {
                        Write-Host "    ✓ Message added to Service Bus queue" -ForegroundColor Green
                        Write-Host "      Queue messages: $currentMessages" -ForegroundColor Gray
                    }
                    
                    break
                }
                elseif ($status -eq "Failed") {
                    Write-Host "    ✗ Workflow failed!" -ForegroundColor Red
                    
                    if ($runDetails.properties.error) {
                        Write-Host "    Error: $($runDetails.properties.error.message)" -ForegroundColor Red
                    }
                    
                    break
                }
            }
        }
        else {
            $remaining = $MonitorDurationSeconds - $elapsed
            Write-Host "  [$elapsed/$MonitorDurationSeconds sec] Waiting for workflow trigger... ($remaining sec remaining)" -ForegroundColor Gray
        }
    }
    }
    
    Start-Sleep -Seconds 1
}

Write-Host ""

# Step 4: Final status
Write-Host "Step 4: Final Status" -ForegroundColor Cyan
Write-Host ""

if ($newRunDetected) {
    if ($workflowCompleted) {
        Write-Host "  ✓ TEST PASSED" -ForegroundColor Green
        Write-Host "  The workflow detected and processed the file successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ TEST INCOMPLETE" -ForegroundColor Yellow
        Write-Host "  Workflow started but did not complete within monitoring period" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  ✗ TEST FAILED" -ForegroundColor Red
    Write-Host "  No workflow run was detected within $MonitorDurationSeconds seconds" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Possible reasons:" -ForegroundColor Yellow
    Write-Host "  1. Workflow is not enabled in Azure Portal" -ForegroundColor White
    Write-Host "  2. FileSystem trigger is not configured correctly" -ForegroundColor White
    Write-Host "  3. On-premise gateway is not connected" -ForegroundColor White
    Write-Host "  4. File polling interval is longer than monitoring duration" -ForegroundColor White
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Check workflow in Azure Portal:" -ForegroundColor White
Write-Host "   https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows/wf-flatfile-pickup/overview" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Verify workflow is enabled and healthy" -ForegroundColor White
Write-Host ""
Write-Host "3. Check workflow run history for details" -ForegroundColor White
Write-Host ""
Write-Host "4. Run diagnostics:" -ForegroundColor White
Write-Host "   .\Diagnose-FlatFileWorkflows.ps1" -ForegroundColor Gray
Write-Host ""

if ($newRunDetected -and $workflowCompleted) {
    Write-Host "5. Check transformation workflow:" -ForegroundColor White
    Write-Host "   The file should now be transformed to XML and JSON" -ForegroundColor Gray
    Write-Host "   Run: .\Test-FlatFile-Simple.ps1 -CheckQueuesOnly" -ForegroundColor Gray
    Write-Host ""
}
