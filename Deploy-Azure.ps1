# Deploy Logic App to Azure - Complete Deployment Script
# This script deploys infrastructure and the Logic App workflow to Azure

param(
    [string]$ResourceGroupName = "AIS_Training_Shibin",
    [string]$Location = "southindia",
    [string]$SubscriptionName = "Swetha Maram"
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Azure Logic App Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Set Azure Subscription
Write-Host "1. Setting Azure subscription..." -ForegroundColor Yellow
az account set --subscription $SubscriptionName
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to set subscription" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ Subscription set: $SubscriptionName" -ForegroundColor Green

# Step 2: Verify Resource Group
Write-Host "`n2. Verifying resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "   Creating resource group..." -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location --tags Owner=shibin.sam@neudesic.com Environment=dev Project=AIS-Training
    Write-Host "   ✓ Resource group created" -ForegroundColor Green
} else {
    Write-Host "   ✓ Resource group exists: $ResourceGroupName" -ForegroundColor Green
}

# Step 3: Deploy Infrastructure (Bicep)
Write-Host "`n3. Deploying infrastructure (Storage, App Service Plan, Logic App)..." -ForegroundColor Yellow
$deploymentName = "logicapp-deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"

az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --template-file "infra/main.bicep" `
    --parameters "infra/main.parameters.json" `
    --parameters location=$Location `
    --output table

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Infrastructure deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ Infrastructure deployed successfully" -ForegroundColor Green

# Step 4: Get Logic App details
Write-Host "`n4. Retrieving Logic App information..." -ForegroundColor Yellow
$logicAppName = "upsert-employee"
$logicAppInfo = az functionapp show --name $logicAppName --resource-group $ResourceGroupName --query "{name:name, state:state, defaultHostName:defaultHostName}" -o json | ConvertFrom-Json

if ($logicAppInfo) {
    Write-Host "   ✓ Logic App: $($logicAppInfo.name)" -ForegroundColor Green
    Write-Host "   ✓ State: $($logicAppInfo.state)" -ForegroundColor Green
    Write-Host "   ✓ URL: https://$($logicAppInfo.defaultHostName)" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to retrieve Logic App information" -ForegroundColor Red
    exit 1
}

# Step 5: Switch to Azure connections
Write-Host "`n5. Configuring Azure connections..." -ForegroundColor Yellow
if (Test-Path "connections.azure.json") {
    Copy-Item "connections.azure.json" "connections.json" -Force
    Write-Host "   ✓ Switched to Azure SQL connections" -ForegroundColor Green
} else {
    Write-Host "   ! Warning: connections.azure.json not found" -ForegroundColor Yellow
}

# Step 6: Deploy Logic App code and workflows
Write-Host "`n6. Deploying Logic App workflows..." -ForegroundColor Yellow
Write-Host "   Publishing to: $logicAppName" -ForegroundColor Cyan

func azure functionapp publish $logicAppName --force

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Logic App deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ Logic App deployed successfully" -ForegroundColor Green

# Step 7: Wait for deployment to complete
Write-Host "`n7. Waiting for Logic App to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Step 8: Verify deployment
Write-Host "`n8. Verifying deployment..." -ForegroundColor Yellow
$logicAppUrl = "https://$($logicAppInfo.defaultHostName)"
Write-Host "   Logic App URL: $logicAppUrl" -ForegroundColor Cyan

# Step 9: Get workflow callback URL
Write-Host "`n9. Getting workflow callback URL..." -ForegroundColor Yellow
try {
    $callbackUrlCommand = "az rest --method post --uri '/subscriptions/{subscriptionId}/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$logicAppName/hostruntime/runtime/webhooks/workflow/api/management/workflows/UpsertEmployee/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2020-05-01-preview'"
    
    Write-Host "   Note: To get the callback URL, run this command:" -ForegroundColor Yellow
    Write-Host "   $callbackUrlCommand" -ForegroundColor White
    
    Write-Host "`n   Or use the Azure Portal:" -ForegroundColor Yellow
    Write-Host "   1. Go to Logic App Designer" -ForegroundColor White
    Write-Host "   2. Open the workflow" -ForegroundColor White
    Write-Host "   3. Click on the HTTP trigger to see the URL" -ForegroundColor White
} catch {
    Write-Host "   ! Could not retrieve callback URL automatically" -ForegroundColor Yellow
}

# Step 10: Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✅ DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nDeployment Summary:" -ForegroundColor Cyan
Write-Host "  • Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  • Location: $Location" -ForegroundColor White
Write-Host "  • Logic App Name: $logicAppName" -ForegroundColor White
Write-Host "  • Logic App URL: $logicAppUrl" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Open Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "  2. Navigate to Logic App: $logicAppName" -ForegroundColor White
Write-Host "  3. Go to Workflows -> UpsertEmployee" -ForegroundColor White
Write-Host "  4. Get the HTTP trigger URL from the designer" -ForegroundColor White
Write-Host "  5. Test the workflow with Postman or curl" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Cyan
