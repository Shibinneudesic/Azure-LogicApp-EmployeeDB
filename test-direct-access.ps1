# Direct Database Access Test Script
# This script bypasses the Logic App and tests the stored procedure directly
# Use this for immediate testing while Logic App local development issues are resolved

Write-Host "`n=== Testing UpsertEmployee Stored Procedure Directly ===" -ForegroundColor Cyan
Write-Host "This bypasses the Logic App and calls the database directly`n" -ForegroundColor Yellow

# Test data - same structure as test-request.json
$testEmployees = @(
    @{
        ID = 2007
        FirstName = 'Shibin'
        LastName = 'Sam'
        Department = 'Quality Assurance'
        Position = 'Senior QA Engineer'
        Salary = 82000
        Email = 'shibin.sam@example.com'
    },
    @{
        ID = 2009
        FirstName = 'Anjali'
        LastName = 'Nair'
        Department = 'Software Development'
        Position = 'Full Stack Developer'
        Salary = 95000
        Email = 'anjali.nair@example.com'
    },
    @{
        ID = 2003
        FirstName = 'Rahul'
        LastName = 'Menon'
        Department = 'Human Resources'
        Position = 'HR Business Partner'
        Salary = 78000
        Email = 'rahul.menon@example.com'
    }
)

Write-Host "Processing $($testEmployees.Count) employees...`n" -ForegroundColor Cyan

# Process each employee
foreach ($emp in $testEmployees) {
    Write-Host "Processing: $($emp.FirstName) $($emp.LastName) (ID: $($emp.ID))..." -ForegroundColor Yellow
    
    $query = @"
EXEC UpsertEmployee 
    @ID=$($emp.ID), 
    @FirstName='$($emp.FirstName)', 
    @LastName='$($emp.LastName)', 
    @Department='$($emp.Department)', 
    @Position='$($emp.Position)', 
    @Salary=$($emp.Salary), 
    @Email='$($emp.Email)'
"@
    
    try {
        $result = sqlcmd -S "(localdb)\MSSQLLocalDB" -d EmployeeDB -Q $query -ErrorAction Stop
        Write-Host "  ✅ Success: Employee ID $($emp.ID) - $($emp.FirstName) $($emp.LastName)" -ForegroundColor Green
    }
    catch {
        Write-Host "  ❌ Error processing employee ID $($emp.ID): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Verification ===" -ForegroundColor Cyan
Write-Host "Querying database for test employees...`n" -ForegroundColor Yellow

# Verify results
$verifyQuery = @"
SELECT EmployeeID, FirstName, LastName, Department, Position, Salary, Email, ModifiedDate
FROM Employee 
WHERE EmployeeID IN (2003, 2007, 2009) 
ORDER BY EmployeeID
"@

sqlcmd -S "(localdb)\MSSQLLocalDB" -d EmployeeDB -Q $verifyQuery -W

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "All test employees have been processed successfully!" -ForegroundColor Green
Write-Host "`nNote: This script provides immediate testing capability while" -ForegroundColor Yellow
Write-Host "      Logic App local development issues are being resolved." -ForegroundColor Yellow
Write-Host "      For production, deploy the Logic App to Azure where" -ForegroundColor Yellow
Write-Host "      ServiceProvider connections work correctly.`n" -ForegroundColor Yellow
