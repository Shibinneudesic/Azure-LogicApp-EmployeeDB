# Diagnostic script for Logic App troubleshooting
Write-Host "=== Logic App Diagnostics ===" -ForegroundColor Cyan

# 1. Check Azurite
Write-Host "`n1. Checking Azurite status..." -ForegroundColor Yellow
$azuriteJob = Get-Job -Name "Azurite" -ErrorAction SilentlyContinue
if ($azuriteJob) {
    Write-Host "   ✓ Azurite is running (Job State: $($azuriteJob.State))" -ForegroundColor Green
} else {
    Write-Host "   ✗ Azurite is not running" -ForegroundColor Red
}

# 2. Check func process
Write-Host "`n2. Checking func host process..." -ForegroundColor Yellow
$funcProcess = Get-Process -Name func -ErrorAction SilentlyContinue
if ($funcProcess) {
    Write-Host "   ✓ Func host is running (PID: $($funcProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "   ✗ Func host is not running" -ForegroundColor Red
}

# 3. Check LocalDB
Write-Host "`n3. Checking LocalDB connection..." -ForegroundColor Yellow
try {
    $result = sqlcmd -S "(localdb)\MSSQLLocalDB" -d EmployeeDB -Q "SELECT COUNT(*) AS RecordCount FROM Employee" -h-1 -W
    Write-Host "   ✓ LocalDB is accessible. Current records: $result" -ForegroundColor Green
} catch {
    Write-Host "   ✗ LocalDB connection failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Test func host endpoint
Write-Host "`n4. Testing func host endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:7071/runtime/webhooks/workflow/api/management/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2022-05-01" -Method POST -ContentType "application/json" -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✓ Func host is responding (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Func host endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Check local.settings.json
Write-Host "`n5. Checking local.settings.json..." -ForegroundColor Yellow
$settings = Get-Content "local.settings.json" | ConvertFrom-Json
$storage = $settings.Values.AzureWebJobsStorage
if ($storage -eq "UseDevelopmentStorage=true") {
    Write-Host "   √ Using local development storage" -ForegroundColor Green
} else {
    Write-Host "   ! Using Azure storage: $storage" -ForegroundColor Yellow
}

# 6. Check connections.json
Write-Host "`n6. Checking connections.json..." -ForegroundColor Yellow
$connections = Get-Content "connections.json" | ConvertFrom-Json
$sqlConn = $connections.serviceProviderConnections.sql.parameterValues.connectionString
Write-Host "   SQL Connection: $sqlConn" -ForegroundColor Cyan

Write-Host "`n=== Diagnostics Complete ===" -ForegroundColor Cyan
