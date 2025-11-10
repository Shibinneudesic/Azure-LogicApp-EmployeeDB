-- ====================================================
-- Grant Permissions for Batch Stored Procedure
-- ====================================================
-- This script grants the necessary permissions to the 
-- Logic App managed identity to execute the batch upsert
-- stored procedure and use the table-valued parameter type
-- ====================================================

USE EmployeeDB;
GO

-- Replace this with your actual Logic App managed identity name
DECLARE @ManagedIdentityName NVARCHAR(128) = 'ais-training-la';

PRINT '================================================';
PRINT 'Granting Permissions for Batch Stored Procedure';
PRINT '================================================';
PRINT '';

-- Grant EXECUTE permission on the stored procedure
PRINT '1. Granting EXECUTE permission on usp_Employee_Upsert_Batch...';
EXEC sp_executesql 
    N'GRANT EXECUTE ON dbo.usp_Employee_Upsert_Batch TO [@Identity]',
    N'@Identity NVARCHAR(128)',
    @Identity = @ManagedIdentityName;
PRINT '   ✓ EXECUTE permission granted';
PRINT '';

-- Grant permission to use the table type
PRINT '2. Granting permission to use EmployeeTableType...';
EXEC sp_executesql 
    N'GRANT EXECUTE ON TYPE::dbo.EmployeeTableType TO [@Identity]',
    N'@Identity NVARCHAR(128)',
    @Identity = @ManagedIdentityName;
PRINT '   ✓ Type usage permission granted';
PRINT '';

-- Grant SELECT permission on Employee table (for MERGE operation)
PRINT '3. Granting SELECT permission on Employee table...';
EXEC sp_executesql 
    N'GRANT SELECT ON dbo.Employee TO [@Identity]',
    N'@Identity NVARCHAR(128)',
    @Identity = @ManagedIdentityName;
PRINT '   ✓ SELECT permission granted';
PRINT '';

-- Grant INSERT permission on Employee table
PRINT '4. Granting INSERT permission on Employee table...';
EXEC sp_executesql 
    N'GRANT INSERT ON dbo.Employee TO [@Identity]',
    N'@Identity NVARCHAR(128)',
    @Identity = @ManagedIdentityName;
PRINT '   ✓ INSERT permission granted';
PRINT '';

-- Grant UPDATE permission on Employee table
PRINT '5. Granting UPDATE permission on Employee table...';
EXEC sp_executesql 
    N'GRANT UPDATE ON dbo.Employee TO [@Identity]',
    N'@Identity NVARCHAR(128)',
    @Identity = @ManagedIdentityName;
PRINT '   ✓ UPDATE permission granted';
PRINT '';

PRINT '================================================';
PRINT 'All permissions granted successfully!';
PRINT '================================================';
PRINT '';
PRINT 'Summary:';
PRINT '  - Managed Identity: ' + @ManagedIdentityName;
PRINT '  - Database: EmployeeDB';
PRINT '  - Permissions: EXECUTE (SP & Type), SELECT, INSERT, UPDATE';
PRINT '';

-- Verify permissions
PRINT 'Verifying Permissions...';
PRINT '';

SELECT 
    dp.name AS [Principal],
    o.name AS [Object],
    o.type_desc AS [Object Type],
    p.permission_name AS [Permission],
    p.state_desc AS [State]
FROM sys.database_permissions p
INNER JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
INNER JOIN sys.objects o ON p.major_id = o.object_id
WHERE dp.name = @ManagedIdentityName
    AND o.name IN ('usp_Employee_Upsert_Batch', 'Employee', 'EmployeeTableType')
ORDER BY o.name, p.permission_name;

PRINT '';
PRINT 'Permission verification complete!';
GO
