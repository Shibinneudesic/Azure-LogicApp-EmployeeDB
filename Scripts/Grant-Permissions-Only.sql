-- Grant permissions to existing Logic App user
-- Run this in Azure SQL Query Editor

-- Grant permissions
ALTER ROLE db_datareader ADD MEMBER [ais-training-la];
ALTER ROLE db_datawriter ADD MEMBER [ais-training-la];
GRANT EXECUTE ON SCHEMA::dbo TO [ais-training-la];
GO

-- Verify permissions
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = 'ais-training-la'
ORDER BY dp.name, r.name;
GO
