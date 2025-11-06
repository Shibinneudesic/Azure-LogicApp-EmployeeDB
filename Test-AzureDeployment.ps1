# Test Azure Logic App Deployment

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Testing Azure Logic App Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$LogicAppName = "upsert-employee"
$ResourceGroup = "AIS_Training_Shibin"

# Test 1: Check if app is running
Write-Host "Test 1: Checking if Logic App is accessible..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://$LogicAppName.azurewebsites.net" -UseBasicParsing -TimeoutSec 30
    Write-Host "✓ Logic App is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
}
catch {
    Write-Host "✗ Logic App is not accessible" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 2: Load test data
Write-Host "Test 2: Loading test data..." -ForegroundColor Yellow
if (Test-Path "test-request.json") {
    $testData = Get-Content "test-request.json" -Raw
    Write-Host "✓ Test data loaded" -ForegroundColor Green
    Write-Host "  Employees to test: $((($testData | ConvertFrom-Json).employees.employee).Count)" -ForegroundColor Cyan
}
else {
    Write-Host "✗ test-request.json not found!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 3: Instructions to get callback URL
Write-Host "Test 3: Getting workflow callback URL..." -ForegroundColor Yellow
Write-Host "  To get the callback URL, follow these steps:" -ForegroundColor Cyan
Write-Host "  1. Go to Azure Portal" -ForegroundColor White
Write-Host "  2. Navigate to Logic App: $LogicAppName" -ForegroundColor White
Write-Host "  3. Click on 'Workflows' -> 'UpsertEmployee'" -ForegroundColor White
Write-Host "  4. Click on 'Overview' -> 'Get Callback URL'" -ForegroundColor White
Write-Host ""
Write-Host "  Or run this command to test with a sample URL pattern:" -ForegroundColor White
Write-Host '  $url = "https://upsert-employee.azurewebsites.net:443/api/UpsertEmployee/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=YOUR_SIG_HERE"' -ForegroundColor Gray
Write-Host '  Invoke-RestMethod -Uri $url -Method Post -Body (Get-Content test-request.json -Raw) -ContentType "application/json"' -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Logic App URL: https://$LogicAppName.azurewebsites.net" -ForegroundColor White
Write-Host "Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host ""
Write-Host "✓ Deployment appears successful!" -ForegroundColor Green
Write-Host "  Next: Get the callback URL from Azure Portal to test the workflow" -ForegroundColor Yellow
Write-Host ""
