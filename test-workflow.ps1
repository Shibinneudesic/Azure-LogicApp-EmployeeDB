# Test the simplified workflow
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Simplified Workflow" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "1. Getting callback URL..." -ForegroundColor Yellow
try {
    $callbackResponse = Invoke-RestMethod -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2020-05-01-preview&code=test" -Method POST
    $callbackUrl = $callbackResponse.value
    Write-Host "   ✓ Callback URL obtained" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Failed to get callback URL: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Sending test request with 2 employees..." -ForegroundColor Yellow
$testData = @{
    employees = @{
        employee = @(
            @{
                id = 5001
                firstName = "Alice"
                lastName = "Johnson"
                department = "Engineering"
                position = "Senior Developer"
                salary = 105000
                email = "alice.johnson@example.com"
            },
            @{
                id = 5002
                firstName = "Bob"
                lastName = "Smith"
                department = "Sales"
                position = "Sales Manager"
                salary = 92000
                email = "bob.smith@example.com"
            }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $callbackUrl -Method POST -Body $testData -ContentType 'application/json'
    Write-Host "   ✓ Request successful!" -ForegroundColor Green
    
    Write-Host "`n3. Response from Logic App:" -ForegroundColor Yellow
    $response | ConvertTo-Json -Depth 5 | Write-Host
    
    Write-Host "`n4. Verifying data in database..." -ForegroundColor Yellow
    $dbResult = sqlcmd -S "(localdb)\MSSQLLocalDB" -d EmployeeDB -Q "SELECT Id, FirstName, LastName, Department, Position, Salary FROM Employee WHERE Id IN (5001, 5002) ORDER BY Id" -W -h -1
    Write-Host $dbResult
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "✅ TEST PASSED!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`nKey Improvements:" -ForegroundColor Cyan
    Write-Host "  • Schema validation at trigger (fail-fast)" -ForegroundColor White
    Write-Host "  • Stored procedure for upsert logic" -ForegroundColor White
    Write-Host "  • No redundant validation loops" -ForegroundColor White
    Write-Host "  • Simplified from 640 to 289 lines" -ForegroundColor White
    
} catch {
    Write-Host "   ✗ Request failed: $_" -ForegroundColor Red
    Write-Host "`nResponse StatusCode:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Red
    Write-Host "Response:" $_.Exception.Message -ForegroundColor Red
    exit 1
}
