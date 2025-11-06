# Read the original workflow
$workflowPath = "UpsertEmployee\workflow.json"
$workflow = Get-Content $workflowPath -Raw | ConvertFrom-Json

# Remove validation-related actions and simplify
$actions = $workflow.definition.actions

# Create new simplified actions object
$newActions = [ordered]@{
    LogStartOfWorkflow = $actions.LogStartOfWorkflow
    InitializeResults = $actions.InitializeResults
    LogBatchStart = $actions.ValidateInput.actions.LogBatchStart
    ForEachEmployee = $actions.ValidateInput.actions.ForEachEmployee
    LogBatchComplete = $actions.ValidateInput.actions.LogBatchComplete
    SuccessResponse = $actions.ValidateInput.actions.SuccessResponse
}

# Update LogBatchStart message
$newActions.LogBatchStart.inputs.message = "Starting batch processing"

# Update runAfter dependencies
$newActions.LogBatchStart.runAfter = [ordered]@{
    InitializeResults = @("Succeeded")
}

$newActions.ForEachEmployee.runAfter = [ordered]@{
    LogBatchStart = @("Succeeded")
}

# Replace actions
$workflow.definition.actions = $newActions

# Save
$workflow | ConvertTo-Json -Depth 100 | Set-Content $workflowPath -Encoding UTF8
Write-Host "Workflow simplified successfully!" -ForegroundColor Green
Write-Host "- Removed ValidateInput wrapper" -ForegroundColor Yellow
Write-Host "- Removed ValidateAllEmployees loop" -ForegroundColor Yellow
Write-Host "- Removed ValidationErrorResponse" -ForegroundColor Yellow
Write-Host "- Schema validation at trigger level now handles all validation (fails fast)" -ForegroundColor Cyan
