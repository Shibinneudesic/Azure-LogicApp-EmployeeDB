# Monitor Logic App Workflows
# Checks the status and recent runs of flat file workflows

param(
    [int]$RefreshSeconds = 10,
    [int]$MaxChecks = 12
)

$resourceGroup = "AIS_Training_Shibin"
$logicAppName = "ais-training-la"
$workflows = @("wf-flatfile-pickup", "wf-flatfile-transformation")

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Logic App Workflow Monitor" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Monitoring for $($RefreshSeconds * $MaxChecks) seconds..." -ForegroundColor Yellow
Write-Host ""

for ($i = 1; $i -le $MaxChecks; $i++) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] Check $i of $MaxChecks" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($workflowName in $workflows) {
        Write-Host "  Workflow: $workflowName" -ForegroundColor Yellow
        
        try {
            # Get workflow state
            $workflow = az logicapp workflow show `
                --name $logicAppName `
                --resource-group $resourceGroup `
                --workflow-name $workflowName `
                --output json 2>$null
            
            if ($workflow) {
                $workflowObj = $workflow | ConvertFrom-Json
                $state = $workflowObj.properties.state
                
                Write-Host "    State: $state" -ForegroundColor $(if($state -eq "Enabled"){"Green"}else{"Yellow"})
                
                # Try to get recent runs (may not work via CLI, needs portal)
                Write-Host "    Check Azure Portal for run history" -ForegroundColor Gray
            }
            else {
                Write-Host "    Could not retrieve workflow info" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host ""
    }
    
    # Check queues
    Write-Host "  Service Bus Queue Status:" -ForegroundColor Yellow
    try {
        $queueResult = az servicebus queue show `
            --resource-group $resourceGroup `
            --namespace-name "sb-flatfile-processing" `
            --name "flatfile-processing-queue" `
            --query "countDetails.activeMessageCount" `
            --output tsv 2>$null
        
        Write-Host "    flatfile-processing-queue: $queueResult messages" -ForegroundColor $(if([int]$queueResult -gt 0){"Green"}else{"Gray"})
    }
    catch {
        Write-Host "    Could not check queue" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "  Storage Queue Status:" -ForegroundColor Yellow
    try {
        $xmlQueue = az storage message peek `
            --queue-name "flatfile-xml-queue" `
            --account-name "aistrainingshibinbf12" `
            --auth-mode login `
            --num-messages 1 `
            --output json 2>$null
        
        $hasXMLMessages = $xmlQueue -and $xmlQueue -ne "[]"
        Write-Host "    flatfile-xml-queue: $(if($hasXMLMessages){'Has messages'}else{'Empty'})" -ForegroundColor $(if($hasXMLMessages){"Green"}else{"Gray"})
    }
    catch {
        Write-Host "    flatfile-xml-queue: Cannot check" -ForegroundColor Gray
    }
    
    try {
        $jsonQueue = az storage message peek `
            --queue-name "flatfile-json-queue" `
            --account-name "aistrainingshibinbf12" `
            --auth-mode login `
            --num-messages 1 `
            --output json 2>$null
        
        $hasJSONMessages = $jsonQueue -and $jsonQueue -ne "[]"
        Write-Host "    flatfile-json-queue: $(if($hasJSONMessages){'Has messages'}else{'Empty'})" -ForegroundColor $(if($hasJSONMessages){"Green"}else{"Gray"})
    }
    catch {
        Write-Host "    flatfile-json-queue: Cannot check" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "---" -ForegroundColor Gray
    Write-Host ""
    
    if ($i -lt $MaxChecks) {
        Start-Sleep -Seconds $RefreshSeconds
    }
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Monitoring Complete" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "View detailed run history in Azure Portal:" -ForegroundColor Yellow
Write-Host "https://portal.azure.com/#@/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/ais-training-la/workflowsconfiguration/wf-flatfile-pickup" -ForegroundColor Gray
Write-Host ""
Write-Host "https://portal.azure.com/#@/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/ais-training-la/workflowsconfiguration/wf-flatfile-transformation" -ForegroundColor Gray
Write-Host ""
