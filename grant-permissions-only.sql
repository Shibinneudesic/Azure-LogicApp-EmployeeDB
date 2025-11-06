-- Grant permissions to existing managed identity user
-- The user 'upsert-employee' already exists, just need to grant permissions

-- Grant database roles for read/write access
ALTER ROLE db_datareader ADD MEMBER [upsert-employee];
ALTER ROLE db_datawriter ADD MEMBER [upsert-employee];

-- Grant EXECUTE permission for stored procedures
GRANT EXECUTE TO [upsert-employee];

-- Grant specific permissions on Employee table
GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [upsert-employee];

-- Verify the permissions
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    dp.create_date AS CreatedDate,
    'Permissions granted successfully' AS Status
FROM sys.database_principals dp
WHERE dp.name = 'upsert-employee';

-- Check role memberships
SELECT 
    roles.name AS RoleName,
    members.name AS MemberName
FROM sys.database_role_members AS drm
JOIN sys.database_principals AS roles ON drm.role_principal_id = roles.principal_id
JOIN sys.database_principals AS members ON drm.member_principal_id = members.principal_id
WHERE members.name = 'upsert-employee';
