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

[If you want to deploy a demo environment, you can click here](#deployment-of-clientinspector-v2-demo-environment)

### Workbooks & Dashboards, part of deployment
[Click here to see the included workbooks](#azure-workbooks-part-of-deployment)

[Click here to see the included dashboards](#azure-dashboards-part-of-deployment)

### Security
[Click here to see the security configured as part of deployment with 1 Azure app](#security-1)

[Click here to see the security separate with 2 Azure app's](#azure-rbac-security-adjustment-separation-of-permissions-between-log-ingestion-and-tabledcr-management)

## Introduction - ClientInspector
**ClientInspector** can be used to collect lots of great information of from your **Windows clients** - and send the data to **Azure LogAnalytics Custom Tables**.

All the data can be accessed using Kusto (KQL) queries in Azure LogAnalytics - or by the provided Azure Workbooks and Azure Dashboards

The deployment installs **13 ready-to-use workbooks** and **14 ready-to-use dashboards**.

If you want to add more views (or workbooks), you can start by investigating the collected data in the custom logs tables using KQL quries. Then make your new views in the workbooks - and pin your favorites to your dashboards.
   
**ClientInspector (v2)** is uploading the collected data into custom logs in Azure LogAnalytics workspace - using Log ingestion API, Azure Data Collection Rules (DCR) and Azure Data Collection Endpoints (DCE). 

You can run the ClientInspector script using your favorite deployment tool. Scripts for Microsoft Intune and ConfigMgr are provided. 

[Click here if you want to get detailed insight about ClientInspector](https://github.com/KnudsenMorten/ClientInspectorV2) 


## Deployment of ClientInspector (v2) environment
1. [Download Deployment.ps1](https://raw.githubusercontent.com/KnudsenMorten/ClientInspectorV2-DeploymentKit/main/Deployment.ps1)
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
$LogAnalyticsResourceGroup       = "<put in RG name for LogAnalytics workspace>" # sample: "rg-logworkspaces-p"
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
$WorkbookDashboardResourceGroup  = "<put in RG name where workbooks/dashboards will be deployed>" # sample: "rg-dashboards-workbooks"
```

4. Verify that you have the required Powershell modules installed. Otherwise you can do this with these commands.

| Module          | Install cmdlet                                    |
| :-------------  | :-----                                            |
| Az              | Install-module Az -Scope CurrentUser              |
| Microsoft.Graph | Install-module Microsoft.Graph -Scope CurrentUser |
| Az.Portal       | Install-module Az.portal -Scope CurrentUser       |
		
5. Start the deployment. You will be required to login to **Azure** and **Microsoft Graph** with an account with **Contributor permissions** on the **Azure subscription**
6. When deployment is completed, you can cut/paste the variables on the screen - and copy it to your favorite editor

	NOTE: You need to adjust the line-separate issue for parameter $LogAnalyticsWorkspaceResourceId
```
$LogAnalyticsWorkspaceResourceId            = 
"/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-logworkspaces-client/providers/Microsoft.OperationalInsights/workspa
ces/log-platform-management-client-p" 
```
   must bc changed to one-liner
```
$LogAnalyticsWorkspaceResourceId            = "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-logworkspaces-client/providers/Microsoft.OperationalInsights/workspaces/log-platform-management-client-p" 
```
7. Insert the lines in the ClientInspector.ps1 file in this section
```
##########################################
# VARIABLES
##########################################

<# ----- onboarding lines ----- BEGIN #>







<#  ----- onboading lines -----  END  #>

```
Example
```
##########################################
# VARIABLES
##########################################

<# ----- onboarding lines ----- BEGIN #>

    $TenantId                                   = "xxxxxx" 
    $LogIngestAppId                             = "xxxxxx" 
    $LogIngestAppSecret                         = "xxxxx" 

    $DceName                                    = "dce-log-platform-management-client-eu01-p" 
    $LogAnalyticsWorkspaceResourceId            = "/subscriptions/6ab28656-d943-439a-9079-4fd3ac3062a1/resourceGroups/rg-logworkspaces-p/providers/Microsoft.OperationalInsights/workspaces/log-platform-management-client-eu01-p" 

    $AzDcrPrefix                                = "clt" 
    $AzDcrSetLogIngestApiAppPermissionsDcrLevel = $false
    $AzDcrLogIngestServicePrincipalObjectId     = "xxxx" 
    $AzLogDcrTableCreateFromReferenceMachine    = @()
    $AzLogDcrTableCreateFromAnyMachine          = $true

<#  ----- onboading lines -----  END  #>

```
8. You are now done with the initial setup of the infrastructure for ClientInspector.

### Potential deployment issues (Azure AD replication latency)
Due to latency in Azure tenant replication, the steps with delegation sometimes do not complete on the initial run.
To mitigate this, the script will pause for 1 min - hopefully Azure AD will replicate by that time.

If it is not working, wait 10-15 min - and re-run the script, if needed - and it will fix any missing things. 
NOTE: Before doing that, grap the secret from the screen - as it will not be seen afterwards.


<details>
  <summary><h2>Sample output of deployment</h2></summary>

```
Validating Azure context is subscription [ fce4f282-fcc6-43fb-94d8-bf1701b862c3 ]

Switching Azure context to subscription [ fce4f282-fcc6-43fb-94d8-bf1701b862c3 ]

Validating Azure resource group exist [ rg-logworkspaces-client ]

Creating Azure resource group [ rg-logworkspaces-client ]

ResourceGroupName : rg-logworkspaces-client
Location          : westeurope
ProvisioningState : Succeeded
Tags              : 
TagsTable         : 
ResourceId        : /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces-client
ManagedBy         : 


Validating Azure LogAnalytics workspace exist [ log-platform-management-client-p ]

Creating LogAnalytics workspace [ log-platform-management-client-p ] in rg-logworkspaces-client

Name                            : log-platform-management-client-p
ResourceId                      : /subscriptions/fce4f282-fcc6-43fb-94d8-xxxxxxx/resourceGroups/rg-logworkspaces-client/providers/Microsoft.OperationalInsights/workspaces/log-platform-management-client-p
ResourceGroupName               : rg-logworkspaces-client
Location                        : westeurope
Tags                            : {}
Sku                             : PerGB2018
CapacityReservationLevel        : 
LastSkuUpdate                   : 03/11/2023 09:56:16
retentionInDays                 : 30
CustomerId                      : 7b13d785-9ed1-45f6-bcd1-fda3c878a376
ProvisioningState               : Succeeded
PublicNetworkAccessForIngestion : Enabled
PublicNetworkAccessForQuery     : Enabled
PrivateLinkScopedResources      : 
WorkspaceCapping                : Microsoft.Azure.Management.OperationalInsights.Models.WorkspaceCapping
CreatedDate                     : 03/11/2023 09:56:16
ModifiedDate                    : 03/11/2023 09:56:16
ForceCmkForQuery                : 
WorkspaceFeatures               : Microsoft.Azure.Commands.OperationalInsights.Models.PSWorkspaceFeatures


Validating Azure App [ CompanyName - Automation - Log-Ingestion ]

Creating Azure App [ CompanyName - Automation - Log-Ingestion ]

Validating Azure Service Principal on App [ CompanyName - Automation - Log-Ingestion ]

Creating Azure Service Principal on App [ CompanyName - Automation - Log-Ingestion ]

Validating Azure Secret on App [ CompanyName - Automation - Log-Ingestion ]

Creating Azure Secret on App [ CompanyName - Automation - Log-Ingestion ]

Secret with name [ Secret used for Log-Ingestion ] created on app [ CompanyName - Automation - Log-Ingestion ]
<secret removed>

AppId for app [ CompanyName - Automation - Log-Ingestion ] is
8837b5cf-9b6e-46b9-8c53-3xxxxxxxxxxxxxx

Validating Azure resource group exist [ rg-dce-log-platform-management-client-p ]

Creating Azure resource group [ rg-dce-log-platform-management-client-p ]

ResourceGroupName : rg-dce-log-platform-management-client-p
Location          : westeurope
ProvisioningState : Succeeded
Tags              : 
TagsTable         : 
ResourceId        : /subscriptions/fce4f282-fcc6-43fb-94d8-xxxxxxx/resourceGroups/rg-dce-log-platform-management-client-p
ManagedBy         : 


Validating Azure resource group exist [ rg-dcr-log-platform-management-client-p ]

ResourceGroupName : rg-dcr-log-platform-management-client-p
Location          : westeurope
ProvisioningState : Succeeded
Tags              : 
TagsTable         : 
ResourceId        : /subscriptions/fce4f282-fcc6-43fbxxxxxx/resourceGroups/rg-dcr-log-platform-management-client-p
ManagedBy         : 


Validating Azure Data Collection Endpoint exist [ dce-log-platform-management-client-p ]

Creating/updating DCE [ dce-log-platform-management-client-p ]

Content           : {"properties":{"description":"DCE for LogIngest to LogAnalytics log-platform-management-client-p","immutableId":"dce-3
                    04a65e571184462bda32d447a3c1a28","configurationAccess":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.
                    westeurope-1.handler.control.monitor.azure.com"},"logsIngestion":{"endpoint":"https://dce-log-platform-management-clie
                    nt-p-nmgf.westeurope-1.ingest.monitor.azure.com"},"metricsIngestion":{"endpoint":"https://dce-log-platform-management-
                    client-p-nmgf.westeurope-1.metrics.ingest.monitor.azure.com"},"networkAcls":{"publicNetworkAccess":"Enabled"},"provisi
                    oningState":"Succeeded"},"location":"westeurope","id":"/subscriptions/fce4f282-fcc6-43fxxxxxxx/resourceGro
                    ups/rg-dce-log-platform-management-client-p/providers/Microsoft.Insights/dataCollectionEndpoints/dce-log-platform-mana
                    gement-client-p","name":"dce-log-platform-management-client-p","type":"Microsoft.Insights/dataCollectionEndpoints","et
                    ag":"\"a600cc82-0000-0d00-0000-640c506c0000\"","systemData":{"createdBy":"mok@2linkit.net","createdByType":"User","cre
                    atedAt":"2023-03-11T09:56:58.468861Z","lastModifiedBy":"mok@2linkit.net","lastModifiedByType":"User","lastModifiedAt":
                    "2023-03-11T09:56:58.468861Z"}}
ParsedHtml        : mshtml.HTMLDocumentClass
Forms             : {}
InputFields       : {}
Links             : {}
Images            : {}
Scripts           : {}
AllElements       : {@{innerHTML=<HEAD></HEAD>
                    <BODY>{"properties":{"description":"DCE for LogIngest to LogAnalytics log-platform-management-client-p","immutableId":
                    "dce-304a65e571184462bda32d447a3c1a28","configurationAccess":{"endpoint":"https://dce-log-platform-management-client-p
                    -nmgf.westeurope-1.handler.control.monitor.azure.com"},"logsIngestion":{"endpoint":"https://dce-log-platform-managemen
                    t-client-p-nmgf.westeurope-1.ingest.monitor.azure.com"},"metricsIngestion":{"endpoint":"https://dce-log-platform-manag
                    ement-client-p-nmgf.westeurope-1.metrics.ingest.monitor.azure.com"},"networkAcls":{"publicNetworkAccess":"Enabled"},"p
                    rovisioningState":"Succeeded"},"location":"westeurope","id":"/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resou
                    rceGroups/rg-dce-log-platform-management-client-p/providers/Microsoft.Insights/dataCollectionEndpoints/dce-log-platfor
                    m-management-client-p","name":"dce-log-platform-management-client-p","type":"Microsoft.Insights/dataCollectionEndpoint
                    s","etag":"\"a600cc82-0000-0d00-0000-640c506c0000\"","systemData":{"createdBy":"mok@2linkit.net","createdByType":"User
                    ","createdAt":"2023-03-11T09:56:58.468861Z","lastModifiedBy":"mok@2linkit.net","lastModifiedByType":"User","lastModifi
                    edAt":"2023-03-11T09:56:58.468861Z"}}</BODY>; innerText={"properties":{"description":"DCE for LogIngest to LogAnalytic
                    s log-platform-management-client-p","immutableId":"dce-304a65e571184462bda32d447a3c1a28","configurationAccess":{"endpo
                    int":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.handler.control.monitor.azure.com"},"logsIngestio
                    n":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.ingest.monitor.azure.com"},"metricsInge
                    stion":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.metrics.ingest.monitor.azure.com"},
                    "networkAcls":{"publicNetworkAccess":"Enabled"},"provisioningState":"Succeeded"},"location":"westeurope","id":"/subscr
                    iptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client-p/providers/Microsof
                    t.Insights/dataCollectionEndpoints/dce-log-platform-management-client-p","name":"dce-log-platform-management-client-p"
                    ,"type":"Microsoft.Insights/dataCollectionEndpoints","etag":"\"a600cc82-0000-0d00-0000-640c506c0000\"","systemData":{"
                    createdBy":"mok@2linkit.net","createdByType":"User","createdAt":"2023-03-11T09:56:58.468861Z","lastModifiedBy":"mok@2l
                    inkit.net","lastModifiedByType":"User","lastModifiedAt":"2023-03-11T09:56:58.468861Z"}}; outerHTML=<HTML><HEAD></HEAD>
                    <BODY>{"properties":{"description":"DCE for LogIngest to LogAnalytics log-platform-management-client-p","immutableId":
                    "dce-304a65e571184462bda32d447a3c1a28","configurationAccess":{"endpoint":"https://dce-log-platform-management-client-p
                    -nmgf.westeurope-1.handler.control.monitor.azure.com"},"logsIngestion":{"endpoint":"https://dce-log-platform-managemen
                    t-client-p-nmgf.westeurope-1.ingest.monitor.azure.com"},"metricsIngestion":{"endpoint":"https://dce-log-platform-manag
                    ement-client-p-nmgf.westeurope-1.metrics.ingest.monitor.azure.com"},"networkAcls":{"publicNetworkAccess":"Enabled"},"p
                    rovisioningState":"Succeeded"},"location":"westeurope","id":"/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resou
                    rceGroups/rg-dce-log-platform-management-client-p/providers/Microsoft.Insights/dataCollectionEndpoints/dce-log-platfor
                    m-management-client-p","name":"dce-log-platform-management-client-p","type":"Microsoft.Insights/dataCollectionEndpoint
                    s","etag":"\"a600cc82-0000-0d00-0000-640c506c0000\"","systemData":{"createdBy":"mok@2linkit.net","createdByType":"User
                    ","createdAt":"2023-03-11T09:56:58.468861Z","lastModifiedBy":"mok@2linkit.net","lastModifiedByType":"User","lastModifi
                    edAt":"2023-03-11T09:56:58.468861Z"}}</BODY></HTML>; outerText={"properties":{"description":"DCE for LogIngest to LogA
                    nalytics log-platform-management-client-p","immutableId":"dce-304a65e571184462bda32d447a3c1a28","configurationAccess":
                    {"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.handler.control.monitor.azure.com"},"logsI
                    ngestion":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.ingest.monitor.azure.com"},"metr
                    icsIngestion":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.metrics.ingest.monitor.azure
                    .com"},"networkAcls":{"publicNetworkAccess":"Enabled"},"provisioningState":"Succeeded"},"location":"westeurope","id":"
                    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client-p/providers/M
                    icrosoft.Insights/dataCollectionEndpoints/dce-log-platform-management-client-p","name":"dce-log-platform-management-cl
                    ient-p","type":"Microsoft.Insights/dataCollectionEndpoints","etag":"\"a600cc82-0000-0d00-0000-640c506c0000\"","systemD
                    ata":{"createdBy":"mok@2linkit.net","createdByType":"User","createdAt":"2023-03-11T09:56:58.468861Z","lastModifiedBy":
                    "mok@2linkit.net","lastModifiedByType":"User","lastModifiedAt":"2023-03-11T09:56:58.468861Z"}}; tagName=HTML}, @{inner
                    HTML=; innerText=; outerHTML=<HEAD></HEAD>; outerText=; tagName=HEAD}, @{innerHTML=; innerText=; outerHTML=; outerText
                    =; tagName=TITLE}, @{innerHTML={"properties":{"description":"DCE for LogIngest to LogAnalytics log-platform-management
                    -client-p","immutableId":"dce-304a65e571184462bda32d447a3c1a28","configurationAccess":{"endpoint":"https://dce-log-pla
                    tform-management-client-p-nmgf.westeurope-1.handler.control.monitor.azure.com"},"logsIngestion":{"endpoint":"https://d
                    ce-log-platform-management-client-p-nmgf.westeurope-1.ingest.monitor.azure.com"},"metricsIngestion":{"endpoint":"https
                    ://dce-log-platform-management-client-p-nmgf.westeurope-1.metrics.ingest.monitor.azure.com"},"networkAcls":{"publicNet
                    workAccess":"Enabled"},"provisioningState":"Succeeded"},"location":"westeurope","id":"/subscriptions/fce4f282-fcc6-43f
                    b-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client-p/providers/Microsoft.Insights/dataCollection
                    Endpoints/dce-log-platform-management-client-p","name":"dce-log-platform-management-client-p","type":"Microsoft.Insigh
                    ts/dataCollectionEndpoints","etag":"\"a600cc82-0000-0d00-0000-640c506c0000\"","systemData":{"createdBy":"mok@2linkit.n
                    et","createdByType":"User","createdAt":"2023-03-11T09:56:58.468861Z","lastModifiedBy":"mok@2linkit.net","lastModifiedB
                    yType":"User","lastModifiedAt":"2023-03-11T09:56:58.468861Z"}}; innerText={"properties":{"description":"DCE for LogIng
                    est to LogAnalytics log-platform-management-client-p","immutableId":"dce-304a65e571184462bda32d447a3c1a28","configurat
                    ionAccess":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.handler.control.monitor.azure.c
                    om"},"logsIngestion":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.ingest.monitor.azure.
                    com"},"metricsIngestion":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.metrics.ingest.mo
                    nitor.azure.com"},"networkAcls":{"publicNetworkAccess":"Enabled"},"provisioningState":"Succeeded"},"location":"westeur
                    ope","id":"/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client-p/
                    providers/Microsoft.Insights/dataCollectionEndpoints/dce-log-platform-management-client-p","name":"dce-log-platform-ma
                    nagement-client-p","type":"Microsoft.Insights/dataCollectionEndpoints","etag":"\"a600cc82-0000-0d00-0000-640c506c0000\
                    "","systemData":{"createdBy":"mok@2linkit.net","createdByType":"User","createdAt":"2023-03-11T09:56:58.468861Z","lastM
                    odifiedBy":"mok@2linkit.net","lastModifiedByType":"User","lastModifiedAt":"2023-03-11T09:56:58.468861Z"}}; outerHTML=
                    <BODY>{"properties":{"description":"DCE for LogIngest to LogAnalytics log-platform-management-client-p","immutableId":
                    "dce-304a65e571184462bda32d447a3c1a28","configurationAccess":{"endpoint":"https://dce-log-platform-management-client-p
                    -nmgf.westeurope-1.handler.control.monitor.azure.com"},"logsIngestion":{"endpoint":"https://dce-log-platform-managemen
                    t-client-p-nmgf.westeurope-1.ingest.monitor.azure.com"},"metricsIngestion":{"endpoint":"https://dce-log-platform-manag
                    ement-client-p-nmgf.westeurope-1.metrics.ingest.monitor.azure.com"},"networkAcls":{"publicNetworkAccess":"Enabled"},"p
                    rovisioningState":"Succeeded"},"location":"westeurope","id":"/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resou
                    rceGroups/rg-dce-log-platform-management-client-p/providers/Microsoft.Insights/dataCollectionEndpoints/dce-log-platfor
                    m-management-client-p","name":"dce-log-platform-management-client-p","type":"Microsoft.Insights/dataCollectionEndpoint
                    s","etag":"\"a600cc82-0000-0d00-0000-640c506c0000\"","systemData":{"createdBy":"mok@2linkit.net","createdByType":"User
                    ","createdAt":"2023-03-11T09:56:58.468861Z","lastModifiedBy":"mok@2linkit.net","lastModifiedByType":"User","lastModifi
                    edAt":"2023-03-11T09:56:58.468861Z"}}</BODY>; outerText={"properties":{"description":"DCE for LogIngest to LogAnalytic
                    s log-platform-management-client-p","immutableId":"dce-304a65e571184462bda32d447a3c1a28","configurationAccess":{"endpo
                    int":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.handler.control.monitor.azure.com"},"logsIngestio
                    n":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.ingest.monitor.azure.com"},"metricsInge
                    stion":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.westeurope-1.metrics.ingest.monitor.azure.com"},
                    "networkAcls":{"publicNetworkAccess":"Enabled"},"provisioningState":"Succeeded"},"location":"westeurope","id":"/subscr
                    iptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client-p/providers/Microsof
                    t.Insights/dataCollectionEndpoints/dce-log-platform-management-client-p","name":"dce-log-platform-management-client-p"
                    ,"type":"Microsoft.Insights/dataCollectionEndpoints","etag":"\"a600cc82-0000-0d00-0000-640c506c0000\"","systemData":{"
                    createdBy":"mok@2linkit.net","createdByType":"User","createdAt":"2023-03-11T09:56:58.468861Z","lastModifiedBy":"mok@2l
                    inkit.net","lastModifiedByType":"User","lastModifiedAt":"2023-03-11T09:56:58.468861Z"}}; tagName=BODY}}
StatusCode        : 200
StatusDescription : OK
RawContentStream  : Microsoft.PowerShell.Commands.WebResponseContentMemoryStream
RawContentLength  : 1211
RawContent        : HTTP/1.1 200 OK
                    Pragma: no-cache
                    Vary: Accept-Encoding
                    x-ms-ratelimit-remaining-subscription-resource-requests: 59
                    Request-Context: appId=cid-v1:2bbfbac8-e1b0-44af-b9c6-3a40669d37e3
                    x-ms-correlation-request-id: 839c2ac5-7fda-4832-91c1-9b712c3cae3b
                    x-ms-client-request-id: eafa86b0-4b30-42bd-b31c-5c68fe4adff7
                    x-ms-routing-request-id: WESTEUROPE:20230311T095658Z:839c2ac5-7fda-4832-91c1-9b712c3cae3b
                    x-ms-request-id: 6a24033b-75ee-4147-8686-66de7a1a89f5
                    api-supported-versions: 2021-04-01, 2021-09-01-preview, 2022-06-01
                    Strict-Transport-Security: max-age=31536000; includeSubDomains
                    X-Content-Type-Options: nosniff
                    Content-Length: 1211
                    Cache-Control: no-cache
                    Content-Type: application/json; charset=utf-8
                    Date: Sat, 11 Mar 2023 09:57:00 GMT
                    Expires: -1
                    Server: Microsoft-HTTPAPI/2.0
                    
                    {"properties":{"description":"DCE for LogIngest to LogAnalytics log-platform-management-client-p","immutableId":"dce-3
                    04a65e571184462bda32d447a3c1a28","configurationAccess":{"endpoint":"https://dce-log-platform-management-client-p-nmgf.
                    westeurope-1.handler.control.monitor.azure.com"},"logsIngestion":{"endpoint":"https://dce-log-platform-management-clie
                    nt-p-nmgf.westeurope-1.ingest.monitor.azure.com"},"metricsIngestion":{"endpoint":"https://dce-log-platform-management-
                    client-p-nmgf.westeurope-1.metrics.ingest.monitor.azure.com"},"networkAcls":{"publicNetworkAccess":"Enabled"},"provisi
                    oningState":"Succeeded"},"location":"westeurope","id":"/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGro
                    ups/rg-dce-log-platform-management-client-p/providers/Microsoft.Insights/dataCollectionEndpoints/dce-log-platform-mana
                    gement-client-p","name":"dce-log-platform-management-client-p","type":"Microsoft.Insights/dataCollectionEndpoints","et
                    ag":"\"a600cc82-0000-0d00-0000-640c506c0000\"","systemData":{"createdBy":"mok@2linkit.net","createdByType":"User","cre
                    atedAt":"2023-03-11T09:56:58.468861Z","lastModifiedBy":"mok@2linkit.net","lastModifiedByType":"User","lastModifiedAt":
                    "2023-03-11T09:56:58.468861Z"}}
BaseResponse      : System.Net.HttpWebResponse
Headers           : {[Pragma, no-cache], [Vary, Accept-Encoding], [x-ms-ratelimit-remaining-subscription-resource-requests, 59], [Request-
                    Context, appId=cid-v1:2bbfbac8-e1b0-44af-b9c6-3a40669d37e3]...}

Sleeping 1 min to let Azure AD replication, before doing delegation

Setting Contributor permissions for app [ CompanyName - Automation - Log-Ingestion ] on Loganalytics workspace [ log-platform-management-cl
ient-p ]

Setting Contributor permissions for app [ CompanyName - Automation - Log-Ingestion ] on RG [ rg-dcr-log-platform-management-client-p ]

Setting Monitoring Metrics Publisher permissions for app [ CompanyName - Automation - Log-Ingestion ] on RG [ rg-dcr-log-platform-managemen
t-client-p ]

Setting Reader permissions for app [ dce-log-platform-management-client-p ] on RG [ rg-dce-log-platform-management-client-p ]
Building list Azure workbooks to deploy

Validating Azure resource group exist [ rg-dashboards-workbooks-demo ]

Creating Azure resource group [ rg-dashboards-workbooks-demo ]

ResourceGroupName : rg-dashboards-workbooks-demo
Location          : westeurope
ProvisioningState : Succeeded
Tags              : 
TagsTable         : 
ResourceId        : /subscriptions/fce4f282-fcc6-43fb-9xxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo
ManagedBy         : 


Deployment of Azure Workbook [ ANTIVIRUS SECURITY CENTER - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ ANTIVIRUS SECURITY CENTER - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ ANTIVIRUS SECURITY CENTER - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:58:15 - Template is valid.
VERBOSE: 10:58:16 - Create template deployment 'ArmDeployment31301'
VERBOSE: 10:58:16 - Checking deployment status in 5 seconds
VERBOSE: 10:58:21 - Resource microsoft.insights/workbooktemplates 'ANTIVIRUS SECURITY CENTER - CLIENTS - V2' provisioning status is succeed
ed

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment31301
CorrelationId           : 9346dfaa-332f-4f16-b1d8-8424d5fd7b84
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:58:19
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      ANTIVIRUS SECURITY CENTER - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      9af1b0c9-12fa-4bc4-b6d3-dc8bac88e729
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "ANTIVIRUS SECURITY CENTER - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "9af1b0c9-12fa-4bc4-b6d3-dc8bac88e729"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/9af1b0c9-12fa-4bc4-b6d3-dc8bac88e729
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/9af1b0c9-12fa-4bc4-b6d3-dc8bac88e729"
                          


Deployment of Azure Workbook [ APPLICATIONS - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ APPLICATIONS - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ APPLICATIONS - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:58:22 - Template is valid.
VERBOSE: 10:58:22 - Create template deployment 'ArmDeployment37382'
VERBOSE: 10:58:22 - Checking deployment status in 5 seconds
VERBOSE: 10:58:27 - Resource microsoft.insights/workbooktemplates 'APPLICATIONS - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment37382
CorrelationId           : 84d731b1-9a72-44ba-a832-f17bdbc140a4
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:58:25
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      APPLICATIONS - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      d1c5a2db-4be1-4b64-96ef-5d388c43556a
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "APPLICATIONS - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "d1c5a2db-4be1-4b64-96ef-5d388c43556a"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/d1c5a2db-4be1-4b64-96ef-5d388c43556a
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/d1c5a2db-4be1-4b64-96ef-5d388c43556a"
                          


Deployment of Azure Workbook [ BITLOCKER - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ BITLOCKER - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ BITLOCKER - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:58:29 - Template is valid.
VERBOSE: 10:58:29 - Create template deployment 'ArmDeployment37905'
VERBOSE: 10:58:29 - Checking deployment status in 5 seconds
VERBOSE: 10:58:34 - Resource microsoft.insights/workbooktemplates 'BITLOCKER - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment37905
CorrelationId           : 7a68a4e8-4aaa-48c6-bed1-b58c53ab3d69
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:58:31
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      BITLOCKER - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      cc803d4a-8815-4d1c-b739-c9967617bad5
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "BITLOCKER - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "cc803d4a-8815-4d1c-b739-c9967617bad5"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/cc803d4a-8815-4d1c-b739-c9967617bad5
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/cc803d4a-8815-4d1c-b739-c9967617bad5"
                          


Deployment of Azure Workbook [ DEFENDER AV - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ DEFENDER AV - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ DEFENDER AV - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:58:35 - Template is valid.
VERBOSE: 10:58:36 - Create template deployment 'ArmDeployment19884'
VERBOSE: 10:58:36 - Checking deployment status in 5 seconds
VERBOSE: 10:58:41 - Resource microsoft.insights/workbooktemplates 'DEFENDER AV - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment19884
CorrelationId           : d372b732-1ac8-49b6-9d44-9fca678d1fd7
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:58:38
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      DEFENDER AV - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      537c5d6c-a4d9-4138-881f-341db79f00ae
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "DEFENDER AV - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "537c5d6c-a4d9-4138-881f-341db79f00ae"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/537c5d6c-a4d9-4138-881f-341db79f00ae
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/537c5d6c-a4d9-4138-881f-341db79f00ae"
                          


Deployment of Azure Workbook [ GROUP POLICY REFRESH - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ GROUP POLICY REFRESH - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ GROUP POLICY REFRESH - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:58:41 - Template is valid.
VERBOSE: 10:58:42 - Create template deployment 'ArmDeployment6794'
VERBOSE: 10:58:42 - Checking deployment status in 5 seconds
VERBOSE: 10:58:47 - Resource microsoft.insights/workbooktemplates 'GROUP POLICY REFRESH - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment6794
CorrelationId           : d9188dcf-c5b3-4ebe-8107-3291775cb736
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:58:45
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      GROUP POLICY REFRESH - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      992a0767-ca48-4253-95cf-63022b734b96
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "GROUP POLICY REFRESH - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "992a0767-ca48-4253-95cf-63022b734b96"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/992a0767-ca48-4253-95cf-63022b734b96
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/992a0767-ca48-4253-95cf-63022b734b96"
                          


Deployment of Azure Workbook [ INVENTORY - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ INVENTORY - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ INVENTORY - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:58:48 - Template is valid.
VERBOSE: 10:58:48 - Create template deployment 'ArmDeployment68655'
VERBOSE: 10:58:48 - Checking deployment status in 5 seconds
VERBOSE: 10:58:53 - Resource microsoft.insights/workbooktemplates 'INVENTORY - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment68655
CorrelationId           : a872ad1b-85eb-4ccc-a538-d6ceb8216eb0
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:58:50
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      INVENTORY - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      17d51514-1846-4fec-8cf1-39a24bb1a8d4
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "INVENTORY - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "17d51514-1846-4fec-8cf1-39a24bb1a8d4"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/17d51514-1846-4fec-8cf1-39a24bb1a8d4
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/17d51514-1846-4fec-8cf1-39a24bb1a8d4"
                          


Deployment of Azure Workbook [ INVENTORY COLLECTION ISSUES - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ INVENTORY COLLECTION ISSUES - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ INVENTORY COLLECTION ISSUES - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:58:54 - Template is valid.
VERBOSE: 10:58:54 - Create template deployment 'ArmDeployment42415'
VERBOSE: 10:58:54 - Checking deployment status in 5 seconds
VERBOSE: 10:58:59 - Resource microsoft.insights/workbooktemplates 'INVENTORY COLLECTION ISSUES - CLIENTS - V2' provisioning status is succe
eded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment42415
CorrelationId           : d7466d25-8c1d-45bf-bb5d-25e3171dcec5
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:58:57
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      INVENTORY COLLECTION ISSUES - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      5cb4403e-f3d2-4711-9a69-9747fd94dc5b
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "INVENTORY COLLECTION ISSUES - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "5cb4403e-f3d2-4711-9a69-9747fd94dc5b"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/5cb4403e-f3d2-4711-9a69-9747fd94dc5b
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/5cb4403e-f3d2-4711-9a69-9747fd94dc5b"
                          


Deployment of Azure Workbook [ LAPS - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ LAPS - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ LAPS - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:59:00 - Template is valid.
VERBOSE: 10:59:01 - Create template deployment 'ArmDeployment88500'
VERBOSE: 10:59:01 - Checking deployment status in 5 seconds
VERBOSE: 10:59:06 - Resource microsoft.insights/workbooktemplates 'LAPS - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment88500
CorrelationId           : f6c75626-d8b3-4ba2-ab22-f22156b05e42
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:59:03
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      LAPS - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      22838ebd-8c52-41de-b495-87cc9230c282
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "LAPS - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "22838ebd-8c52-41de-b495-87cc9230c282"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/22838ebd-8c52-41de-b495-87cc9230c282
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/22838ebd-8c52-41de-b495-87cc9230c282"
                          


Deployment of Azure Workbook [ LOCAL ADMINS - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ LOCAL ADMINS - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ LOCAL ADMINS - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:59:07 - Template is valid.
VERBOSE: 10:59:07 - Create template deployment 'ArmDeployment22890'
VERBOSE: 10:59:07 - Checking deployment status in 5 seconds
VERBOSE: 10:59:12 - Resource microsoft.insights/workbooktemplates 'LOCAL ADMINS - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment22890
CorrelationId           : 369ffb96-a6fe-4c69-9719-94c0c2238b2f
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:59:10
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      LOCAL ADMINS - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      b3337012-27c9-4901-ac2e-d09d94b5adf2
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "LOCAL ADMINS - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "b3337012-27c9-4901-ac2e-d09d94b5adf2"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/b3337012-27c9-4901-ac2e-d09d94b5adf2
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/b3337012-27c9-4901-ac2e-d09d94b5adf2"
                          


Deployment of Azure Workbook [ NETWORK INFORMATION - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ NETWORK INFORMATION - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ NETWORK INFORMATION - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:59:13 - Template is valid.
VERBOSE: 10:59:13 - Create template deployment 'ArmDeployment12479'
VERBOSE: 10:59:13 - Checking deployment status in 5 seconds
VERBOSE: 10:59:18 - Resource microsoft.insights/workbooktemplates 'NETWORK INFORMATION - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment12479
CorrelationId           : 4601724d-7fe8-45f5-a4a8-39299d2abe53
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:59:16
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      NETWORK INFORMATION - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      1fbc5236-e368-4aae-9465-08ce8afecfbd
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "NETWORK INFORMATION - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "1fbc5236-e368-4aae-9465-08ce8afecfbd"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/1fbc5236-e368-4aae-9465-08ce8afecfbd
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/1fbc5236-e368-4aae-9465-08ce8afecfbd"
                          


Deployment of Azure Workbook [ OFFICE - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ OFFICE - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ OFFICE - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:59:19 - Template is valid.
VERBOSE: 10:59:20 - Create template deployment 'ArmDeployment27643'
VERBOSE: 10:59:20 - Checking deployment status in 5 seconds
VERBOSE: 10:59:25 - Resource microsoft.insights/workbooktemplates 'OFFICE - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment27643
CorrelationId           : 4771722a-6fdd-462d-904b-6675a558bf9d
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:59:22
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      OFFICE - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      af40c550-8dd3-4da5-bd61-d41ad4e237ff
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "OFFICE - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "af40c550-8dd3-4da5-bd61-d41ad4e237ff"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/af40c550-8dd3-4da5-bd61-d41ad4e237ff
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/af40c550-8dd3-4da5-bd61-d41ad4e237ff"
                          


Deployment of Azure Workbook [ UNEXPECTED SHUTDOWNS - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ UNEXPECTED SHUTDOWNS - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ UNEXPECTED SHUTDOWNS - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:59:26 - Template is valid.
VERBOSE: 10:59:26 - Create template deployment 'ArmDeployment3361'
VERBOSE: 10:59:26 - Checking deployment status in 5 seconds
VERBOSE: 10:59:31 - Resource microsoft.insights/workbooktemplates 'UNEXPECTED SHUTDOWNS - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment3361
CorrelationId           : 020ff7fd-7b44-4f55-ab13-2d6d27962224
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:59:28
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      UNEXPECTED SHUTDOWNS - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      cf5c8933-83a5-4e46-9576-e94765136baa
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "UNEXPECTED SHUTDOWNS - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "cf5c8933-83a5-4e46-9576-e94765136baa"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/cf5c8933-83a5-4e46-9576-e94765136baa
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/cf5c8933-83a5-4e46-9576-e94765136baa"
                          


Deployment of Azure Workbook [ WINDOWS FIREWALL - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ WINDOWS FIREWALL - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ WINDOWS FIREWALL - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:59:32 - Template is valid.
VERBOSE: 10:59:32 - Create template deployment 'ArmDeployment12329'
VERBOSE: 10:59:32 - Checking deployment status in 5 seconds
VERBOSE: 10:59:38 - Resource microsoft.insights/workbooktemplates 'WINDOWS FIREWALL - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment12329
CorrelationId           : 62b58e1b-9d59-4556-9bad-41ff203a8baf
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:59:35
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      WINDOWS FIREWALL - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      e4f46179-360b-4ceb-927d-85d757ef29e1
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "WINDOWS FIREWALL - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "e4f46179-360b-4ceb-927d-85d757ef29e1"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/e4f46179-360b-4ceb-927d-85d757ef29e1
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/e4f46179-360b-4ceb-927d-85d757ef29e1"
                          


Deployment of Azure Workbook [ WINDOWS UPDATE - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
   Building temporary ARM template [ WINDOWS UPDATE - CLIENTS - V2.txt ] in C:\Users\MOK~1.2LI\AppData\Local\Temp folder
   Starting deployment of workbook [ WINDOWS UPDATE - CLIENTS - V2 ] 

VERBOSE: Performing the operation "Creating Deployment" on target "rg-dashboards-workbooks-demo".
VERBOSE: 10:59:38 - Template is valid.
VERBOSE: 10:59:39 - Create template deployment 'ArmDeployment7396'
VERBOSE: 10:59:39 - Checking deployment status in 5 seconds
VERBOSE: 10:59:44 - Resource microsoft.insights/workbooktemplates 'WINDOWS UPDATE - CLIENTS - V2' provisioning status is succeeded

ResourceGroupName       : rg-dashboards-workbooks-demo
OnErrorDeployment       : 
DeploymentName          : ArmDeployment7396
CorrelationId           : 1b7615e5-ddc8-42ae-be74-2b020bac0219
ProvisioningState       : Succeeded
Timestamp               : 11-03-2023 09:59:41
Mode                    : Incremental
TemplateLink            : 
TemplateLinkString      : 
DeploymentDebugLogLevel : 
Parameters              : {[workbookDisplayName, 
                          Type        Value     
                          ----------  ----------
                          String      WINDOWS UPDATE - CLIENTS - V2
                          ], [workbookType, 
                          Type        Value     
                          ----------  ----------
                          String      workbook  
                          ], [workbookSourceId, 
                          Type        Value     
                          ----------  ----------
                          String      Azure Monitor
                          ], [workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      9827e5e4-a754-4aac-8b39-2eee0876761d
                          ]}
Tags                    : 
ParametersString        : 
                          Name                   Type                       Value     
                          =====================  =========================  ==========
                          workbookDisplayName    String                     "WINDOWS UPDATE - CLIENTS - V2"
                          workbookType           String                     "workbook"
                          workbookSourceId       String                     "Azure Monitor"
                          workbookId             String                     "9827e5e4-a754-4aac-8b39-2eee0876761d"
                          
Outputs                 : {[workbookId, 
                          Type        Value     
                          ----------  ----------
                          String      /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/prov
                          iders/microsoft.insights/workbooks/9827e5e4-a754-4aac-8b39-2eee0876761d
                          ]}
OutputsString           : 
                          Name             Type                       Value     
                          ===============  =========================  ==========
                          workbookId       String                     "/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/
                          rg-dashboards-workbooks-demo/providers/microsoft.insights/workbooks/9827e5e4-a754-4aac-8b39-2eee0876761d"
                          

Building list Azure dashboards to deploy

Validating Azure resource group exist [ rg-dashboards-workbooks-demo ]

ResourceGroupName : rg-dashboards-workbooks-demo
Location          : westeurope
ProvisioningState : Succeeded
Tags              : 
TagsTable         : 
ResourceId        : /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo
ManagedBy         : 


Deployment of Azure Dashboard [ APPLICATIONS - CLIENTS - V2 ] in progress .... please wait !
   Adjusting ARM template with LogAnalytics workspace information
lense 0
part  0
lense 0
part  1
   Starting deployment of dashboard [ APPLICATIONS - CLIENTS - V2 ] 


Id       : /subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-dashboards-workbooks-demo/providers/Microsoft.Portal/dash
           boards/APPLICATIONS_-_CLIENTS_-_V2
Lens     : Microsoft.Azure.PowerShell.Cmdlets.Portal.Models.Api201901Preview.DashboardPropertiesLenses
Location : westeurope
Metadata : Microsoft.Azure.PowerShell.Cmdlets.Portal.Models.Api201901Preview.DashboardPropertiesMetadata
Name     : APPLICATIONS_-_CLIENTS_-_V2
Tag      : Microsoft.Azure.PowerShell.Cmdlets.Portal.Models.Api201901Preview.DashboardTags
Type     : Microsoft.Portal/dashboards


Tenant Id:
f0fa27a0-8e7c-4f63-9a77-ec94786b7c9e

LogIngestion Azure App Name:
CompanyName - Automation - Log-Ingestion

LogIngestion Azure App Id:
8837b5cf-9b6e-46b9-8c53-3d66137c13d9
LogIngestion Azure App Secret:
<<<removed>>>

LogIngestion Azure Service Principal Object Id for app:
5a1cba73-26f3-4267-9078-259ee35e0bc4

Azure LogAnalytics Workspace Resource Id:
/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-logworkspaces-client/providers/Microsoft.OperationalInsights/workspac
es/log-platform-management-client-p

Azure Data Collection Endpoint Name:
dce-log-platform-management-client-p

Azure Data Collection Endpoint Log Ingestion Uri:
https://dce-log-platform-management-client-p-nmgf.westeurope-1.ingest.monitor.azure.com

-------------------------------------------------

Please insert these lines in ClientInspector:

$TenantId                                   = "f0fa27a0-8e7c-4f63-9a77-ec94786b7c9e" 
$LogIngestAppId                             = "8837b5cf-9b6e-46b9-8c53-3d66137c13d9" 
$LogIngestAppSecret                         = "<<<removed>>>" 

$DceName                                    = "dce-log-platform-management-client-p" 
$LogAnalyticsWorkspaceResourceId            = 
"/subscriptions/fce4f282-fcc6-43fb-94d8-bfxxxxxxxxx/resourceGroups/rg-logworkspaces-client/providers/Microsoft.OperationalInsights/workspa
ces/log-platform-management-client-p" 

$AzDcrPrefix                                = "clt" 
$AzDcrSetLogIngestApiAppPermissionsDcrLevel = $false
$AzDcrLogIngestServicePrincipalObjectId     = "5a1cba73-26f3-4267-9078-259ee35e0bc4" 
$AzLogDcrTableCreateFromReferenceMachine    = @()
$AzDcrDceTableCreateFromAnyMachine          = $true

```
</details>


## Deployment of ClientInspector (v2) demo-environment
If you want to deploy a demo environment, please [download and modify the file Deployment-DemoEnvironment.ps1](https://raw.githubusercontent.com/KnudsenMorten/ClientInspectorV2-DeploymentKit/main/Deployment-DemoEnvironment.ps1) and just fill out **Azure SubscriptionId** and **Azure TenantId** - and you will get a complete environment with this configuration. 

You will have the option to control the demo number using the $UseRandomNumber = $true/false. If you choose $true the number will randomize, so it is easy to re-run multiple times.

| Parameter                       | Configuration                                |
| :-------------                  | :------------------                          |
| AzureAppName                    | Demo1 - Automation - Log-Ingestion            |
| AzAppSecretName                 | Secret used for Log-Ingestion                |
| LogAnalyticsResourceGroup       | rg-logworkspaces-demo1                        |
| LoganalyticsWorkspaceName       | log-platform-management-client-demo1-p        |
| LoganalyticsLocation            | westeurope                                   |
| AzDceName                       | dce-log-platform-management-client-demo1-p    |
| AzDceResourceGroup              | rg-dce-log-platform-management-client-demo1-p |
| AzDcrResourceGroup              | rg-dcr-log-platform-management-client-demo1-p |
| AzDcrPrefix                     | clt                                          |
| TemplateCategory                | Demo IT Operation Security Templates         |
| WorkbookDashboardResourceGroup  | rg-dashboards-workbooks-demo1                 |

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
| CLIENT KPI STATUS | CLIENTS | MANAGED DASHBOARD (V2)            | Core security and operational KPIs - related to clients |
| ANTIVIRUS SECURITY CENTER | CLIENTS | MANAGED DASHBOARD (V2)    | Antivirus Security Center from Windows - default antivirus, state, configuration |
| APPLICATIONS | CLIENTS | MANAGED DASHBOARD (V2)                 | Installed applications, both using WMI and registry |
| BITLOCKER | CLIENTS | MANAGED DASHBOARD (V2)                    | Bitlocker & TPM configuration |
| DEFENDER AV | CLIENTS | MANAGED DASHBOARD (V2)                  | Microsoft Defender Antivirus settings including ASR, exclusions, realtime protection, etc |
| GROUP POLICY REFRESH | CLIENTS | MANAGED DASHBOARD (V2)         | Group Policy - last refresh |
| INVENTORY | CLIENTS | MANAGED DASHBOARD (V2)                    | Computer information - bios, processor, hardware info, Windows OS info, OS information, last restart, vpn |
| INVENTORY COLLECTION ISSUES | CLIENTS | MANAGED DASHBOARD (V2)  | Collection issues related to WMI |
| LAPS | CLIENTS | MANAGED DASHBOARD (V2)                         | LAPS - version |
| LOCAL ADMINS | CLIENTS | MANAGED DASHBOARD (V2)                 | Local administrators group membership |
| NETWORK INFORMATION | CLIENTS | MANAGED DASHBOARD (V2)          | Network adapters, IP configuration |
| UNEXPECTED SHUTDOWNS | CLIENTS | MANAGED DASHBOARD (V2)         | Events from eventlog looking for specific events including logon events, blue screens, etc. |
| WINDOWS FIREWALL | CLIENTS | MANAGED DASHBOARD (V2)             | Windows firewall - settings for all 3 modes |
| WINDOWS UPDATE | CLIENTS | MANAGED DASHBOARD (V2)               | Windows Update - last result (when), windows update source information (where), pending updates, last installations (what) |


## Security


For simplicity demo-purpose, the deployment will configure the created Azure app with RBAC permissions to both do log ingestion and table/DCR management. If you want to go into product, I recommend, that you implement separation 

| Target                                                  | Delegation To                    | Azure RBAC Permission        | Comment                                                                   | 
|:-------------                                           |:-----                            |:-----                        |:-----                                                                     |
| Azure Resource Group for Azure Data Collection Rules    | Azure app used for log ingestion | Monitoring Publisher Metrics | used to send in data                                                      |
| Azure Resource Group for Azure Data Endpoint            | Azure app used for log ingestion | Reader                       | needed to retrieve information about DCE - used as part of uploading data |
| Azure Resource Group for Azure Data Collection Rules    | Azure app used for log ingestion | Contributor                  | needed to send in data                                                    |
| Azure Resource Group for Azure Data Collection Endpoint | Azure app used for log ingestion | Contributor                  | needed to create/update DCEs (if needed after deployment)                 |
| Azure LogAnalytics Workspace                            | Azure app used for log ingestion | Contributor                  | needed to create/update Azure LogAnaltyics custom log tables              |

If you want to separate permissions from log ingestion and create/update table/DCR management, you can do this by creating a separate Azure app used for table/DCR management (fx. xxxx - Automation - Log Ingest Management). [Click here to see the security separate with 2 Azure app's](#azure-rbac-security-adjustment-separation-of-permissions-between-log-ingestion-and-tabledcr-management)

## Azure RBAC Security adjustment, separation of permissions between log ingestion and table/DCR management
If you want to separate the log ingestion process with the table management process, you can do this by having one more Azure app, which is used for table/dcr/schema management.

You need to adjust permissions according to these settings:

| Target                                                  | Delegation To                           | Azure RBAC Permission        | Comment                                                                   | 
|:-------------                                           |:-----                                   |:-----                        |:-----                                                                     |
| Azure Resource Group for Azure Data Collection Rules    | Azure app used for log ingestion        | Monitoring Publisher Metrics | used to send in data                                                      |
| Azure Resource Group for Azure Data Endpoint            | Azure app used for log ingestion        | Reader<br><br>When you run this script, it will configure the log ingestion account with Contributor permissions, if you run with default config. This configuration must be adjusted, so the logestion app will only need Reader permissions.| needed to retrieve information about DCE - used as part of uploading data |
| Azure Resource Group for Azure Data Collection Rules    | Azure app used for table/DCR management | Contributor                  | needed to send in data                                                    |
| Azure Resource Group for Azure Data Collection Endpoint | Azure app used for table/DCR management | Contributor                  | needed to create/update DCEs and also needed to create/update an DCR with referrences to a DCE |
| Azure LogAnalytics Workspace                            | Azure app used for table/DCR management | Contributor                  | needed to create/update Azure LogAnaltyics custom log tables              |
