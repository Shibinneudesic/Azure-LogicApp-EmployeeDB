-- ====================================================
-- Azure SQL Database - Employee Table Creation Script
-- ====================================================
-- This script creates the Employee table with proper constraints,
-- indexing, and audit fields for the Logic App Upsert operation.

-- Create the Employee database if it doesn't exist
-- Note: In Azure SQL Database, use CREATE DATABASE in a separate session
-- IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'EmployeeDB')
-- BEGIN
--     CREATE DATABASE EmployeeDB;
-- END

USE EmployeeDB;
GO

-- Drop table if exists for clean recreation
IF OBJECT_ID('dbo.Employee', 'U') IS NOT NULL
    DROP TABLE dbo.Employee;
GO

-- Create Employee table with comprehensive schema
CREATE TABLE dbo.Employee (
    -- Primary Key
    EmployeeID INT NOT NULL CONSTRAINT PK_Employee PRIMARY KEY,
    
    -- Required Fields
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    
    -- Optional Fields
    Department NVARCHAR(100) NULL,
    Position NVARCHAR(100) NULL,
    Salary DECIMAL(18,2) NULL,
    
    -- Email field for future use
    Email NVARCHAR(255) NULL,
    
    -- Audit Fields
    CreatedDate DATETIME2(7) NOT NULL CONSTRAINT DF_Employee_CreatedDate DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2(7) NOT NULL CONSTRAINT DF_Employee_ModifiedDate DEFAULT GETUTCDATE(),
    CreatedBy NVARCHAR(100) NOT NULL CONSTRAINT DF_Employee_CreatedBy DEFAULT SYSTEM_USER,
    ModifiedBy NVARCHAR(100) NOT NULL CONSTRAINT DF_Employee_ModifiedBy DEFAULT SYSTEM_USER,
    
    -- Soft delete flag
    IsActive BIT NOT NULL CONSTRAINT DF_Employee_IsActive DEFAULT 1,
    
    -- Row version for optimistic concurrency
    RowVersion ROWVERSION NOT NULL
);
GO

-- Create non-clustered indexes for better query performance
CREATE NONCLUSTERED INDEX IX_Employee_LastName_FirstName 
ON dbo.Employee (LastName ASC, FirstName ASC);
GO

CREATE NONCLUSTERED INDEX IX_Employee_Department 
ON dbo.Employee (Department ASC) 
WHERE Department IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX IX_Employee_IsActive 
ON dbo.Employee (IsActive ASC);
GO

-- Create a trigger to automatically update ModifiedDate and ModifiedBy
CREATE TRIGGER tr_Employee_UpdateAudit
ON dbo.Employee
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE e
    SET ModifiedDate = GETUTCDATE(),
        ModifiedBy = SYSTEM_USER
    FROM dbo.Employee e
    INNER JOIN inserted i ON e.EmployeeID = i.EmployeeID;
END;
GO

-- Create a stored procedure for upsert operation
CREATE PROCEDURE dbo.UpsertEmployee
    @EmployeeID INT,
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @Department NVARCHAR(100) = NULL,
    @Position NVARCHAR(100) = NULL,
    @Salary DECIMAL(18,2) = NULL,
    @Email NVARCHAR(255) = NULL,
    @OperationType NVARCHAR(10) OUTPUT,
    @RowsAffected INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExistingCount INT;
    
    -- Check if employee exists
    SELECT @ExistingCount = COUNT(*)
    FROM dbo.Employee
    WHERE EmployeeID = @EmployeeID AND IsActive = 1;
    
    BEGIN TRY
        IF @ExistingCount > 0
        BEGIN
            -- Update existing employee
            UPDATE dbo.Employee
            SET FirstName = @FirstName,
                LastName = @LastName,
                Department = @Department,
                Position = @Position,
                Salary = @Salary,
                Email = @Email
            WHERE EmployeeID = @EmployeeID AND IsActive = 1;
            
            SET @RowsAffected = @@ROWCOUNT;
            SET @OperationType = 'UPDATE';
        END
        ELSE
        BEGIN
            -- Insert new employee
            INSERT INTO dbo.Employee (EmployeeID, FirstName, LastName, Department, Position, Salary, Email)
            VALUES (@EmployeeID, @FirstName, @LastName, @Department, @Position, @Salary, @Email);
            
            SET @RowsAffected = @@ROWCOUNT;
            SET @OperationType = 'INSERT';
        END
    END TRY
    BEGIN CATCH
        -- Re-throw the error
        THROW;
    END CATCH
END;
GO

-- Create a view for active employees
CREATE VIEW dbo.vw_ActiveEmployees
AS
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    Department,
    Position,
    Salary,
    Email,
    CreatedDate,
    ModifiedDate,
    CreatedBy,
    ModifiedBy
FROM dbo.Employee
WHERE IsActive = 1;
GO

-- Insert sample data for testing
INSERT INTO dbo.Employee (EmployeeID, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (1001, 'John', 'Doe', 'IT', 'Software Engineer', 75000.00, 'john.doe@company.com'),
    (1002, 'Jane', 'Smith', 'HR', 'HR Manager', 80000.00, 'jane.smith@company.com'),
    (1003, 'Mike', 'Johnson', 'Finance', 'Financial Analyst', 65000.00, 'mike.johnson@company.com');
GO

-- Verify the data
SELECT * FROM dbo.vw_ActiveEmployees;
GO

-- Grant permissions for Logic App service account
-- Note: Replace 'LogicAppServiceAccount' with your actual service account or managed identity
-- GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [LogicAppServiceAccount];
-- GRANT EXECUTE ON dbo.UpsertEmployee TO [LogicAppServiceAccount];

PRINT 'Employee table and related objects created successfully!';
PRINT 'Sample data inserted for testing.';
PRINT 'Remember to configure proper permissions for your Logic App service account.';