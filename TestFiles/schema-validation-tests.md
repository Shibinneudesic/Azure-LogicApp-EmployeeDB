# Test Cases for Schema-Based Validation

## Valid Request
```json
{
  "employees": {
    "employee": [
      {
        "id": 1,
        "firstName": "John",
        "lastName": "Doe",
        "department": "IT",
        "position": "Developer",
        "salary": 75000,
        "email": "john.doe@example.com"
      },
      {
        "id": 2,
        "firstName": "Jane",
        "lastName": "Smith"
      }
    ]
  }
}
```

## Invalid - Missing lastName
```json
{
  "employees": {
    "employee": [
      {
        "id": 1,
        "firstName": "John"
      }
    ]
  }
}
```

## Invalid - ID is 0
```json
{
  "employees": {
    "employee": [
      {
        "id": 0,
        "firstName": "John",
        "lastName": "Doe"
      }
    ]
  }
}
```

## Invalid - Empty firstName
```json
{
  "employees": {
    "employee": [
      {
        "id": 1,
        "firstName": "",
        "lastName": "Doe"
      }
    ]
  }
}
```

## Invalid - Whitespace-only lastName
```json
{
  "employees": {
    "employee": [
      {
        "id": 1,
        "firstName": "John",
        "lastName": "   "
      }
    ]
  }
}
```

## Invalid - Missing employees.employee array
```json
{
  "employees": {}
}
```

## Invalid - Empty array
```json
{
  "employees": {
    "employee": []
  }
}
```

## Invalid - Wrong structure (no employees wrapper)
```json
{
  "employee": [
    {
      "id": 1,
      "firstName": "John",
      "lastName": "Doe"
    }
  ]
}
```

## Testing Command (PowerShell)

```powershell
# Get the workflow URL first
$workflowUrl = "YOUR_WORKFLOW_URL_HERE"

# Test valid request
$validBody = @{
    employees = @{
        employee = @(
            @{
                id = 1
                firstName = "John"
                lastName = "Doe"
                department = "IT"
                salary = 75000
            }
        )
    }
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri $workflowUrl -Method Post -Body $validBody -ContentType "application/json"

# Test invalid request (missing lastName)
$invalidBody = @{
    employees = @{
        employee = @(
            @{
                id = 1
                firstName = "John"
            }
        )
    }
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri $workflowUrl -Method Post -Body $invalidBody -ContentType "application/json"
```
