# Test Script for Production-Level Workflow
# Run this script to test the simplified workflow

$baseUrl = "http://localhost:7071"
$endpoint = "$baseUrl/api/UpsertEmployee/triggers/When_a_HTTP_request_is_received/invoke"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Testing Simplified Workflow" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Valid Request - Multiple Employees
Write-Host "Test 1: Valid Request with Multiple Employees" -ForegroundColor Yellow
$validPayload = @{
    employees = @{
        employee = @(
            @{
                id = 2001
                firstName = "Alice"
                lastName = "Johnson"
                department = "Engineering"
                position = "Senior Developer"
                salary = 95000.00
                email = "alice.johnson@company.com"
            },
            @{
                id = 2002
                firstName = "Bob"
                lastName = "Williams"
                department = "Marketing"
                position = "Marketing Manager"
                salary = 85000.00
                email = "bob.williams@company.com"
            },
            @{
                id = 2003
                firstName = "Carol"
                lastName = "Davis"
                department = "Sales"
                position = "Sales Representative"
                salary = 65000.00
                email = "carol.davis@company.com"
            }
        )
    }
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint `
        -ContentType "application/json" `
        -Body ($validPayload | ConvertTo-Json -Depth 10)
    
    Write-Host "✓ Success!" -ForegroundColor Green
    Write-Host "Status: $($response.status)" -ForegroundColor Green
    Write-Host "Message: $($response.message)" -ForegroundColor Green
    Write-Host "Total Processed: $($response.details.totalProcessed)" -ForegroundColor Green
    Write-Host "Total Inserted: $($response.details.totalInserted)" -ForegroundColor Green
    Write-Host "Total Updated: $($response.details.totalUpdated)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Gray
    $response | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Gray
}
catch {
    Write-Host "✗ Failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 2: Schema Validation Error - Empty Array
Write-Host "Test 2: Schema Validation Error - Empty Employee Array" -ForegroundColor Yellow
$emptyArrayPayload = @{
    employees = @{
        employee = @()
    }
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint `
        -ContentType "application/json" `
        -Body ($emptyArrayPayload | ConvertTo-Json -Depth 10)
    
    Write-Host "✗ Should have failed but succeeded!" -ForegroundColor Red
}
catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "✓ Expected error caught!" -ForegroundColor Green
    Write-Host "Error Code: $($errorResponse.errorCode)" -ForegroundColor Yellow
    Write-Host "Message: $($errorResponse.message)" -ForegroundColor Yellow
    Write-Host "Response:" -ForegroundColor Gray
    $errorResponse | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Gray
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 3: Schema Validation Error - Missing Structure
Write-Host "Test 3: Schema Validation Error - Missing employees.employee" -ForegroundColor Yellow
$missingStructurePayload = @{
    employees = @{}
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint `
        -ContentType "application/json" `
        -Body ($missingStructurePayload | ConvertTo-Json -Depth 10)
    
    Write-Host "✗ Should have failed but succeeded!" -ForegroundColor Red
}
catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "✓ Expected error caught!" -ForegroundColor Green
    Write-Host "Error Code: $($errorResponse.errorCode)" -ForegroundColor Yellow
    Write-Host "Message: $($errorResponse.message)" -ForegroundColor Yellow
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 4: Field Validation Error - Invalid Employee Data
Write-Host "Test 4: Field Validation Error - Invalid Employee Fields" -ForegroundColor Yellow
$invalidFieldsPayload = @{
    employees = @{
        employee = @(
            @{
                id = 0
                firstName = ""
                lastName = "Smith"
            },
            @{
                id = -5
                firstName = "Valid"
                lastName = ""
            },
            @{
                id = 3001
                firstName = "   "
                lastName = "   "
            }
        )
    }
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint `
        -ContentType "application/json" `
        -Body ($invalidFieldsPayload | ConvertTo-Json -Depth 10)
    
    Write-Host "✗ Should have failed but succeeded!" -ForegroundColor Red
}
catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "✓ Expected error caught!" -ForegroundColor Green
    Write-Host "Error Code: $($errorResponse.errorCode)" -ForegroundColor Yellow
    Write-Host "Message: $($errorResponse.message)" -ForegroundColor Yellow
    Write-Host "Error Count: $($errorResponse.details.errorCount)" -ForegroundColor Yellow
    Write-Host "Response:" -ForegroundColor Gray
    $errorResponse | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor Gray
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 5: Partial Validation Error - Some Valid, Some Invalid
Write-Host "Test 5: Partial Validation Error - Mixed Valid/Invalid Records" -ForegroundColor Yellow
$mixedPayload = @{
    employees = @{
        employee = @(
            @{
                id = 4001
                firstName = "Valid"
                lastName = "Employee"
                department = "IT"
            },
            @{
                id = 0
                firstName = ""
                lastName = "Invalid"
            },
            @{
                id = 4002
                firstName = "Another"
                lastName = "Valid"
            }
        )
    }
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint `
        -ContentType "application/json" `
        -Body ($mixedPayload | ConvertTo-Json -Depth 10)
    
    Write-Host "✗ Should have failed but succeeded!" -ForegroundColor Red
}
catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    Write-Host "✓ Expected error caught!" -ForegroundColor Green
    Write-Host "Error Code: $($errorResponse.errorCode)" -ForegroundColor Yellow
    Write-Host "Message: $($errorResponse.message)" -ForegroundColor Yellow
    Write-Host "Total Employees: $($errorResponse.details.totalEmployees)" -ForegroundColor Yellow
    Write-Host "Error Count: $($errorResponse.details.errorCount)" -ForegroundColor Yellow
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 6: Update Existing Employee
Write-Host "Test 6: Update Existing Employee (Run Test 1 first)" -ForegroundColor Yellow
$updatePayload = @{
    employees = @{
        employee = @(
            @{
                id = 2001
                firstName = "Alice"
                lastName = "Johnson-Smith"
                department = "Engineering"
                position = "Lead Developer"
                salary = 105000.00
                email = "alice.johnson@company.com"
            }
        )
    }
}

try {
    $response = Invoke-RestMethod -Method Post -Uri $endpoint `
        -ContentType "application/json" `
        -Body ($updatePayload | ConvertTo-Json -Depth 10)
    
    Write-Host "✓ Success!" -ForegroundColor Green
    Write-Host "Status: $($response.status)" -ForegroundColor Green
    Write-Host "Message: $($response.message)" -ForegroundColor Green
    Write-Host "Total Processed: $($response.details.totalProcessed)" -ForegroundColor Green
    Write-Host "Total Inserted: $($response.details.totalInserted)" -ForegroundColor Green
    Write-Host "Total Updated: $($response.details.totalUpdated)" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "All Tests Completed!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
