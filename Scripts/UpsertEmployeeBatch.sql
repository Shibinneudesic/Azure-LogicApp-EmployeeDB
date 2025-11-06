-- ====================================================
-- Batch Upsert Stored Procedure for Employee Data
-- ====================================================
-- This stored procedure handles batch upsert operations for multiple employees
-- with proper error handling and transaction management

USE EmployeeDB;
GO

-- Drop the procedure if it exists
IF OBJECT_ID('dbo.UpsertEmployeeBatch', 'P') IS NOT NULL
    DROP PROCEDURE dbo.UpsertEmployeeBatch;
GO

-- Create a table type for batch operations
IF TYPE_ID('dbo.EmployeeTableType') IS NOT NULL
    DROP TYPE dbo.EmployeeTableType;
GO

CREATE TYPE dbo.EmployeeTableType AS TABLE
(
    Id INT NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Department NVARCHAR(100) NULL,
    Position NVARCHAR(100) NULL,
    Salary DECIMAL(18,2) NULL,
    Email NVARCHAR(255) NULL
);
GO

-- Create the batch upsert stored procedure
CREATE PROCEDURE dbo.UpsertEmployeeBatch
    @Employees dbo.EmployeeTableType READONLY,
    @TotalProcessed INT OUTPUT,
    @TotalInserted INT OUTPUT,
    @TotalUpdated INT OUTPUT,
    @ErrorMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @InsertedCount INT = 0;
    DECLARE @UpdatedCount INT = 0;
    DECLARE @ErrorOccurred BIT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Create temp table for MERGE output
        CREATE TABLE #MergeOutput (ActionType NVARCHAR(10));
        
        -- Perform MERGE operation for batch upsert
        MERGE dbo.Employee AS target
        USING @Employees AS source
        ON target.Id = source.Id AND target.IsActive = 1
        
        -- Update existing records
        WHEN MATCHED THEN
            UPDATE SET
                FirstName = source.FirstName,
                LastName = source.LastName,
                Department = source.Department,
                Position = source.Position,
                Salary = source.Salary,
                Email = source.Email,
                ModifiedDate = GETUTCDATE(),
                ModifiedBy = SYSTEM_USER
        
        -- Insert new records
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (Id, FirstName, LastName, Department, Position, Salary, Email)
            VALUES (source.Id, source.FirstName, source.LastName, 
                    source.Department, source.Position, source.Salary, source.Email)
        
        OUTPUT $action INTO #MergeOutput(ActionType);
        
        -- Count the operations
        SELECT 
            @InsertedCount = COUNT(CASE WHEN ActionType = 'INSERT' THEN 1 END),
            @UpdatedCount = COUNT(CASE WHEN ActionType = 'UPDATE' THEN 1 END)
        FROM #MergeOutput;
        
        DROP TABLE #MergeOutput;
        
        -- Set output parameters
        SET @TotalProcessed = @InsertedCount + @UpdatedCount;
        SET @TotalInserted = @InsertedCount;
        SET @TotalUpdated = @UpdatedCount;
        SET @ErrorMessage = NULL;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Capture error details
        SET @ErrorOccurred = 1;
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @TotalProcessed = 0;
        SET @TotalInserted = 0;
        SET @TotalUpdated = 0;
        
        -- Re-throw the error for proper error handling
        THROW;
    END CATCH
END;
GO

-- Grant execute permission
-- GRANT EXECUTE ON dbo.UpsertEmployeeBatch TO [LogicAppServiceAccount];

PRINT 'Batch upsert stored procedure created successfully!';
GO
