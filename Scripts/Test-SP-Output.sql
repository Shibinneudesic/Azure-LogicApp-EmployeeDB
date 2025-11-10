-- Test the stored procedure to see the exact output structure
USE empdb;
GO

DECLARE @TestEmployees dbo.EmployeeTableType;

-- Insert test data
INSERT INTO @TestEmployees (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (101, 'Test', 'User', 'IT', 'Developer', 75000, 'test@example.com');

-- Execute the SP and see the result
EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;

-- This should return a single row with columns:
-- Status, Message, ErrorCode, ErrorDetails, TotalProcessed, TotalInserted, TotalUpdated, ProcessedDate
