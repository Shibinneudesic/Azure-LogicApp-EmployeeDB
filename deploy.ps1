# Deploy Logic App Infrastructure with Policy Compliance
# This script deploys the Logic App and required resources to the existing resource group

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "AIS_Training_Shibin",
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "cbb1dbec-731f-4479-a084-bdaec5e54fd4",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "Canada Central"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting Logic App Infrastructure Deployment..." -ForegroundColor Green

try {
    # Set the subscription context
    Write-Host "Setting subscription context..." -ForegroundColor Yellow
    az account set --subscription $SubscriptionId
    
    # Verify the resource group exists and has the required tags
    Write-Host "Verifying resource group and tags..." -ForegroundColor Yellow
    $rgInfo = az group show --name $ResourceGroupName --query "{name:name, tags:tags}" --output json | ConvertFrom-Json
    
    if (-not $rgInfo) {
        throw "Resource group '$ResourceGroupName' not found!"
    }
    
    if (-not $rgInfo.tags.Owner -or $rgInfo.tags.Owner -notlike "*neudesic.com*") {
        throw "Resource group '$ResourceGroupName' missing required Owner tag with Neudesic.com email!"
    }
    
    Write-Host "Resource group verified with Owner tag: $($rgInfo.tags.Owner)" -ForegroundColor Green
    
    # Deploy the Bicep template
    Write-Host "Deploying infrastructure..." -ForegroundColor Yellow
    $deploymentName = "logic-app-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "infra/main.bicep" `
        --parameters "infra/main.parameters.json" `
        --name $deploymentName `
        --verbose
    
    if ($LASTEXITCODE -ne 0) {
        throw "Deployment failed with exit code $LASTEXITCODE"
    }
    
    # Get deployment outputs
    Write-Host "Getting deployment outputs..." -ForegroundColor Yellow
    $outputs = az deployment group show `
        --resource-group $ResourceGroupName `
        --name $deploymentName `
        --query "properties.outputs" `
        --output json | ConvertFrom-Json
    
    Write-Host "Deployment completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Deployment Summary:" -ForegroundColor Cyan
    Write-Host "  Logic App Name: $($outputs.logicAppName.value)" -ForegroundColor White
    Write-Host "  Logic App URL: $($outputs.logicAppUrl.value)" -ForegroundColor White
    Write-Host "  Storage Account: $($outputs.storageAccountName.value)" -ForegroundColor White
    Write-Host "  App Service Plan: $($outputs.appServicePlanName.value)" -ForegroundColor White
    Write-Host "  Resource Group: $($outputs.resourceGroupName.value)" -ForegroundColor White
    Write-Host ""
    Write-Host "Azure Portal Link:" -ForegroundColor Cyan
    Write-Host "  https://portal.azure.com/#@neudesic.onmicrosoft.com/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/overview" -ForegroundColor Blue
    
}
catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Deployment completed successfully!" -ForegroundColor Green