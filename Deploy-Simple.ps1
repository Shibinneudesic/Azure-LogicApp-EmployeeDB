# Simple Deploy Script for Logic App
$ErrorActionPreference = "Stop"

Write-Host "Deploying Logic App to Azure..." -ForegroundColor Cyan

# Switch to Azure connections
if (Test-Path "connections.azure.json") {
    Copy-Item "connections.azure.json" "connections.json" -Force
    Write-Host "✓ Switched to Azure SQL connections" -ForegroundColor Green
}

# Deploy using func CLI
Write-Host "Running deployment..." -ForegroundColor Yellow
func azure functionapp publish upsert-employee --force

Write-Host "✓ Deployment completed!" -ForegroundColor Green
Write-Host "Check Azure Portal for workflow status" -ForegroundColor Cyan
