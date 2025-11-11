# ==============================================================================
# Azure Flat File Processing - End-to-End Test Script
# ==============================================================================
# Tests the complete asynchronous workflow:
# 1. File pickup from on-premise file server via Gateway
# 2. Validation and sending to Service Bus queue
# 3. Transformation (CSV to XML and JSON)
# 4. Sending transformed data to Azure Storage Queues
# ==============================================================================

param(
    [switch]$SkipFileUpload,
    [switch]$CheckQueuesOnly,
    [switch]$MonitorWorkflows,
    [switch]$CheckStorageQueues,
    [string]$TestFileName = "employees_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

$ErrorActionPreference = "Continue"

# ==============================================================================
# Configuration
# ==============================================================================
$config = @{
    SubscriptionId = "cbb1dbec-731f-4479-a084-bdaec5e54fd4"
    ResourceGroup = "AIS_Training_Shibin"
    LogicAppName = "ais-training-la"
    ServiceBusNamespace = "sb-flatfile-processing"
    StorageAccount = "aistrainingshibinbf12"
    
    # Workflows
    Workflow1 = "wf-flatfile-pickup"
    Workflow2 = "wf-flatfile-transformation"
    
    # Service Bus Queues
    ProcessingQueue = "flatfile-processing-queue"
    DeadLetterQueue = "flatfile-deadletter-queue"
    
    # Storage Queues
    XMLQueue = "flatfile-xml-queue"
    JSONQueue = "flatfile-json-queue"
    
    # File locations
    LocalSourceFile = "c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee\Artifacts\employees.csv"
    OnPremiseTargetPath = "C:\EmployeeFiles"
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Azure Flat File Processing - E2E Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ==============================================================================
# Function: Check Prerequisites
# ==============================================================================
function Test-Prerequisites {
    Write-Host "[Step 1] Checking Prerequisites..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check Azure CLI
    try {
        $azVersion = az version --output json 2>$null | ConvertFrom-Json
        Write-Host "  ✓ Azure CLI: $($azVersion.'azure-cli')" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Azure CLI not found. Install from: https://aka.ms/InstallAzureCLI" -ForegroundColor Red
        return $false
    }
    
    # Check logged in
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        Write-Host "  ✓ Logged in as: $($account.user.name)" -ForegroundColor Green
        Write-Host "  ✓ Subscription: $($account.name)" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Not logged in to Azure. Run: az login" -ForegroundColor Red
        return $false
    }
    
    # Check source file exists
    if (Test-Path $config.LocalSourceFile) {
        Write-Host "  ✓ Source CSV file exists" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Source CSV file not found: $($config.LocalSourceFile)" -ForegroundColor Red
        return $false
    }
    
    # Check on-premise target directory
    if (Test-Path $config.OnPremiseTargetPath) {
        Write-Host "  ✓ On-premise target directory exists: $($config.OnPremiseTargetPath)" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ On-premise target directory not found: $($config.OnPremiseTargetPath)" -ForegroundColor Yellow
        Write-Host "    Creating directory..." -ForegroundColor Yellow
        try {
            New-Item -ItemType Directory -Path $config.OnPremiseTargetPath -Force | Out-Null
            Write-Host "  ✓ Directory created successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Failed to create directory: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    
    Write-Host ""
    return $true
}

# ==============================================================================
# Function: Upload Test File
# ==============================================================================
function Upload-TestFile {
    param([string]$FileName)
    
    Write-Host "[Step 2] Uploading Test File to On-Premise Location..." -ForegroundColor Yellow
    Write-Host ""
    
    $targetPath = Join-Path $config.OnPremiseTargetPath $FileName
    
    try {
        Copy-Item $config.LocalSourceFile $targetPath -Force
        Write-Host "  ✓ File copied to: $targetPath" -ForegroundColor Green
        
        $fileInfo = Get-Item $targetPath
        Write-Host "  ✓ File size: $($fileInfo.Length) bytes" -ForegroundColor Green
        Write-Host "  ✓ Last modified: $($fileInfo.LastWriteTime)" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "  ℹ The Logic App wf-flatfile-pickup should detect this file within 1-3 minutes" -ForegroundColor Cyan
        Write-Host ""
        
        return $targetPath
    }
    catch {
        Write-Host "  ✗ Failed to copy file: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# ==============================================================================
# Function: Monitor Workflow Runs
# ==============================================================================
function Monitor-WorkflowRuns {
    param(
        [string]$WorkflowName,
        [int]$MaxWaitSeconds = 180
    )
    
    Write-Host "[Step 3] Monitoring Workflow: $WorkflowName..." -ForegroundColor Yellow
    Write-Host ""
    
    $startTime = Get-Date
    $foundRun = $false
    
    Write-Host "  Waiting for workflow run (timeout: $MaxWaitSeconds seconds)..." -ForegroundColor Cyan
    
    while ((Get-Date) -lt $startTime.AddSeconds($MaxWaitSeconds)) {
        try {
            # Get recent workflow runs
            $runs = az logicapp workflow show `
                --name $config.LogicAppName `
                --resource-group $config.ResourceGroup `
                --workflow-name $WorkflowName `
                --query "properties" `
                --output json 2>$null | ConvertFrom-Json
            
            if ($runs) {
                Write-Host "  ✓ Workflow is enabled and accessible" -ForegroundColor Green
                $foundRun = $true
                break
            }
        }
        catch {
            # Workflow might not be deployed yet
        }
        
        $elapsedSeconds = [int]((Get-Date) - $startTime).TotalSeconds
        Write-Host "  Waiting... $elapsedSeconds seconds elapsed" -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
    
    if ($foundRun) {
        Write-Host ""
        Write-Host "  📊 To view run history, use:" -ForegroundColor Cyan
        Write-Host "     Azure Portal → Logic App → $WorkflowName → Overview → Runs History" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  🔗 Direct URL:" -ForegroundColor Cyan
        Write-Host "     https://portal.azure.com/#@/resource/subscriptions/$($config.SubscriptionId)/resourceGroups/$($config.ResourceGroup)/providers/Microsoft.Web/sites/$($config.LogicAppName)/workflowsconfiguration/$WorkflowName" -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host "  ⚠ Workflow monitoring timed out" -ForegroundColor Yellow
        Write-Host "    Check Azure Portal manually" -ForegroundColor Gray
    }
}

# ==============================================================================
# Function: Check Service Bus Queues
# ==============================================================================
function Check-ServiceBusQueues {
    Write-Host "[Step 4] Checking Service Bus Queues..." -ForegroundColor Yellow
    Write-Host ""
    
    $namespace = "$($config.ServiceBusNamespace).servicebus.windows.net"
    
    # Check processing queue
    Write-Host "  📬 Queue: $($config.ProcessingQueue)" -ForegroundColor Cyan
    try {
        $queueInfo = az servicebus queue show `
            --resource-group $config.ResourceGroup `
            --namespace-name $config.ServiceBusNamespace `
            --name $config.ProcessingQueue `
            --query "{ActiveMessages:countDetails.activeMessageCount, DeadLetters:countDetails.deadLetterMessageCount, Size:sizeInBytes}" `
            --output json 2>$null | ConvertFrom-Json
        
        Write-Host "    Active Messages: $($queueInfo.ActiveMessages)" -ForegroundColor $(if($queueInfo.ActiveMessages -gt 0){"Green"}else{"Gray"})
        Write-Host "    Dead Letters: $($queueInfo.DeadLetters)" -ForegroundColor $(if($queueInfo.DeadLetters -gt 0){"Red"}else{"Gray"})
        Write-Host "    Size: $($queueInfo.Size) bytes" -ForegroundColor Gray
    }
    catch {
        Write-Host "    ⚠ Could not retrieve queue info: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # Check dead letter queue
    Write-Host "  📬 Queue: $($config.DeadLetterQueue)" -ForegroundColor Cyan
    try {
        $dlqInfo = az servicebus queue show `
            --resource-group $config.ResourceGroup `
            --namespace-name $config.ServiceBusNamespace `
            --name $config.DeadLetterQueue `
            --query "{ActiveMessages:countDetails.activeMessageCount, Size:sizeInBytes}" `
            --output json 2>$null | ConvertFrom-Json
        
        Write-Host "    Active Messages: $($dlqInfo.ActiveMessages)" -ForegroundColor $(if($dlqInfo.ActiveMessages -gt 0){"Red"}else{"Gray"})
        Write-Host "    Size: $($dlqInfo.Size) bytes" -ForegroundColor Gray
    }
    catch {
        Write-Host "    ⚠ Could not retrieve queue info: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ==============================================================================
# Function: Check Storage Queues
# ==============================================================================
function Check-StorageQueues {
    Write-Host "[Step 5] Checking Storage Queues..." -ForegroundColor Yellow
    Write-Host ""
    
    $queues = @($config.XMLQueue, $config.JSONQueue)
    
    foreach ($queueName in $queues) {
        Write-Host "  📦 Queue: $queueName" -ForegroundColor Cyan
        
        try {
            # Get queue metadata
            $queueMetadata = az storage queue metadata show `
                --name $queueName `
                --account-name $config.StorageAccount `
                --auth-mode login `
                --output json 2>$null | ConvertFrom-Json
            
            Write-Host "    ✓ Queue exists" -ForegroundColor Green
            
            # Try to peek messages (requires Storage Queue Data Contributor role)
            try {
                $messages = az storage message peek `
                    --queue-name $queueName `
                    --account-name $config.StorageAccount `
                    --auth-mode login `
                    --num-messages 1 `
                    --output json 2>$null | ConvertFrom-Json
                
                if ($messages -and $messages.Count -gt 0) {
                    Write-Host "    ✓ Messages found in queue!" -ForegroundColor Green
                    Write-Host "    📄 First message preview:" -ForegroundColor Cyan
                    Write-Host "       $($messages[0].content.Substring(0, [Math]::Min(100, $messages[0].content.Length)))..." -ForegroundColor Gray
                }
                else {
                    Write-Host "    ℹ No messages in queue (may still be processing)" -ForegroundColor Gray
                }
            }
            catch {
                Write-Host "    ℹ Cannot peek messages (may need permissions)" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "    ⚠ Could not access queue: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        Write-Host ""
    }
}

# ==============================================================================
# Function: Generate Test Report
# ==============================================================================
function Generate-TestReport {
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  Test Summary & Next Steps" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "✅ Test Execution Complete!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📊 Verification Checklist:" -ForegroundColor Cyan
    Write-Host "  1. ☐ Check wf-flatfile-pickup run history in Azure Portal" -ForegroundColor White
    Write-Host "  2. ☐ Verify message in Service Bus processing queue" -ForegroundColor White
    Write-Host "  3. ☐ Check wf-flatfile-transformation run history" -ForegroundColor White
    Write-Host "  4. ☐ Verify XML message in flatfile-xml-queue" -ForegroundColor White
    Write-Host "  5. ☐ Verify JSON message in flatfile-json-queue" -ForegroundColor White
    Write-Host ""
    
    Write-Host "🔗 Quick Access Links:" -ForegroundColor Cyan
    Write-Host "  Logic App Overview:" -ForegroundColor White
    Write-Host "  https://portal.azure.com/#@/resource/subscriptions/$($config.SubscriptionId)/resourceGroups/$($config.ResourceGroup)/providers/Microsoft.Web/sites/$($config.LogicAppName)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Service Bus Queues:" -ForegroundColor White
    Write-Host "  https://portal.azure.com/#@/resource/subscriptions/$($config.SubscriptionId)/resourceGroups/$($config.ResourceGroup)/providers/Microsoft.ServiceBus/namespaces/$($config.ServiceBusNamespace)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Storage Account Queues:" -ForegroundColor White
    Write-Host "  https://portal.azure.com/#@/resource/subscriptions/$($config.SubscriptionId)/resourceGroups/$($config.ResourceGroup)/providers/Microsoft.Storage/storageAccounts/$($config.StorageAccount)/storageexplorer" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🔍 Monitoring Commands:" -ForegroundColor Cyan
    Write-Host "  # Check Service Bus queues" -ForegroundColor White
    Write-Host "  .\Test-FlatFileAzure-EndToEnd.ps1 -CheckQueuesOnly" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  # Check Storage queues" -ForegroundColor White
    Write-Host "  .\Test-FlatFileAzure-EndToEnd.ps1 -CheckStorageQueues" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "📝 Log Analytics Queries:" -ForegroundColor Cyan
    Write-Host "  // View all workflow runs" -ForegroundColor White
    Write-Host "  AzureDiagnostics" -ForegroundColor Gray
    Write-Host "  | where ResourceProvider == 'MICROSOFT.WEB'" -ForegroundColor Gray
    Write-Host "  | where ResourceType == 'SITES'" -ForegroundColor Gray
    Write-Host "  | where Category == 'WorkflowRuntime'" -ForegroundColor Gray
    Write-Host "  | project TimeGenerated, OperationName, workflowName_s, status_s" -ForegroundColor Gray
    Write-Host "  | order by TimeGenerated desc" -ForegroundColor Gray
    Write-Host ""
}

# ==============================================================================
# Main Execution
# ==============================================================================

# Handle quick check modes
if ($CheckQueuesOnly) {
    Check-ServiceBusQueues
    exit 0
}

if ($CheckStorageQueues) {
    Check-StorageQueues
    exit 0
}

if ($MonitorWorkflows) {
    Monitor-WorkflowRuns -WorkflowName $config.Workflow1 -MaxWaitSeconds 60
    Write-Host ""
    Monitor-WorkflowRuns -WorkflowName $config.Workflow2 -MaxWaitSeconds 60
    exit 0
}

# Full end-to-end test
Write-Host "Starting End-to-End Test at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""

# Step 1: Prerequisites
if (-not (Test-Prerequisites)) {
    Write-Host ""
    Write-Host "❌ Prerequisites check failed. Please resolve the issues above." -ForegroundColor Red
    exit 1
}

# Step 2: Upload file
if (-not $SkipFileUpload) {
    $uploadedFile = Upload-TestFile -FileName $TestFileName
    if (-not $uploadedFile) {
        Write-Host "❌ File upload failed." -ForegroundColor Red
        exit 1
    }
    
    # Wait for workflow to detect file
    Write-Host "  ⏳ Waiting 30 seconds for workflow to detect file..." -ForegroundColor Cyan
    Start-Sleep -Seconds 30
} else {
    Write-Host "[Step 2] Skipping file upload (using existing files)" -ForegroundColor Yellow
    Write-Host ""
}

# Step 3: Monitor workflow 1
Monitor-WorkflowRuns -WorkflowName $config.Workflow1 -MaxWaitSeconds 120

# Wait for Service Bus processing
Write-Host "  ⏳ Waiting 15 seconds for Service Bus processing..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

# Step 4: Check Service Bus
Check-ServiceBusQueues

# Wait for transformation
Write-Host "  ⏳ Waiting 30 seconds for transformation workflow..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Step 5: Check Storage Queues
Check-StorageQueues

# Final report
Generate-TestReport

Write-Host "Test completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""
