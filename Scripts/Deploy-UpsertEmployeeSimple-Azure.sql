-- Deploy UpsertEmployeeSimple stored procedure to Azure SQL
-- This is the simplified version without OUTPUT parameters used by the Logic App

IF OBJECT_ID('dbo.UpsertEmployeeSimple', 'P') IS NOT NULL
    DROP PROCEDURE dbo.UpsertEmployeeSimple;
GO

CREATE PROCEDURE dbo.UpsertEmployeeSimple
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
    
    -- Check if employee exists
    IF EXISTS(SELECT 1 FROM Employee WHERE Id = @ID AND IsActive = 1)
    BEGIN
        -- Update existing employee
        UPDATE Employee
        SET 
            FirstName = @FirstName,
            LastName = @LastName,
            Department = @Department,
            Position = @Position,
            Salary = @Salary,
            Email = @Email,
            ModifiedDate = GETDATE()
        WHERE Id = @ID AND IsActive = 1;
    END
    ELSE
    BEGIN
        -- Insert new employee
        INSERT INTO Employee (Id, FirstName, LastName, Department, Position, Salary, Email)
        VALUES (@ID, @FirstName, @LastName, @Department, @Position, @Salary, @Email);
    END
END
GO

-- Test the procedure
PRINT 'UpsertEmployeeSimple procedure created successfully';
