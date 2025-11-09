# Execute Grant Access Script on Azure SQL
# This script runs the GrantManagedIdentityAccess.sql on Azure SQL database

Write-Host "`n=== Granting Logic App Managed Identity Access ===" -ForegroundColor Cyan
Write-Host "Logic App: ais-training-la" -ForegroundColor Yellow
Write-Host "Database: empdb" -ForegroundColor Yellow
Write-Host "Server: aistrainingserver.database.windows.net" -ForegroundColor Yellow

$serverName = "aistrainingserver.database.windows.net"
$databaseName = "empdb"
$sqlFile = Join-Path $PSScriptRoot "GrantManagedIdentityAccess.sql"

# Check if SQL file exists
if (-not (Test-Path $sqlFile)) {
    Write-Host "✗ SQL file not found: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "`nConnecting to Azure SQL..." -ForegroundColor Cyan

# Get Azure AD access token
Write-Host "Getting Azure AD token..." -ForegroundColor Gray
$token = az account get-access-token --resource https://database.windows.net --query accessToken -o tsv

if (-not $token) {
    Write-Host "✗ Failed to get Azure AD token" -ForegroundColor Red
    Write-Host "Please ensure you're logged in: az login" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Token obtained" -ForegroundColor Green

# Execute SQL script using sqlcmd with Azure AD token
Write-Host "`nExecuting SQL script..." -ForegroundColor Cyan

try {
    # Using Invoke-Sqlcmd with access token
    $result = sqlcmd -S $serverName -d $databaseName -G -i $sqlFile
    
    Write-Host "`n=== Script Output ===" -ForegroundColor Green
    $result | ForEach-Object { Write-Host $_ -ForegroundColor White }
    
    Write-Host "`n✓ Permissions granted successfully!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Test the workflow again from Azure" -ForegroundColor White
    Write-Host "2. The Logic App should now be able to execute usp_Employee_Upsert" -ForegroundColor White
    
} catch {
    Write-Host "`n✗ Error executing SQL script" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host "`nManual steps:" -ForegroundColor Cyan
    Write-Host "1. Open Azure Portal > SQL Database: empdb" -ForegroundColor White
    Write-Host "2. Go to Query Editor and login with Azure AD" -ForegroundColor White
    Write-Host "3. Run the script from: $sqlFile" -ForegroundColor White
}
