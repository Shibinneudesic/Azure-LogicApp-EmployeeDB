# Quick Demo Guide - Employee Upsert Workflow

## ✅ Deployment Status: DEPLOYED & READY

**Workflow Name**: `wf-employee-upsert`  
**Logic App**: `ais-training-la`  
**Status**: Deployed successfully at 10:35 AM

## 🔗 Workflow Endpoint

```
https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net:443/api/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=AaY1Rk_qyhnCKcSjK2YdSgSNEpVS4J92JDniY_34gvQ
```

## 📝 Test with PowerShell (Quick)

```powershell
# Test with existing test file
$endpoint = "https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net:443/api/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=AaY1Rk_qyhnCKcSjK2YdSgSNEpVS4J92JDniY_34gvQ"

$body = Get-Content "test-request.json" -Raw

$response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body -ContentType "application/json"

$response | ConvertTo-Json -Depth 10
```

## 📝 Test with Postman

1. **Method**: POST
2. **URL**: (Use the endpoint above)
3. **Headers**: 
   - `Content-Type`: `application/json`
4. **Body** (Raw JSON):
   ```json
   {
     "employees": {
       "employee": [
         {
           "id": 2010,
           "firstName": "Test",
           "lastName": "User",
           "department": "Testing",
           "position": "Test Engineer",
           "salary": 75000,
           "email": "test.user@example.com"
         }
       ]
     }
   }
   ```

## 📝 Test with cURL

```bash
curl -X POST "https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net:443/api/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=AaY1Rk_qyhnCKcSjK2YdSgSNEpVS4J92JDniY_34gvQ" \
  -H "Content-Type: application/json" \
  -d @test-request.json
```

## 🎯 View in Azure Portal

1. Go to: https://portal.azure.com
2. Navigate to: **Resource Groups** → **AIS_Training_Shibin** → **ais-training-la**
3. Click on **Workflows** in left menu
4. Click on **wf-employee-upsert**
5. View **Run History** to see execution details

**Direct Link to Logic App**:
```
https://portal.azure.com/#@/resource/subscriptions/cbb1dbec-731f-4479-a084-bdaec5e54fd4/resourceGroups/AIS_Training_Shibin/providers/Microsoft.Web/sites/ais-training-la/logicApp
```

## ✅ What Works

- ✅ Workflow deployed to Azure
- ✅ HTTP trigger endpoint active
- ✅ Workflow receives and processes requests
- ✅ Returns structured JSON responses
- ✅ Input validation
- ✅ Error handling with detailed error messages

## ⚠️ Current Issue

SQL connection may need verification. If you see "Unknown error" in response:
- Check SQL database is accessible
- Verify managed identity has permissions
- SQL connection string is correct

## 🔍 Monitor in Real-Time

**Application Insights Query**:
```
Go to: Application Insights → ais-training-la → Logs

Query:
requests
| where cloud_RoleName == "ais-training-la"
| where name contains "wf-employee-upsert"
| project timestamp, name, resultCode, duration
| order by timestamp desc
```

## 📊 Expected Response Structure

**Success Response** (200):
```json
{
  "status": "success",
  "code": 200,
  "message": "All employees processed successfully",
  "details": {
    "totalRequested": 2,
    "successfulOperations": 2,
    "failedOperations": 0
  },
  "timestamp": "2025-11-10T05:09:54.1498018Z",
  "runId": "08584388555116043664763600878CU00"
}
```

**Partial Success Response** (207):
```json
{
  "status": "partial_success",
  "code": 207,
  "message": "Some employees processed successfully, others failed",
  "details": {
    "totalRequested": 2,
    "successfulOperations": 1,
    "failedOperations": 1,
    "failedEmployees": [...]
  }
}
```

## 🚀 Demo Script

1. **Show the deployment**
   - "I've deployed the Logic App to Azure"
   - Show Azure Portal with the workflow

2. **Explain the architecture**
   - HTTP trigger → Validation → SQL upsert → Response
   - Error handling and logging
   - Application Insights monitoring

3. **Test the endpoint**
   - Run PowerShell test command
   - Show response in console
   - Show run history in Azure Portal

4. **Show monitoring**
   - Open Application Insights
   - Show request telemetry
   - Show execution timeline

## 📁 Test Files Available

- `test-request.json` - Valid employee data
- `test-invalid-request.json` - Invalid data for error testing

## ⏱️ Quick Test (30 seconds)

```powershell
# One-liner test
Invoke-RestMethod -Uri "https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net:443/api/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=AaY1Rk_qyhnCKcSjK2YdSgSNEpVS4J92JDniY_34gvQ" -Method Post -Body (Get-Content "test-request.json" -Raw) -ContentType "application/json" | ConvertTo-Json -Depth 5
```

**Good luck with your demo! 🎉**
