-- =============================================
-- Grant Permissions After SP Recreation
-- The managed identity needs EXECUTE permission on the recreated SP
-- =============================================

USE empdb;
GO

-- The managed identity user should already exist from before
-- We just need to grant EXECUTE permission on the recreated stored procedure

-- Grant EXECUTE permission on the stored procedure
GRANT EXECUTE ON OBJECT::dbo.usp_Employee_Upsert_Batch 
TO [ais-training-la];
GO

-- Verify the permission
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    o.name AS ObjectName,
    o.type_desc AS ObjectType,
    p.permission_name,
    p.state_desc
FROM sys.database_permissions p
INNER JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
INNER JOIN sys.objects o ON p.major_id = o.object_id
WHERE dp.name = 'ais-training-la'
  AND o.name = 'usp_Employee_Upsert_Batch'
ORDER BY dp.name, o.name;

PRINT 'EXECUTE permission granted on usp_Employee_Upsert_Batch to ais-training-la';
