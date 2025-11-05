-- ====================================================
-- Azure SQL Database - Managed Identity Configuration
-- ====================================================
-- This script configures the Logic App's managed identity
-- to access the Azure SQL Database

-- Instructions:
-- 1. Connect to your Azure SQL Database using SQL Server Management Studio or Azure Data Studio
-- 2. Use the server admin account (sqladmin) to execute this script
-- 3. Replace {LOGIC_APP_NAME} with your actual Logic App name
-- 4. Replace {MANAGED_IDENTITY_PRINCIPAL_ID} with the actual principal ID from deployment

USE EmployeeDB;
GO

-- Check if the user already exists
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '{LOGIC_APP_NAME}')
BEGIN
    -- Create user for the Logic App's managed identity
    -- Replace {LOGIC_APP_NAME} with your actual Logic App name
    CREATE USER [{LOGIC_APP_NAME}] FROM EXTERNAL PROVIDER;
    PRINT 'Created user for Logic App managed identity';
END
ELSE
BEGIN
    PRINT 'User for Logic App managed identity already exists';
END
GO

-- Grant necessary permissions
-- Data reader permission for SELECT operations
ALTER ROLE db_datareader ADD MEMBER [{LOGIC_APP_NAME}];
PRINT 'Granted db_datareader role';

-- Data writer permission for INSERT/UPDATE operations
ALTER ROLE db_datawriter ADD MEMBER [{LOGIC_APP_NAME}];
PRINT 'Granted db_datawriter role';

-- Grant execute permission on stored procedures
GRANT EXECUTE ON dbo.UpsertEmployee TO [{LOGIC_APP_NAME}];
PRINT 'Granted EXECUTE permission on UpsertEmployee stored procedure';

-- Grant execute permission on all stored procedures (optional)
-- GRANT EXECUTE TO [{LOGIC_APP_NAME}];

-- Verify permissions
SELECT 
    dp.class_desc,
    dp.permission_name,
    dp.state_desc,
    p.name AS principal_name,
    o.name AS object_name
FROM sys.database_permissions dp
LEFT JOIN sys.objects o ON dp.major_id = o.object_id
LEFT JOIN sys.database_principals p ON dp.grantee_principal_id = p.principal_id
WHERE p.name = '{LOGIC_APP_NAME}'
ORDER BY dp.class_desc, dp.permission_name;

PRINT 'Managed identity configuration completed successfully!';
PRINT 'The Logic App can now access the database using managed identity authentication.';

-- Optional: Create a test user for development/testing
-- This is useful for testing the stored procedures manually
/*
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'LogicAppTestUser')
BEGIN
    CREATE USER [LogicAppTestUser] WITH PASSWORD = 'TestPassword123!';
    ALTER ROLE db_datareader ADD MEMBER [LogicAppTestUser];
    ALTER ROLE db_datawriter ADD MEMBER [LogicAppTestUser];
    GRANT EXECUTE ON dbo.UpsertEmployee TO [LogicAppTestUser];
    PRINT 'Created test user for development';
END
*/