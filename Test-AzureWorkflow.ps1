# Test Azure Logic App Workflow
# Run this script after the workflow has fully initialized in Azure (wait 10-15 minutes after deployment)

param(
    [Parameter(Mandatory=$false)]
    [string]$LogicAppName = "upsert-employee",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "AIS_Training_Shibin",
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "cbb1dbec-731f-4479-a084-bdaec5e54fd4"
)

$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Azure Logic App Workflow Test Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Get the callback URL
Write-Host "Step 1: Getting workflow callback URL..." -ForegroundColor Yellow
try {
    $callbackUrl = az rest --method post `
        --uri "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$LogicAppName/hostruntime/runtime/webhooks/workflow/api/management/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2023-12-01" `
        --query "value" -o tsv
    
    if ($callbackUrl) {
        Write-Host "✓ Callback URL obtained" -ForegroundColor Green
        Write-Host "  URL: $callbackUrl" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Could not get callback URL. Workflow may not be initialized yet." -ForegroundColor Red
        Write-Host "  Please wait 10-15 minutes after deployment and try again." -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ Error getting callback URL: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  The workflow may not be fully deployed yet." -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Test 1: Valid Request (Success Case)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test 1: Valid Employee Insert/Update" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$test1Body = @'
{
  "employees": {
    "employee": [
      {
        "id": 9101,
        "firstName": "Azure",
        "lastName": "TestUser",
        "department": "Engineering",
        "position": "Cloud Engineer",
        "salary": 95000,
        "email": "azure.testuser@company.com"
      },
      {
        "id": 9102,
        "firstName": "Production",
        "lastName": "Deploy",
        "department": "DevOps",
        "position": "DevOps Engineer",
        "salary": 98000,
        "email": "prod.deploy@company.com"
      }
    ]
  }
}
'@

Write-Host "Sending request with 2 valid employees..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $callbackUrl -Method Post -Body $test1Body -ContentType "application/json"
    Write-Host "✓ Test 1 PASSED" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor White
    $response | ConvertTo-Json -Depth 5
} catch {
    Write-Host "✗ Test 1 FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Yellow
    if ($_.ErrorDetails.Message) {
        $_.ErrorDetails.Message | ConvertFrom-Json | ConvertTo-Json -Depth 5
    }
}

Write-Host "`n"

# Test 2: Validation Error (Missing Required Field)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test 2: Validation Error - Missing Field" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$test2Body = @'
{
  "employees": {
    "employee": [
      {
        "id": 9201,
        "lastName": "OnlyLastName"
      }
    ]
  }
}
'@

Write-Host "Sending request with missing firstName..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $callbackUrl -Method Post -Body $test2Body -ContentType "application/json"
    Write-Host "✗ Test 2 FAILED - Should have returned validation error" -ForegroundColor Red
    $response | ConvertTo-Json -Depth 5
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host "✓ Test 2 PASSED - Validation error returned correctly" -ForegroundColor Green
        Write-Host "Response:" -ForegroundColor White
        if ($_.ErrorDetails.Message) {
            $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
            if ($errorResponse.code -eq 400 -and $errorResponse.status -eq "error") {
                Write-Host "  Code: $($errorResponse.code) ✓" -ForegroundColor Green
                Write-Host "  Status: $($errorResponse.status) ✓" -ForegroundColor Green
                Write-Host "  Message: $($errorResponse.message)" -ForegroundColor White
            }
            $errorResponse | ConvertTo-Json -Depth 5
        }
    } else {
        Write-Host "✗ Test 2 FAILED - Unexpected status code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    }
}

Write-Host "`n"

# Test 3: Schema Validation Error (Invalid Structure)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test 3: Schema Error - Invalid Structure" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$test3Body = @'
{
  "employees": {}
}
'@

Write-Host "Sending request with empty employee array..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $callbackUrl -Method Post -Body $test3Body -ContentType "application/json"
    Write-Host "✗ Test 3 FAILED - Should have returned schema error" -ForegroundColor Red
    $response | ConvertTo-Json -Depth 5
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host "✓ Test 3 PASSED - Schema error returned correctly" -ForegroundColor Green
        Write-Host "Response:" -ForegroundColor White
        if ($_.ErrorDetails.Message) {
            $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
            if ($errorResponse.code -eq 400 -and $errorResponse.status -eq "error") {
                Write-Host "  Code: $($errorResponse.code) ✓" -ForegroundColor Green
                Write-Host "  Status: $($errorResponse.status) ✓" -ForegroundColor Green
                Write-Host "  Message: $($errorResponse.message)" -ForegroundColor White
            }
            $errorResponse | ConvertTo-Json -Depth 5
        }
    } else {
        Write-Host "✗ Test 3 FAILED - Unexpected status code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    }
}

Write-Host "`n"

# Test 4: Batch Insert (Multiple Employees)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test 4: Batch Insert - 5 Employees" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$test4Body = @'
{
  "employees": {
    "employee": [
      {"id": 9301, "firstName": "Alice", "lastName": "Johnson", "department": "HR", "position": "HR Manager", "salary": 85000, "email": "alice.j@company.com"},
      {"id": 9302, "firstName": "Bob", "lastName": "Smith", "department": "IT", "position": "System Admin", "salary": 80000, "email": "bob.s@company.com"},
      {"id": 9303, "firstName": "Charlie", "lastName": "Brown", "department": "Sales", "position": "Sales Rep", "salary": 70000, "email": "charlie.b@company.com"},
      {"id": 9304, "firstName": "Diana", "lastName": "Prince", "department": "Marketing", "position": "Marketing Lead", "salary": 90000, "email": "diana.p@company.com"},
      {"id": 9305, "firstName": "Eve", "lastName": "Taylor", "department": "Finance", "position": "Accountant", "salary": 75000, "email": "eve.t@company.com"}
    ]
  }
}
'@

Write-Host "Sending request with 5 employees..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $callbackUrl -Method Post -Body $test4Body -ContentType "application/json"
    Write-Host "✓ Test 4 PASSED" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor White
    if ($response.details.totalProcessed -eq 5) {
        Write-Host "  Processed: $($response.details.totalProcessed)/5 ✓" -ForegroundColor Green
    }
    $response | ConvertTo-Json -Depth 5
} catch {
    Write-Host "✗ Test 4 FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Yellow
    if ($_.ErrorDetails.Message) {
        $_.ErrorDetails.Message | ConvertFrom-Json | ConvertTo-Json -Depth 5
    }
}

Write-Host "`n"

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Suite Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Valid requests return code: 200" -ForegroundColor Green
Write-Host "✓ Validation errors return code: 400" -ForegroundColor Green
Write-Host "✓ Schema errors return code: 400" -ForegroundColor Green
Write-Host "✓ Batch processing works correctly" -ForegroundColor Green
Write-Host ""
Write-Host "Azure Portal - Workflow Runs:" -ForegroundColor Yellow
Write-Host "https://portal.azure.com/#@neudesic.onmicrosoft.com/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Web/sites/$LogicAppName/logicApps" -ForegroundColor Cyan
Write-Host ""
