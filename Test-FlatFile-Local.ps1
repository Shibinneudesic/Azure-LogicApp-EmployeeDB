# Local Testing Script for Flat File Workflows
# Tests both workflows locally using Azurite and local Service Bus

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Flat File Workflows - Local Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$sourceFile = ".\Artifacts\employees.csv"
$testDir = "C:\EmployeeFiles"
$serviceBusQueue = "flatfile-processing-queue"

# Check prerequisites
Write-Host "[Prerequisite Check]" -ForegroundColor Yellow
Write-Host ""

$azurite = Get-Process -Name "Azurite" -ErrorAction SilentlyContinue
if ($azurite) {
    Write-Host "  ✓ Azurite is running (PID: $($azurite.Id))" -ForegroundColor Green
} else {
    Write-Host "  ✗ Azurite is NOT running" -ForegroundColor Red
    Write-Host "    Run: .\Setup-LocalTesting.ps1" -ForegroundColor Yellow
    exit 1
}

$funcHost = Get-Process -Name "func" -ErrorAction SilentlyContinue
if ($funcHost) {
    Write-Host "  ✓ Func host is running (PID: $($funcHost.Id))" -ForegroundColor Green
} else {
    Write-Host "  ✗ Func host is NOT running" -ForegroundColor Red
    Write-Host "    Run: func start" -ForegroundColor Yellow
    exit 1
}

if (Test-Path $sourceFile) {
    Write-Host "  ✓ Source CSV file exists" -ForegroundColor Green
} else {
    Write-Host "  ✗ Source CSV file not found: $sourceFile" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test Workflow 1: File Pickup
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Testing Workflow 1: File Pickup" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Copying test file to monitored directory..." -ForegroundColor Yellow

if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$testFile = Join-Path $testDir "employees_local_$timestamp.csv"

Copy-Item $sourceFile $testFile -Force
$fileInfo = Get-Item $testFile

Write-Host "  ✓ File copied" -ForegroundColor Green
Write-Host "    Location: $testFile" -ForegroundColor Gray
Write-Host "    Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 2: Waiting for wf-flatfile-pickup to process (30 seconds)..." -ForegroundColor Yellow
Write-Host "  Check the func host terminal for workflow execution logs" -ForegroundColor Cyan
Write-Host ""

Start-Sleep -Seconds 30

# Check if message appeared in Service Bus (we'll check locally via func host logs)
Write-Host "  ℹ Check the func host terminal for:" -ForegroundColor Cyan
Write-Host "    - Workflow 'wf-flatfile-pickup' execution" -ForegroundColor Gray
Write-Host "    - Service Bus send operation" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 3: Manually triggering Workflow 2 for testing..." -ForegroundColor Yellow
Write-Host ""

# For local testing of workflow 2, we need to manually send a test message
# Since Service Bus trigger in local requires actual Azure Service Bus
Write-Host "  Note: Workflow 2 (transformation) requires Service Bus trigger" -ForegroundColor Cyan
Write-Host "  For full local testing, we have two options:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Option 1: Use Azure Service Bus (already configured)" -ForegroundColor White
Write-Host "    - Workflow 1 will send message to Azure Service Bus" -ForegroundColor Gray
Write-Host "    - Workflow 2 will be triggered automatically" -ForegroundColor Gray
Write-Host ""
Write-Host "  Option 2: Test transformation logic separately" -ForegroundColor White
Write-Host "    - Manually trigger workflow 2 via HTTP (if configured)" -ForegroundColor Gray
Write-Host "    - Or test XSLT/Liquid maps independently" -ForegroundColor Gray
Write-Host ""

# Wait for Service Bus processing
Write-Host "Waiting 30 seconds for Service Bus processing..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check storage queues
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Checking Storage Queues" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$storageEndpoint = "http://127.0.0.1:10001/devstoreaccount1"
$queues = @("flatfile-xml-queue", "flatfile-json-queue")

foreach ($queueName in $queues) {
    Write-Host "Queue: $queueName" -ForegroundColor Yellow
    $uri = "$storageEndpoint/$queueName/messages?peekonly=true&numofmessages=1"
    
    try {
        $response = Invoke-WebRequest -Uri $uri -Method GET -Headers @{
            "x-ms-version" = "2021-08-06"
        } -ErrorAction Stop
        
        if ($response.StatusCode -eq 200 -and $response.Content) {
            Write-Host "  ✓ Messages found in queue!" -ForegroundColor Green
            
            # Parse and display message
            [xml]$content = $response.Content
            if ($content.QueueMessagesList.QueueMessage) {
                $messageText = $content.QueueMessagesList.QueueMessage.MessageText
                $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($messageText))
                
                Write-Host "  Message preview (first 200 chars):" -ForegroundColor Cyan
                Write-Host "  $($decoded.Substring(0, [Math]::Min(200, $decoded.Length)))..." -ForegroundColor Gray
            }
        } else {
            Write-Host "  ℹ No messages in queue yet" -ForegroundColor Gray
        }
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 404) {
            Write-Host "  ℹ Queue is empty" -ForegroundColor Gray
        } else {
            Write-Host "  ⚠ Could not check queue: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✓ Test file uploaded to: $testFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps to verify:" -ForegroundColor Yellow
Write-Host "1. Check func host terminal for workflow execution logs" -ForegroundColor White
Write-Host "2. Look for 'wf-flatfile-pickup' workflow run" -ForegroundColor White
Write-Host "3. Look for 'wf-flatfile-transformation' workflow run" -ForegroundColor White
Write-Host "4. Check if messages appeared in storage queues (shown above)" -ForegroundColor White
Write-Host ""
Write-Host "To view queues in Azure Storage Explorer:" -ForegroundColor Cyan
Write-Host "  - Connect to: UseDevelopmentStorage=true" -ForegroundColor Gray
Write-Host "  - Navigate to Queues → flatfile-xml-queue / flatfile-json-queue" -ForegroundColor Gray
Write-Host ""
Write-Host "To test in Azure instead:" -ForegroundColor Cyan
Write-Host "  Run: .\Test-FlatFile-Simple.ps1" -ForegroundColor Gray
Write-Host ""
