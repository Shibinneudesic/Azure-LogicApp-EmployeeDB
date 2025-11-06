-- This script grants the Logic App managed identity access to the SQL database
-- Run this script on the 'empdb' database

-- Step 1: Create user for Logic App managed identity
CREATE USER [upsert-employee] FROM EXTERNAL PROVIDER;

-- Step 2: Grant database roles
ALTER ROLE db_datareader ADD MEMBER [upsert-employee];
ALTER ROLE db_datawriter ADD MEMBER [upsert-employee];

-- Step 3: Grant specific table permissions
GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [upsert-employee];

-- Step 4: Verify the setup
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    'Created successfully' AS Status
FROM sys.database_principals dp
WHERE dp.name = 'upsert-employee';

PRINT 'Logic App managed identity access granted successfully!';