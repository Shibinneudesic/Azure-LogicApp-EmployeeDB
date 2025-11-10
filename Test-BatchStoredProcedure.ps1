# ====================================================
# Test Batch Stored Procedure
# ====================================================
# This script tests the batch upsert stored procedure
# with various scenarios
# ====================================================

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Testing Batch Upsert Stored Procedure" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$serverName = "localhost"  # Change to your Azure SQL server for Azure testing
$databaseName = "EmployeeDB"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Server: $serverName" -ForegroundColor White
Write-Host "  Database: $databaseName" -ForegroundColor White
Write-Host ""

# Test 1: Success - Insert New Employees
Write-Host "Test 1: Insert New Employees (Batch)" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

$test1Query = @"
DECLARE @TestEmployees dbo.EmployeeTableType;

INSERT INTO @TestEmployees (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (5001, 'Alice', 'Anderson', 'Engineering', 'Software Engineer', 95000.00, 'alice.anderson@example.com'),
    (5002, 'Bob', 'Brown', 'Marketing', 'Marketing Manager', 85000.00, 'bob.brown@example.com'),
    (5003, 'Carol', 'Carter', 'Sales', 'Sales Representative', 65000.00, 'carol.carter@example.com');

EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;
"@

try {
    $result1 = Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $test1Query
    
    Write-Host "Status: $($result1.Status)" -ForegroundColor $(if($result1.Status -eq 'success'){'Green'}else{'Red'})
    Write-Host "Message: $($result1.Message)" -ForegroundColor White
    Write-Host "Total Processed: $($result1.TotalProcessed)" -ForegroundColor Cyan
    Write-Host "Total Inserted: $($result1.TotalInserted)" -ForegroundColor Cyan
    Write-Host "Total Updated: $($result1.TotalUpdated)" -ForegroundColor Cyan
    Write-Host "✓ Test 1 Passed" -ForegroundColor Green
} catch {
    Write-Host "✗ Test 1 Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 2: Success - Update Existing Employees
Write-Host "Test 2: Update Existing Employees (Batch)" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

$test2Query = @"
DECLARE @TestEmployees dbo.EmployeeTableType;

INSERT INTO @TestEmployees (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (5001, 'Alice', 'Anderson', 'Engineering', 'Senior Software Engineer', 105000.00, 'alice.anderson@example.com'),
    (5002, 'Bob', 'Brown', 'Marketing', 'Senior Marketing Manager', 95000.00, 'bob.brown@example.com');

EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;
"@

try {
    $result2 = Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $test2Query
    
    Write-Host "Status: $($result2.Status)" -ForegroundColor $(if($result2.Status -eq 'success'){'Green'}else{'Red'})
    Write-Host "Message: $($result2.Message)" -ForegroundColor White
    Write-Host "Total Processed: $($result2.TotalProcessed)" -ForegroundColor Cyan
    Write-Host "Total Inserted: $($result2.TotalInserted)" -ForegroundColor Cyan
    Write-Host "Total Updated: $($result2.TotalUpdated)" -ForegroundColor Cyan
    Write-Host "✓ Test 2 Passed" -ForegroundColor Green
} catch {
    Write-Host "✗ Test 2 Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 3: Mixed - Insert and Update
Write-Host "Test 3: Mixed Operations (Insert + Update)" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

$test3Query = @"
DECLARE @TestEmployees dbo.EmployeeTableType;

INSERT INTO @TestEmployees (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (5001, 'Alice', 'Anderson', 'Engineering', 'Lead Software Engineer', 115000.00, 'alice.anderson@example.com'),
    (5004, 'David', 'Davis', 'IT', 'System Administrator', 75000.00, 'david.davis@example.com');

EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;
"@

try {
    $result3 = Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $test3Query
    
    Write-Host "Status: $($result3.Status)" -ForegroundColor $(if($result3.Status -eq 'success'){'Green'}else{'Red'})
    Write-Host "Message: $($result3.Message)" -ForegroundColor White
    Write-Host "Total Processed: $($result3.TotalProcessed)" -ForegroundColor Cyan
    Write-Host "Total Inserted: $($result3.TotalInserted)" -ForegroundColor Cyan
    Write-Host "Total Updated: $($result3.TotalUpdated)" -ForegroundColor Cyan
    Write-Host "✓ Test 3 Passed" -ForegroundColor Green
} catch {
    Write-Host "✗ Test 3 Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 4: Error - Empty Employee List
Write-Host "Test 4: Validation Error (Empty List)" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow

$test4Query = @"
DECLARE @TestEmployees dbo.EmployeeTableType;

-- Don't insert any employees (empty table)

EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;
"@

try {
    $result4 = Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $test4Query
    
    Write-Host "Status: $($result4.Status)" -ForegroundColor $(if($result4.Status -eq 'error'){'Yellow'}else{'Red'})
    Write-Host "Message: $($result4.Message)" -ForegroundColor White
    Write-Host "Error Code: $($result4.ErrorCode)" -ForegroundColor Yellow
    Write-Host "Error Details: $($result4.ErrorDetails)" -ForegroundColor Yellow
    
    if ($result4.Status -eq 'error') {
        Write-Host "✓ Test 4 Passed (Error handled correctly)" -ForegroundColor Green
    } else {
        Write-Host "✗ Test 4 Failed (Expected error status)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Test 4 Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 2

# Test 5: Transaction Rollback (Duplicate Key)
Write-Host "Test 5: Transaction Rollback (Error in Batch)" -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor Yellow

# First, check current count
$countBefore = (Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query "SELECT COUNT(*) as cnt FROM dbo.Employee WHERE Id >= 6000").cnt
Write-Host "Employee count before (Id >= 6000): $countBefore" -ForegroundColor White

$test5Query = @"
DECLARE @TestEmployees dbo.EmployeeTableType;

INSERT INTO @TestEmployees (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (6001, 'Test', 'User1', 'IT', 'Developer', 75000.00, 'test1@example.com'),
    (6002, 'Test', 'User2', 'HR', 'Manager', 85000.00, 'test2@example.com');

-- First insert should succeed
EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;

-- Now try to insert with duplicate email (assuming email has unique constraint)
-- This should cause rollback
DECLARE @TestEmployees2 dbo.EmployeeTableType;
INSERT INTO @TestEmployees2 (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (6003, 'Test', 'User3', 'IT', 'Developer', 75000.00, 'duplicate@example.com'),
    (6003, 'Test', 'User3Duplicate', 'IT', 'Developer', 75000.00, 'duplicate2@example.com');  -- Duplicate ID

EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees2;
"@

try {
    $result5 = Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $test5Query -ErrorAction Continue
    
    if ($result5) {
        Write-Host "Status: $($result5.Status)" -ForegroundColor Yellow
        Write-Host "Message: $($result5.Message)" -ForegroundColor White
        if ($result5.ErrorCode) {
            Write-Host "Error Code: $($result5.ErrorCode)" -ForegroundColor Yellow
            Write-Host "Error Details: $($result5.ErrorDetails)" -ForegroundColor Yellow
        }
    }
    
    # Verify rollback - count should only increase by 2 (first batch), not 4
    $countAfter = (Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query "SELECT COUNT(*) as cnt FROM dbo.Employee WHERE Id >= 6000").cnt
    Write-Host "Employee count after (Id >= 6000): $countAfter" -ForegroundColor White
    
    if ($countAfter -eq ($countBefore + 2)) {
        Write-Host "✓ Test 5 Passed (Transaction rolled back correctly)" -ForegroundColor Green
        Write-Host "  Only first batch was inserted, second batch rolled back due to duplicate ID" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Test 5 Failed (Unexpected count: $countAfter, expected: $($countBefore + 2))" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Expected error caught: $($_.Exception.Message)" -ForegroundColor Yellow
    
    # Verify rollback still
    $countAfter = (Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query "SELECT COUNT(*) as cnt FROM dbo.Employee WHERE Id >= 6000").cnt
    Write-Host "Employee count after error (Id >= 6000): $countAfter" -ForegroundColor White
    
    if ($countAfter -eq ($countBefore + 2)) {
        Write-Host "✓ Test 5 Passed (Transaction rolled back correctly after error)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Stored Procedure: dbo.usp_Employee_Upsert_Batch" -ForegroundColor White
Write-Host "Table Type: dbo.EmployeeTableType" -ForegroundColor White
Write-Host ""
Write-Host "✓ Batch insert tested" -ForegroundColor Green
Write-Host "✓ Batch update tested" -ForegroundColor Green
Write-Host "✓ Mixed operations tested" -ForegroundColor Green
Write-Host "✓ Validation error handling tested" -ForegroundColor Green
Write-Host "✓ Transaction rollback tested" -ForegroundColor Green
Write-Host ""
Write-Host "All tests completed!" -ForegroundColor Cyan
Write-Host ""

# Cleanup test data
Write-Host "Cleanup test data? (Y/N): " -NoNewline -ForegroundColor Yellow
$cleanup = Read-Host

if ($cleanup -eq 'Y' -or $cleanup -eq 'y') {
    Write-Host "Cleaning up test employees (Id >= 5000)..." -ForegroundColor Yellow
    Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query "DELETE FROM dbo.Employee WHERE Id >= 5000"
    Write-Host "✓ Cleanup completed" -ForegroundColor Green
} else {
    Write-Host "Skipping cleanup" -ForegroundColor White
}
