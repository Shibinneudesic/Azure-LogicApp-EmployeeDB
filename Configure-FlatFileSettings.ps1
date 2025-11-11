# Configure Azure Logic App Settings for Flat File Processing
# Run this script to set up all required application settings

$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "ais-training-la"
# Get Service Bus connection string from Azure (recommended) or set manually
$serviceBusConnectionString = Read-Host "Enter Service Bus Connection String (or press Enter to retrieve from Azure)"
if ([string]::IsNullOrWhiteSpace($serviceBusConnectionString)) {
    Write-Host "Retrieving Service Bus connection string from Azure..." -ForegroundColor Gray
    $serviceBusConnectionString = az servicebus namespace authorization-rule keys list `
        --resource-group $resourceGroup `
        --namespace-name "sb-flatfile-processing" `
        --name "RootManageSharedAccessKey" `
        --query primaryConnectionString `
        --output tsv
}
$storageAccountName = "aistrainingshibinbf12"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Configuring Logic App Settings" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Prompt for file server credentials
Write-Host "Enter File Server Credentials:" -ForegroundColor Yellow
Write-Host "(The account that has access to C:\EmployeeFiles)" -ForegroundColor Gray
Write-Host ""

$username = Read-Host "Username (e.g., SERVERNAME\username or domain\username)"
$password = Read-Host "Password" -AsSecureString
$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

Write-Host "`nConfiguring application settings..." -ForegroundColor Yellow

# Get storage account connection string
Write-Host "Getting storage account connection string..." -ForegroundColor Gray
$storageConnectionString = az storage account show-connection-string `
  --name $storageAccountName `
  --resource-group $resourceGroup `
  --query connectionString `
  --output tsv

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get storage connection string" -ForegroundColor Red
    exit 1
}

# Set application settings
Write-Host "Setting Logic App application settings..." -ForegroundColor Gray
az logicapp config appsettings set `
  --name $logicAppName `
  --resource-group $resourceGroup `
  --settings `
    SERVICE_BUS_CONNECTION_STRING="$serviceBusConnectionString" `
    STORAGE_ACCOUNT_CONNECTION_STRING="$storageConnectionString" `
    ONPREMISE_FILE_USERNAME="$username" `
    ONPREMISE_FILE_PASSWORD="$passwordPlain"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Application settings configured successfully!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Failed to configure application settings" -ForegroundColor Red
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Service Bus: sb-flatfile-processing" -ForegroundColor White
Write-Host "Storage Account: $storageAccountName" -ForegroundColor White
Write-Host "Gateway: AIS-Training-Standard-Gateway" -ForegroundColor White
Write-Host "File Server User: $username" -ForegroundColor White
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Deploy the Logic App workflows" -ForegroundColor White
Write-Host "2. Grant Managed Identity permissions to resources" -ForegroundColor White
Write-Host "3. Test the workflows" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan
