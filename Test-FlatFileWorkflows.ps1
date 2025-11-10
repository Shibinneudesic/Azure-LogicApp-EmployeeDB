# Test Script for Flat File Processing Workflows
# Created: November 9, 2025

param(
    [switch]$SetupOnly,
    [switch]$TestWorkflow1Only,
    [switch]$TestWorkflow2Only,
    [switch]$Cleanup
)

$ErrorActionPreference = "Stop"
$testDir = "c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee"
$testFilesDir = "$testDir\TestFiles\EmployeeFiles"
$sourceCSV = "$testDir\Artifacts\employees.csv"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flat File Workflow Testing" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if Azurite is running
function Test-AzuriteRunning {
    $azuriteProcess = Get-Process -Name "Azurite" -ErrorAction SilentlyContinue
    if ($azuriteProcess) {
        Write-Host "✓ Azurite is running (PID: $($azuriteProcess.Id))" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Azurite is NOT running" -ForegroundColor Red
        Write-Host "  Start it with: azurite --silent --location . --debug azurite-debug.log" -ForegroundColor Yellow
        return $false
    }
}

# Function to check if Azure Functions host is running
function Test-FuncHostRunning {
    $funcProcess = Get-Process -Name "func" -ErrorAction SilentlyContinue
    if ($funcProcess) {
        Write-Host "✓ Azure Functions host is running (PID: $($funcProcess.Id))" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Azure Functions host is NOT running" -ForegroundColor Red
        Write-Host "  Start it with: func start" -ForegroundColor Yellow
        return $false
    }
}

# Setup test environment
function Setup-TestEnvironment {
    Write-Host "`n[1] Setting up test environment..." -ForegroundColor Cyan
    
    # Create test directories
    if (-not (Test-Path $testFilesDir)) {
        New-Item -ItemType Directory -Path $testFilesDir -Force | Out-Null
        Write-Host "  Created test directory: $testFilesDir" -ForegroundColor Green
    } else {
        Write-Host "  Test directory exists: $testFilesDir" -ForegroundColor Green
    }
    
    # Create storage queues using Azure Storage Emulator
    Write-Host "`n  Creating local storage queues..." -ForegroundColor Yellow
    
    try {
        # Install Azure.Storage.Queues module if not present
        if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
            Write-Host "    Installing Az.Storage module..." -ForegroundColor Yellow
            Install-Module -Name Az.Storage -Force -AllowClobber -Scope CurrentUser
        }
        
        # Create queues using REST API to Azurite
        $storageAccount = "devstoreaccount1"
        $storageKey = "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
        $queueEndpoint = "http://127.0.0.1:10001/$storageAccount"
        
        $queues = @(
            "flatfile-xml-queue",
            "flatfile-json-queue"
        )
        
        foreach ($queueName in $queues) {
            $uri = "$queueEndpoint/$queueName"
            try {
                $response = Invoke-WebRequest -Uri $uri -Method PUT -Headers @{
                    "x-ms-version" = "2021-08-06"
                } -ErrorAction SilentlyContinue
                Write-Host "    ✓ Created queue: $queueName" -ForegroundColor Green
            } catch {
                if ($_.Exception.Response.StatusCode.value__ -eq 409) {
                    Write-Host "    ✓ Queue already exists: $queueName" -ForegroundColor Green
                } else {
                    Write-Host "    ⚠ Could not create queue: $queueName - $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }
    } catch {
        Write-Host "    ⚠ Storage queue setup skipped: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "    Note: Queues will be created automatically when messages are sent" -ForegroundColor Gray
    }
    
    Write-Host "`n✓ Test environment setup complete!" -ForegroundColor Green
}
    
    Write-Host "`n✓ Test environment setup complete!" -ForegroundColor Green
}

# Test Workflow 1 - File Pickup
function Test-Workflow1 {
    Write-Host "`n[2] Testing Workflow 1 (File Pickup)..." -ForegroundColor Cyan
    
    if (-not (Test-Path $sourceCSV)) {
        Write-Host "  ✗ Source CSV not found: $sourceCSV" -ForegroundColor Red
        return $false
    }
    
    # Copy test file with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $testFileName = "employees_test_$timestamp.csv"
    $testFilePath = Join-Path $testFilesDir $testFileName
    
    Write-Host "  Copying test file to: $testFileName" -ForegroundColor Yellow
    Copy-Item $sourceCSV $testFilePath -Force
    
    Write-Host "  ✓ Test file created: $testFilePath" -ForegroundColor Green
    Write-Host "`n  Waiting for workflow to pick up file (check Logic App designer)..." -ForegroundColor Yellow
    Write-Host "  File location: $testFilePath" -ForegroundColor Gray
    Write-Host "  Open Azure Portal → Logic App → wf-flatfile-pickup → Overview" -ForegroundColor Gray
    
    return $true
}

# Test Workflow 2 - Transformation
function Test-Workflow2 {
    Write-Host "`n[3] Testing Workflow 2 (Transformation)..." -ForegroundColor Cyan
    Write-Host "  This workflow is triggered by Service Bus queue messages" -ForegroundColor Yellow
    Write-Host "  For local testing, you need to configure Service Bus connection" -ForegroundColor Yellow
    Write-Host "`n  Options:" -ForegroundColor Cyan
    Write-Host "  1. Use Azure Service Bus (configure SERVICE_BUS_CONNECTION_STRING in local.settings.json)" -ForegroundColor Gray
    Write-Host "  2. Test transformation actions manually in the designer" -ForegroundColor Gray
    Write-Host "  3. Deploy to Azure and test end-to-end" -ForegroundColor Gray
}

# Check queue messages
function Check-QueueMessages {
    Write-Host "`n[4] Checking queue messages..." -ForegroundColor Cyan
    
    $queueEndpoint = "http://127.0.0.1:10001/devstoreaccount1"
    $queues = @("flatfile-xml-queue", "flatfile-json-queue")
    
    foreach ($queueName in $queues) {
        Write-Host "`n  Queue: $queueName" -ForegroundColor Yellow
        $uri = "$queueEndpoint/$queueName/messages?peekonly=true&numofmessages=1"
        
        try {
            $response = Invoke-WebRequest -Uri $uri -Method GET -Headers @{
                "x-ms-version" = "2021-08-06"
            } -ErrorAction Stop
            
            if ($response.StatusCode -eq 200 -and $response.Content) {
                Write-Host "    ✓ Messages found in queue" -ForegroundColor Green
                Write-Host "    Response: $($response.Content)" -ForegroundColor Gray
            } else {
                Write-Host "    ℹ No messages in queue" -ForegroundColor Gray
            }
        } catch {
            Write-Host "    ⚠ Could not check queue: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# Cleanup
function Cleanup-TestEnvironment {
    Write-Host "`n[5] Cleaning up test environment..." -ForegroundColor Cyan
    
    if (Test-Path $testFilesDir) {
        Remove-Item "$testFilesDir\*.csv" -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed test CSV files" -ForegroundColor Green
    }
    
    Write-Host "  Note: Azurite queues are not cleared. Clear them manually if needed." -ForegroundColor Gray
}

# Main execution
Write-Host "Pre-flight checks:" -ForegroundColor Cyan
$azuriteOk = Test-AzuriteRunning
$funcOk = Test-FuncHostRunning

if (-not $azuriteOk -or -not $funcOk) {
    Write-Host "`n✗ Prerequisites not met. Please start required services." -ForegroundColor Red
    exit 1
}

if ($Cleanup) {
    Cleanup-TestEnvironment
    exit 0
}

if ($SetupOnly) {
    Setup-TestEnvironment
    exit 0
}

if ($TestWorkflow1Only) {
    Setup-TestEnvironment
    Test-Workflow1
    exit 0
}

if ($TestWorkflow2Only) {
    Test-Workflow2
    exit 0
}

# Run all tests
Setup-TestEnvironment
Test-Workflow1
Start-Sleep -Seconds 3
Check-QueueMessages
Test-Workflow2

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Instructions:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Check workflow runs in VS Code Logic App designer" -ForegroundColor White
Write-Host "2. For local testing, workflows need to be enabled in designer" -ForegroundColor White
Write-Host "3. For Service Bus integration, configure connection in local.settings.json" -ForegroundColor White
Write-Host "4. For full end-to-end testing, deploy to Azure" -ForegroundColor White
Write-Host "`n✓ Test script completed!" -ForegroundColor Green
