# Monitoring & Observability Configuration Summary

## Overview
This document summarizes the monitoring and logging configuration for the Logic App Standard solution.

## Azure Resources

### 1. Log Analytics Workspace
- **Resource Name**: `LAStd-UpsertEmployee-Logs`
- **Resource Type**: Microsoft.OperationalInsights/workspaces
- **Location**: Canada Central
- **SKU**: PerGB2018
- **Workspace ID**: `8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c`
- **Data Retention**: 30 days
- **Purpose**: Central log repository for all telemetry data

### 2. Application Insights
- **Resource Name**: `ais-training-la`
- **Resource Type**: Microsoft.Insights/components
- **Location**: Canada Central
- **Application Type**: web
- **Instrumentation Key**: `714a6b4e-1c59-40c2-aba0-5d9f4ccd220d`
- **Connection String**: 
  ```
  InstrumentationKey=714a6b4e-1c59-40c2-aba0-5d9f4ccd220d;
  IngestionEndpoint=https://canadacentral-1.in.applicationinsights.azure.com/;
  LiveEndpoint=https://canadacentral.livediagnostics.monitor.azure.com/;
  ApplicationId=4aedfd7f-b888-4b64-96ff-92e453c0d91f
  ```
- **Workspace Integration**: Linked to LAStd-UpsertEmployee-Logs
- **Ingestion Mode**: LogAnalytics (all data flows to Log Analytics workspace)

## Configuration Status

### ✅ Azure Logic App Settings (Production)
The following settings are configured in the `ais-training-la` Logic App:

```bash
APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=714a6b4e-1c59-40c2-aba0-5d9f4ccd220d;IngestionEndpoint=https://canadacentral-1.in.applicationinsights.azure.com/;LiveEndpoint=https://canadacentral.livediagnostics.monitor.azure.com/;ApplicationId=4aedfd7f-b888-4b64-96ff-92e453c0d91f

APPINSIGHTS_INSTRUMENTATIONKEY=714a6b4e-1c59-40c2-aba0-5d9f4ccd220d
```

### ✅ Local Development Settings (local.settings.json)
The following settings are configured for local development:

```json
{
  "Values": {
    "LOG_ANALYTICS_WORKSPACE_ID": "8e0e91cd-3ac1-4479-b7c7-74f1e7af5f0c",
    "LOG_ANALYTICS_PRIMARY_KEY": "fw6ZBfFnxtAGuKPivop/AU0kfI8xq6vLJ/UTv7HVCrYRIDKwk+HYvCmbOJogALloqroMIPR+4TUM+PvLogDMQg==",
    "APPINSIGHTS_INSTRUMENTATIONKEY": "714a6b4e-1c59-40c2-aba0-5d9f4ccd220d",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "InstrumentationKey=714a6b4e-1c59-40c2-aba0-5d9f4ccd220d;IngestionEndpoint=https://canadacentral-1.in.applicationinsights.azure.com/;LiveEndpoint=https://canadacentral.livediagnostics.monitor.azure.com/;ApplicationId=4aedfd7f-b888-4b64-96ff-92e453c0d91f"
  }
}
```

### ✅ Infrastructure as Code (Bicep)
The `infra/main.bicep` file now includes:

1. **Log Analytics Workspace Resource**
   ```bicep
   resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
     name: logAnalyticsWorkspaceName
     properties: {
       sku: { name: 'PerGB2018' }
       retentionInDays: 30
     }
   }
   ```

2. **Application Insights Resource**
   ```bicep
   resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
     name: applicationInsightsName
     properties: {
       Application_Type: 'web'
       WorkspaceResourceId: logAnalyticsWorkspace.id
       IngestionMode: 'LogAnalytics'
     }
   }
   ```

3. **Logic App Settings**
   ```bicep
   {
     name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
     value: applicationInsights.properties.ConnectionString
   }
   {
     name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
     value: applicationInsights.properties.InstrumentationKey
   }
   ```

## Data Flow

```
Logic App Workflows
        ↓
Application Insights SDK
        ↓
Application Insights (ais-training-la)
        ↓
Log Analytics Workspace (LAStd-UpsertEmployee-Logs)
        ↓
Azure Monitor / Queries
```

## What Gets Logged

### 1. Workflow Execution Data
- Workflow triggers and runs
- Action execution details
- Input/output data (sanitized)
- Execution duration and status
- Correlation IDs for distributed tracing

### 2. Application Telemetry
- Custom metrics and events
- Dependencies (SQL, Service Bus, Storage)
- Performance counters
- Request/response data
- Exception tracking

### 3. Infrastructure Logs
- Platform logs
- Resource health events
- Diagnostic logs
- Metric data

## Querying Logs

### Using Azure Portal
1. Navigate to Application Insights: `ais-training-la`
2. Click on "Logs" in the left menu
3. Run KQL queries against the workspace

### Using Log Analytics
1. Navigate to Log Analytics Workspace: `LAStd-UpsertEmployee-Logs`
2. Click on "Logs" in the left menu
3. Run queries across all connected resources

### Sample Queries

**Recent Workflow Runs:**
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.WEB"
| where ResourceType == "SITES"
| where Category == "FunctionAppLogs"
| where OperationName contains "workflow"
| project TimeGenerated, OperationName, ResultDescription, CorrelationId
| order by TimeGenerated desc
| take 50
```

**Failed Workflows:**
```kql
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.WEB"
| where Category == "FunctionAppLogs"
| where Level == "Error"
| project TimeGenerated, Message, CorrelationId
| order by TimeGenerated desc
```

**Performance Metrics:**
```kql
requests
| where cloud_RoleName == "ais-training-la"
| summarize 
    RequestCount = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95)
    by name
| order by RequestCount desc
```

## Best Practices

### ✅ Implemented
- Single Log Analytics workspace for centralized logging
- Application Insights linked to workspace for unified experience
- Connection strings configured in both local and Azure environments
- Infrastructure as Code includes monitoring resources
- 30-day retention for compliance

### 📋 Recommended Next Steps
1. **Set up Alerts**
   - Failed workflow runs
   - High error rates
   - Performance degradation
   - Service Bus dead-letter queue messages

2. **Create Dashboards**
   - Workflow execution overview
   - Error rate trends
   - Performance metrics
   - Dependency health

3. **Enable Diagnostic Settings**
   - Service Bus namespace logs
   - Storage account logs
   - SQL database logs

4. **Configure Workbooks**
   - Custom visualizations
   - Business metrics
   - Operational insights

## Cleanup Actions Completed

### ✅ Removed Duplicate Resources
- Deleted duplicate Application Insights: `ais-training-la20251110952`
- Kept only: `ais-training-la` (properly linked to Log Analytics workspace)

### ✅ Consolidated Storage
- Using single storage account: `aistrainingshibinbf12`
- Deleted 4 unused storage accounts

## Troubleshooting

### No Telemetry in Application Insights
1. Check connection string is correct
2. Verify Logic App is running
3. Check firewall/network rules
4. Wait 2-5 minutes for data to appear

### Missing Logs in Log Analytics
1. Verify Application Insights is linked to workspace
2. Check ingestion mode is "LogAnalytics"
3. Verify workspace permissions
4. Check data retention settings

### Local Development Logging
- Local runs may not send telemetry to Application Insights
- Use local.settings.json for local configuration
- Check Azure Functions Core Tools logs

## References
- [Application Insights Overview](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Log Analytics Workspace](https://docs.microsoft.com/azure/azure-monitor/logs/log-analytics-overview)
- [Logic Apps Monitoring](https://docs.microsoft.com/azure/logic-apps/monitor-logic-apps)
- [Kusto Query Language (KQL)](https://docs.microsoft.com/azure/data-explorer/kusto/query/)
