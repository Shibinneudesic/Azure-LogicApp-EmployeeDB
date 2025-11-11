# Quick Resolution Guide for Flat File Workflow Issue

## Problem Summary
The flat file workflows (`wf-flatfile-pickup` and `wf-flatfile-transformation`) are deployed to Azure Logic App `ais-training-la` but are not triggering when files are added to `C:\EmployeeFiles`.

## Root Cause
The workflows show:
- **State**: `null` (not "Enabled" or "Disabled")  
- **Health**: "Healthy"
- **Gateway Status**: "Installed" and connected
- **App Settings**: All configured correctly

The `null` state suggests the workflows may need to be manually enabled in the Azure Portal or there's an issue with the workflow trigger configuration.

## Solutions to Try

### Solution 1: Enable Workflows via Azure Portal (RECOMMENDED)
1. Open Azure Portal: https://portal.azure.com
2. Navigate to: **Resource Groups** → **AIS_Training_Shibin** → **ais-training-la** (Logic App)
3. In the left menu, click **Workflows**
4. For each workflow (`wf-flatfile-pickup`, `wf-flatfile-transformation`):
   - Click on the workflow name
   - Click **Enable** button at the top
   - Verify the status changes to "Enabled"
5. Wait 30 seconds and upload a test file

### Solution 2: Check Workflow Trigger Settings
1. In Azure Portal, open `wf-flatfile-pickup` workflow
2. Click **Designer** or **Code View**
3. Verify the trigger configuration:
   - **Folder Path**: Should be `/EmployeeFiles`
   - **Connection**: Should use FileSystem connection with the gateway
   - **Gateway**: Should be `AIS-Training-Standard-Gateway`
4. If anything is missing, reconfigure and save

### Solution 3: Recreate FileSystem Connection
The FileSystem connection may need to be recreated:
1. In Azure Portal, navigate to **API Connections** in the resource group
2. Look for FileSystem connection
3. Click **Edit API connection**
4. Re-enter credentials:
   - Username: `shibin`
   - Password: (your password)
   - Gateway: Select `AIS-Training-Standard-Gateway`
5. Test the connection
6. Save changes

### Solution 4: Check Gateway Data Source
1. Open **On-premises data gateway** application on your local machine
2. Verify the gateway is running and connected
3. Check **Data Sources**:
   - Should have a data source named "FileSystem" or similar
   - Path should include `C:\EmployeeFiles`
   - Credentials should be valid
4. If not configured, add a new data source:
   - Type: **File**
   - Root folder: `C:`
   - Windows authentication with valid credentials

### Solution 5: Manual Trigger Test
Test if the workflow logic works by triggering it manually:
1. In Azure Portal, open `wf-flatfile-pickup` workflow
2. Click **Overview** → **Run Trigger** → **Run**
3. If it fails, check the error message
4. If it succeeds, the issue is with the file system trigger, not the workflow logic

## Verification Steps

After applying fixes:
1. **Check workflow state**:
   ```powershell
   .\Diagnose-FlatFileWorkflows.ps1
   ```
   Should show: `State: Enabled`

2. **Upload test file**:
   ```powershell
   Copy-Item ".\Artifacts\employees.csv" "C:\EmployeeFiles\test.csv"
   ```

3. **Wait 2-3 minutes** (FileSystem triggers can take time)

4. **Check Service Bus queue**:
   ```powershell
   .\Test-FlatFile-Simple.ps1 -CheckQueuesOnly
   ```
   Should show messages in `flatfile-processing-queue`

5. **Check workflow runs** in Azure Portal:
   - Navigate to workflow → Overview → Run History
   - Should see recent runs with "Succeeded" status

## Alternative: Use HTTP Trigger Instead
If the FileSystem trigger continues to have issues, you can modify the workflow to use an HTTP trigger and call it from a PowerShell script or scheduled task when files are detected.

## Contact Azure Support If:
- Gateway status shows "Not Installed" or "Error"
- Workflow state cannot be changed to "Enabled"
- Error messages appear in workflow health status
- All solutions above have been tried without success

## Quick Test Command
```powershell
# Run this single command to test end-to-end:
Copy-Item ".\Artifacts\employees.csv" "C:\EmployeeFiles\test_$(Get-Date -Format 'HHmmss').csv"; Start-Sleep -Seconds 120; .\Test-FlatFile-Simple.ps1 -CheckQueuesOnly
```

This will upload a file, wait 2 minutes, and check if messages appear in the queues.
