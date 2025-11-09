-- This script grants the Logic App managed identity access to the SQL database
-- Run this script on the 'empdb' database
-- Logic App: ais-training-la

-- Step 1: Create user for Logic App managed identity
-- Use the Logic App name (ais-training-la)
CREATE USER [ais-training-la] FROM EXTERNAL PROVIDER;

-- Step 2: Grant database roles
ALTER ROLE db_datareader ADD MEMBER [ais-training-la];
ALTER ROLE db_datawriter ADD MEMBER [ais-training-la];

-- Step 3: Grant specific table permissions
-- Note: Table name in Azure is 'Employee' (singular), not 'Employees'
GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [ais-training-la];

-- Step 4: Grant EXECUTE permission on stored procedures
-- Grant on both old and new stored procedure names to be safe
IF OBJECT_ID('dbo.UpsertEmployeeSimple', 'P') IS NOT NULL
    GRANT EXECUTE ON dbo.UpsertEmployeeSimple TO [ais-training-la];

IF OBJECT_ID('dbo.usp_Employee_Upsert', 'P') IS NOT NULL
    GRANT EXECUTE ON dbo.usp_Employee_Upsert TO [ais-training-la];

-- Step 5: Verify the setup
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    'Created successfully' AS Status
FROM sys.database_principals dp
WHERE dp.name = 'ais-training-la';

-- Verify permissions
SELECT 
    USER_NAME(grantee_principal_id) AS UserName,
    OBJECT_NAME(major_id) AS ObjectName,
    permission_name AS Permission,
    state_desc AS State
FROM sys.database_permissions
WHERE grantee_principal_id = USER_ID('ais-training-la');

PRINT 'Logic App managed identity access granted successfully!';