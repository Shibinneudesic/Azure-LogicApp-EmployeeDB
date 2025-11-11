# Quick HTTP Workflow Test - Tests the local HTTP-triggered workflow immediately

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Testing HTTP Workflow Locally - FAST" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check if func host is running
$funcProcess = Get-Process -Name "func" -ErrorAction SilentlyContinue
if (-not $funcProcess) {
    Write-Host "Starting func host in background..." -ForegroundColor Yellow
    Start-Process -FilePath "func" -ArgumentList "host start" -WindowStyle Hidden
    Start-Sleep -Seconds 15
    Write-Host "Func host started" -ForegroundColor Green
    Write-Host ""
}

# Test the HTTP workflow
Write-Host "Testing HTTP workflow at http://localhost:7071..." -ForegroundColor Cyan
Write-Host ""

# Read sample CSV
$csvContent = Get-Content ".\Artifacts\employees.csv" -Raw

# Prepare request body
$body = @{
    fileName = "test_employees.csv"
    fileContent = $csvContent
} | ConvertTo-Json

Write-Host "Calling workflow..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "http://localhost:7071/api/wf-flatfile-pickup-http/triggers/manual/invoke" `
        -Method POST `
        -Body $body `
        -ContentType "application/json" `
        -TimeoutSec 30
    
    Write-Host "✓ Workflow executed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response:" -ForegroundColor Gray
    $response | ConvertTo-Json -Depth 5
    Write-Host ""
}
catch {
    if ($_.Exception.Response.StatusCode.Value__ -eq 404) {
        Write-Host "✗ Workflow not found at http://localhost:7071" -ForegroundColor Red
        Write-Host ""
        Write-Host "The HTTP workflow may not be running. Let me check available endpoints..." -ForegroundColor Yellow
        Write-Host ""
        
        try {
            $adminResponse = Invoke-RestMethod -Uri "http://localhost:7071/admin/host/status" -Method GET -ErrorAction SilentlyContinue
            Write-Host "Host is running but workflow not loaded" -ForegroundColor Yellow
        }
        catch {
            Write-Host "Func host is not running on port 7071" -ForegroundColor Red
            Write-Host "Run: func host start" -ForegroundColor White
        }
    }
    else {
        Write-Host "✗ Error: $_" -ForegroundColor Red
    }
    Write-Host ""
}

# Check Service Bus queue
Write-Host "Checking Service Bus queue..." -ForegroundColor Cyan
try {
    $result = az servicebus queue show `
        --resource-group "AIS_Training_Shibin" `
        --namespace-name "sb-flatfile-processing" `
        --name "flatfile-processing-queue" `
        --query "countDetails.activeMessageCount" `
        --output tsv 2>$null
    
    Write-Host "  Active messages: $result" -ForegroundColor $(if([int]$result -gt 0){"Green"}else{"Gray"})
}
catch {
    Write-Host "  Could not check queue" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
