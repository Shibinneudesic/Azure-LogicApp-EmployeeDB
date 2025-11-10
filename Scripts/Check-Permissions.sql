-- Check if the managed identity user exists and its permissions
-- Run this on empdb database

-- Check if user exists
SELECT 
    dp.name AS UserName, 
    dp.type_desc AS UserType,
    dp.create_date AS CreatedDate
FROM sys.database_principals dp
WHERE dp.name = 'ais-training-la';

-- Check role memberships
SELECT 
    dp.name AS UserName,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = 'ais-training-la'
ORDER BY r.name;

-- Check specific permissions on stored procedure
SELECT 
    pr.name AS ObjectName,
    pr.type_desc AS ObjectType,
    dp.name AS UserName,
    dp.type_desc AS UserType,
    pe.permission_name,
    pe.state_desc AS PermissionState
FROM sys.database_permissions pe
INNER JOIN sys.database_principals dp ON pe.grantee_principal_id = dp.principal_id
INNER JOIN sys.objects pr ON pe.major_id = pr.object_id
WHERE dp.name = 'ais-training-la'
    AND pr.name IN ('usp_Employee_Upsert_Batch', 'EmployeeTableType')
ORDER BY pr.name, pe.permission_name;
