# Quick Setup Test Script for Flat File Workflows
# November 9, 2025

$testDir = "c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee"
$testFilesDir = "$testDir\TestFiles\EmployeeFiles"
$sourceCSV = "$testDir\Artifacts\employees.csv"

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " Flat File Workflows - Local Test Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check Azurite
$azurite = Get-Process -Name "Azurite" -ErrorAction SilentlyContinue
if ($azurite) {
    Write-Host "`n[√] Azurite running (PID: $($azurite.Id))" -ForegroundColor Green
} else {
    Write-Host "`n[!] Azurite NOT running" -ForegroundColor Yellow
}

# Check func host
$func = Get-Process -Name "func" -ErrorAction SilentlyContinue
if ($func) {
    Write-Host "[√] Functions host running (PID: $($func.Id))" -ForegroundColor Green
} else {
    Write-Host "[!] Functions host NOT running" -ForegroundColor Yellow
}

# Create test directory
Write-Host "`n[*] Creating test directory..." -ForegroundColor Yellow
if (-not (Test-Path $testFilesDir)) {
    New-Item -ItemType Directory -Path $testFilesDir -Force | Out-Null
}
Write-Host "[√] Test directory ready: $testFilesDir" -ForegroundColor Green

# Copy test file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$testFile = Join-Path $testFilesDir "employees_$timestamp.csv"
Copy-Item $sourceCSV $testFile -Force
Write-Host "[√] Test file created: employees_$timestamp.csv" -ForegroundColor Green

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " Local Testing Notes" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test file location:" -ForegroundColor Yellow
Write-Host "  $testFile" -ForegroundColor White
Write-Host ""
Write-Host "Limitations for local testing:" -ForegroundColor Yellow
Write-Host "  • File System trigger requires On-Premise Data Gateway" -ForegroundColor Gray
Write-Host "  • Service Bus trigger requires Azure Service Bus connection" -ForegroundColor Gray
Write-Host "  • Storage Queue actions require running Azurite" -ForegroundColor Gray
Write-Host ""
Write-Host "Recommended testing approach:" -ForegroundColor Yellow
Write-Host "  1. Deploy workflows to Azure Logic App" -ForegroundColor White
Write-Host "  2. Configure connections in Azure Portal" -ForegroundColor White
Write-Host "  3. Test end-to-end in Azure environment" -ForegroundColor White
Write-Host ""
Write-Host "To test transformations locally:" -ForegroundColor Yellow
Write-Host "  1. Open wf-flatfile-transformation/workflow.json" -ForegroundColor White
Write-Host "  2. Right-click → Open in Designer" -ForegroundColor White
Write-Host "  3. Manually test XSLT and Liquid actions" -ForegroundColor White
Write-Host ""
Write-Host "[√] Setup complete!" -ForegroundColor Green
