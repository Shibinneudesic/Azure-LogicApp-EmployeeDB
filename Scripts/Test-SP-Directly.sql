-- Test the stored procedure directly with a single employee
-- Run this in Azure Portal Query Editor to verify the SP works

DECLARE @TestEmployees dbo.EmployeeTableType;

-- Insert test employee
INSERT INTO @TestEmployees (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES (999, 'Test', 'User', 'IT', 'Developer', 75000, 'test.user@example.com');

-- Execute the stored procedure
EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;

-- Check if the employee was inserted/updated
SELECT * FROM dbo.Employee WHERE Id = 999;
