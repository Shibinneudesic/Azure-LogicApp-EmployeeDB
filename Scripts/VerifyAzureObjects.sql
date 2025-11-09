-- Verify what objects exist in Azure SQL database 'empdb'
-- Run this in Azure Portal Query Editor to see current state

-- Check tables
SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    create_date AS CreatedDate
FROM sys.tables
ORDER BY name;

-- Check stored procedures
SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ProcedureName,
    create_date AS CreatedDate
FROM sys.procedures
ORDER BY name;

-- Check columns in Employee table (if it exists)
IF OBJECT_ID('dbo.Employee', 'U') IS NOT NULL
BEGIN
    SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Employee' AND TABLE_SCHEMA = 'dbo'
    ORDER BY ORDINAL_POSITION;
END

-- Check existing database users
SELECT 
    name AS UserName,
    type_desc AS UserType,
    create_date AS CreatedDate
FROM sys.database_principals
WHERE type IN ('E', 'S', 'U') -- E=External, S=SQL, U=Windows
ORDER BY name;
