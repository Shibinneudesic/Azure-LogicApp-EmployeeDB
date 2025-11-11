# Diagnostic Script for Flat File Processing Workflows
# This script checks the health and configuration of the flat file workflows

param(
    [switch]$EnableWorkflows,
    [switch]$RestartLogicApp
)

$ErrorActionPreference = "Continue"

# Configuration
$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "ais-training-la"
$subscriptionId = "cbb1dbec-731f-4479-a084-bdaec5e54fd4"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Flat File Workflows Diagnostic" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Function: Check Workflow State
function Check-WorkflowState {
    param($workflowName)
    
    Write-Host "Checking workflow: $workflowName" -ForegroundColor Yellow
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows/$workflowName`?api-version=2022-03-01"
    
    try {
        $result = az rest --method GET --uri $uri --output json 2>$null | ConvertFrom-Json
        
        Write-Host "  Name: $($result.name)" -ForegroundColor Gray
        Write-Host "  State: $($result.properties.state)" -ForegroundColor $(if($result.properties.state -eq 'Enabled'){"Green"}elseif($result.properties.state -eq 'Disabled'){"Red"}else{"Yellow"})
        Write-Host "  Health: $($result.properties.health.state)" -ForegroundColor $(if($result.properties.health.state -eq 'Healthy'){"Green"}else{"Red"})
        
        if ($result.properties.health.error) {
            Write-Host "  Error: $($result.properties.health.error.message)" -ForegroundColor Red
        }
        
        return $result
    }
    catch {
        Write-Host "  Failed to get workflow state: $_" -ForegroundColor Red
        return $null
    }
}

# Function: Enable Workflow
function Enable-Workflow {
    param($workflowName)
    
    Write-Host "Enabling workflow: $workflowName" -ForegroundColor Yellow
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows/$workflowName`?api-version=2022-03-01"
    
    $body = @{
        properties = @{
            state = "Enabled"
        }
    } | ConvertTo-Json
    
    try {
        az rest --method PATCH --uri $uri --body $body --output none 2>$null
        Write-Host "  Workflow enabled successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to enable workflow: $_" -ForegroundColor Red
    }
}

# Function: Check Recent Runs
function Check-RecentRuns {
    param($workflowName)
    
    Write-Host "Checking recent runs for: $workflowName" -ForegroundColor Yellow
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows/$workflowName/runs`?api-version=2022-03-01"
    
    try {
        $result = az rest --method GET --uri $uri --query "value[0:3]" --output json 2>$null | ConvertFrom-Json
        
        if ($result -and $result.Count -gt 0) {
            Write-Host "  Found $($result.Count) recent runs:" -ForegroundColor Gray
            
            foreach ($run in $result) {
                $statusColor = switch ($run.properties.status) {
                    "Succeeded" { "Green" }
                    "Failed" { "Red" }
                    "Running" { "Yellow" }
                    default { "Gray" }
                }
                
                Write-Host "    Run: $($run.name.Split('/')[-1])" -ForegroundColor Gray
                Write-Host "    Status: $($run.properties.status)" -ForegroundColor $statusColor
                Write-Host "    Start Time: $($run.properties.startTime)" -ForegroundColor Gray
                
                if ($run.properties.error) {
                    Write-Host "    Error: $($run.properties.error.message)" -ForegroundColor Red
                }
                Write-Host ""
            }
        }
        else {
            Write-Host "  No runs found" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "  Failed to get runs: $_" -ForegroundColor Red
    }
}

# Function: Check Gateway Connection
function Check-GatewayConnection {
    Write-Host "Checking On-Premise Gateway Connection" -ForegroundColor Yellow
    
    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/connectionGateways/AIS-Training-Standard-Gateway`?api-version=2016-06-01"
    
    try {
        $result = az rest --method GET --uri $uri --output json 2>$null | ConvertFrom-Json
        
        Write-Host "  Gateway Name: $($result.properties.displayName)" -ForegroundColor Gray
        Write-Host "  Machine Name: $($result.properties.machineName)" -ForegroundColor Gray
        Write-Host "  Status: $($result.properties.status)" -ForegroundColor $(if($result.properties.status -eq 'Installed'){"Green"}else{"Red"})
        Write-Host "  Contact: $($result.properties.contactInformation -join ', ')" -ForegroundColor Gray
    }
    catch {
        Write-Host "  Failed to get gateway info: $_" -ForegroundColor Red
    }
}

# Function: Check App Settings
function Check-AppSettings {
    Write-Host "Checking Application Settings" -ForegroundColor Yellow
    
    try {
        $settings = az webapp config appsettings list --name $logicAppName --resource-group $resourceGroup --query "[?name=='SERVICE_BUS_CONNECTION_STRING' || name=='ONPREMISE_FILE_USERNAME' || name=='ONPREMISE_FILE_PASSWORD']" --output json 2>$null | ConvertFrom-Json
        
        $requiredSettings = @('SERVICE_BUS_CONNECTION_STRING', 'ONPREMISE_FILE_USERNAME', 'ONPREMISE_FILE_PASSWORD')
        
        foreach ($setting in $requiredSettings) {
            $found = $settings | Where-Object { $_.name -eq $setting }
            if ($found) {
                $displayValue = if ($setting -like "*PASSWORD*" -or $setting -like "*CONNECTION_STRING*") { "***HIDDEN***" } else { $found.value }
                Write-Host "  $setting`: $displayValue" -ForegroundColor Green
            }
            else {
                Write-Host "  $setting`: MISSING" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "  Failed to get app settings: $_" -ForegroundColor Red
    }
}

# Function: Restart Logic App
function Restart-LogicApp {
    Write-Host "Restarting Logic App: $logicAppName" -ForegroundColor Yellow
    
    try {
        az webapp restart --name $logicAppName --resource-group $resourceGroup --output none 2>$null
        Write-Host "  Logic App restart initiated" -ForegroundColor Green
        Write-Host "  Waiting 30 seconds for restart..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
    catch {
        Write-Host "  Failed to restart Logic App: $_" -ForegroundColor Red
    }
}

# Main Execution
Write-Host "Step 1: Checking Gateway Connection" -ForegroundColor Cyan
Write-Host ""
Check-GatewayConnection
Write-Host ""

Write-Host "Step 2: Checking Application Settings" -ForegroundColor Cyan
Write-Host ""
Check-AppSettings
Write-Host ""

Write-Host "Step 3: Checking Workflow States" -ForegroundColor Cyan
Write-Host ""

$workflows = @("wf-flatfile-pickup", "wf-flatfile-transformation")

foreach ($workflow in $workflows) {
    $state = Check-WorkflowState $workflow
    Write-Host ""
    
    if ($EnableWorkflows -and $state -and $state.properties.state -ne "Enabled") {
        Enable-Workflow $workflow
        Write-Host ""
    }
}

Write-Host "Step 4: Checking Recent Workflow Runs" -ForegroundColor Cyan
Write-Host ""

foreach ($workflow in $workflows) {
    Check-RecentRuns $workflow
    Write-Host ""
}

if ($RestartLogicApp) {
    Write-Host "Step 5: Restarting Logic App" -ForegroundColor Cyan
    Write-Host ""
    Restart-LogicApp
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Diagnostic Complete" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Recommendations:" -ForegroundColor Yellow
Write-Host "1. If workflows are disabled, run: .\Diagnose-FlatFileWorkflows.ps1 -EnableWorkflows" -ForegroundColor White
Write-Host "2. If workflows are unhealthy, run: .\Diagnose-FlatFileWorkflows.ps1 -RestartLogicApp" -ForegroundColor White
Write-Host "3. Upload a test file to C:\EmployeeFiles to trigger the workflow" -ForegroundColor White
Write-Host "4. Check Azure Portal for detailed run history and errors" -ForegroundColor White
Write-Host ""
