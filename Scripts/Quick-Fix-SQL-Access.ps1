# Quick Fix: Grant Logic App SQL Access
# Run this to grant SQL permissions to the Logic App managed identity

$ServerName = "aistrainingserver.database.windows.net"
$DatabaseName = "empdb"
$LogicAppName = "ais-training-la"

Write-Host "=" -ForegroundColor Cyan
Write-Host "Granting SQL Access to Logic App Managed Identity" -ForegroundColor Cyan
Write-Host "=" -ForegroundColor Cyan
Write-Host ""

Write-Host "Server: $ServerName" -ForegroundColor Yellow
Write-Host "Database: $DatabaseName" -ForegroundColor Yellow
Write-Host "Logic App: $LogicAppName" -ForegroundColor Yellow
Write-Host ""

# SQL Script
$SqlScript = @"
-- Create user for Logic App managed identity
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$LogicAppName')
BEGIN
    CREATE USER [$LogicAppName] FROM EXTERNAL PROVIDER;
    PRINT 'User created successfully';
END
ELSE
BEGIN
    PRINT 'User already exists';
END
GO

-- Grant permissions
ALTER ROLE db_datareader ADD MEMBER [$LogicAppName];
ALTER ROLE db_datawriter ADD MEMBER [$LogicAppName];
GRANT EXECUTE ON SCHEMA::dbo TO [$LogicAppName];
GO

-- Verify
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = '$LogicAppName'
ORDER BY dp.name, r.name;
"@

Write-Host "Executing SQL script..." -ForegroundColor Green

try {
    # Execute using Azure CLI (requires you to be logged in with SQL admin permissions)
    $SqlScript | Out-File -FilePath "temp_grant.sql" -Encoding UTF8
    
    az sql db execute `
        --server $ServerName.Replace(".database.windows.net", "") `
        --name $DatabaseName `
        --file-path "temp_grant.sql" `
        --auth-type SqlPassword
    
    Write-Host ""
    Write-Host "✅ SQL permissions granted successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now test the Logic App workflow again." -ForegroundColor Cyan
    
    # Cleanup
    Remove-Item "temp_grant.sql" -ErrorAction SilentlyContinue
}
catch {
    Write-Host ""
    Write-Host "❌ Error executing SQL script" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "MANUAL STEPS:" -ForegroundColor Yellow
    Write-Host "1. Open Azure Portal" -ForegroundColor White
    Write-Host "2. Navigate to SQL Server: aistrainingserver" -ForegroundColor White
    Write-Host "3. Go to Database: empdb" -ForegroundColor White
    Write-Host "4. Click 'Query editor' in left menu" -ForegroundColor White
    Write-Host "5. Login with your SQL admin credentials" -ForegroundColor White
    Write-Host "6. Run the SQL script from: Scripts\Grant-LogicAppSQL-Access-Quick.sql" -ForegroundColor White
}
