-- ====================================================
-- Enhanced Batch Upsert Stored Procedure for Employee Data
-- Returns result set for Logic App consumption
-- ====================================================
-- Features:
-- 1. Batch processing with table-valued parameter
-- 2. Transaction management with automatic rollback on error
-- 3. Returns structured result set (status, message, counts)
-- 4. Proper error handling with detailed messages
-- ====================================================

USE EmployeeDB;
GO

-- Drop the procedure if it exists
IF OBJECT_ID('dbo.usp_Employee_Upsert_Batch', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Employee_Upsert_Batch;
GO

-- Create/Recreate table type for batch operations
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
CREATE PROCEDURE dbo.usp_Employee_Upsert_Batch
    @Employees dbo.EmployeeTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @InsertedCount INT = 0;
    DECLARE @UpdatedCount INT = 0;
    DECLARE @TotalProcessed INT = 0;
    DECLARE @Status NVARCHAR(50);
    DECLARE @Message NVARCHAR(1000);
    DECLARE @ErrorCode NVARCHAR(50);
    DECLARE @ErrorDetails NVARCHAR(4000);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate input
        IF NOT EXISTS (SELECT 1 FROM @Employees)
        BEGIN
            SET @Status = 'error';
            SET @Message = 'No employees provided for processing';
            SET @ErrorCode = 'VALIDATION_ERROR';
            SET @ErrorDetails = 'Employee list is empty';
            
            -- Return error result set
            SELECT 
                @Status AS [Status],
                @Message AS [Message],
                @ErrorCode AS ErrorCode,
                @ErrorDetails AS ErrorDetails,
                0 AS TotalProcessed,
                0 AS TotalInserted,
                0 AS TotalUpdated,
                GETUTCDATE() AS ProcessedDate;
            
            RETURN;
        END
        
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
        
        -- Set success values
        SET @TotalProcessed = @InsertedCount + @UpdatedCount;
        SET @Status = 'success';
        SET @Message = CONCAT('Successfully processed ', @TotalProcessed, ' employee(s)');
        
        COMMIT TRANSACTION;
        
        -- Return success result set
        SELECT 
            @Status AS [Status],
            @Message AS [Message],
            NULL AS ErrorCode,
            NULL AS ErrorDetails,
            @TotalProcessed AS TotalProcessed,
            @InsertedCount AS TotalInserted,
            @UpdatedCount AS TotalUpdated,
            GETUTCDATE() AS ProcessedDate;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Capture error details
        SET @Status = 'error';
        SET @Message = 'Error processing employee batch';
        SET @ErrorCode = CONCAT('SQL_ERROR_', ERROR_NUMBER());
        SET @ErrorDetails = CONCAT(
            'Error Number: ', ERROR_NUMBER(), 
            ', Line: ', ERROR_LINE(), 
            ', Message: ', ERROR_MESSAGE()
        );
        
        -- Return error result set
        SELECT 
            @Status AS [Status],
            @Message AS [Message],
            @ErrorCode AS ErrorCode,
            @ErrorDetails AS ErrorDetails,
            0 AS TotalProcessed,
            0 AS TotalInserted,
            0 AS TotalUpdated,
            GETUTCDATE() AS ProcessedDate;
            
    END CATCH
END;
GO

PRINT 'Enhanced batch upsert stored procedure created successfully!';
PRINT 'Table Type: dbo.EmployeeTableType';
PRINT 'Procedure: dbo.usp_Employee_Upsert_Batch';
GO

-- Test the procedure with sample data
/*
DECLARE @TestEmployees dbo.EmployeeTableType;

INSERT INTO @TestEmployees (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (1, 'John', 'Doe', 'IT', 'Developer', 75000.00, 'john.doe@example.com'),
    (2, 'Jane', 'Smith', 'HR', 'Manager', 85000.00, 'jane.smith@example.com'),
    (3, 'Bob', 'Johnson', 'Finance', 'Analyst', 65000.00, 'bob.johnson@example.com');

EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;
*/
