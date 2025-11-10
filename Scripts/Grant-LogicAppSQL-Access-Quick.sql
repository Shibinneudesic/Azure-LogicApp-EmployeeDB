-- Grant Logic App Managed Identity Access to SQL Database
-- Run this script on the Azure SQL Database: empdb
-- Server: aistrainingserver.database.windows.net
-- Database: empdb

-- Step 1: Create user for the Logic App managed identity
-- Replace the app name if different
CREATE USER [ais-training-la] FROM EXTERNAL PROVIDER;
GO

-- Step 2: Grant necessary permissions
-- For Employee table operations
ALTER ROLE db_datareader ADD MEMBER [ais-training-la];
ALTER ROLE db_datawriter ADD MEMBER [ais-training-la];
GO

-- Step 3: Grant EXECUTE permission on stored procedures
GRANT EXECUTE ON SCHEMA::dbo TO [ais-training-la];
GO

-- Step 4: Verify the user was created
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

-- Expected output should show:
-- UserName          UserType                RoleName
-- ais-training-la   EXTERNAL_USER          db_datareader
-- ais-training-la   EXTERNAL_USER          db_datawriter
