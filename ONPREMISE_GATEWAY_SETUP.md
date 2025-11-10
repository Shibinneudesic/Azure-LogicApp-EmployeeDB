# On-Premise Data Gateway Setup Guide

## Overview
The On-Premise Data Gateway enables secure data transfer between on-premises data sources (like your file server) and Azure Logic Apps.

## Prerequisites
- Windows Server 2016 or later (or Windows 10/11)
- .NET Framework 4.7.2 or later
- Administrator access to the server
- Azure account with permissions to create gateway resources
- The server must have access to the file location: `C:\EmployeeFiles`

## Step 1: Download Gateway Software

1. Go to: https://aka.ms/opdg
2. Download the latest version of On-Premise Data Gateway
3. Save the installer to your file server

**Alternative Download Link**: 
https://www.microsoft.com/en-us/download/details.aspx?id=53127

## Step 2: Install Gateway on File Server

### Installation Steps:

1. **Run the installer** as Administrator
   - Double-click `GatewayInstall.exe`
   - Accept the license terms

2. **Choose Installation Path**
   - Default: `C:\Program Files\On-premises data gateway`
   - Click **Next**

3. **Sign in with Azure Account**
   - Use: `shibin.sam@neudesic.com` (or your Azure account)
   - Sign in with your Azure credentials

4. **Register Gateway**
   - **Gateway Name**: `gateway-flatfile-ais-training`
   - **Recovery Key**: Create a strong recovery key (minimum 8 characters)
   - **IMPORTANT**: Save the recovery key securely - you'll need it for recovery
   - **Region**: Select **Canada Central** (same as your Logic App)
   - Click **Configure**

5. **Wait for Registration**
   - The gateway will register with Azure
   - Status should show: "The gateway is online and ready to be used"

6. **Keep Gateway Service Running**
   - The gateway runs as a Windows service
   - Service name: `PBIEgwService` (Power BI Enterprise Gateway Service)
   - Should be set to start automatically

## Step 3: Create Gateway Resource in Azure

### Option A: Using Azure Portal

1. Go to Azure Portal: https://portal.azure.com
2. Search for "On-premises data gateways"
3. Click **+ Create**
4. Fill in details:
   - **Subscription**: `cbb1dbec-731f-4479-a084-bdaec5e54fd4`
   - **Resource Group**: `AIS_Training_Shibin`
   - **Name**: `gateway-flatfile-ais-training`
   - **Region**: `Canada Central`
   - **Installation Name**: Select the gateway you just registered
5. Click **Review + Create** → **Create**

### Option B: Using Azure CLI

Run this command after gateway installation:

```powershell
az resource create `
  --resource-group "AIS_Training_Shibin" `
  --name "gateway-flatfile-ais-training" `
  --resource-type "Microsoft.Web/connectionGateways" `
  --properties "{`"displayName`":`"gateway-flatfile-ais-training`",`"connectionGatewayInstallation`":{`"id`":`"/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/connectionGatewayInstallations/gateway-flatfile-ais-training`"}}" `
  --location "canadacentral"
```

## Step 4: Get Gateway Resource ID

After creating the gateway resource in Azure, get its ID:

```powershell
az resource show `
  --resource-group "AIS_Training_Shibin" `
  --name "gateway-flatfile-ais-training" `
  --resource-type "Microsoft.Web/connectionGateways" `
  --query "id" -o tsv
```

**Save this ID** - you'll need it for the Logic App configuration.

## Step 5: Configure File System Access

### Create Service Account (Recommended):

1. **Create a Windows service account** on the file server:
   - Username: `fileserver\svc_logicapp` (or domain account)
   - Password: Strong password
   - Grant this account:
     - Read access to `C:\EmployeeFiles`
     - "Log on as a service" right

2. **Configure Gateway to use this account**:
   - Open "On-premises data gateway" app on the server
   - Go to **Service Settings**
   - Change service account to the one you created
   - Restart the gateway service

### OR Use Current User (Testing Only):

For testing purposes, you can use your current Windows account:
- Username: `SERVERNAME\YourUsername`
- Password: Your Windows password

**IMPORTANT**: The account must have read access to `C:\EmployeeFiles`

## Step 6: Test Gateway Connection

1. Open "On-premises data gateway" app on server
2. Check **Status** tab
3. Should show: 
   - Status: Online
   - Version: [Latest version]
   - Last contacted: [Recent timestamp]

## Step 7: Create Test Directory and File

On the file server, create:

```powershell
# Create directory
New-Item -Path "C:\EmployeeFiles" -ItemType Directory -Force

# Create a test CSV file
$testCsv = @"
EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID
1001,John,Doe,john.doe@company.com,555-0101,2024-01-15,IT_PROG,75000,0.10,100,90
1002,Jane,Smith,jane.smith@company.com,555-0102,2024-02-20,SA_REP,65000,0.15,101,80
"@

Set-Content -Path "C:\EmployeeFiles\test_employees.csv" -Value $testCsv

Write-Host "Test file created: C:\EmployeeFiles\test_employees.csv"
```

## Configuration Values Needed

After completing the setup, you'll need these values:

| Setting | Value | Where to Get It |
|---------|-------|-----------------|
| Gateway Resource ID | `/subscriptions/.../connectionGateways/gateway-flatfile-ais-training` | Azure CLI command in Step 4 |
| File Server Username | `SERVERNAME\username` | Your Windows account or service account |
| File Server Password | `********` | Windows password |
| Root Folder | `C:\EmployeeFiles` | Directory created in Step 7 |

## Troubleshooting

### Gateway shows offline:
1. Check Windows service is running
2. Check network connectivity to Azure
3. Verify firewall allows outbound 443
4. Check gateway app for error messages

### Cannot connect to file system:
1. Verify the account has read permissions
2. Test access manually: `Test-Path C:\EmployeeFiles`
3. Check gateway service account configuration
4. Ensure path exists and is accessible

### Gateway not appearing in Azure:
1. Verify you signed in with correct Azure account
2. Check you selected correct region (Canada Central)
3. Wait 5-10 minutes for propagation
4. Restart gateway service

### File trigger not working:
1. Verify directory exists: `C:\EmployeeFiles`
2. Check file permissions for gateway service account
3. Test by manually placing a CSV file
4. Check Logic App run history for errors

## Network Requirements

The gateway server needs outbound access to:
- `*.servicebus.windows.net` (port 443)
- `*.frontend.clouddatahub.net` (port 443)
- `*.core.windows.net` (port 443)
- `*.azure-api.net` (port 443)

## Security Best Practices

1. ✅ Use a dedicated service account (not your personal account)
2. ✅ Grant minimum required permissions (read-only on C:\EmployeeFiles)
3. ✅ Keep gateway software updated
4. ✅ Store recovery key securely (password manager)
5. ✅ Monitor gateway health regularly
6. ✅ Use strong passwords
7. ✅ Enable Windows Firewall on gateway server

## Next Steps After Gateway Setup

Once the gateway is installed and registered:

1. ✅ Get Gateway Resource ID
2. ✅ Add gateway configuration to Logic App settings
3. ✅ Update connections.json
4. ✅ Deploy workflows
5. ✅ Test file pickup

I'll help you with these steps once the gateway is set up!

## Quick Verification Checklist

Before proceeding to deployment:

- [ ] Gateway software installed on file server
- [ ] Gateway registered and showing "online" status
- [ ] Gateway resource created in Azure (AIS_Training_Shibin resource group)
- [ ] Gateway Resource ID obtained
- [ ] Service account created (or using Windows account)
- [ ] Test directory created: C:\EmployeeFiles
- [ ] Test CSV file placed in directory
- [ ] Gateway service account has read access to directory

## Support Links

- Gateway Documentation: https://docs.microsoft.com/data-integration/gateway/
- Gateway Download: https://aka.ms/opdg
- Troubleshooting: https://docs.microsoft.com/data-integration/gateway/service-gateway-tshoot
- Logic Apps + Gateway: https://docs.microsoft.com/azure/logic-apps/logic-apps-gateway-install
