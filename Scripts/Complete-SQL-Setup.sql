-- Complete SQL Setup for Logic App
-- Run ALL of this in Azure SQL Query Editor on database: empdb

-- Step 1: Drop and recreate user (if there are issues)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ais-training-la')
BEGIN
    -- Remove from roles first
    EXEC sp_droprolemember 'db_datareader', 'ais-training-la';
    EXEC sp_droprolemember 'db_datawriter', 'ais-training-la';
    -- Drop user
    DROP USER [ais-training-la];
    PRINT 'User dropped successfully';
END
GO

-- Step 2: Create user fresh
CREATE USER [ais-training-la] FROM EXTERNAL PROVIDER;
PRINT 'User created successfully';
GO

-- Step 3: Grant all necessary permissions
ALTER ROLE db_datareader ADD MEMBER [ais-training-la];
ALTER ROLE db_datawriter ADD MEMBER [ais-training-la];
GRANT EXECUTE ON SCHEMA::dbo TO [ais-training-la];
GRANT EXECUTE ON OBJECT::dbo.usp_Employee_Upsert TO [ais-training-la];
PRINT 'Permissions granted successfully';
GO

-- Step 4: Verify everything
PRINT 'Verification Results:';
PRINT '==================';

SELECT 
    'User Exists' AS CheckType,
    name AS UserName,
    type_desc AS UserType
FROM sys.database_principals
WHERE name = 'ais-training-la';

SELECT 
    'Role Membership' AS CheckType,
    USER_NAME(drm.member_principal_id) AS UserName,
    USER_NAME(drm.role_principal_id) AS RoleName
FROM sys.database_role_members drm
WHERE USER_NAME(drm.member_principal_id) = 'ais-training-la';

SELECT 
    'Schema Permissions' AS CheckType,
    dp.name AS UserName,
    p.permission_name AS Permission,
    SCHEMA_NAME(p.major_id) AS SchemaName
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE dp.name = 'ais-training-la'
AND p.class_desc = 'SCHEMA';

PRINT 'Setup complete! Test your Logic App now.';
GO
