-- =============================================
-- Fix Stored Procedure Counting Logic
-- Correctly count inserts vs updates after MERGE
-- =============================================

USE empdb;
GO

-- Drop and recreate with fixed counting
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_Employee_Upsert_Batch]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_Employee_Upsert_Batch]
GO

CREATE PROCEDURE [dbo].[usp_Employee_Upsert_Batch]
    @Employees dbo.EmployeeTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TotalProcessed INT = 0;
    DECLARE @TotalInserted INT = 0;
    DECLARE @TotalUpdated INT = 0;
    DECLARE @ErrorMessage NVARCHAR(MAX) = NULL;
    DECLARE @ErrorCode NVARCHAR(50) = NULL;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate input
        IF NOT EXISTS (SELECT 1 FROM @Employees)
        BEGIN
            SET @ErrorMessage = 'No employee data provided';
            SET @ErrorCode = 'VALIDATION_ERROR';
            RAISERROR(@ErrorMessage, 16, 1);
        END
        
        -- Use MERGE with OUTPUT to capture insert vs update counts
        DECLARE @MergeOutput TABLE (ActionType NVARCHAR(10));
        
        MERGE INTO dbo.Employee AS target
        USING @Employees AS source
        ON target.Id = source.Id
        WHEN MATCHED THEN
            UPDATE SET
                FirstName = source.FirstName,
                LastName = source.LastName,
                Department = source.Department,
                Position = source.Position,
                Salary = source.Salary,
                Email = source.Email
        WHEN NOT MATCHED THEN
            INSERT (Id, FirstName, LastName, Department, Position, Salary, Email)
            VALUES (source.Id, source.FirstName, source.LastName, source.Department, 
                    source.Position, source.Salary, source.Email)
        OUTPUT $action INTO @MergeOutput;
        
        -- Count the results
        SET @TotalInserted = (SELECT COUNT(*) FROM @MergeOutput WHERE ActionType = 'INSERT');
        SET @TotalUpdated = (SELECT COUNT(*) FROM @MergeOutput WHERE ActionType = 'UPDATE');
        SET @TotalProcessed = @TotalInserted + @TotalUpdated;
        
        COMMIT TRANSACTION;
        
        -- Return success result
        SELECT 
            'success' AS Status,
            'Successfully processed ' + CAST(@TotalProcessed AS NVARCHAR(10)) + ' employee(s)' AS Message,
            NULL AS ErrorCode,
            NULL AS ErrorDetails,
            @TotalProcessed AS TotalProcessed,
            @TotalInserted AS TotalInserted,
            @TotalUpdated AS TotalUpdated,
            CONVERT(VARCHAR(23), GETDATE(), 126) AS ProcessedDate;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorCode = CAST(ERROR_NUMBER() AS NVARCHAR(50));
        
        SELECT 
            'error' AS Status,
            'Batch processing failed: ' + @ErrorMessage AS Message,
            @ErrorCode AS ErrorCode,
            'Error at line ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ' in ' + ERROR_PROCEDURE() AS ErrorDetails,
            0 AS TotalProcessed,
            0 AS TotalInserted,
            0 AS TotalUpdated,
            CONVERT(VARCHAR(23), GETDATE(), 126) AS ProcessedDate;
    END CATCH
END
GO

-- Test the fixed stored procedure
DECLARE @TestEmployees dbo.EmployeeTableType;

-- Test with mix of new and existing employees
INSERT INTO @TestEmployees (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (101, 'Alice', 'Anderson', 'IT', 'Senior Developer', 80000, 'alice.updated@example.com'),  -- Should UPDATE
    (102, 'Bob', 'Brown', 'HR', 'HR Manager', 90000, 'bob.updated@example.com'),              -- Should UPDATE
    (999, 'New', 'Employee', 'Finance', 'Analyst', 70000, 'new.employee@example.com');        -- Should INSERT

-- Execute and verify counts
EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;

PRINT '';
PRINT 'Stored procedure counting logic fixed!';
PRINT 'Expected: TotalProcessed=3, TotalInserted=1, TotalUpdated=2';
