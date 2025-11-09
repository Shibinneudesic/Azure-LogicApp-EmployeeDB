-- Deploy usp_Employee_Upsert stored procedure to Azure SQL database 'empdb'
-- This replaces the old UpsertEmployeeSimple procedure
-- Run this in Azure Portal Query Editor

-- Drop old procedure if exists
IF OBJECT_ID('dbo.UpsertEmployeeSimple', 'P') IS NOT NULL
    DROP PROCEDURE dbo.UpsertEmployeeSimple;
GO

-- Create new procedure with standard naming
IF OBJECT_ID('dbo.usp_Employee_Upsert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Employee_Upsert;
GO

CREATE PROCEDURE dbo.usp_Employee_Upsert
    @ID INT,
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @Department NVARCHAR(100) = NULL,
    @Position NVARCHAR(100) = NULL,
    @Salary DECIMAL(18,2) = NULL,
    @Email NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Check if employee exists
        IF EXISTS(SELECT 1 FROM dbo.Employee WHERE Id = @ID AND IsActive = 1)
        BEGIN
            -- Update existing employee
            UPDATE dbo.Employee
            SET 
                FirstName = @FirstName,
                LastName = @LastName,
                Department = @Department,
                Position = @Position,
                Salary = @Salary,
                Email = @Email,
                ModifiedDate = GETUTCDATE()
            WHERE Id = @ID AND IsActive = 1;
            
            -- Return success info
            SELECT 
                @ID AS EmployeeID,
                'UPDATE' AS Operation,
                @@ROWCOUNT AS RowsAffected,
                'Success' AS Status;
        END
        ELSE
        BEGIN
            -- Insert new employee
            INSERT INTO dbo.Employee (Id, FirstName, LastName, Department, Position, Salary, Email)
            VALUES (@ID, @FirstName, @LastName, @Department, @Position, @Salary, @Email);
            
            -- Return success info
            SELECT 
                @ID AS EmployeeID,
                'INSERT' AS Operation,
                @@ROWCOUNT AS RowsAffected,
                'Success' AS Status;
        END
    END TRY
    BEGIN CATCH
        -- Return error info
        SELECT 
            @ID AS EmployeeID,
            'ERROR' AS Operation,
            0 AS RowsAffected,
            ERROR_MESSAGE() AS Status;
        
        -- Re-throw error for Logic App to catch
        THROW;
    END CATCH
END
GO

-- Verify procedure was created
SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ProcedureName,
    create_date AS CreatedDate,
    modify_date AS ModifiedDate
FROM sys.procedures
WHERE name = 'usp_Employee_Upsert';
GO

PRINT 'usp_Employee_Upsert procedure deployed successfully!';
PRINT 'Old UpsertEmployeeSimple procedure removed.';
PRINT 'Now run GrantManagedIdentityAccess.sql to grant permissions.';
