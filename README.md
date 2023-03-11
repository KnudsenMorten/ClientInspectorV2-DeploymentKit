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
12. deployment of **Azure Workbooks**
13. deployment of **Azure Dashboards**

### Deployment
[You can see details on how to configure the deployment here](#deployment-of-clientinspector-v2-environment)

[If you want to deploy a demo environment, you can click here](deployment-of-clientinspector-v2-demo-environment)

### Workbooks & Dashboards, part of deployment
[Click here to see the included workbooks](#azure-workbooks-part-of-deployment)

[Click here to see the included dashboards](#azure-dashboards-part-of-deployment)

### Security
[Click here to see the security configured as part of deployment with 1 Azure app](#security-1)

[Click here to see the security separate with 2 Azure app's](#azure-rbac-security-adjustment-separation-of-permissions-between-log-ingestion-and-tabledcr-management)

You can configure the parameters according to you needs. Please go to [deployment section](#Deployment of ClientInspector (v2) environment)

## Introduction - ClientInspector
**ClientInspector** can be used to collect lots of great information of from your **Windows clients** - and send the data to **Azure LogAnalytics Custom Tables**.

All the data can be accessed using Kusto (KQL) queries in Azure LogAnalytics - or by the provided Azure Workbooks and Azure Dashboards

The deployment installs **13 ready-to-use workbooks** and **14 ready-to-use dashboards**.

If you want to add more views (or workbooks), you can start by investigating the collected data in the custom logs tables using KQL quries. Then make your new views in the workbooks - and pin your favorites to your dashboards.
   
**ClientInspector (v2)** is uploading the collected data into custom logs in Azure LogAnalytics workspace - using Log ingestion API, Azure Data Collection Rules (DCR) and Azure Data Collection Endpoints (DCE). 

You can run the ClientInspector script using your favorite deployment tool. Scripts for Microsoft Intune and ConfigMgr are provided. 

[Click here if you want to get detailed insight about ClientInspector](https://github.com/KnudsenMorten/ClientInspectorV2) 


## Deployment of ClientInspector (v2) environment
1. [Download all files in this Github Repository as zip to your environment](https://github.com/KnudsenMorten/ClientInspectorV2-DeploymentKit/archive/refs/heads/main.zip)
2. Open the file **Deployment.ps1** in your favorite editor
3. Change the variables to your needs
```
#------------------------------------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------------------------------------

# Azure App
$AzureAppName                    = "<put in name for your Azure App used for log ingestion>" # sample - "xxxx - Automation - Log-Ingestion"
$AzAppSecretName                 = "Secret used for Log-Ingestion"  # sample showed - use any text to show purpose of secret on Azure app

# Azure Active Directory (AAD)
$TenantId                        = "<put in your Azure AD TenantId>"

# Azure LogAnalytics
$LogAnalyticsSubscription        = "<put in the SubId of where to place environment>"
$LogAnalyticsResourceGroup       = "<put in RG name for LogAnalytics workspace>" # sample: "rg-logworkspaces"
$LoganalyticsWorkspaceName       = "<put in name of LogAnalytics workspace>" # sample: "log-platform-management-client-p"
$LoganalyticsLocation            = "<put in desired region>" # sample: westeurope


# Azure Data Collection Endpoint
$AzDceName                       = "<put in naming convention for Azure DCE>" # sample: "dce-" + $LoganalyticsWorkspaceName
$AzDceResourceGroup              = "<put in RG name for Azure DCE>" # sample: "rg-dce-" + $LoganalyticsWorkspaceName

# Azure Data Collection Rules
$AzDcrResourceGroup              = "<put in RG name for Azure DCRs>" # sample: "rg-dcr-" + $LoganalyticsWorkspaceName
$AzDcrPrefixClient               = "<put in prefix for easier sorting/searching of DCRs>" # sample: "clt" (short for client)

# Azure Workbooks & Dashboards
$TemplateCategory                = "<put in name for Azure Workbook Templates name>" # sample: "CompanyX IT Operation Security Templates"
$WorkbookDashboardResourceGroup  = "<put in RG name where workbooks/dashboards wi be deployed>" # sample: "rg-dashboards-workbooks"
```
4. Verify that you have the required Powershell modules installed. Otherwise you can do this with these commands.

		| Module          | Install cmdlet (CurrentUser-scope)
		| :-------------   | :-----|
		| Az              | Install-module Az -Scope CurrentUser |
		| Microsoft.Graph | Install-module Microsoft.Graph -Scope CurrentUser |
		| Az.Portal       | Install-module Az.portal -Scope CurrentUser |
5. Start the deployment. You will be required to login to **Azure** and **Microsoft Graph** with an account with Contributor permissions on the Azure subscription
6. When deployment is completed, you will cut/paste the updated variables on the screen - and copy it to your favorite editor

	NOTE: You need to adjust the line-separate issue

### Potential deployment issues (Azure AD replication latency)
Due to latency in Azure tenant replication, the steps with delegation sometimes do not complete on the initial run.
To mitigate this, the script will pause for 1 min - hopefully Azure AD will replicate by that time.

If it is not working, wait 10-15 min - and re-run the script, if needed - and it will fix any missing things. 
NOTE: Before doing that, grap the secret from the screen - as it will not be seen afterwards.

## Deployment of ClientInspector (v2) demo-environment
If you want to deploy a demo environment, please modify the file **Deployment-Demo.ps1** and just fill out **Azure SubscriptionId** and **Azure TenantId** - and you will get a complete environment with this configuration:

| Parameter                       | Configuration
| :-------------                  | :------------------ |
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

## Azure Workbooks, part of deployment

| Workbook Name                                | Purpose
| -------------                                | :-----|
| ANTIVIRUS SECURITY CENTER - CLIENTS - V2     | Antivirus Security Center from Windows - default antivirus, state, configuration |
| APPLICATIONS - CLIENTS - V2                  | Installed applications, both using WMI and registry |
| BITLOCKER - CLIENTS - V2                     | Bitlocker & TPM configuration |
| DEFENDER AV - CLIENTS - V2                   | Microsoft Defender Antivirus settings including ASR, exclusions, realtime protection, etc |
| GROUP POLICY REFRESH - CLIENTS - V2          | Group Policy - last refresh |
| INVENTORY - CLIENTS - V2                     | Computer information - bios, processor, hardware info, Windows OS info, OS information, last restart, vpn |
| INVENTORY COLLECTION ISSUES - CLIENTS - V2   | Collection issues related to WMI |
| LAPS - CLIENTS - V2                          | LAPS - version |
| LOCAL ADMINS - CLIENTS - V2                  | Local administrators group membership |
| NETWORK INFORMATION - CLIENTS - V2           | Network adapters, IP configuration |
| UNEXPECTED SHUTDOWNS - CLIENTS - V2          | Events from eventlog looking for specific events including logon events, blue screens, etc. |
| WINDOWS FIREWALL - CLIENTS - V2              | Windows firewall - settings for all 3 modes |
| WINDOWS UPDATE - CLIENTS - V2                | Windows Update - last result (when), windows update source information (where), pending updates, last installations (what) |

## Azure Dashboards, part of deployment

| Dashboards Name                              | Purpose
| -------------                                | :-----|
| CLIENT KPI STATUS                            | Core security and operational KPIs - related to clients |
| ANTIVIRUS SECURITY CENTER - CLIENTS - V2     | Antivirus Security Center from Windows - default antivirus, state, configuration |
| APPLICATIONS - CLIENTS - V2                  | Installed applications, both using WMI and registry |
| BITLOCKER - CLIENTS - V2                     | Bitlocker & TPM configuration |
| DEFENDER AV - CLIENTS - V2                   | Microsoft Defender Antivirus settings including ASR, exclusions, realtime protection, etc |
| GROUP POLICY REFRESH - CLIENTS - V2          | Group Policy - last refresh |
| INVENTORY - CLIENTS - V2                     | Computer information - bios, processor, hardware info, Windows OS info, OS information, last restart, vpn |
| INVENTORY COLLECTION ISSUES - CLIENTS - V2   | Collection issues related to WMI |
| LAPS - CLIENTS - V2                          | LAPS - version |
| LOCAL ADMINS - CLIENTS - V2                  | Local administrators group membership |
| NETWORK INFORMATION - CLIENTS - V2           | Network adapters, IP configuration |
| UNEXPECTED SHUTDOWNS - CLIENTS - V2          | Events from eventlog looking for specific events including logon events, blue screens, etc. |
| WINDOWS FIREWALL - CLIENTS - V2              | Windows firewall - settings for all 3 modes |
| WINDOWS UPDATE - CLIENTS - V2                | Windows Update - last result (when), windows update source information (where), pending updates, last installations (what) |


## Security
For simplicity purpose, the deployment will configure the created Azure app with RBAC permissions to both do log ingestion and table/DCR management.

| Target                                                  | Delegation To                    | Azure RBAC Permission        | Comment                                                                   | 
|:-------------                                           |:-----                            |:-----                        |:-----                                                                     |
| Azure Resource Group for Azure Data Collection Rules    | Azure app used for log ingestion | Monitoring Publisher Metrics | used to send in data                                                      |
| Azure Resource Group for Azure Data Endpoint            | Azure app used for log ingestion | Reader                       | needed to retrieve information about DCE - used as part of uploading data |
| Azure Resource Group for Azure Data Collection Rules    | Azure app used for log ingestion | Contributor                  | needed to send in data                                                    |
| Azure Resource Group for Azure Data Collection Endpoint | Azure app used for log ingestion | Contributor                  | needed to create/update DCEs (if needed after deployment)                 |
| Azure LogAnalytics Workspace                            | Azure app used for log ingestion | Contributor                  | needed to create/update Azure LogAnaltyics custom log tables              |

If you want to separate permissions from log ingestion and create/update table/DCR management, you can do this by creating a separate Azure app used for table/DCR management (fx. xxxx - Automation - Log Ingest Management). [Click here to see the security separate with 2 Azure app's](#azure-rbac-security-adjustment-separation-of-permissions-between-log-ingestion-and-tabledcr-management)

## Azure RBAC Security adjustment, separation of permissions between log ingestion and table/DCR management
You need to adjust permissions according to these settings:

| Target                                                  | Delegation To                           | Azure RBAC Permission        | Comment                                                                   | 
|:-------------                                           |:-----                                   |:-----                        |:-----                                                                     |
| Azure Resource Group for Azure Data Collection Rules    | Azure app used for log ingestion        | Monitoring Publisher Metrics | used to send in data                                                      |
| Azure Resource Group for Azure Data Endpoint            | Azure app used for log ingestion        | Reader                       | needed to retrieve information about DCE - used as part of uploading data |
| Azure Resource Group for Azure Data Collection Rules    | Azure app used for table/DCR management | Contributor                  | needed to send in data                                                    |
| Azure Resource Group for Azure Data Collection Endpoint | Azure app used for table/DCR management | Contributor                  | needed to create/update DCEs (if needed after deployment)                 |
| Azure LogAnalytics Workspace                            | Azure app used for table/DCR management | Contributor                  | needed to create/update Azure LogAnaltyics custom log tables              |

[Please go to the ClientInspector site to see how this specific scenario is configured](https://github.com/KnudsenMorten/ClientInspectorV2) 
