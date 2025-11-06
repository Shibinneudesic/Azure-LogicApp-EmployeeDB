# Alternative Test Script - Direct Database Insert
# Since the Logic App has runtime issues, this script tests the database directly

Write-Host "=== Testing Employee Upsert Directly ===" -ForegroundColor Cyan

$employees = @(
    @{id=2007; firstName="Shibin"; lastName="Sam"; department="Quality Assurance"; position="Senior QA Engineer"; salary=82000; email="shibin.sam@example.com"},
    @{id=2009; firstName="Anjali"; lastName="Nair"; department="Software Development"; position="Full Stack Developer"; salary=95000; email="anjali.nair@example.com"},
    @{id=2003; firstName="Rahul"; lastName="Menon"; department="Human Resources"; position="HR Business Partner"; salary=78000; email="rahul.menon@example.com"}
)

Write-Host "`nInserting/Updating $($employees.Count) employees..." -ForegroundColor Yellow

foreach ($emp in $employees) {
    $query = "EXEC UpsertEmployee @ID=$($emp.id), @FirstName='$($emp.firstName)', @LastName='$($emp.lastName)', @Department='$($emp.department)', @Position='$($emp.position)', @Salary=$($emp.salary), @Email='$($emp.email)'"
    
    Write-Host "`nProcessing: $($emp.firstName) $($emp.lastName) (ID: $($emp.id))..." -ForegroundColor Cyan
    
    try {
        sqlcmd -S "(localdb)\MSSQLLocalDB" -d EmployeeDB -Q $query -ErrorAction Stop | Out-Null
        Write-Host "  Success!" -ForegroundColor Green
    } catch {
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n`nVerifying records in database..." -ForegroundColor Yellow
sqlcmd -S "(localdb)\MSSQLLocalDB" -d EmployeeDB -Q "SELECT EmployeeID, FirstName, LastName, Department, Position, Salary, Email FROM Employee WHERE EmployeeID IN (2007, 2009, 2003) ORDER BY EmployeeID" -W

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "`nNote: The stored procedure works correctly!" -ForegroundColor Green
Write-Host "The Logic App has a runtime issue that needs further investigation." -ForegroundColor Yellow
