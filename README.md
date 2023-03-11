# ClientInspectorV2-DeploymentKit

## Introduction
The purpose of this repository is to provide everything needed to deploy a complete environment for **ClientInspector (v2)**

The deployment includes the following steps:
1. create **Azure Resource Group** for **Azure LogAnalytics Workspace**
2. create **Azure LogAnalytics Workspace**
3. create **Azure App registration** used for upload of data by ClientInspector
4. create **Azure service principal** on Azure App
5. create needed secret on **Azure app** 
6. create the **Azure Resource Group** for **Azure Data Collection Endpoint (DCE)** in same region as Azure LogAnalytics Workspace
7. create the **Azure Resource Group** for **Azure Data Collection Rules (DCR)** in same region as Azure LogAnalytics Workspace
8. create **Azure Data Collection Endpoint (DCE)** in same region as Azure LogAnalytics Workspace
9. delegate permissions for **Azure App** on **LogAnalytics workspace** - see section Security for more info
10. delegate permissions for **Azure App** on **Azure Resource Group** for **Azure Data Collection Rules (DCR)**
11. delegate permissions for **Azure App** on **Azure Resource Group** for **Azure Data Collection Endpoints (DCE)**
12. deployment of **20+ Azure Workbooks**
13. deployment of **20+ Azure Dashboards**

You can configure the parameters according to you needs. Please go to [deployment section](#Deployment of ClientInspector (v2) environment)

You can re-run the script multiple times, if needed - and it will only fix any missing things.
This can be useful, when you are dependent on Azure worldwide replication. For example delegation of permissions can sometimes fail on the initial deployment just after the Azure App was created due to Azure needs to replicate worldwide.

## Introduction - ClientInspector
**ClientInspector** will collect tons of **information from the Windows clients** - and send the data to **Azure LogAnalytics Custom Tables**.

All the data can be accessed using Kusto (KQL) queries in Loganalytics - or by the provided 20+ Azure Workbooks and **20+ Azure Dashboards**
   
[Click here can you get detailed insight to ClientInspector](https://github.com/KnudsenMorten/ClientInspectorV2) 

**ClientInspector (v2)** is uploading the collected data into custom logs in Azure LogAnalytics workspace - using Log ingestion API, Azure Data Collection Rules (DCR) and Azure Data Collection Endpoints (DCE). 

The old ClientInspector (v1) was using the HTTP Data Collector API and custom logs (MMA-format).


## Deployment of ClientInspector (v2) environment
1. [Download all files in this Github Repository as zip to your environment](https://github.com/KnudsenMorten/ClientInspectorV2-DeploymentKit/archive/refs/heads/main.zip)
2. Open the file **Deployment.ps1** in your favorite editor
3. Change the variables to your needs
```
#------------------------------------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------------------------------------

# Azure App
$AzureAppName                          = "<put in name for your Azure App used for log ingestion>" # sample - "xxxx - Automation - Log-Ingestion"
$AzAppSecretName                       = "Secret used for Log-Ingestion"  # sample showed - use any text to show purpose of secret on Azure app

# Azure Active Directory (AAD)
$TenantId                              = "<put in your Azure AD TenantId>"

# Azure LogAnalytics
$LogAnalyticsSubscription              = "<put in the SubId of where to place environment>"
$LogAnalyticsResourceGroup             = "<put in RG name for LogAnalytics workspace>" # sample: "rg-logworkspaces"
$LoganalyticsWorkspaceName             = "<put in name of LogAnalytics workspace>" # sample: "log-platform-management-client-p"
$LoganalyticsLocation                  = "<put in desired region>" # sample: westeurope


# Azure Data Collection Endpoint
$AzDceName                             = "<put in naming cnvention for Azure DCE>" # sample: "dce-" + $LoganalyticsWorkspaceName
$AzDceResourceGroup                    = "<put in RG name for Azure DCE>" # sample: "rg-dce-" + $LoganalyticsWorkspaceName

# Azure Data Collection Rules
$AzDcrResourceGroup                    = "<put in RG name for Azure DCRs>" # sample: "rg-dcr-" + $LoganalyticsWorkspaceName
$AzDcrPrefixClient                     = "<put in prefix for easier sorting/searching of DCRs>" # sample: "clt" (short for client)

# Azure Workbooks & Dashboards
$TemplateCategory                      = "<put in name for Azure Workbook Templates name>" # sample: "CompanyX IT Operation Security Templates"
$WorkbookDashboardResourceGroup        = "<put in RG name whre workbooks/dashboards wi be deployed>" # sample: "rg-dashboards-workbooks"
```

## Deployment of ClientInspector (v2) demo-environment
If you want to deploy a demo environment, please modify the file **Deployment-Demo.ps1** and just fill out **Azure SubscriptionId** and **Azure TenantId** - and you will get a complete environment with this configuration:

| Parameter                       | Configuration
| -------------                   | :-----|
| AzureAppName                    | Demo - Automation - Log-Ingestion |
| AzAppSecretName                 | Secret used for Log-Ingestion |
| LogAnalyticsResourceGroup       | rg-logworkspaces-demo |
| LoganalyticsWorkspaceName       | log-platform-management-client-demo-p |
| LoganalyticsLocation            | westeurope |
| AzDceName                       | dce-log-platform-management-client-demo-p |
| AzDceResourceGroup              | rg-dce-log-platform-management-client-demo-p |
| AzDcrResourceGroup              | rg-dcr-log-platform-management-client-demo-p |
| AzDcrPrefixClient               | clt |
| TemplateCategory                | Demo IT Operation Security Templates |
| WorkbookDashboardResourceGroup  | rg-dashboards-workbooks-demo |

#workbooks
## Azure Workbooks, part of deployment

#dashboards
## Azure Dashboards, part of deployment
