-- Deploy usp_Employee_Upsert stored procedure to Azure SQL

-- Drop if exists
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
    
    -- Check if employee exists
    IF EXISTS (SELECT 1 FROM Employees WHERE Id = @ID)
    BEGIN
        -- Update existing employee
        UPDATE Employees
        SET 
            FirstName = @FirstName,
            LastName = @LastName,
            Department = @Department,
            Position = @Position,
            Salary = @Salary,
            Email = @Email,
            UpdatedAt = GETUTCDATE()
        WHERE Id = @ID;
    END
    ELSE
    BEGIN
        -- Insert new employee
        INSERT INTO Employees (Id, FirstName, LastName, Department, Position, Salary, Email, CreatedAt, UpdatedAt)
        VALUES (@ID, @FirstName, @LastName, @Department, @Position, @Salary, @Email, GETUTCDATE(), GETUTCDATE());
    END
END
GO

PRINT 'usp_Employee_Upsert procedure created successfully';
