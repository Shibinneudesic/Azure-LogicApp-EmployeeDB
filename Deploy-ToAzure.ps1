# Deploy Logic App Workflow to Azure
# This script ensures correct configuration and deploys the workflow

param(
    [Parameter(Mandatory=$false)]
    [string]$LogicAppName = "upsert-employee",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "AIS_Training_Shibin",
    
    [Parameter(Mandatory=$false)]
    [string]$SqlServer = "aistrainingserver",
    
    [Parameter(Mandatory=$false)]
    [string]$Database = "empdb"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Logic App Deployment to Azure" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify Azure login
Write-Host "Step 1: Verifying Azure login..." -ForegroundColor Yellow
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✓ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "✓ Subscription: $($account.name)" -ForegroundColor Green
}
catch {
    Write-Host "✗ Not logged into Azure. Please run 'az login'" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Backup current connections
Write-Host "Step 2: Backing up current configuration..." -ForegroundColor Yellow
if (Test-Path "connections.json") {
    Copy-Item "connections.json" "connections.backup-$(Get-Date -Format 'yyyyMMddHHmmss').json" -Force
    Write-Host "✓ Backed up connections.json" -ForegroundColor Green
}
Write-Host ""

# Step 3: Switch to Azure connections
Write-Host "Step 3: Switching to Azure connections..." -ForegroundColor Yellow
if (Test-Path "connections.azure.json") {
    Copy-Item "connections.azure.json" "connections.json" -Force
    Write-Host "✓ Using Azure SQL connection string" -ForegroundColor Green
}
else {
    Write-Host "✗ connections.azure.json not found!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Verify SQL Database is online
Write-Host "Step 4: Verifying Azure SQL Database..." -ForegroundColor Yellow
try {
    $dbStatus = az sql db show --name $Database --resource-group $ResourceGroup --server $SqlServer --query "status" -o tsv
    Write-Host "✓ Database status: $dbStatus" -ForegroundColor Green
    
    if ($dbStatus -eq "Paused") {
        Write-Host "  Database is paused. It will auto-resume on first connection." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "✗ Could not verify database status" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
Write-Host ""

# Step 5: Verify Logic App exists
Write-Host "Step 5: Verifying Logic App..." -ForegroundColor Yellow
try {
    $logicApp = az logicapp show --name $LogicAppName --resource-group $ResourceGroup | ConvertFrom-Json
    Write-Host "✓ Logic App: $($logicApp.name)" -ForegroundColor Green
    Write-Host "✓ State: $($logicApp.state)" -ForegroundColor Green
    Write-Host "✓ URL: https://$($logicApp.defaultHostName)" -ForegroundColor Green
}
catch {
    Write-Host "✗ Logic App not found!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 6: Check workflow configuration
Write-Host "Step 6: Verifying workflow configuration..." -ForegroundColor Yellow
if (Test-Path "UpsertEmployee/workflow.json") {
    $workflow = Get-Content "UpsertEmployee/workflow.json" -Raw
    if ($workflow -match 'EXEC (\w+)\s') {
        Write-Host "✓ Stored Procedure: $($Matches[1])" -ForegroundColor Green
    }
    Write-Host "✓ Workflow file ready" -ForegroundColor Green
}
else {
    Write-Host "✗ Workflow file not found!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 7: Deploy to Azure
Write-Host "Step 7: Deploying Logic App workflow to Azure..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Cyan
Write-Host ""

try {
    func azure functionapp publish $LogicAppName --force
    
    Write-Host ""
    Write-Host "✓ Deployment completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "✗ Deployment failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Logic App URL: https://$($logicApp.defaultHostName)" -ForegroundColor White
Write-Host "Portal Link: https://portal.azure.com/#resource$($logicApp.id)" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait 2-3 minutes for deployment to complete" -ForegroundColor White
Write-Host "2. Verify the stored procedure exists in Azure SQL" -ForegroundColor White
Write-Host "3. Test the workflow using callback URL from Azure Portal" -ForegroundColor White
Write-Host ""

