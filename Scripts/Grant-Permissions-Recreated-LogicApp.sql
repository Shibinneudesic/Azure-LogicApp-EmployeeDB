-- Grant permissions to the Logic App managed identity for the new Logic App instance
-- Run this on empdb database as an admin user

-- Step 1: Create user for the managed identity if it doesn't exist
-- The user name should match the Logic App name: ais-training-la
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ais-training-la')
BEGIN
    PRINT 'Creating user for managed identity: ais-training-la';
    CREATE USER [ais-training-la] FROM EXTERNAL PROVIDER;
    PRINT 'User created successfully';
END
ELSE
BEGIN
    PRINT 'User ais-training-la already exists';
END
GO

-- Step 2: Grant CONNECT permission
PRINT 'Granting CONNECT permission...';
GRANT CONNECT TO [ais-training-la];
GO

-- Step 3: Grant EXECUTE permission on the stored procedure
PRINT 'Granting EXECUTE permission on stored procedure...';
GRANT EXECUTE ON OBJECT::dbo.usp_Employee_Upsert_Batch TO [ais-training-la];
GO

-- Step 4: Grant EXECUTE permission on the table type (required for table-valued parameters)
PRINT 'Granting EXECUTE permission on table type...';
GRANT EXECUTE ON TYPE::dbo.EmployeeTableType TO [ais-training-la];
GO

-- Step 5: Grant SELECT permission on Employee table (in case SP needs to read)
PRINT 'Granting SELECT permission on Employee table...';
GRANT SELECT ON OBJECT::dbo.Employee TO [ais-training-la];
GO

-- Step 6: Grant INSERT, UPDATE permissions on Employee table (for the MERGE operation in SP)
PRINT 'Granting INSERT and UPDATE permissions on Employee table...';
GRANT INSERT ON OBJECT::dbo.Employee TO [ais-training-la];
GRANT UPDATE ON OBJECT::dbo.Employee TO [ais-training-la];
GO

-- Verify permissions
PRINT '';
PRINT '========== PERMISSION VERIFICATION ==========';
SELECT 
    dp.name AS UserName,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = 'ais-training-la'
ORDER BY r.name;

SELECT 
    pr.name AS ObjectName,
    pr.type_desc AS ObjectType,
    pe.permission_name,
    pe.state_desc AS PermissionState
FROM sys.database_permissions pe
INNER JOIN sys.database_principals dp ON pe.grantee_principal_id = dp.principal_id
INNER JOIN sys.objects pr ON pe.major_id = pr.object_id
WHERE dp.name = 'ais-training-la'
ORDER BY pr.name, pe.permission_name;

PRINT '';
PRINT '✓ Permissions granted successfully!';
PRINT 'User: ais-training-la';
PRINT 'Database: empdb';
PRINT 'Server: aistrainingserver.database.windows.net';
