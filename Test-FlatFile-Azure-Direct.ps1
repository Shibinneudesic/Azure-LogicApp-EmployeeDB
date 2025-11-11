# Quick Test Script for Flat File Workflows in Azure
# Since local testing has limitations, let's test directly in Azure

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Testing Flat File Workflows in Azure" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Note: Local testing has limitations:" -ForegroundColor Yellow
Write-Host "  - Parallel actions not supported locally" -ForegroundColor Gray
Write-Host "  - File System trigger needs gateway (not available locally)" -ForegroundColor Gray
Write-Host "  - Best to test in Azure where workflows are deployed" -ForegroundColor Gray
Write-Host ""

$response = Read-Host "Do you want to test in Azure now? (Y/N)"

if ($response -eq "Y" -or $response -eq "y") {
    Write-Host ""
    Write-Host "Starting Azure test..." -ForegroundColor Green
    Write-Host ""
    
    .\Test-FlatFile-Simple.ps1
}
else {
    Write-Host ""
    Write-Host "To test in Azure later, run:" -ForegroundColor Cyan
    Write-Host "  .\Test-FlatFile-Simple.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To view Azure workflow status:" -ForegroundColor Cyan
    Write-Host "  https://portal.azure.com → Logic App → ais-training-la" -ForegroundColor Gray
    Write-Host ""
}
