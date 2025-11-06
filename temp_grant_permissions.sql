CREATE USER [upsert-employee] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [upsert-employee];
ALTER ROLE db_datawriter ADD MEMBER [upsert-employee];
GRANT EXECUTE TO [upsert-employee];
GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [upsert-employee];
SELECT dp.name AS PrincipalName, dp.type_desc AS PrincipalType FROM sys.database_principals dp WHERE dp.name = 'upsert-employee';
