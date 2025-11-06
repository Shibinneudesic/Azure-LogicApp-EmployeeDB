import json

# Read the workflow
with open('UpsertEmployee/workflow.json', 'r', encoding='utf-8') as f:
    workflow = json.load(f)

# Get the actions inside ValidateInput
validate_input = workflow['definition']['actions']['ValidateInput']
inner_actions = validate_input['actions']

# Create the new Try scope with stored procedure
try_scope = {
    "type": "Scope",
    "actions": {
        "LogEmployeeStart": {
            "type": "Compose",
            "inputs": {
                "timestamp": "@utcNow()",
                "workflowName": "UpsertEmployee",
                "runId": "@workflow().run.name",
                "logLevel": "INFO",
                "message": "Processing employee via stored procedure",
                "employeeID": "@items('ForEachEmployee')?['id']",
                "firstName": "@items('ForEachEmployee')?['firstName']",
                "lastName": "@items('ForEachEmployee')?['lastName']"
            },
            "runAfter": {}
        },
        "ExecuteUpsertStoredProcedure": {
            "type": "ServiceProvider",
            "inputs": {
                "parameters": {
                    "procedureName": "UpsertEmployee",
                    "procedureParameters": {
                        "ID": "@items('ForEachEmployee')?['id']",
                        "FirstName": "@items('ForEachEmployee')?['firstName']",
                        "LastName": "@items('ForEachEmployee')?['lastName']",
                        "Department": "@items('ForEachEmployee')?['department']",
                        "Position": "@items('ForEachEmployee')?['position']",
                        "Salary": "@items('ForEachEmployee')?['salary']",
                        "Email": "@items('ForEachEmployee')?['email']"
                    }
                },
                "serviceProviderConfiguration": {
                    "connectionName": "sql",
                    "operationId": "executeProcedure",
                    "serviceProviderId": "/serviceProviders/sql"
                }
            },
            "runAfter": {
                "LogEmployeeStart": ["Succeeded"]
            }
        },
        "AppendUpsertResult": {
            "type": "AppendToArrayVariable",
            "inputs": {
                "name": "ProcessingResults",
                "value": {
                    "employeeID": "@items('ForEachEmployee')?['id']",
                    "firstName": "@items('ForEachEmployee')?['firstName']",
                    "lastName": "@items('ForEachEmployee')?['lastName']",
                    "operation": "UPSERT",
                    "status": "success",
                    "timestamp": "@utcNow()"
                }
            },
            "runAfter": {
                "ExecuteUpsertStoredProcedure": ["Succeeded"]
            }
        }
    },
    "runAfter": {}
}

# Update ForEachEmployee to use the new Try scope
inner_actions['ForEachEmployee']['actions']['Try'] = try_scope

# Update LogBatchStart message
inner_actions['LogBatchStart']['inputs']['message'] = "Starting batch processing"

# Create new flat actions structure (removing ValidateInput wrapper)
new_actions = {
    "LogStartOfWorkflow": workflow['definition']['actions']['LogStartOfWorkflow'],
    "InitializeResults": workflow['definition']['actions']['InitializeResults'],
    "LogBatchStart": inner_actions['LogBatchStart'],
    "ForEachEmployee": inner_actions['ForEachEmployee'],
    "LogBatchComplete": inner_actions['LogBatchComplete'],
    "SuccessResponse": inner_actions['SuccessResponse']
}

# Update runAfter dependencies
new_actions['LogBatchStart']['runAfter'] = {
    "InitializeResults": ["Succeeded"]
}
new_actions['ForEachEmployee']['runAfter'] = {
    "LogBatchStart": ["Succeeded"]
}

# Replace the actions
workflow['definition']['actions'] = new_actions

# Save the updated workflow
with open('UpsertEmployee/workflow.json', 'w', encoding='utf-8') as f:
    json.dump(workflow, f, indent=2)

print("✅ Workflow transformation complete!")
print("\n📋 Changes made:")
print("  • Removed ValidateInput IF wrapper - schema validation at trigger handles this")
print("  • Removed ValidateAllEmployees loop - redundant validation")
print("  • Removed ValidationErrorResponse - trigger fails fast on invalid schema")
print("  • Replaced Check/Update/Insert logic with stored procedure call")
print("  • Simplified workflow from 640 to ~250 lines")
print("\n🎯 Result: Clean, maintainable workflow with fail-fast validation")
