# Simple Flat File Processing Test Script
# Tests the Azure deployed asynchronous workflow

param(
    [switch]$CheckQueuesOnly
)

$ErrorActionPreference = "Continue"

# Configuration
$resourceGroup = "AIS_Training_Shibin"
$serviceBusNamespace = "sb-flatfile-processing"
$storageAccount = "aistrainingshibinbf12"
$sourceFile = "c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee\Artifacts\employees.csv"
$targetPath = "C:\EmployeeFiles"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Flat File Processing Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Function: Check Service Bus Queues
function Check-ServiceBusQueues {
    Write-Host "Checking Service Bus Queues..." -ForegroundColor Yellow
    Write-Host ""
    
    # Processing Queue
    Write-Host "  Queue: flatfile-processing-queue" -ForegroundColor Cyan
    try {
        $result = az servicebus queue show `
            --resource-group $resourceGroup `
            --namespace-name $serviceBusNamespace `
            --name flatfile-processing-queue `
            --query "countDetails" `
            --output json 2>$null
        
        if ($result) {
            $counts = $result | ConvertFrom-Json
            Write-Host "    Active Messages: $($counts.activeMessageCount)" -ForegroundColor Green
            Write-Host "    Dead Letters: $($counts.deadLetterMessageCount)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "    Could not retrieve queue info" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Dead Letter Queue
    Write-Host "  Queue: flatfile-deadletter-queue" -ForegroundColor Cyan
    try {
        $result = az servicebus queue show `
            --resource-group $resourceGroup `
            --namespace-name $serviceBusNamespace `
            --name flatfile-deadletter-queue `
            --query "countDetails" `
            --output json 2>$null
        
        if ($result) {
            $counts = $result | ConvertFrom-Json
            Write-Host "    Active Messages: $($counts.activeMessageCount)" -ForegroundColor $(if($counts.activeMessageCount -gt 0){"Red"}else{"Gray"})
        }
    }
    catch {
        Write-Host "    Could not retrieve queue info" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Function: Check Storage Queues
function Check-StorageQueues {
    Write-Host "Checking Storage Queues..." -ForegroundColor Yellow
    Write-Host ""
    
    $queues = @("flatfile-xml-queue", "flatfile-json-queue")
    
    foreach ($queueName in $queues) {
        Write-Host "  Queue: $queueName" -ForegroundColor Cyan
        
        try {
            # Check if queue exists
            $exists = az storage queue exists `
                --name $queueName `
                --account-name $storageAccount `
                --auth-mode login `
                --output json 2>$null
            
            if ($exists -eq "true" -or $exists -like "*true*") {
                Write-Host "    Queue exists" -ForegroundColor Green
                
                # Try to peek messages
                try {
                    $messages = az storage message peek `
                        --queue-name $queueName `
                        --account-name $storageAccount `
                        --auth-mode login `
                        --num-messages 1 `
                        --output json 2>$null
                    
                    if ($messages -and $messages -ne "[]") {
                        Write-Host "    Messages found!" -ForegroundColor Green
                    }
                    else {
                        Write-Host "    No messages (may still be processing)" -ForegroundColor Gray
                    }
                }
                catch {
                    Write-Host "    Cannot peek messages" -ForegroundColor Gray
                }
            }
        }
        catch {
            Write-Host "    Could not access queue" -ForegroundColor Yellow
        }
        
        Write-Host ""
    }
}

# Function: Upload Test File
function Upload-TestFile {
    Write-Host "Uploading Test File..." -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Test-Path $sourceFile)) {
        Write-Host "  Source file not found: $sourceFile" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path $targetPath)) {
        Write-Host "  Creating target directory..." -ForegroundColor Yellow
        try {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            Write-Host "  Directory created: $targetPath" -ForegroundColor Green
        }
        catch {
            Write-Host "  Failed to create directory: $_" -ForegroundColor Red
            return $false
        }
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $testFile = Join-Path $targetPath "employees_test_$timestamp.csv"
    
    try {
        Copy-Item $sourceFile $testFile -Force
        $fileInfo = Get-Item $testFile
        
        Write-Host "  File copied successfully" -ForegroundColor Green
        Write-Host "  Location: $testFile" -ForegroundColor Gray
        Write-Host "  Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  The Logic App should pick up this file within 1-3 minutes" -ForegroundColor Cyan
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host "  Failed to copy file: $_" -ForegroundColor Red
        return $false
    }
}

# Main Execution
if ($CheckQueuesOnly) {
    Check-ServiceBusQueues
    Check-StorageQueues
    exit 0
}

# Full test
Write-Host "Step 1: Uploading test file to on-premise location" -ForegroundColor Cyan
Write-Host ""
$uploadSuccess = Upload-TestFile

if (-not $uploadSuccess) {
    Write-Host "Test failed at file upload step" -ForegroundColor Red
    exit 1
}

Write-Host "Step 2: Waiting 30 seconds for workflow to process..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "Step 3: Checking Service Bus queues" -ForegroundColor Cyan
Write-Host ""
Check-ServiceBusQueues

Write-Host "Step 4: Waiting 30 seconds for transformation..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "Step 5: Checking Storage queues" -ForegroundColor Cyan
Write-Host ""
Check-StorageQueues

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Test Complete" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Check Azure Portal for workflow run history" -ForegroundColor White
Write-Host "2. Verify messages in Service Bus and Storage queues" -ForegroundColor White
Write-Host "3. Review Application Insights for detailed logs" -ForegroundColor White
Write-Host ""
Write-Host "Azure Portal Links:" -ForegroundColor Yellow
Write-Host "Logic App: https://portal.azure.com/#@/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/ais-training-la" -ForegroundColor Gray
Write-Host "Service Bus: https://portal.azure.com/#@/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.ServiceBus/namespaces/sb-flatfile-processing" -ForegroundColor Gray
Write-Host ""
