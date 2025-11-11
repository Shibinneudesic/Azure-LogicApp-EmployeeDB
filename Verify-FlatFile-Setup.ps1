# ====================================================
# Flat File Processing Setup Verification Script
# ====================================================
# Verifies all components for Assignment 2 are correctly configured
# ====================================================

param(
    [switch]$Detailed
)

$ErrorActionPreference = "Continue"

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  FLAT FILE PROCESSING - SETUP VERIFICATION" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

$config = @{
    ResourceGroup = "AIS_Training_Shibin"
    LogicAppName = "ais-training-la"
    ServiceBusNamespace = "sb-flatfile-processing"
    StorageAccount = "aistrainingshibinbf12"
    GatewayName = "AIS-Training-Standard-Gateway"
}

$allGood = $true

# ===================================================================
# 1. CHECK LOCAL WORKFLOW FILES
# ===================================================================
Write-Host "[1] Checking Local Workflow Files..." -ForegroundColor Yellow
Write-Host ""

$workflows = @(
    @{Name="wf-flatfile-pickup"; Description="File System Pickup Workflow"},
    @{Name="wf-flatfile-transformation"; Description="Service Bus Transformation Workflow"}
)

foreach ($wf in $workflows) {
    $path = ".\$($wf.Name)\workflow.json"
    if (Test-Path $path) {
        $content = Get-Content $path -Raw | ConvertFrom-Json
        $triggerType = $content.definition.triggers.PSObject.Properties.Value[0].'$type' -replace 'Microsoft\.Logic\.', ''
        Write-Host "  ✅ $($wf.Name)" -ForegroundColor Green
        Write-Host "     Description: $($wf.Description)" -ForegroundColor Gray
        Write-Host "     Trigger: $triggerType" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ $($wf.Name) - NOT FOUND" -ForegroundColor Red
        $allGood = $false
    }
}
Write-Host ""

# ===================================================================
# 2. CHECK TRANSFORMATION MAPS
# ===================================================================
Write-Host "[2] Checking Transformation Maps..." -ForegroundColor Yellow
Write-Host ""

$maps = @(
    @{Name="EmployeeCSVToXML.xslt"; Type="XSLT"},
    @{Name="EmployeeCSVToJSON.liquid"; Type="Liquid"}
)

foreach ($map in $maps) {
    $path = ".\Artifacts\Maps\$($map.Name)"
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        Write-Host "  ✅ $($map.Name) ($($map.Type))" -ForegroundColor Green
        Write-Host "     Size: $size bytes" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ $($map.Name) - NOT FOUND" -ForegroundColor Red
        $allGood = $false
    }
}
Write-Host ""

# ===================================================================
# 3. CHECK SAMPLE CSV FILE
# ===================================================================
Write-Host "[3] Checking Sample CSV File..." -ForegroundColor Yellow
Write-Host ""

$csvPath = ".\Artifacts\employees.csv"
if (Test-Path $csvPath) {
    $lines = (Get-Content $csvPath).Count
    Write-Host "  ✅ employees.csv" -ForegroundColor Green
    Write-Host "     Lines: $lines (including header)" -ForegroundColor Gray
} else {
    Write-Host "  ❌ employees.csv - NOT FOUND" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# ===================================================================
# 4. CHECK AZURE SERVICE BUS
# ===================================================================
Write-Host "[4] Checking Azure Service Bus..." -ForegroundColor Yellow
Write-Host ""

try {
    $sbNamespace = az servicebus namespace show `
        --name $config.ServiceBusNamespace `
        --resource-group $config.ResourceGroup 2>&1 | ConvertFrom-Json
    
    Write-Host "  ✅ Service Bus Namespace: $($sbNamespace.name)" -ForegroundColor Green
    Write-Host "     Status: $($sbNamespace.status)" -ForegroundColor Gray
    Write-Host "     Location: $($sbNamespace.location)" -ForegroundColor Gray
    Write-Host ""
    
    # Check queues
    $queues = az servicebus queue list `
        --namespace-name $config.ServiceBusNamespace `
        --resource-group $config.ResourceGroup 2>&1 | ConvertFrom-Json
    
    $expectedQueues = @("flatfile-processing-queue", "flatfile-deadletter-queue")
    foreach ($expectedQueue in $expectedQueues) {
        $queue = $queues | Where-Object { $_.name -eq $expectedQueue }
        if ($queue) {
            Write-Host "  ✅ Queue: $expectedQueue" -ForegroundColor Green
            Write-Host "     Message Count: $($queue.messageCount)" -ForegroundColor Gray
            Write-Host "     Status: $($queue.status)" -ForegroundColor Gray
        } else {
            Write-Host "  ❌ Queue: $expectedQueue - NOT FOUND" -ForegroundColor Red
            $allGood = $false
        }
    }
} catch {
    Write-Host "  ❌ Service Bus check failed: $_" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# ===================================================================
# 5. CHECK AZURE STORAGE QUEUES
# ===================================================================
Write-Host "[5] Checking Azure Storage Queues..." -ForegroundColor Yellow
Write-Host ""

try {
    $storageQueues = az storage queue list `
        --account-name $config.StorageAccount `
        --auth-mode login 2>&1 | ConvertFrom-Json
    
    $expectedStorageQueues = @("flatfile-xml-queue", "flatfile-json-queue")
    foreach ($expectedQueue in $expectedStorageQueues) {
        $queue = $storageQueues | Where-Object { $_.name -eq $expectedQueue }
        if ($queue) {
            Write-Host "  ✅ Storage Queue: $expectedQueue" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Storage Queue: $expectedQueue - NOT FOUND" -ForegroundColor Red
            $allGood = $false
        }
    }
} catch {
    Write-Host "  ⚠️  Storage Queue check failed (may need authentication)" -ForegroundColor Yellow
    Write-Host "     Run: az login" -ForegroundColor Gray
}
Write-Host ""

# ===================================================================
# 6. CHECK ON-PREMISE DATA GATEWAY
# ===================================================================
Write-Host "[6] Checking On-Premise Data Gateway..." -ForegroundColor Yellow
Write-Host ""

try {
    $gateway = az resource show `
        --resource-group $config.ResourceGroup `
        --name $config.GatewayName `
        --resource-type "Microsoft.Web/connectionGateways" 2>&1 | ConvertFrom-Json
    
    Write-Host "  ✅ Gateway: $($gateway.name)" -ForegroundColor Green
    Write-Host "     Location: $($gateway.location)" -ForegroundColor Gray
    Write-Host "     Status: $($gateway.properties.provisioningState)" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ Gateway check failed: $_" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# ===================================================================
# 7. CHECK LOGIC APP
# ===================================================================
Write-Host "[7] Checking Logic App..." -ForegroundColor Yellow
Write-Host ""

try {
    $logicApp = az logicapp show `
        --name $config.LogicAppName `
        --resource-group $config.ResourceGroup 2>&1 | ConvertFrom-Json
    
    Write-Host "  ✅ Logic App: $($logicApp.name)" -ForegroundColor Green
    Write-Host "     State: $($logicApp.state)" -ForegroundColor Gray
    Write-Host "     Location: $($logicApp.location)" -ForegroundColor Gray
    
    # Check managed identity
    if ($logicApp.identity) {
        Write-Host "     Managed Identity: Enabled" -ForegroundColor Gray
        Write-Host "     Principal ID: $($logicApp.identity.principalId)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ❌ Logic App check failed: $_" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# ===================================================================
# 8. CHECK CONNECTIONS
# ===================================================================
Write-Host "[8] Checking connections.json Configuration..." -ForegroundColor Yellow
Write-Host ""

if (Test-Path ".\connections.json") {
    $connections = Get-Content ".\connections.json" -Raw | ConvertFrom-Json
    
    $expectedConnections = @("sql", "serviceBus", "FileSystem", "azureloganalyticsdatacollector")
    foreach ($connName in $expectedConnections) {
        if ($connections.serviceProviderConnections.$connName) {
            Write-Host "  ✅ Connection: $connName" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Connection: $connName - NOT CONFIGURED" -ForegroundColor Yellow
        }
    }
    
    # Check Azure Queues managed API connection
    if ($connections.managedApiConnections.azurequeues) {
        Write-Host "  ✅ Managed API Connection: azurequeues" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Managed API Connection: azurequeues - NOT CONFIGURED" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ❌ connections.json - NOT FOUND" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# ===================================================================
# 9. CHECK FILE SERVER DIRECTORY
# ===================================================================
Write-Host "[9] Checking File Server Directory..." -ForegroundColor Yellow
Write-Host ""

$fileServerPath = "C:\EmployeeFiles"
if (Test-Path $fileServerPath) {
    $fileCount = (Get-ChildItem $fileServerPath -Filter "*.csv").Count
    Write-Host "  ✅ Directory: $fileServerPath" -ForegroundColor Green
    Write-Host "     CSV Files: $fileCount" -ForegroundColor Gray
} else {
    Write-Host "  ⚠️  Directory: $fileServerPath - NOT FOUND" -ForegroundColor Yellow
    Write-Host "     Run: .\Setup-FileServerDirectory.ps1" -ForegroundColor Gray
}
Write-Host ""

# ===================================================================
# SUMMARY
# ===================================================================
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

if ($allGood) {
    Write-Host "✅ ALL CHECKS PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your flat file processing workflows are ready!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Deploy workflows to Azure:" -ForegroundColor White
    Write-Host "     func azure functionapp publish $($config.LogicAppName)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Test the end-to-end flow:" -ForegroundColor White
    Write-Host "     .\Test-FlatFileAzure-EndToEnd.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Or test with simple script:" -ForegroundColor White
    Write-Host "     .\Test-FlatFile-Simple.ps1" -ForegroundColor Gray
} else {
    Write-Host "⚠️  SOME CHECKS FAILED" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please review the errors above and fix them." -ForegroundColor White
    Write-Host ""
    Write-Host "Common Solutions:" -ForegroundColor Yellow
    Write-Host "  • Run: az login (for authentication)" -ForegroundColor White
    Write-Host "  • Restore workflows: git checkout b3ac23d -- wf-flatfile-*/" -ForegroundColor White
    Write-Host "  • Create file directory: .\Setup-FileServerDirectory.ps1" -ForegroundColor White
}
Write-Host ""

# ===================================================================
# ARCHITECTURE DIAGRAM
# ===================================================================
if ($Detailed) {
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "  ARCHITECTURE" -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host @"
┌─────────────────────────────────────────────────────────────┐
│                    FLAT FILE PROCESSING                     │
│                   ASYNCHRONOUS WORKFLOW                     │
└─────────────────────────────────────────────────────────────┘

  ┌──────────────────┐
  │  File Server     │
  │  C:\EmployeeFiles│
  │  (employees.csv) │
  └────────┬─────────┘
           │
           │ On-Premise Gateway
           │ ($($config.GatewayName))
           ▼
  ┌─────────────────────────────────────────────┐
  │  WORKFLOW 1: wf-flatfile-pickup             │
  │  ─────────────────────────────────────────  │
  │  Trigger: File System (when CSV created)    │
  │  Actions:                                   │
  │    1. Get file content                      │
  │    2. Validate file size (1B - 10MB)        │
  │    3. Send to Service Bus queue             │
  │  Error Handling:                            │
  │    • Try/Catch Scopes                       │
  │    • Dead-letter queue for failures         │
  └────────┬────────────────────────────────────┘
           │
           ▼
  ┌─────────────────┐
  │  Service Bus    │
  │  Namespace      │
  │  • flatfile-processing-queue                │
  │  • flatfile-deadletter-queue                │
  └────────┬────────┘
           │
           │ Message Trigger
           ▼
  ┌─────────────────────────────────────────────┐
  │  WORKFLOW 2: wf-flatfile-transformation     │
  │  ─────────────────────────────────────────  │
  │  Trigger: Service Bus queue message         │
  │  Actions:                                   │
  │    1. Parse CSV content                     │
  │    2. PARALLEL TRANSFORMATION:              │
  │       ├─ XSLT → XML                         │
  │       └─ Liquid → JSON                      │
  │    3. Send to Storage Queues                │
  │    4. Complete Service Bus message          │
  │  Error Handling:                            │
  │    • Try/Catch per transformation           │
  │    • Dead-letter failed messages            │
  └────────┬────────────────────────────────────┘
           │
           ├──────────────────┬─────────────────┐
           ▼                  ▼                 ▼
  ┌─────────────┐   ┌─────────────┐   ┌────────────┐
  │ Storage     │   │ Storage     │   │ Service    │
  │ Queue (XML) │   │ Queue (JSON)│   │ Bus        │
  │ flatfile-   │   │ flatfile-   │   │ (Complete) │
  │ xml-queue   │   │ json-queue  │   └────────────┘
  └─────────────┘   └─────────────┘

KEY FEATURES:
✅ Asynchronous processing (decoupled workflows)
✅ File system monitoring with on-premise gateway
✅ Service Bus queue for reliable messaging
✅ Parallel transformations (XSLT + Liquid)
✅ Comprehensive error handling
✅ Dead-letter queues for failed messages
✅ Correlation ID tracking across workflows
"@ -ForegroundColor White
    Write-Host ""
}

Write-Host "Run with -Detailed flag to see architecture diagram" -ForegroundColor Gray
Write-Host ""
