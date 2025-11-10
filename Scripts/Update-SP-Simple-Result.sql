-- =============================================
-- Update Stored Procedure to Return Simple Object
-- Instead of nested arrays [[{...}]], return just the values
-- =============================================

USE empdb;
GO

-- Drop and recreate the stored procedure
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
        
        -- Perform merge operation
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
                    source.Position, source.Salary, source.Email);
        
        -- Get counts
        SET @TotalProcessed = (SELECT COUNT(*) FROM @Employees);
        SET @TotalInserted = @@ROWCOUNT - (SELECT COUNT(*) FROM @Employees e 
                                           INNER JOIN dbo.Employee emp ON e.Id = emp.Id);
        SET @TotalUpdated = @TotalProcessed - @TotalInserted;
        
        COMMIT TRANSACTION;
        
        -- Return simple values (not SELECT which creates result set array)
        -- Use RETURN for status code and output parameters for data
        -- Since we can't use OUTPUT params easily from Logic Apps with executeQuery,
        -- we'll use SELECT but format it to return a single row as a flat structure
        
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

-- Test the updated stored procedure
DECLARE @TestEmployees dbo.EmployeeTableType;

INSERT INTO @TestEmployees (Id, FirstName, LastName, Department, Position, Salary, Email)
VALUES 
    (101, 'Alice', 'Anderson', 'IT', 'Developer', 75000, 'alice@example.com'),
    (102, 'Bob', 'Brown', 'HR', 'Manager', 85000, 'bob@example.com'),
    (103, 'Carol', 'Carter', 'Finance', 'Analyst', 70000, 'carol@example.com');

-- Execute and see the simple result
EXEC dbo.usp_Employee_Upsert_Batch @Employees = @TestEmployees;

PRINT 'Stored procedure updated successfully!';
PRINT 'The SP now returns a simple result set (single row) instead of nested arrays.';
