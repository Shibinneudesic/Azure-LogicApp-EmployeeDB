# PowerShell script to grant Logic App managed identity access to SQL database
# This script uses Azure PowerShell with Azure AD authentication

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerName = "aistrainingserver.database.windows.net",
    
    [Parameter(Mandatory=$false)]
    [string]$DatabaseName = "empdb",
    
    [Parameter(Mandatory=$false)]
    [string]$LogicAppName = "upsert-employee"
)

Write-Host "Granting SQL Database Access to Logic App Managed Identity..." -ForegroundColor Green
Write-Host "Server: $ServerName" -ForegroundColor Yellow
Write-Host "Database: $DatabaseName" -ForegroundColor Yellow
Write-Host "Logic App: $LogicAppName" -ForegroundColor Yellow

try {
    # Import required modules
    Write-Host "Checking required modules..." -ForegroundColor Yellow
    
    # Install SqlServer module if not present
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        Write-Host "Installing SqlServer PowerShell module..." -ForegroundColor Yellow
        Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
    }
    
    # Get access token for SQL
    Write-Host "Getting Azure access token..." -ForegroundColor Yellow
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "https://database.windows.net/").AccessToken
    
    # SQL commands to grant access
    $sqlCommands = @"
-- Create user for Logic App managed identity
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$LogicAppName')
BEGIN
    CREATE USER [$LogicAppName] FROM EXTERNAL PROVIDER;
    PRINT 'User [$LogicAppName] created successfully';
END
ELSE
BEGIN
    PRINT 'User [$LogicAppName] already exists';
END

-- Grant database roles
ALTER ROLE db_datareader ADD MEMBER [$LogicAppName];
ALTER ROLE db_datawriter ADD MEMBER [$LogicAppName];

-- Grant specific table permissions
GRANT SELECT, INSERT, UPDATE ON dbo.Employee TO [$LogicAppName];

-- Verify the setup
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    'Access granted successfully' AS Status
FROM sys.database_principals dp
WHERE dp.name = '$LogicAppName';

PRINT 'Logic App managed identity access granted successfully!';
"@

    # Execute SQL commands
    Write-Host "Executing SQL commands..." -ForegroundColor Yellow
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseName -AccessToken $token -Query $sqlCommands -Verbose
    
    Write-Host "SUCCESS! Managed identity access granted." -ForegroundColor Green
    
    if ($result) {
        Write-Host "Verification Results:" -ForegroundColor Cyan
        $result | Format-Table -AutoSize
    }
    
}
catch {
    Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please run the SQL script manually in Azure portal Query Editor." -ForegroundColor Yellow
    Write-Host "Script location: Scripts\GrantManagedIdentityAccess.sql" -ForegroundColor Yellow
}

Write-Host "Script completed." -ForegroundColor Green