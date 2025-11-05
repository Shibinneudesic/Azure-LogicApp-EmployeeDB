# Employee Upsert Logic App - Deployment Guide

## Overview
This document provides comprehensive instructions for deploying the Employee Upsert Logic App from local development to Azure production environment.

## Prerequisites

### Local Development
- Visual Studio Code with Azure Logic Apps (Standard) extension
- SQL Server Management Studio or Azure Data Studio
- Postman for API testing
- LocalDB SQL Server Express (for local development)

### Azure Deployment
- Azure subscription with appropriate permissions
- Azure CLI installed and configured
- PowerShell 5.1 or later
- .NET 6.0 or later SDK

## Local Development Setup

### 1. Database Setup
```sql
-- Run the LocalDB script to create the database
sqlcmd -S "(localdb)\MSSQLLocalDB" -i "Scripts\CreateEmployeeTable_LocalDB.sql"
```

### 2. Start the Logic App Locally
```powershell
# Navigate to the project directory
cd "c:\Repo\AITTrainings\LogicApps\UpsertEmployee\UpsertEmployee"

# Start the Logic App locally
func host start
```

### 3. Test Locally
- Import the Postman collection: `Postman\EmployeeUpsert_TestCollection.json`
- Update the `logicAppUrl` variable with your local endpoint
- Run the test scenarios

## Azure Deployment

### Phase 1: Create Azure Resources

#### 1. Create Resource Group
```powershell
# Set variables
$resourceGroupName = "rg-employee-upsert-prod"
$location = "East US"
$appName = "logicapp-employee-upsert"
$sqlServerName = "sql-employee-upsert-prod"
$sqlDatabaseName = "EmployeeDB"
$logAnalyticsName = "log-employee-upsert-prod"

# Create resource group
az group create --name $resourceGroupName --location $location
```

#### 2. Create Azure SQL Database
```powershell
# Create SQL Server
az sql server create --name $sqlServerName --resource-group $resourceGroupName --location $location --admin-user sqladmin --admin-password "ComplexPassword123!"

# Create SQL Database
az sql db create --resource-group $resourceGroupName --server $sqlServerName --name $sqlDatabaseName --service-objective Basic

# Configure firewall rule for Azure services
az sql server firewall-rule create --resource-group $resourceGroupName --server $sqlServerName --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
```

#### 3. Create Log Analytics Workspace
```powershell
# Create Log Analytics workspace
az monitor log-analytics workspace create --resource-group $resourceGroupName --workspace-name $logAnalyticsName --location $location
```

#### 4. Create Logic App
```powershell
# Create storage account for Logic App
$storageAccountName = "stemployeeupsert$(Get-Random)"
az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS

# Create App Service Plan
$appServicePlanName = "asp-employee-upsert-prod"
az appservice plan create --name $appServicePlanName --resource-group $resourceGroupName --location $location --sku WS1 --is-linux

# Create Logic App
az logicapp create --name $appName --resource-group $resourceGroupName --plan $appServicePlanName --storage-account $storageAccountName
```

### Phase 2: Configure Database

#### 1. Run Azure SQL Database Setup
```sql
-- Connect to Azure SQL Database and run:
-- Scripts\CreateEmployeeTable.sql
-- Remember to update the connection string in the script
```

#### 2. Configure Managed Identity for SQL Access
```powershell
# Enable system-assigned managed identity for Logic App
az logicapp identity assign --name $appName --resource-group $resourceGroupName

# Get the principal ID
$principalId = az logicapp identity show --name $appName --resource-group $resourceGroupName --query principalId --output tsv

# Grant SQL access to managed identity (run this in SQL Server Management Studio)
# CREATE USER [logicapp-employee-upsert] FROM EXTERNAL PROVIDER;
# ALTER ROLE db_datareader ADD MEMBER [logicapp-employee-upsert];
# ALTER ROLE db_datawriter ADD MEMBER [logicapp-employee-upsert];
# GRANT EXECUTE ON dbo.UpsertEmployee TO [logicapp-employee-upsert];
```

### Phase 3: Deploy Logic App Code

#### 1. Update Configuration for Production
Update the following files for production deployment:

**connections.json**
```json
{
  "managedApiConnections": {},
  "serviceProviderConnections": {
    "sql": {
      "parameterValues": {
        "server": "sql-employee-upsert-prod.database.windows.net",
        "database": "EmployeeDB",
        "authType": "managedIdentity"
      },
      "serviceProvider": {
        "id": "/serviceProviders/sql"
      },
      "displayName": "sql"
    }
  }
}
```

#### 2. Deploy the Logic App
```powershell
# Build and deploy
func azure functionapp publish $appName --force
```

### Phase 4: Configure Application Settings

```powershell
# Configure application settings
az logicapp config appsettings set --name $appName --resource-group $resourceGroupName --settings @"
[
  {
    "name": "WORKFLOWS_SUBSCRIPTION_ID",
    "value": "$(az account show --query id --output tsv)"
  },
  {
    "name": "WORKFLOWS_RESOURCE_GROUP_NAME",
    "value": "$resourceGroupName"
  },
  {
    "name": "WORKFLOWS_LOCATION_NAME",
    "value": "$location"
  }
]
"@
```

## Testing in Production

### 1. Get the Logic App Trigger URL
```powershell
# Get the callback URL
$triggerUrl = az logicapp show --name $appName --resource-group $resourceGroupName --query "defaultWebsiteUrl" --output tsv
Write-Host "Logic App URL: $triggerUrl"
```

### 2. Update Postman Collection
- Update the `logicAppUrl` variable in Postman with the production URL
- Run the test scenarios to validate the deployment

## Monitoring and Logging

### 1. Configure Application Insights
```powershell
# Create Application Insights
$appInsightsName = "ai-employee-upsert-prod"
az monitor app-insights component create --app $appInsightsName --location $location --resource-group $resourceGroupName

# Link to Logic App
$appInsightsKey = az monitor app-insights component show --app $appInsightsName --resource-group $resourceGroupName --query instrumentationKey --output tsv
az logicapp config appsettings set --name $appName --resource-group $resourceGroupName --settings APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey
```

### 2. Monitor Workflow Runs
- Use Azure Portal to monitor Logic App runs
- Check Application Insights for detailed telemetry
- Review SQL Database query performance

## Security Considerations

### 1. Network Security
```powershell
# Restrict Logic App access to specific IPs (optional)
az logicapp config access-restriction add --name $appName --resource-group $resourceGroupName --ip-address "YOUR_IP_ADDRESS" --priority 100

# Configure SQL Database firewall rules
az sql server firewall-rule create --resource-group $resourceGroupName --server $sqlServerName --name "ClientIPRange" --start-ip-address "YOUR_START_IP" --end-ip-address "YOUR_END_IP"
```

### 2. Data Protection
- Enable Azure SQL Database encryption at rest (enabled by default)
- Configure backup retention policies
- Enable auditing and threat detection

## Backup and Disaster Recovery

### 1. Database Backup
```powershell
# Configure automated backups
az sql db update --name $sqlDatabaseName --resource-group $resourceGroupName --server $sqlServerName --backup-retention 7
```

### 2. Logic App Backup
- Export Logic App definition regularly
- Store in source control (GitHub/Azure DevOps)
- Document configuration settings

## Troubleshooting

### Common Issues
1. **Connection failures**: Check managed identity permissions
2. **SQL timeouts**: Review query performance and indexing
3. **Logic App errors**: Check Application Insights logs
4. **Authentication issues**: Verify managed identity configuration

### Diagnostic Commands
```powershell
# Check Logic App status
az logicapp show --name $appName --resource-group $resourceGroupName --query "state"

# View recent logs
az logicapp log download --name $appName --resource-group $resourceGroupName

# Test SQL connectivity
az sql db show-connection-string --server $sqlServerName --name $sqlDatabaseName --client ado.net
```

## Cost Optimization

### 1. SQL Database
- Use Basic tier for development/testing
- Scale up to Standard/Premium for production based on performance requirements
- Monitor DTU usage and scale accordingly

### 2. Logic App
- Use Consumption plan for low-volume scenarios
- Use Standard plan for high-volume or complex workflows
- Monitor execution metrics and adjust plan accordingly

## Maintenance

### Regular Tasks
1. Review and update SQL Database maintenance plans
2. Monitor Logic App performance metrics
3. Update dependencies and security patches
4. Review and rotate access keys
5. Validate backup and recovery procedures

### Monthly Reviews
1. Cost analysis and optimization
2. Security audit and compliance check
3. Performance tuning and optimization
4. Documentation updates

---

## Support and Contact

For technical support or questions:
- Create support tickets in Azure Portal
- Review Azure Logic Apps documentation
- Check Azure SQL Database best practices
- Monitor Azure Service Health for service updates