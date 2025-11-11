# Test HTTP-Triggered Flat File Pickup Workflow Locally
# This script tests the HTTP version of the workflow on your local machine

param(
    [string]$FileName = "employees.csv",
    [string]$SourceFile = ".\Artifacts\employees.csv",
    [string]$LocalWorkflowUrl = "http://localhost:7071/api/wf-flatfile-pickup-http/triggers/manual/invoke?api-version=2022-05-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0"
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Test HTTP Flat File Pickup - LOCAL" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check if source file exists
if (-not (Test-Path $SourceFile)) {
    Write-Host "ERROR: Source file not found: $SourceFile" -ForegroundColor Red
    exit 1
}

# Read file content
Write-Host "Reading file: $SourceFile" -ForegroundColor Yellow
$fileContent = Get-Content $SourceFile -Raw
$fileSize = (Get-Item $SourceFile).Length

Write-Host "  File: $FileName" -ForegroundColor Gray
Write-Host "  Size: $fileSize bytes" -ForegroundColor Gray
Write-Host ""

# Prepare request body
$requestBody = @{
    fileName = $FileName
    fileContent = $fileContent
} | ConvertTo-Json

Write-Host "Sending request to local workflow..." -ForegroundColor Yellow
Write-Host "  URL: $LocalWorkflowUrl" -ForegroundColor Gray
Write-Host ""

try {
    # Call the workflow
    $response = Invoke-RestMethod -Uri $LocalWorkflowUrl -Method Post -Body $requestBody -ContentType "application/json"
    
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Cyan
    Write-Host "  Status: $($response.status)" -ForegroundColor Green
    Write-Host "  Message: $($response.message)" -ForegroundColor Gray
    Write-Host "  Correlation ID: $($response.correlationId)" -ForegroundColor Gray
    Write-Host "  File Name: $($response.fileName)" -ForegroundColor Gray
    Write-Host "  File Size: $($response.fileSize) bytes" -ForegroundColor Gray
    Write-Host "  Timestamp: $($response.timestamp)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Check Service Bus queue for the message" -ForegroundColor White
    Write-Host "2. The transformation workflow should pick it up automatically" -ForegroundColor White
    Write-Host "3. Verify XML and JSON outputs in storage queues" -ForegroundColor White
    Write-Host ""
    
    exit 0
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    
    if ($statusCode) {
        Write-Host "FAILED!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
        
        try {
            $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "Error Details:" -ForegroundColor Yellow
            Write-Host "  Status: $($errorBody.status)" -ForegroundColor Red
            Write-Host "  Error: $($errorBody.error)" -ForegroundColor Red
            Write-Host "  Message: $($errorBody.message)" -ForegroundColor Red
            
            if ($errorBody.correlationId) {
                Write-Host "  Correlation ID: $($errorBody.correlationId)" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "ERROR: Could not connect to local workflow" -ForegroundColor Red
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "1. Local Logic App (func host) is not running" -ForegroundColor White
        Write-Host "2. Workflow name is incorrect" -ForegroundColor White
        Write-Host "3. Port 7071 is not accessible" -ForegroundColor White
        Write-Host ""
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    exit 1
}
