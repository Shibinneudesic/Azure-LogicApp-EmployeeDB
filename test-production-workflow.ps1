# Production Workflow Test Script
# Tests all error handling and logging scenarios

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Production Workflow Test Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Local endpoint
$endpoint = "http://localhost:7071/api/UpsertEmployeeV2/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

# Test 1: Happy Path - Full Success (200)
Write-Host "`n[TEST 1] Happy Path - Full Success" -ForegroundColor Yellow
Write-Host "Expected: HTTP 200, All employees processed" -ForegroundColor Gray

$payload1 = @{
    employees = @{
        employee = @(
            @{
                id = 6001
                firstName = "Alice"
                lastName = "Johnson"
                department = "Engineering"
                position = "Senior Developer"
                salary = 95000
                email = "alice.johnson@company.com"
            },
            @{
                id = 6002
                firstName = "Bob"
                lastName = "Smith"
                department = "Engineering"
                position = "Developer"
                salary = 75000
                email = "bob.smith@company.com"
            }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    $response1 = Invoke-WebRequest -Uri $endpoint -Method Post -Body $payload1 -ContentType "application/json" -UseBasicParsing
    Write-Host "✓ Status: $($response1.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Green
    $response1.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
}

# Test 2: Validation Error (400)
Write-Host "`n[TEST 2] Validation Error - Missing Required Fields" -ForegroundColor Yellow
Write-Host "Expected: HTTP 400, Validation error" -ForegroundColor Gray

$payload2 = @{
    employees = @{
        employee = @(
            @{
                id = $null
                firstName = "Invalid"
                lastName = "User"
            }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    $response2 = Invoke-WebRequest -Uri $endpoint -Method Post -Body $payload2 -ContentType "application/json" -UseBasicParsing
    Write-Host "✓ Status: $($response2.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "✓ Expected error: $($_.Exception.Response.StatusCode)" -ForegroundColor Green
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response:" -ForegroundColor Green
        $responseBody | ConvertFrom-Json | ConvertTo-Json -Depth 10
    }
}

# Test 3: Schema Error (400)
Write-Host "`n[TEST 3] Schema Error - Invalid Request Structure" -ForegroundColor Yellow
Write-Host "Expected: HTTP 400, Schema validation error" -ForegroundColor Gray

$payload3 = @{
    employees = @{}
} | ConvertTo-Json -Depth 10

try {
    $response3 = Invoke-WebRequest -Uri $endpoint -Method Post -Body $payload3 -ContentType "application/json" -UseBasicParsing
} catch {
    Write-Host "✓ Expected error: $($_.Exception.Response.StatusCode)" -ForegroundColor Green
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response:" -ForegroundColor Green
        $responseBody | ConvertFrom-Json | ConvertTo-Json -Depth 10
    }
}

# Test 4: Large Batch
Write-Host "`n[TEST 4] Large Batch Test - 10 Employees" -ForegroundColor Yellow
Write-Host "Expected: HTTP 200, All 10 employees processed" -ForegroundColor Gray

$employees = @()
for ($i = 7001; $i -le 7010; $i++) {
    $employees += @{
        id = $i
        firstName = "Employee"
        lastName = "Number$i"
        department = "Testing"
        position = "Test Engineer"
        salary = 70000 + ($i % 10) * 1000
        email = "employee$i@company.com"
    }
}

$payload4 = @{
    employees = @{
        employee = $employees
    }
} | ConvertTo-Json -Depth 10

try {
    $response4 = Invoke-WebRequest -Uri $endpoint -Method Post -Body $payload4 -ContentType "application/json" -UseBasicParsing
    Write-Host "✓ Status: $($response4.StatusCode)" -ForegroundColor Green
    $response4.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Idempotency Test
Write-Host "`n[TEST 5] Idempotency Test - Retry Employee 6001" -ForegroundColor Yellow
Write-Host "Expected: HTTP 200, Same employee updated" -ForegroundColor Gray

$payload5 = @{
    employees = @{
        employee = @(
            @{
                id = 6001
                firstName = "Alice"
                lastName = "Johnson-Updated"
                department = "Engineering"
                position = "Lead Developer"
                salary = 105000
                email = "alice.johnson@company.com"
            }
        )
    }
} | ConvertTo-Json -Depth 10

try {
    $response5 = Invoke-WebRequest -Uri $endpoint -Method Post -Body $payload5 -ContentType "application/json" -UseBasicParsing
    Write-Host "✓ Status: $($response5.StatusCode)" -ForegroundColor Green
    $response5.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Suite Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Check Log Analytics for logs (2-5 min delay)" -ForegroundColor White
Write-Host "2. Review PRODUCTION-READY-FEATURES.md" -ForegroundColor White
Write-Host "3. Verify SQL: " -ForegroundColor White
Write-Host "   sqlcmd -S '(localdb)\MSSQLLocalDB' -d EmployeeDB -Q 'SELECT * FROM Employees WHERE ID >= 6001'" -ForegroundColor Gray
