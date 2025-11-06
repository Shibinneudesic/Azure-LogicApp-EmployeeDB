-- Grant permissions to the NEW managed identity (after Logic App recreation)
-- The Logic App was recreated, so it has a new Principal ID

-- Step 1: Create user for the NEW Logic App managed identity
CREATE USER [upsert-employee] FROM EXTERNAL PROVIDER;

-- Step 2: Grant database roles
ALTER ROLE db_datareader ADD MEMBER [upsert-employee];
ALTER ROLE db_datawriter ADD MEMBER [upsert-employee];

-- Step 3: Grant EXECUTE permission for stored procedures
GRANT EXECUTE TO [upsert-employee];

-- Step 4: Grant specific table permissions
GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [upsert-employee];

-- Step 5: Verify
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    dp.create_date AS CreatedDate
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
