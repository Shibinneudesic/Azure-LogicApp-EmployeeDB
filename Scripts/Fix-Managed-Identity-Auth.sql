-- Troubleshooting script for managed identity authentication
-- Run this in Azure Portal Query Editor as an admin

-- Step 1: Check if the user exists
PRINT '========== STEP 1: CHECK USER EXISTS ==========';
SELECT 
    name AS UserName,
    type_desc AS UserType,
    authentication_type_desc AS AuthType,
    create_date AS Created
FROM sys.database_principals
WHERE name = 'ais-training-la';

-- Step 2: Drop and recreate the user (if exists)
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ais-training-la')
BEGIN
    PRINT '';
    PRINT '========== STEP 2: DROPPING EXISTING USER ==========';
    DROP USER [ais-training-la];
    PRINT 'User dropped successfully';
END

-- Step 3: Create user with correct syntax
PRINT '';
PRINT '========== STEP 3: CREATING USER FROM EXTERNAL PROVIDER ==========';
CREATE USER [ais-training-la] FROM EXTERNAL PROVIDER;
PRINT 'User created successfully';

-- Step 4: Grant all required permissions
PRINT '';
PRINT '========== STEP 4: GRANTING PERMISSIONS ==========';

-- Connect permission
GRANT CONNECT TO [ais-training-la];
PRINT '✓ CONNECT granted';

-- Execute on stored procedure
GRANT EXECUTE ON OBJECT::dbo.usp_Employee_Upsert_Batch TO [ais-training-la];
PRINT '✓ EXECUTE on usp_Employee_Upsert_Batch granted';

-- Execute on table type
GRANT EXECUTE ON TYPE::dbo.EmployeeTableType TO [ais-training-la];
PRINT '✓ EXECUTE on EmployeeTableType granted';

-- Table permissions
GRANT SELECT ON OBJECT::dbo.Employee TO [ais-training-la];
GRANT INSERT ON OBJECT::dbo.Employee TO [ais-training-la];
GRANT UPDATE ON OBJECT::dbo.Employee TO [ais-training-la];
PRINT '✓ SELECT, INSERT, UPDATE on Employee granted';

-- Step 5: Verify everything
PRINT '';
PRINT '========== STEP 5: VERIFICATION ==========';

-- Check user
SELECT 
    name AS UserName,
    type_desc AS UserType,
    authentication_type_desc AS AuthType
FROM sys.database_principals
WHERE name = 'ais-training-la';

-- Check permissions
SELECT 
    pr.name AS ObjectName,
    pr.type_desc AS ObjectType,
    pe.permission_name AS Permission,
    pe.state_desc AS State
FROM sys.database_permissions pe
INNER JOIN sys.database_principals dp ON pe.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects pr ON pe.major_id = pr.object_id
WHERE dp.name = 'ais-training-la'
ORDER BY pr.name, pe.permission_name;

PRINT '';
PRINT '✓✓✓ SETUP COMPLETE ✓✓✓';
PRINT 'User: ais-training-la';
PRINT 'Database: empdb';
PRINT 'Server: aistrainingserver.database.windows.net';
PRINT 'Principal ID: 99ded633-38c2-4f05-a41c-7ba48aed3285';
