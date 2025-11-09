# Test 500 Error - Terminate Action Scenarios

## How the Try-Catch-Terminate Works
- **Try scope** contains all business logic
- **Catch scope** runs when Try fails (runAfter: Failed, Skipped, TimedOut)
- **Terminate action** ends workflow with HTTP 500 and formatted error details

## Ways to Trigger 500 Error

### 1. **SQL Connection Failure** (Easiest)
Temporarily break the SQL connection in Azure Portal:

**Steps:**
1. Go to Logic App → Configuration
2. Find the SQL connection string
3. Change the password/server name to invalid value
4. Send any valid request
5. **Result**: SQL connection fails → Try scope fails → Catch runs → Terminate (500)

**Restore**: Change connection back to correct value

---

### 2. **Malformed JSON Structure** (If Parse JSON action exists)
Send JSON that doesn't match the expected schema:

```bash
curl --location 'https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net:443/api/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=WeV6SfqxPui2Pgi2i4NJDulJFNnI0ftCxNnoZBCFxvE' \
--header 'Content-Type: application/json' \
--data-raw '{
  "employees": "THIS_SHOULD_BE_AN_OBJECT_NOT_STRING"
}'
```

**Note**: This might return 400 if validation catches it first.

---

### 3. **SQL Constraint Violation**
Create a scenario where SQL throws an error:

**Option A - Exceed VARCHAR limit:**
```bash
curl --location 'https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net:443/api/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=WeV6SfqxPui2Pgi2i4NJDulJFNnI0ftCxNnoZBCFxvE' \
--header 'Content-Type: application/json' \
--data-raw '{
  "employees": {
    "employee": [
      {
        "id": 9001,
        "firstName": "'"$(python -c "print('A' * 200)")"'",
        "lastName": "Test",
        "department": "IT"
      }
    ]
  }
}'
```

**Option B - Set IsActive=0 for an employee, then try to update:**
1. Run SQL in Azure Portal: `UPDATE dbo.Employee SET IsActive = 0 WHERE Id = 2001;`
2. Send request to update ID 2001
3. **Result**: SQL UPDATE affects 0 rows (employee not found because IsActive=0)

---

### 4. **Temporarily Remove EXECUTE Permission** (Guaranteed 500)
This will cause SQL authentication to fail within the Try scope:

**In Azure Portal Query Editor:**
```sql
-- Remove EXECUTE permission
REVOKE EXECUTE ON dbo.usp_Employee_Upsert FROM [ais-training-la];
```

**Test Request** (any valid payload):
```bash
curl --location 'https://ais-training-la-b9fmb9f3bma5b6bb.canadacentral-01.azurewebsites.net:443/api/wf-employee-upsert/triggers/When_a_HTTP_request_is_received/invoke?api-version=2022-05-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=WeV6SfqxPui2Pgi2i4NJDulJFNnI0ftCxNnoZBCFxvE' \
--header 'Content-Type: application/json' \
--data-raw '{
  "employees": {
    "employee": [
      {
        "id": 9999,
        "firstName": "Test",
        "lastName": "Error",
        "department": "IT"
      }
    ]
  }
}'
```

**Expected Result:**
- SQL action fails with permission error
- Try scope status: Failed
- Catch scope triggers
- Terminate action runs with HTTP 500

**Restore Permission:**
```sql
GRANT EXECUTE ON dbo.usp_Employee_Upsert TO [ais-training-la];
```

---

### 5. **Drop the Stored Procedure** (Nuclear Option)
```sql
-- Drop the stored procedure
DROP PROCEDURE dbo.usp_Employee_Upsert;
```

Send any request → SQL can't find the procedure → Try fails → Terminate (500)

**Restore:** Re-run `Deploy-usp_Employee_Upsert.sql`

---

## Recommended Test Approach

**Best for testing: Option 4 (REVOKE EXECUTE)**
- Clean and reversible
- Guaranteed to trigger Try scope failure
- Easy to restore
- Doesn't corrupt data

**Steps:**
1. Revoke EXECUTE permission
2. Send valid employee data
3. Verify HTTP 500 response with formatted error details
4. Check Application Insights for CRITICAL log
5. Restore EXECUTE permission
6. Verify workflow works again

---

## Expected 500 Response Structure

```json
{
  "status": "failed",
  "message": "Workflow terminated due to critical error",
  "runStatus": "Failed",
  "error": {
    "code": 500,
    "message": "Critical workflow failure - check logs for details",
    "details": [
      {
        "action": "Upsert_Employee",
        "status": "Failed",
        "errorCode": "ServiceOperationFailed",
        "errorMessage": "The service provider action failed with error code 'ServiceOperationFailed'..."
      }
    ]
  }
}
```

---

## Verification Checklist

After triggering 500 error, verify:
- [ ] HTTP response code: 500
- [ ] Response body contains formatted error details
- [ ] Workflow run status: Failed (in Azure Portal)
- [ ] Catch scope executed successfully
- [ ] Filter_Try_Scope_Errors action ran
- [ ] Format_Errors action ran
- [ ] Log_Critical_Error action ran (check Application Insights)
- [ ] Terminate action ran with runStatus: Failed, code: 500
- [ ] Application Insights logs show CRITICAL level entry
