# Setup File Server Directory and Test CSV File
# Run this script on the machine where the gateway is installed

Write-Host "Setting up file server directory..." -ForegroundColor Cyan

# Step 1: Create directory
$directoryPath = "C:\EmployeeFiles"
if (-not (Test-Path $directoryPath)) {
    New-Item -Path $directoryPath -ItemType Directory -Force | Out-Null
    Write-Host "✅ Created directory: $directoryPath" -ForegroundColor Green
} else {
    Write-Host "✅ Directory already exists: $directoryPath" -ForegroundColor Yellow
}

# Step 2: Create test CSV file
$testCsv = @"
EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID
198,Donald,OConnell,DOCONNEL,650.507.9833,21-JUN-07,SH_CLERK,2600, - ,124,50
199,Douglas,Grant,DGRANT,650.507.9844,13-JAN-08,SH_CLERK,2600, - ,124,50
200,Jennifer,Whalen,JWHALEN,515.123.4444,17-SEP-03,AD_ASST,4400, - ,101,10
201,Michael,Hartstein,MHARTSTE,515.123.5555,17-FEB-04,MK_MAN,13000, - ,100,20
202,Pat,Fay,PFAY,603.123.6666,17-AUG-05,MK_REP,6000, - ,201,20
"@

$testFileName = "employees_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$testFilePath = Join-Path $directoryPath $testFileName

Set-Content -Path $testFilePath -Value $testCsv -Encoding UTF8
Write-Host "✅ Created test file: $testFilePath" -ForegroundColor Green

# Step 3: Verify directory access
Write-Host "`nVerifying directory access..." -ForegroundColor Cyan
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Current user: $currentUser" -ForegroundColor Yellow

# Check read permissions
try {
    $files = Get-ChildItem -Path $directoryPath -ErrorAction Stop
    Write-Host "✅ Read access confirmed - Found $($files.Count) file(s)" -ForegroundColor Green
} catch {
    Write-Host "❌ Read access failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Display summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "SETUP COMPLETE" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "Directory Path : $directoryPath" -ForegroundColor White
Write-Host "Test File      : $testFileName" -ForegroundColor White
Write-Host "Current User   : $currentUser" -ForegroundColor White
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Create gateway resource in Azure Portal" -ForegroundColor White
Write-Host "2. Note the Gateway Resource ID" -ForegroundColor White
Write-Host "3. Return to chat to create workflows" -ForegroundColor White
Write-Host "="*60 -ForegroundColor Cyan
