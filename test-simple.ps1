# Simple test script for UpsertEmployee Logic App
Write-Host "===  Testing UpsertEmployee Logic App ===" -ForegroundColor Cyan

# Get callback URL
Write-Host "`n1. Getting callback URL..." -ForegroundColor Yellow
$callbackInfo = Invoke-RestMethod -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2022-05-01" -Method POST -ContentType "application/json"
$callbackUrl = $callbackInfo.value
Write-Host "   Callback URL obtained: $callbackUrl" -ForegroundColor Green

# Read test data
Write-Host "`n2. Reading test data..." -ForegroundColor Yellow
$testData = Get-Content "test-request.json" -Raw | ConvertFrom-Json
Write-Host "   Test data loaded: $($testData.employees.Count) employees" -ForegroundColor Green

# Send POST request
Write-Host "`n3. Sending POST request..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $callbackUrl -Method POST -Body (Get-Content "test-request.json" -Raw) -ContentType "application/json" -TimeoutSec 120
    
    Write-Host "`n=== SUCCESS! ===" -ForegroundColor Green
    Write-Host "`nResponse:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 10
    
    # Query database to verify
    Write-Host "`n4. Verifying database records..." -ForegroundColor Yellow
    $employeeIds = ($testData.employees | ForEach-Object { $_.id }) -join ','
    $query = "SELECT * FROM Employee WHERE EmployeeID IN ($employeeIds)"
    $dbResults = sqlcmd -S "(localdb)\MSSQLLocalDB" -d EmployeeDB -Q $query -W -h-1
    
    Write-Host "`nDatabase Records:" -ForegroundColor Cyan
    Write-Host $dbResults
    
} catch {
    Write-Host "`n=== ERROR ===" -ForegroundColor Red
    Write-Host $_.Exception.Message
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $responseBody = $reader.ReadToEnd()
        Write-Host "`nResponse Body:" -ForegroundColor Yellow
        Write-Host $responseBody
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
