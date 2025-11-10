# Gateway Configuration Values Template

## Fill these values after gateway installation:

### Gateway Information
```
Gateway Name in Azure Portal: gateway-flatfile-ais-training
Gateway Resource ID: [PASTE FROM AZURE CLI COMMAND]
Gateway Status: [Check in gateway app - should be "Online"]
```

### File Server Credentials
```
Server Name: [YOUR FILE SERVER NAME]
Username: [e.g., SERVERNAME\username or DOMAIN\username]
Password: [Windows account password]
Root Folder: C:\EmployeeFiles
```

### Quick Commands to Get Gateway ID

After gateway is registered in Azure, run:

```powershell
# List all gateways in resource group
az resource list --resource-group "AIS_Training_Shibin" --resource-type "Microsoft.Web/connectionGateways" --query "[].{Name:name, ID:id}" -o table

# Or get specific gateway ID
az resource show --resource-group "AIS_Training_Shibin" --name "gateway-flatfile-ais-training" --resource-type "Microsoft.Web/connectionGateways" --query "id" -o tsv
```

### Configuration to Add to Logic App Settings

Once you have the values, I'll add these to Logic App:

```
ONPREMISE_GATEWAY_ID = [Gateway Resource ID from above]
ONPREMISE_FILE_USERNAME = [Username with file access]
ONPREMISE_FILE_PASSWORD = [Password]
SERVICE_BUS_CONNECTION_STRING = [Your Service Bus Connection String]
```

## Verification Steps

1. Install gateway on file server
2. Register with Azure (Canada Central region)
3. Create gateway resource in Azure Portal
4. Get Gateway Resource ID
5. Notify me - I'll configure Logic App settings and deploy workflows

## Test File Location

Make sure this directory exists on your file server:
```
C:\EmployeeFiles
```

Place CSV files here for processing.
