-- Verify what permissions the Logic App user has
-- Run this in Azure SQL Query Editor to check current state

-- Check if user exists
SELECT 
    name AS UserName,
    type_desc AS UserType,
    create_date AS CreatedDate
FROM sys.database_principals
WHERE name = 'ais-training-la';
GO

-- Check role memberships
SELECT 
    USER_NAME(drm.member_principal_id) AS UserName,
    USER_NAME(drm.role_principal_id) AS RoleName
FROM sys.database_role_members drm
WHERE USER_NAME(drm.member_principal_id) = 'ais-training-la';
GO

-- Check schema permissions
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    p.class_desc AS PermissionClass,
    p.permission_name AS Permission,
    SCHEMA_NAME(p.major_id) AS SchemaName
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE dp.name = 'ais-training-la';
GO

-- If the above returns NO RESULTS for role memberships, run this:
-- ALTER ROLE db_datareader ADD MEMBER [ais-training-la];
-- ALTER ROLE db_datawriter ADD MEMBER [ais-training-la];
-- GRANT EXECUTE ON SCHEMA::dbo TO [ais-training-la];
