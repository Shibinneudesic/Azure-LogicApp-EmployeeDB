# Deploy Flat File Workflows to Azure Logic App
# This script deploys the workflow files to the Azure Logic App

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Configuration
$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "ais-training-la"
$localPath = "."

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Deploy Flat File Workflows" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Function: Deploy workflow
function Deploy-Workflow {
    param(
        [string]$workflowName,
        [string]$workflowPath
    )
    
    Write-Host "Deploying workflow: $workflowName" -ForegroundColor Yellow
    
    if (-not (Test-Path "$workflowPath\workflow.json")) {
        Write-Host "  ERROR: workflow.json not found in $workflowPath" -ForegroundColor Red
        return $false
    }
    
    try {
        # Create zip file for deployment
        $tempZip = [System.IO.Path]::GetTempFileName() + ".zip"
        
        # Get all files in the workflow directory
        $files = Get-ChildItem -Path $workflowPath -Recurse -File
        
        # Create zip archive
        Add-Type -Assembly System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::Open($tempZip, 'Create')
        
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($workflowPath.Length + 1)
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relativePath) | Out-Null
        }
        
        $zip.Dispose()
        
        Write-Host "  Created deployment package: $tempZip" -ForegroundColor Gray
        
        # Deploy to Azure using Kudu API
        $publishProfile = az webapp deployment list-publishing-profiles `
            --name $logicAppName `
            --resource-group $resourceGroup `
            --query "[?publishMethod=='MSDeploy'].{username:userName,password:userPWD}" `
            --output json | ConvertFrom-Json | Select-Object -First 1
        
        if (-not $publishProfile) {
            Write-Host "  ERROR: Could not get publishing credentials" -ForegroundColor Red
            Remove-Item $tempZip -Force
            return $false
        }
        
        $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($publishProfile.username):$($publishProfile.password)"))
        
        # Upload via Kudu VFS API
        $kuduUrl = "https://$logicAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$workflowName/"
        
        # Create workflow directory
        Invoke-WebRequest -Uri $kuduUrl -Method PUT -Headers @{Authorization = "Basic $base64Auth"} -ContentType "application/json" -Body "" -ErrorAction SilentlyContinue | Out-Null
        
        # Upload workflow.json
        $workflowContent = Get-Content "$workflowPath\workflow.json" -Raw
        $uploadUrl = "$kuduUrl/workflow.json"
        
        Invoke-WebRequest -Uri $uploadUrl -Method PUT -Headers @{Authorization = "Basic $base64Auth"} -ContentType "application/json" -Body $workflowContent | Out-Null
        
        Write-Host "  Deployed workflow.json" -ForegroundColor Green
        
        # Clean up
        Remove-Item $tempZip -Force
        
        return $true
    }
    catch {
        Write-Host "  ERROR: Deployment failed - $_" -ForegroundColor Red
        if (Test-Path $tempZip) {
            Remove-Item $tempZip -Force
        }
        return $false
    }
}

# Function: Enable workflow
function Enable-WorkflowAfterDeploy {
    param([string]$workflowName)
    
    Write-Host "  Enabling workflow..." -ForegroundColor Gray
    
    $uri = "https://management.azure.com/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$logicAppName/workflows/$workflowName`?api-version=2022-03-01"
    
    $body = @{
        properties = @{
            state = "Enabled"
        }
    } | ConvertTo-Json
    
    try {
        az rest --method PATCH --uri $uri --body $body --output none 2>$null
        Write-Host "  Workflow enabled" -ForegroundColor Green
    }
    catch {
        Write-Host "  WARNING: Could not enable workflow - $_" -ForegroundColor Yellow
    }
}

# Main execution
Write-Host "Checking prerequisites..." -ForegroundColor Cyan
Write-Host ""

# Check if workflows exist locally
$workflows = @(
    @{Name="wf-flatfile-pickup"; Path="$localPath\wf-flatfile-pickup"},
    @{Name="wf-flatfile-transformation"; Path="$localPath\wf-flatfile-transformation"}
)

$allExist = $true
foreach ($wf in $workflows) {
    if (Test-Path $wf.Path) {
        Write-Host "  Found: $($wf.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "  Missing: $($wf.Name)" -ForegroundColor Red
        $allExist = $false
    }
}

if (-not $allExist) {
    Write-Host ""
    Write-Host "ERROR: Not all workflows found locally" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Deploying workflows..." -ForegroundColor Cyan
Write-Host ""

$deployedCount = 0

foreach ($wf in $workflows) {
    if (Deploy-Workflow -workflowName $wf.Name -workflowPath $wf.Path) {
        Enable-WorkflowAfterDeploy -workflowName $wf.Name
        $deployedCount++
        Write-Host ""
    }
}

Write-Host "Restarting Logic App to apply changes..." -ForegroundColor Cyan
az webapp restart --name $logicAppName --resource-group $resourceGroup --output none
Write-Host "  Restart initiated" -ForegroundColor Green
Write-Host ""

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Deployed workflows: $deployedCount / $($workflows.Count)" -ForegroundColor $(if($deployedCount -eq $workflows.Count){"Green"}else{"Yellow"})
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait 30 seconds for Logic App to restart" -ForegroundColor White
Write-Host "2. Run diagnostic script: .\Diagnose-FlatFileWorkflows.ps1" -ForegroundColor White
Write-Host "3. Upload test file: Copy-Item '.\Artifacts\employees.csv' 'C:\EmployeeFiles\test.csv'" -ForegroundColor White
Write-Host ""
