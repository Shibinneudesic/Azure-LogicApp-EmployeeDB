# Test Azure Logic App Workflow
# Logic App: ais-training-la
# Workflow: wf-employee-upsert

Write-Host "`n=== Testing Azure Logic App Workflow ===" -ForegroundColor Cyan
Write-Host "Logic App: ais-training-la" -ForegroundColor Yellow
Write-Host "Workflow: wf-employee-upsert" -ForegroundColor Yellow

# Get the callback URL from Azure
Write-Host "`nGetting callback URL..." -ForegroundColor Cyan
$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "ais-training-la"
$workflowName = "wf-employee-upsert"

# Get subscription ID
$subscription = az account show | ConvertFrom-Json
$subscriptionId = $subscription.id

Write-Host "Subscription: $($subscription.name)" -ForegroundColor Gray

# Get access token
$token = az account get-access-token --query accessToken -o tsv

# Get callback URL
$url = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/hostruntime/runtime/webhooks/workflow/api/management/workflows/$workflowName/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2020-05-01-preview"
$headers = @{"Authorization" = "Bearer $token"}

try {
    $callbackResp = Invoke-RestMethod -Uri $url -Method POST -Headers $headers
    $callbackUrl = $callbackResp.value
    Write-Host "✓ Callback URL obtained" -ForegroundColor Green
    
    # Test 1: Valid employee
    Write-Host "`n--- Test 1: Valid Employee ---" -ForegroundColor Cyan
    $payload1 = @{
        "employees" = @{
            "employee" = @(
                @{
                    "id" = 95001
                    "firstName" = "Azure"
                    "lastName" = "Test"
                    "department" = "Engineering"
                    "position" = "Developer"
                    "salary" = 85000
                    "email" = "azure@test.com"
                }
            )
        }
    } | ConvertTo-Json -Depth 10
    
    $result1 = Invoke-RestMethod -Uri $callbackUrl -Method POST -Body $payload1 -ContentType "application/json"
    Write-Host "✓ Status: $($result1.status) ($($result1.code))" -ForegroundColor Green
    Write-Host "  Message: $($result1.message)" -ForegroundColor White
    Write-Host "  Total Processed: $($result1.details.totalProcessed)" -ForegroundColor White
    
    # Test 2: Validation error
    Write-Host "`n--- Test 2: Validation Error ---" -ForegroundColor Cyan
    $payload2 = @{
        "employees" = @{
            "employee" = @(
                @{
                    "id" = 95002
                    "lastName" = "OnlyLastName"
                    "department" = "Test"
                }
            )
        }
    } | ConvertTo-Json -Depth 10
    
    try {
        $result2 = Invoke-RestMethod -Uri $callbackUrl -Method POST -Body $payload2 -ContentType "application/json"
        Write-Host "✗ Expected validation error but got success" -ForegroundColor Red
    } catch {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "✓ Validation Error (Expected)" -ForegroundColor Green
        Write-Host "  Status: $($errorDetails.code)" -ForegroundColor White
        Write-Host "  Message: $($errorDetails.message)" -ForegroundColor White
        Write-Host "  Errors: $($errorDetails.details.totalErrors)" -ForegroundColor White
    }
    
    # Test 3: Batch processing
    Write-Host "`n--- Test 3: Batch Processing ---" -ForegroundColor Cyan
    $payload3 = @{
        "employees" = @{
            "employee" = @(
                @{
                    "id" = 95003
                    "firstName" = "Batch"
                    "lastName" = "Employee1"
                    "department" = "IT"
                    "position" = "Dev"
                    "salary" = 80000
                    "email" = "batch1@test.com"
                },
                @{
                    "id" = 95004
                    "firstName" = "Batch"
                    "lastName" = "Employee2"
                    "department" = "HR"
                    "position" = "Manager"
                    "salary" = 90000
                    "email" = "batch2@test.com"
                },
                @{
                    "id" = 95005
                    "firstName" = "Batch"
                    "lastName" = "Employee3"
                    "department" = "Sales"
                    "position" = "Rep"
                    "salary" = 70000
                    "email" = "batch3@test.com"
                }
            )
        }
    } | ConvertTo-Json -Depth 10
    
    $result3 = Invoke-RestMethod -Uri $callbackUrl -Method POST -Body $payload3 -ContentType "application/json"
    Write-Host "✓ Status: $($result3.status) ($($result3.code))" -ForegroundColor Green
    Write-Host "  Message: $($result3.message)" -ForegroundColor White
    Write-Host "  Total Processed: $($result3.details.totalProcessed) / $($result3.details.requestedCount)" -ForegroundColor White
    
    Write-Host "`n=== All Tests Completed ===" -ForegroundColor Green
    
} catch {
    Write-Host "`n✗ Error getting callback URL" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host "`nPlease ensure:" -ForegroundColor Cyan
    Write-Host "1. You're logged into Azure CLI (az login)" -ForegroundColor White
    Write-Host "2. You have access to resource group: $resourceGroup" -ForegroundColor White
    Write-Host "3. Logic App 'ais-training-la' exists and is running" -ForegroundColor White
}
