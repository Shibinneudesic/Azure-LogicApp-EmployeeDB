# Check On-Premise Data Gateway Registration Status

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Gateway Registration Check" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if gateway service is running
Write-Host "1. Checking Gateway Service..." -ForegroundColor Yellow
$service = Get-Service -Name "PBIEgwService" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "   ✅ Service Status: $($service.Status)" -ForegroundColor Green
    Write-Host "   ✅ Display Name: $($service.DisplayName)" -ForegroundColor Green
} else {
    Write-Host "   ❌ Gateway service not found!" -ForegroundColor Red
    exit
}

# Check gateway installation directory
Write-Host "`n2. Checking Gateway Installation..." -ForegroundColor Yellow
$gatewayPath = "C:\Program Files\On-premises data gateway"
if (Test-Path $gatewayPath) {
    Write-Host "   ✅ Installation found: $gatewayPath" -ForegroundColor Green
    
    # Check for gateway executable
    $gatewayExe = Join-Path $gatewayPath "EnterpriseGatewayConfigurator.exe"
    if (Test-Path $gatewayExe) {
        Write-Host "   ✅ Configurator found" -ForegroundColor Green
    }
} else {
    Write-Host "   ❌ Installation not found at default location" -ForegroundColor Red
}

# Check gateway configuration
Write-Host "`n3. Checking Gateway Configuration..." -ForegroundColor Yellow
$configPath = "$env:ProgramData\Microsoft\On-premises data gateway"
if (Test-Path $configPath) {
    Write-Host "   ✅ Configuration directory found" -ForegroundColor Green
    
    # Look for configuration file
    $configFile = Get-ChildItem -Path $configPath -Filter "*.config" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($configFile) {
        Write-Host "   ✅ Configuration file found: $($configFile.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "   ⚠️  Configuration directory not found" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If the gateway is installed but not showing in Azure Portal:" -ForegroundColor White
Write-Host ""
Write-Host "1. Open the Gateway Configurator:" -ForegroundColor Cyan
Write-Host "   - Start Menu → 'On-premises data gateway'" -ForegroundColor Gray
Write-Host "   - Or run: " -ForegroundColor Gray
Write-Host "     Start-Process 'C:\Program Files\On-premises data gateway\EnterpriseGatewayConfigurator.exe'" -ForegroundColor DarkGray
Write-Host ""
Write-Host "2. Check the gateway status:" -ForegroundColor Cyan
Write-Host "   - Should show 'Status: Online'" -ForegroundColor Gray
Write-Host "   - Note the Gateway Name" -ForegroundColor Gray
Write-Host "   - Note the Region (should be Canada Central)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. If not registered or wrong region:" -ForegroundColor Cyan
Write-Host "   - Click 'Sign in' with your Azure account" -ForegroundColor Gray
Write-Host "   - Re-register with correct settings" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Current Azure Account Check:" -ForegroundColor Cyan
Write-Host "   - Gateway must be registered with: shibin.sam@neudesic.com" -ForegroundColor Gray
Write-Host "   - Region must be: Canada Central" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================`n" -ForegroundColor Cyan
