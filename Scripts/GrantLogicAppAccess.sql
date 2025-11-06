-- SQL Script to Grant Logic App Access to Database
-- Run this on the 'empdb' database on 'aistrainingserver'

-- Create a user for the Logic App's managed identity
CREATE USER [upsert-employee] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions to the user
ALTER ROLE db_datareader ADD MEMBER [upsert-employee];
ALTER ROLE db_datawriter ADD MEMBER [upsert-employee];
ALTER ROLE db_ddladmin ADD MEMBER [upsert-employee];

-- Grant specific permissions for the Employee table operations
GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [upsert-employee];

-- Verify the user was created successfully
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.name = 'upsert-employee';