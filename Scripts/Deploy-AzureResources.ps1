# Azure Resource Deployment Script
# This script creates all required Azure resources for the Employee Upsert Logic App

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-employee-upsert-prod",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "prod"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-ColorOutput Green "=== Azure Employee Upsert Logic App Deployment ==="
Write-Host ""

# Set subscription context
Write-ColorOutput Yellow "Setting subscription context..."
az account set --subscription $SubscriptionId

# Generate unique names
$timestamp = Get-Date -Format "yyyyMMddHHmm"
$uniqueId = $timestamp.Substring($timestamp.Length - 6)

$appName = "logicapp-employee-upsert-$Environment-$uniqueId"
$sqlServerName = "sql-employee-upsert-$Environment-$uniqueId"
$sqlDatabaseName = "EmployeeDB"
$logAnalyticsName = "log-employee-upsert-$Environment-$uniqueId"
$storageAccountName = "stempupsert$Environment$uniqueId"
$appServicePlanName = "asp-employee-upsert-$Environment-$uniqueId"
$appInsightsName = "ai-employee-upsert-$Environment-$uniqueId"

Write-ColorOutput Cyan "Resource names:"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Logic App: $appName"
Write-Host "SQL Server: $sqlServerName"
Write-Host "SQL Database: $sqlDatabaseName"
Write-Host "Log Analytics: $logAnalyticsName"
Write-Host "Storage Account: $storageAccountName"
Write-Host "App Service Plan: $appServicePlanName"
Write-Host "Application Insights: $appInsightsName"
Write-Host ""

# Create resource group
Write-ColorOutput Yellow "Creating resource group..."
try {
    az group create --name $ResourceGroupName --location $Location --output table
    Write-ColorOutput Green "✓ Resource group created successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to create resource group: $_"
    exit 1
}

# Create storage account
Write-ColorOutput Yellow "Creating storage account..."
try {
    az storage account create `
        --name $storageAccountName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --output table
    Write-ColorOutput Green "✓ Storage account created successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to create storage account: $_"
    exit 1
}

# Create Log Analytics workspace
Write-ColorOutput Yellow "Creating Log Analytics workspace..."
try {
    az monitor log-analytics workspace create `
        --resource-group $ResourceGroupName `
        --workspace-name $logAnalyticsName `
        --location $Location `
        --output table
    Write-ColorOutput Green "✓ Log Analytics workspace created successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to create Log Analytics workspace: $_"
    exit 1
}

# Create Application Insights
Write-ColorOutput Yellow "Creating Application Insights..."
try {
    az monitor app-insights component create `
        --app $appInsightsName `
        --location $Location `
        --resource-group $ResourceGroupName `
        --application-type web `
        --output table
    Write-ColorOutput Green "✓ Application Insights created successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to create Application Insights: $_"
    exit 1
}

# Create SQL Server
Write-ColorOutput Yellow "Creating Azure SQL Server..."
Write-Host "Please enter SQL Server admin password (minimum 8 characters, must contain uppercase, lowercase, numbers, and special characters):"
$sqlAdminPassword = Read-Host -AsSecureString
$sqlAdminPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlAdminPassword))

try {
    az sql server create `
        --name $sqlServerName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --admin-user sqladmin `
        --admin-password $sqlAdminPasswordText `
        --output table
    Write-ColorOutput Green "✓ SQL Server created successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to create SQL Server: $_"
    exit 1
}

# Configure SQL Server firewall
Write-ColorOutput Yellow "Configuring SQL Server firewall..."
try {
    # Allow Azure services
    az sql server firewall-rule create `
        --resource-group $ResourceGroupName `
        --server $sqlServerName `
        --name AllowAzureServices `
        --start-ip-address 0.0.0.0 `
        --end-ip-address 0.0.0.0 `
        --output table
    
    # Get current public IP and allow it
    $currentIP = (Invoke-WebRequest -Uri "https://ipinfo.io/ip" -UseBasicParsing).Content.Trim()
    az sql server firewall-rule create `
        --resource-group $ResourceGroupName `
        --server $sqlServerName `
        --name "ClientIP" `
        --start-ip-address $currentIP `
        --end-ip-address $currentIP `
        --output table
    
    Write-ColorOutput Green "✓ SQL Server firewall configured successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to configure SQL Server firewall: $_"
    exit 1
}

# Create SQL Database
Write-ColorOutput Yellow "Creating Azure SQL Database..."
try {
    az sql db create `
        --resource-group $ResourceGroupName `
        --server $sqlServerName `
        --name $sqlDatabaseName `
        --service-objective Basic `
        --output table
    Write-ColorOutput Green "✓ SQL Database created successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to create SQL Database: $_"
    exit 1
}

# Create App Service Plan
Write-ColorOutput Yellow "Creating App Service Plan..."
try {
    az appservice plan create `
        --name $appServicePlanName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --sku WS1 `
        --is-linux `
        --output table
    Write-ColorOutput Green "✓ App Service Plan created successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to create App Service Plan: $_"
    exit 1
}

# Create Logic App
Write-ColorOutput Yellow "Creating Logic App..."
try {
    az logicapp create `
        --name $appName `
        --resource-group $ResourceGroupName `
        --plan $appServicePlanName `
        --storage-account $storageAccountName `
        --output table
    Write-ColorOutput Green "✓ Logic App created successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to create Logic App: $_"
    exit 1
}

# Enable managed identity
Write-ColorOutput Yellow "Enabling managed identity for Logic App..."
try {
    az logicapp identity assign `
        --name $appName `
        --resource-group $ResourceGroupName `
        --output table
    Write-ColorOutput Green "✓ Managed identity enabled successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to enable managed identity: $_"
    exit 1
}

# Get Application Insights instrumentation key
Write-ColorOutput Yellow "Configuring Application Insights..."
try {
    $appInsightsKey = az monitor app-insights component show `
        --app $appInsightsName `
        --resource-group $ResourceGroupName `
        --query instrumentationKey `
        --output tsv
    
    # Configure Logic App settings
    az logicapp config appsettings set `
        --name $appName `
        --resource-group $ResourceGroupName `
        --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey" `
        "WORKFLOWS_SUBSCRIPTION_ID=$SubscriptionId" `
        "WORKFLOWS_RESOURCE_GROUP_NAME=$ResourceGroupName" `
        "WORKFLOWS_LOCATION_NAME=$Location" `
        --output table
    
    Write-ColorOutput Green "✓ Application Insights configured successfully"
} catch {
    Write-ColorOutput Red "✗ Failed to configure Application Insights: $_"
    exit 1
}

# Get connection strings and important information
Write-ColorOutput Yellow "Retrieving connection information..."

$sqlConnectionString = az sql db show-connection-string `
    --server $sqlServerName `
    --name $sqlDatabaseName `
    --client ado.net `
    --output tsv

$logicAppUrl = az logicapp show `
    --name $appName `
    --resource-group $ResourceGroupName `
    --query "defaultWebsiteUrl" `
    --output tsv

$managedIdentityPrincipalId = az logicapp identity show `
    --name $appName `
    --resource-group $ResourceGroupName `
    --query principalId `
    --output tsv

Write-ColorOutput Green "=== Deployment Completed Successfully ==="
Write-Host ""
Write-ColorOutput Cyan "Important Information:"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Logic App Name: $appName"
Write-Host "Logic App URL: $logicAppUrl"
Write-Host "SQL Server: $sqlServerName.database.windows.net"
Write-Host "SQL Database: $sqlDatabaseName"
Write-Host "SQL Admin User: sqladmin"
Write-Host "Managed Identity Principal ID: $managedIdentityPrincipalId"
Write-Host ""

Write-ColorOutput Yellow "Next Steps:"
Write-Host "1. Run the SQL database setup script against Azure SQL Database"
Write-Host "2. Configure SQL Database permissions for the managed identity"
Write-Host "3. Update connections.json with Azure SQL connection details"
Write-Host "4. Deploy the Logic App code using 'func azure functionapp publish $appName'"
Write-Host "5. Test the Logic App using the provided Postman collection"
Write-Host ""

Write-ColorOutput Cyan "SQL Connection String (update with your password):"
Write-Host $sqlConnectionString
Write-Host ""

Write-ColorOutput Red "Important: Save this information securely!"

# Create output file with all the information
$outputFile = "Azure-Deployment-Info-$timestamp.txt"
@"
Azure Employee Upsert Logic App Deployment Information
Deployment Date: $(Get-Date)
Subscription ID: $SubscriptionId
Resource Group: $ResourceGroupName
Location: $Location

Azure Resources:
- Logic App: $appName
- Logic App URL: $logicAppUrl
- SQL Server: $sqlServerName.database.windows.net
- SQL Database: $sqlDatabaseName
- SQL Admin User: sqladmin
- Storage Account: $storageAccountName
- App Service Plan: $appServicePlanName
- Application Insights: $appInsightsName
- Log Analytics: $logAnalyticsName
- Managed Identity Principal ID: $managedIdentityPrincipalId

SQL Connection String:
$sqlConnectionString

Next Steps:
1. Run the SQL database setup script
2. Configure managed identity permissions
3. Deploy Logic App code
4. Test with Postman collection
"@ | Out-File -FilePath $outputFile -Encoding UTF8

Write-ColorOutput Green "✓ Deployment information saved to: $outputFile"