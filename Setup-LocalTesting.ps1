# Local Testing Setup for Flat File Workflows
# This script sets up the local environment for testing

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Flat File Workflows - Local Setup" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$serviceBusNamespace = "sb-flatfile-processing"
$resourceGroup = "AIS_Training_Shibin"

Write-Host "[Step 1] Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

# Check if Azurite is running
$azurite = Get-Process -Name "Azurite" -ErrorAction SilentlyContinue
if ($azurite) {
    Write-Host "  ✓ Azurite is running" -ForegroundColor Green
}
else {
    Write-Host "  ✗ Azurite is NOT running" -ForegroundColor Red
    Write-Host "    Start Azurite with: azurite --silent --location . --debug azurite.log" -ForegroundColor Yellow
    Write-Host ""
    $response = Read-Host "Start Azurite now? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Start-Process -FilePath "azurite" -ArgumentList "--silent","--location",".","--debug","azurite.log" -WindowStyle Hidden
        Write-Host "  ✓ Azurite started" -ForegroundColor Green
        Start-Sleep -Seconds 3
    }
}

Write-Host ""
Write-Host "[Step 2] Getting Service Bus connection string..." -ForegroundColor Yellow
Write-Host ""

try {
    # Get Service Bus connection string
    $connectionString = az servicebus namespace authorization-rule keys list `
        --resource-group $resourceGroup `
        --namespace-name $serviceBusNamespace `
        --name RootManageSharedAccessKey `
        --query primaryConnectionString `
        --output tsv 2>$null
    
    if ($connectionString) {
        Write-Host "  ✓ Service Bus connection string retrieved" -ForegroundColor Green
        
        # Update local.settings.json
        $settingsPath = ".\local.settings.json"
        $settings = Get-Content $settingsPath | ConvertFrom-Json
        
        # Add Service Bus connection string
        $settings.Values | Add-Member -MemberType NoteProperty -Name "SERVICE_BUS_CONNECTION_STRING" -Value $connectionString -Force
        
        # Add file system credentials (for local testing without gateway)
        $settings.Values | Add-Member -MemberType NoteProperty -Name "ONPREMISE_FILE_USERNAME" -Value "" -Force
        $settings.Values | Add-Member -MemberType NoteProperty -Name "ONPREMISE_FILE_PASSWORD" -Value "" -Force
        
        # Save settings
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
        
        Write-Host "  ✓ local.settings.json updated" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Could not retrieve connection string" -ForegroundColor Red
    }
}
catch {
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "[Step 3] Creating local connections configuration..." -ForegroundColor Yellow
Write-Host ""

# Create connections.local.json for local testing
$localConnections = @{
    managedApiConnections = @{}
    serviceProviderConnections = @{
        serviceBus = @{
            parameterValues = @{
                connectionString = "@appsetting('SERVICE_BUS_CONNECTION_STRING')"
            }
            serviceProvider = @{
                id = "/serviceProviders/serviceBus"
            }
            displayName = "serviceBus"
        }
        FileSystem = @{
            parameterValues = @{
                basePath = "C:"
                username = ""
                password = ""
            }
            serviceProvider = @{
                id = "/serviceProviders/FileSystem"
            }
            displayName = "FileSystem"
        }
        AzureBlob = @{
            parameterValues = @{
                connectionString = "UseDevelopmentStorage=true"
            }
            serviceProvider = @{
                id = "/serviceProviders/AzureBlob"
            }
            displayName = "AzureBlob"
        }
    }
}

$localConnections | ConvertTo-Json -Depth 10 | Set-Content ".\connections.local.json"
Write-Host "  ✓ connections.local.json created" -ForegroundColor Green

Write-Host ""
Write-Host "[Step 4] Creating storage queues in Azurite..." -ForegroundColor Yellow
Write-Host ""

$storageAccount = "devstoreaccount1"
$queueEndpoint = "http://127.0.0.1:10001/$storageAccount"
$queues = @("flatfile-xml-queue", "flatfile-json-queue")

foreach ($queueName in $queues) {
    $uri = "$queueEndpoint/$queueName"
    try {
        $response = Invoke-WebRequest -Uri $uri -Method PUT -Headers @{
            "x-ms-version" = "2021-08-06"
        } -ErrorAction SilentlyContinue
        Write-Host "  ✓ Created queue: $queueName" -ForegroundColor Green
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 409) {
            Write-Host "  ✓ Queue already exists: $queueName" -ForegroundColor Green
        }
        else {
            Write-Host "  ⚠ Could not create queue: $queueName" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "[Step 5] Creating test file directory..." -ForegroundColor Yellow
Write-Host ""

$testDir = "C:\EmployeeFiles"
if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    Write-Host "  ✓ Created directory: $testDir" -ForegroundColor Green
}
else {
    Write-Host "  ✓ Directory exists: $testDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Stop the current func host (if running)" -ForegroundColor White
Write-Host "2. Restart func host: func start" -ForegroundColor White
Write-Host "3. Run the local test: .\Test-FlatFile-Local.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Note: For Workflow 1 (file pickup), the FileSystem connector" -ForegroundColor Cyan
Write-Host "will work locally without a gateway for local file paths" -ForegroundColor Cyan
Write-Host ""
