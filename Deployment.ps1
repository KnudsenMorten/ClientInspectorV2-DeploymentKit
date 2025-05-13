#Requires -Version 5.0

<#
    .NAME
    ClientInspector-DeploymentKit

    .SYNOPSIS
    The purpose of this repository is to provide everything needed to deploy a complete environment for ClientInspector (v2)

    The deployment includes the following steps:

    (1)  create Azure Resource Group for Azure LogAnalytics Workspace
    (2)  create Azure LogAnalytics Workspace
    (3)  create Azure App registration used for upload of data by ClientInspector
    (4)  create Azure service principal on Azure App
    (5)  create needed secret on Azure app
    (6)  create the Azure Resource Group for Azure Data Collection Endpoint (DCE) in same region as Azure LogAnalytics Workspace
    (7)  create the Azure Resource Group for Azure Data Collection Rules (DCR) in same region as Azure LogAnalytics Workspace
    (8)  create Azure Data Collection Endpoint (DCE) in same region as Azure LogAnalytics Workspace
    (9)  delegate permissions for Azure App on LogAnalytics workspace - see section Security for more info
    (10) delegate permissions for Azure App on Azure Resource Group for Azure Data Collection Rules (DCR)
    (11) delegate permissions for Azure App on Azure Resource Group for Azure Data Collection Endpoints (DCE)
    (12) deployment of Azure Workbooks
    (13) deployment of Azure Dashboards

    Please check out the deployment guide on link https://github.com/KnudsenMorten/ClientInspectorV2-DeploymentKit


    .NOTES
    
    .VERSION
    1.0.0
    
    .AUTHOR
    Morten Knudsen, Microsoft MVP - https://mortenknudsen.net

    .LICENSE
    Licensed under the MIT license.

    .PROJECTURI
    https://github.com/KnudsenMorten/ClientInspectorV2-DeploymentKit


    .WARRANTY
    Use at your own risk, no warranty given!
#>


#------------------------------------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------------------------------------


    # put in your path where ClientInspector, AzLogDcrIngestPS and workbooks/dashboards will be downloaded to !
    $FolderRoot                            = (Get-location).Path
   
    # Azure App
    $AzureAppName                          = "<put in name for your Azure App used for log ingestion>" # sample - "xxxx - Automation - Log-Ingestion"
    $AzAppSecretName                       = "Secret used for Log-Ingestion"  # sample showed - use any text to show purpose of secret on Azure app

    # Azure Active Directory (AAD)
    $TenantId                              = "<put in your Azure AD TenantId>"

    # Azure LogAnalytics
    $LogAnalyticsSubscription              = "<put in the SubId of where to place environment>"
    $LogAnalyticsResourceGroup             = "<put in RG name for LogAnalytics workspace>" # sample: "rg-logworkspaces-p"
    $LoganalyticsWorkspaceName             = "<put in name of LogAnalytics workspace>" # sample: "log-platform-management-client-p"
    $LoganalyticsLocation                  = "<put in desired region>" # sample: westeurope


    # Azure Data Collection Endpoint
    $AzDceName                             = "<put in naming cnvention for Azure DCE>" # sample: "dce-" + $LoganalyticsWorkspaceName
    $AzDceResourceGroup                    = "<put in RG name for Azure DCE>" # sample: "rg-dce-" + $LoganalyticsWorkspaceName

    # Azure Data Collection Rules
    $AzDcrResourceGroup                    = "<put in RG name for Azure DCRs>" # sample: "rg-dcr-" + $LoganalyticsWorkspaceName
    $AzDcrPrefix                           = "<put in prefix for easier sorting/searching of DCRs>" # sample: "clt" (short for client)

    # Azure Workbooks & Dashboards
    $TemplateCategory                      = "<put in name for Azure Workbook Templates name>" # sample: "CompanyX IT Operation Security Templates"
    $WorkbookDashboardResourceGroup        = "<put in RG name whre workbooks/dashboards will be deployed>" # sample: "rg-dashboards-workbooks"

    $ScriptDirectory                       = $PSScriptRoot
    $WorkBook_Repository_Path              = "$($ScriptDirectory)\AZURE_WORKBOOKS_LATEST_RELEASE_V2"
    $Dashboard_Repository_Path             = "$($ScriptDirectory)\AZURE_DASHBOARDS_LATEST_RELEASE_v2"
    

    $WorkBook_Repository_Path              = "AZURE_WORKBOOKS_LATEST_RELEASE_V2"
    $Dashboard_Repository_Path             = "AZURE_DASHBOARDS_LATEST_RELEASE_V2"

    $Workbooks    = @("ANTIVIRUS SECURITY CENTER - CLIENTS - V2.json", `
                      "APPLICATIONS - CLIENTS - V2.json", `
                      "BITLOCKER - CLIENTS - V2.json", `
                      "DEFENDER AV - CLIENTS - V2.json", `
                      "GROUP POLICY REFRESH - CLIENTS - V2.json", `
                      "INVENTORY - CLIENTS - V2.json", `
                      "INVENTORY COLLECTION ISSUES - CLIENTS - V2.json", `
                      "LAPS - CLIENTS - V2.json", `
                      "LOCAL ADMINS - CLIENTS - V2.json",`
                      "NETWORK INFORMATION - CLIENTS - V2.json", `
                      "OFFICE - CLIENTS - V2.json", `
                      "UNEXPECTED SHUTDOWNS - CLIENTS - V2.json", `
                      "WINDOWS FIREWALL - CLIENTS - V2.json", `
                      "WINDOWS UPDATE - CLIENTS - V2.json"
                     )

    $Dashboards   = @("ANTIVIRUS SECURITY CENTER - CLIENTS - V2.json", `
                      "APPLICATIONS - CLIENTS - V2.json", `
                      "BITLOCKER - CLIENTS - V2.json", `
                      "CLIENT KPI STATUS - V2.json", `
                      "DEFENDER AV - CLIENTS - V2.json", `
                      "GROUP POLICY REFRESH - CLIENTS - V2.json", `
                      "INVENTORY - CLIENTS - V2.json", `
                      "INVENTORY COLLECTION ISSUES - CLIENTS - V2.json", `
                      "LAPS - CLIENTS - V2.json", `
                      "LOCAL ADMINS GROUP - CLIENTS - V2.json",`
                      "NETWORK INFORMATION - CLIENTS - V2.json", `
                      "OFFICE - CLIENTS - V2.json", `
                      "UNEXPECTED SHUTDOWNS - CLIENTS - V2.json", `
                      "WINDOWS FIREWALL - CLIENTS - V2.json", `
                      "WINDOWS UPDATE - CLIENTS - V2.json"
                     )

#------------------------------------------------------------------------------------------------------------
# Verification download path
#------------------------------------------------------------------------------------------------------------

    # put in your path where ClientInspector, AzLogDcrIngestPS and workbooks/dashboards will be downloaded to !
    $FolderRoot = (Get-location).Path + "\" + $LoganalyticsWorkspaceName

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Delete"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Cancel"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $heading = "Download path"
    $message = "This deployment kit will download latest files into current directory. Do you want to continue with this path? `n`n $($FolderRoot) "
    $Prompt = $host.ui.PromptForChoice($heading, $message, $options, 1)
    switch ($prompt) {
                        0
                            {
                                # Continuing
                            }
                        1
                            {
                                Write-Host "No" -ForegroundColor Red
                                Exit
                            }
                    }

    MD $FolderRoot -ErrorAction SilentlyContinue -Force | Out-Null
    CD $FolderRoot | Out-Null


#------------------------------------------------------------------------------------------------------------
# Downloading newest versions of workbooks fra ClientInspector-DeploymentKit Github
#------------------------------------------------------------------------------------------------------------

    # path to store files
    $TempPath = $FolderRoot + "\" + $WorkBook_Repository_Path

    # Checking if existing workbook files are found. If $true, then they will be deleted
    $ExistFilesCheck = Get-ChildItem "$($TempPath)\*.json" -ErrorAction SilentlyContinue
    If ($ExistFilesCheck)
        {
            Write-Output "Existing files found .... removing ensuring latest are used !"
            Remove-Item -Path $ExistFilesCheck -Force
        }

    # Creating
    MD $TempPath -ErrorAction SilentlyContinue -force | Out-Null

    # Downloading
    ForEach ($Workbook in $Workbooks)
        {
            $SourceFile = $Workbook.replace(" ","%20")

            $SourcePath = "https://raw.githubusercontent.com/KnudsenMorten/ClientInspectorV2-DeploymentKit/main/" + $WorkBook_Repository_Path + "/" + $SourceFile
            $DestinationPath = $TempPath + "\" + $Workbook
            Write-Output ""
            Write-Output "Downloading latest version of Azure Workbooks [ $($Workbook) ]"
            Write-Output "  from https://github.com/KnudsenMorten/ClientInspectorV2-DeploymentKit"
            Write-Output "  into local path $($TempPath)"

            # download newest version
            $Download = (New-Object System.Net.WebClient).DownloadFile($SourcePath, $DestinationPath)
        }

#------------------------------------------------------------------------------------------------------------
# Downloading newest versions of dashboards fra ClientInspector-DeploymentKit Github
#------------------------------------------------------------------------------------------------------------
    
    # path to store files
    $TempPath = $FolderRoot + "\" + $Dashboard_Repository_Path

    # Checking if existing dashboards files are found. If $true, then they will be deleted
    $ExistFilesCheck = Get-ChildItem "$($TempPath)\*.json" -ErrorAction SilentlyContinue
    If ($ExistFilesCheck)
        {
            Write-Output "Existing files found .... removing ensuring latest are used !"
            Remove-Item -Path $ExistFilesCheck -Force
        }

    # Creating
    MD $TempPath -ErrorAction SilentlyContinue -Force | Out-Null

    ForEach ($Dashboard in $Dashboards)
        {
            $SourceFile = $Dashboard.replace(" ","%20")

            $SourcePath = "https://raw.githubusercontent.com/KnudsenMorten/ClientInspectorV2-DeploymentKit/main/" + $Dashboard_Repository_Path + "/" + $SourceFile
            $DestinationPath = $TempPath + "\" + $Dashboard
            Write-Output ""
            Write-Output "Downloading latest version of Azure Dashboards [ $($Dashboard) ]"
            Write-Output "  from https://github.com/KnudsenMorten/ClientInspectorV2-DeploymentKit"
            Write-Output "  into $($TempPath)"

            # download newest version
            $Download = (New-Object System.Net.WebClient).DownloadFile($SourcePath, $DestinationPath)
        }


#------------------------------------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------------------------------------

    Write-Output "Checking needed functions ... Please Wait !"
    $ModuleCheck = Get-Module -Name Az.Resources -ListAvailable -ErrorAction SilentlyContinue
    If (!($ModuleCheck))
        {
            Write-Output "Installing Az-module in CurrentUser scope ... Please Wait !"
            Install-module -Name Az -Force -Scope CurrentUser
        }

    $ModuleCheck = Get-Module -Name Az.Portal -ListAvailable -ErrorAction SilentlyContinue
    If (!($ModuleCheck))
        {
            Write-Output "Installing Az.Portal in CurrentUser scope ... Please Wait !"
            Install-module -Name Az.Portal -Force -Scope CurrentUser
        }

    $ModuleCheck = Get-Module -Name Microsoft.Graph -ListAvailable -ErrorAction SilentlyContinue
    If (!($ModuleCheck))
        {
            Write-Output "Installing Microsoft.Graph in CurrentUser scope ... Please Wait !"
            Install-module -Name Microsoft.Graph -Force -Scope CurrentUser
        }

    <#
        Install-module Az -Scope CurrentUser
        Install-module Microsoft.Graph -Scope CurrentUser
        install-module Az.portal -Scope CurrentUser

        Import-module Az -Scope CurrentUser
        Import-module Az.Accounts -Scope CurrentUser
        Import-module Az.Resources -Scope CurrentUser
        Import-module Microsoft.Graph.Applications -Scope CurrentUser
        Import-Module Microsoft.Graph.DeviceManagement.Enrolment -Scope CurrentUser
    #>


#------------------------------------------------------------------------------------------------------------
# Connection
#------------------------------------------------------------------------------------------------------------

    #---------------------------------------------------------
    # Connect to Azure
    #---------------------------------------------------------
        Connect-AzAccount -Tenant $TenantId -WarningAction SilentlyContinue

        #---------------------------------------------------------
        # Get Access Token
        #---------------------------------------------------------
            $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
            $AccessToken = $AccessToken.Token

        #---------------------------------------------------------
        # Build Headers for Azure REST API with access token
        #---------------------------------------------------------
            $Headers = @{
                            "Authorization"="Bearer $($AccessToken)"
                            "Content-Type"="application/json"
                        }


    #---------------------------------------------------------
    # Connect to Microsoft Graph
    #---------------------------------------------------------
        <#
            Find-MgGraphCommand -command Add-MgApplicationPassword | Select -First 1 -ExpandProperty Permissions
        #>

        $MgScope = @(
                        "Application.ReadWrite.All",`
                        "Directory.Read.All",`
                        "Directory.AccessAsUser.All",
                        "RoleManagement.ReadWrite.Directory"
                    )


        Connect-MgGraph -TenantId $TenantId  -Scopes $MgScope


    #-------------------------------------------------------------------------------------
    # Azure Context
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Validating Azure context is subscription [ $($LogAnalyticsSubscription) ]"
        $AzContext = Get-AzContext
            If ($AzContext.Subscription -ne $LogAnalyticsSubscription )
                {
                    Write-Output ""
                    Write-Output "Switching Azure context to subscription [ $($LogAnalyticsSubscription) ]"
                    $AzContext = Set-AzContext -Subscription $LogAnalyticsSubscription -Tenant $TenantId
                }

    #-------------------------------------------------------------------------------------
    # Create the resource group for Azure LogAnalytics workspace
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Validating Azure resource group exist [ $($LogAnalyticsResourceGroup) ]"
        try {
            Get-AzResourceGroup -Name $LogAnalyticsResourceGroup -ErrorAction Stop
        } catch {
            Write-Output ""
            Write-Output "Creating Azure resource group [ $($LogAnalyticsResourceGroup) ]"
            New-AzResourceGroup -Name $LogAnalyticsResourceGroup -Location $LoganalyticsLocation
        }

    #-------------------------------------------------------------------------------------
    # Create the workspace
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Validating Azure LogAnalytics workspace exist [ $($LoganalyticsWorkspaceName) ]"
        try {
            $LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup -ErrorAction Stop
        } catch {
            Write-Output ""
            Write-Output "Creating LogAnalytics workspace [ $($LoganalyticsWorkspaceName) ] in $LogAnalyticsResourceGroup"
            New-AzOperationalInsightsWorkspace -Location $LoganalyticsLocation -Name $LoganalyticsWorkspaceName -Sku PerGB2018 -ResourceGroupName $LogAnalyticsResourceGroup
        }

    #-------------------------------------------------------------------------------------
    # Get workspace details
    #-------------------------------------------------------------------------------------

        $LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup
    
        $LogAnalyticsWorkspaceResourceId = $LogWorkspaceInfo.ResourceId

    #-------------------------------------------------------------------------------------
    # Create Azure app registration
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Validating Azure App [ $($AzureAppName) ]"
        $AppCheck = Get-MgApplication -Filter "DisplayName eq '$AzureAppName'" -ErrorAction Stop
            If ($AppCheck -eq $null)
                {
                    Write-Output ""
                    Write-host "Creating Azure App [ $($AzureAppName) ]"
                    $AzureApp = New-MgApplication -DisplayName $AzureAppName
                }

    #-------------------------------------------------------------------------------------
    # Create service principal on Azure app
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Validating Azure Service Principal on App [ $($AzureAppName) ]"
        $AppInfo  = Get-MgApplication -Filter "DisplayName eq '$AzureAppName'"

        $AppId    = $AppInfo.AppId
        $ObjectId = $AppInfo.Id

        $ServicePrincipalCheck = Get-MgServicePrincipal -Filter "AppId eq '$AppId'"
            If ($ServicePrincipalCheck -eq $null)
                {
                    Write-Output ""
                    Write-host "Creating Azure Service Principal on App [ $($AzureAppName) ]"
                    $ServicePrincipal = New-MgServicePrincipal -AppId $AppId
                }

    #-------------------------------------------------------------------------------------
    # Create secret on Azure app
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Validating Azure Secret on App [ $($AzureAppName) ]"
        $AppInfo  = Get-MgApplication -Filter "AppId eq '$AppId'"

        $AppId    = $AppInfo.AppId
        $ObjectId = $AppInfo.Id

            If ($AzAppSecretName -notin $AppInfo.PasswordCredentials.DisplayName)
                {
                    Write-Output ""
                    Write-host "Creating Azure Secret on App [ $($AzureAppName) ]"

                    $passwordCred = @{
                        displayName = $AzAppSecretName
                        endDateTime = (Get-Date).AddYears(1)
                    }

                    $AzAppSecret = (Add-MgApplicationPassword -applicationId $ObjectId -PasswordCredential $passwordCred).SecretText
                    Write-Output ""
                    Write-Output "Secret with name [ $($AzAppSecretName) ] created on app [ $($AzureAppName) ]"
                    Write-Output $AzAppSecret
                    Write-Output ""
                    Write-Output "AppId for app [ $($AzureAppName) ] is"
                    Write-Output $AppId
                }

    #-------------------------------------------------------------------------------------
    # Create the resource group for Data Collection Endpoints (DCE) in same region as LA
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Validating Azure resource group exist [ $($AzDceResourceGroup) ]"
        try {
            Get-AzResourceGroup -Name $AzDceResourceGroup -ErrorAction Stop
        } catch {
            Write-Output ""
            Write-Output "Creating Azure resource group [ $($AzDceResourceGroup) ]"
            New-AzResourceGroup -Name $AzDceResourceGroup -Location $LoganalyticsLocation
        }

    #-------------------------------------------------------------------------------------
    # Create the resource group for Data Collection Rules (DCR) in same region as LA
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Validating Azure resource group exist [ $($AzDcrResourceGroup) ]"
        try {
            Get-AzResourceGroup -Name $AzDcrResourceGroup -ErrorAction Stop
        } catch {
            Write-Output ""
            Write-Output "Creating Azure resource group [ $($AzDcrResourceGroup) ]"
            New-AzResourceGroup -Name $AzDcrResourceGroup -Location $LoganalyticsLocation
        }

    #-------------------------------------------------------------------------------------
    # Create Data Collection Endpoint
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Validating Azure Data Collection Endpoint exist [ $($AzDceName) ]"
        
        $DceUri = "https://management.azure.com" + "/subscriptions/" + $LogAnalyticsSubscription + "/resourceGroups/" + $AzDceResourceGroup + "/providers/Microsoft.Insights/dataCollectionEndpoints/" + $AzDceName + "?api-version=2022-06-01"
        Try
            {
                Invoke-RestMethod -Uri $DceUri -Method GET -Headers $Headers
            }
        Catch
            {
                Write-Output ""
                Write-Output "Creating/updating DCE [ $($AzDceName) ]"

                $DceObject = [pscustomobject][ordered]@{
                                properties = @{
                                                description = "DCE for LogIngest to LogAnalytics $LoganalyticsWorkspaceName"
                                                networkAcls = @{
                                                                    publicNetworkAccess = "Enabled"

                                                                }
                                                }
                                location = $LogAnalyticsLocation
                                name = $AzDceName
                                type = "Microsoft.Insights/dataCollectionEndpoints"
                            }

                $DcePayload = $DceObject | ConvertTo-Json -Depth 20

                $DceUri = "https://management.azure.com" + "/subscriptions/" + $LogAnalyticsSubscription + "/resourceGroups/" + $AzDceResourceGroup + "/providers/Microsoft.Insights/dataCollectionEndpoints/" + $AzDceName + "?api-version=2022-06-01"

                Try
                    {
                        Invoke-WebRequest -Uri $DceUri -Method PUT -Body $DcePayload -Headers $Headers
                    }
                Catch
                    {
                    }
            }
        
    #-------------------------------------------------------------------------------------
    # Sleeping 1 min to let Azure AD replicate before doing delegation
    #-------------------------------------------------------------------------------------

        Write-Output "Sleeping 3 min to let Azure AD replicate before doing delegation"
        Start-Sleep -s 180

    #-------------------------------------------------------------------------------------
    # Delegation permissions for Azure App on LogAnalytics workspace
    # Needed for table management - not needed for log ingestion - for simplifity it is setup when having 1 app
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Setting Contributor permissions for app [ $($AzureAppName) ] on Loganalytics workspace [ $($LoganalyticsWorkspaceName) ]"

        $LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup
    
        $LogAnalyticsWorkspaceResourceId = $LogWorkspaceInfo.ResourceId

        $ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
        $DcrRgResourceId          = (Get-AzResourceGroup -Name $AzDcrResourceGroup).ResourceId

        # Contributor on LogAnalytics workspacespace
            $guid = (new-guid).guid
            $ContributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
            $roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($ContributorRoleId)"
            $roleUrl = "https://management.azure.com" + $LogAnalyticsWorkspaceResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
            $roleBody = @{
                properties = @{
                    roleDefinitionId = $roleDefinitionId
                    principalId      = $ServicePrincipalObjectId
                    scope            = $LogAnalyticsWorkspaceResourceId
                }
            }
            $jsonRoleBody = $roleBody | ConvertTo-Json -Depth 6

            $result = try
                {
                    Invoke-RestMethod -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
                }
            catch
                {
                }


    #-------------------------------------------------------------------------------------
    # Delegation permissions for Azure App on DCR Resource Group
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Setting Contributor permissions for app [ $($AzureAppName) ] on RG [ $($AzDcrResourceGroup) ]"

        $ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
        $AzDcrRgResourceId        = (Get-AzResourceGroup -Name $AzDcrResourceGroup).ResourceId

        # Contributor
            $guid = (new-guid).guid
            $ContributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
            $roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($ContributorRoleId)"
            $roleUrl = "https://management.azure.com" + $AzDcrRgResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
            $roleBody = @{
                properties = @{
                    roleDefinitionId = $roleDefinitionId
                    principalId      = $ServicePrincipalObjectId
                    scope            = $AzDcrRgResourceId
                }
            }
            $jsonRoleBody = $roleBody | ConvertTo-Json -Depth 6

            $result = try
                {
                    Invoke-RestMethod -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
                }
            catch
                {
                }

        Write-Output ""
        Write-Output "Setting Monitoring Metrics Publisher permissions for app [ $($AzureAppName) ] on RG [ $($AzDcrResourceGroup) ]"

        # Monitoring Metrics Publisher
            $guid = (new-guid).guid
            $monitorMetricsPublisherRoleId = "3913510d-42f4-4e42-8a64-420c390055eb"
            $roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($monitorMetricsPublisherRoleId)"
            $roleUrl = "https://management.azure.com" + $AzDcrRgResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
            $roleBody = @{
                properties = @{
                    roleDefinitionId = $roleDefinitionId
                    principalId      = $ServicePrincipalObjectId
                    scope            = $AzDcrRgResourceId
                }
            }
            $jsonRoleBody = $roleBody | ConvertTo-Json -Depth 6

            $result = try
                {
                    Invoke-RestMethod -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
                }
            catch
                {
                }

    #-------------------------------------------------------------------------------------
    # Delegation permissions for Azure App on DCE Resource Group
    #-------------------------------------------------------------------------------------

        Write-Output ""
        Write-Output "Setting Contributor permissions for app [ $($AzDceName) ] on RG [ $($AzDceResourceGroup) ]"

        $ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
        $AzDceRgResourceId        = (Get-AzResourceGroup -Name $AzDceResourceGroup).ResourceId

        # Contributor
            $guid = (new-guid).guid
            $ContributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
            $roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($ContributorRoleId)"
            $roleUrl = "https://management.azure.com" + $AzDceRgResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
            $roleBody = @{
                properties = @{
                    roleDefinitionId = $roleDefinitionId
                    principalId      = $ServicePrincipalObjectId
                    scope            = $AzDceRgResourceId
                }
            }
            $jsonRoleBody = $roleBody | ConvertTo-Json -Depth 6

            $result = try
                {
                    Invoke-RestMethod -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
                }
            catch
                {
                }


#------------------------------------------------------------------------------------------------------------
# Azure Workbooks & Dashboards
#------------------------------------------------------------------------------------------------------------

    #-------------------------------------------------------------------------------------
    # Azure WorkBook Deployment
    #-------------------------------------------------------------------------------------

        #------------------------------------
        # PreReq
        #------------------------------------

            Write-Output "Building list Azure workbooks to deploy"
            $TempPath = (Get-location).Path + "\" + $WorkBook_Repository_Path
            $Files = Get-ChildItem -Path $TempPath | %{$_.FullName}


        #-------------------------------------------------------------------------------------
        # Create the resource group for Azure Workbooks & Dashboards
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure resource group exist [ $($WorkbookDashboardResourceGroup) ]"
            try {
                Get-AzResourceGroup -Name $WorkbookDashboardResourceGroup -ErrorAction Stop
            } catch {
                Write-Output ""
                Write-Output "Creating Azure resource group [ $($WorkbookDashboardResourceGroup) ]"
                New-AzResourceGroup -Name $WorkbookDashboardResourceGroup -Location $LoganalyticsLocation
            }

        #-------------------------------------------------------------------------------------
        # Deployment of Workbooks (loop)
        #-------------------------------------------------------------------------------------
            
            ForEach ($File in $Files)
                {
                    # read ARM file
                    $TemplateFileName    = $File.Split("\")[-1]
                    $TemplateName        = $TemplateFileName.Split(".")[0]

                    Write-Output ""
                    Write-Output "Deployment of Azure Workbook [ $($TemplateName) ] in progress .... please wait !"

                    Write-Output "   Adjusting ARM template with LogAnalytics workspace information"

                    # convert file to JSON
                        $ArmTemplate         = Get-Content $File -Raw -Encoding UTF8
                        $ArmTemplateJson     = $ArmTemplate | ConvertFrom-Json

                    # Add galleries definition to convert workbook to a workbook template 
                        $ArmTemplateJson.resources.properties | Add-Member -NotePropertyName "galleries" -NotePropertyValue "" -Force
                        $gallerydefinition = [PSCustomObject]@{
                                                    name = $TemplateName
                                                    category = $TemplateCategory
                                                    order = 100
                                                    type = "workbook"
                                                    resourceType = "Azure Monitor"
                                              }
                    
                    # add gallerydefinition to object as array
                        $ArmTemplateJson.resources.properties.galleries = @($gallerydefinition)
                    
                    # tell ARM template it should install as workbook templates
                        $ArmTemplateJson.resources | Add-Member -MemberType NoteProperty -Name "type" -Value "microsoft.insights/workbooktemplates" -Force

                    # change name for template
                        $ArmTemplateJson.resources | Add-Member -MemberType NoteProperty -Name "name" -Value $TemplateName -Force

                    # change API version to support workbook templates
                        $ArmTemplateJson.resources | Add-Member -MemberType NoteProperty -Name "apiVersion" -Value "2020-11-20" -Force

                    # convert JSON-formatted data in templates to PSCustomObject
                        $Data = $ArmTemplateJson.resources.properties.serializedData | ConvertFrom-Json
                    
                    # Updating LogAnalytics workspaceId
                        $IndexCount = $Data.Items.Count
                        $Index = 0
                        Do
                            {
                                $Data.items[$Index].content.crossComponentResources = @("$LogAnalyticsWorkspaceResourceId")
                                $Index += 1
                            }
                        Until ($Index -eq $IndexCount)

                    # Converting modified PSCustomObject data to compressed JSON
                        $Data = $Data | ConvertTo-Json -Depth 50 -Compress

                    # Updating ARM template object with modified data (workbook) - not used if workbook template
                    #    $ArmTemplateJson.resources.properties.serializedData = $Data

                    # Updating ARM template object with modified data (workbooktemplate)
                        $ArmTemplateJson.resources.properties | Add-Member -NotePropertyName "templateData" -NotePropertyValue "" -Force
                        $ArmTemplateJson.resources.properties.templateData = $Data

                    Write-Output "   Building temporary ARM template [ $($TemplateFileName) ] in $($ENV:TEMP) folder"
                    # Export object to ARM template file
                        $ArmTemplateExport = $ArmTemplateJson | ConvertTo-Json -Depth 50
                        $TemplateFile      = $Env:TEMP + "\" + $TemplateFileName
                        $ArmTemplateExport | out-file $TemplateFile -Force

                    Write-Output "   Starting deployment of workbook [ $($TemplateName) ] "
                    Write-Output ""

                    # parameters for ARM deployment
                            $parameters = @{
                            'Name'                  = "ArmDeployment" + (Get-Random -Maximum 100000)
                            'ResourceGroup'         = $WorkbookDashboardResourceGroup
                            'TemplateFile'          = $TemplateFile
                            'workbookType'          = "workbook"
                            'workbookSourceId'      = "Azure Monitor"
                            'workbookdisplayName'   = $TemplateName
                            'Verbose'               = $true
                        }

                        New-AzResourceGroupDeployment  @parameters
                }


    #-------------------------------------------------------------------------------------
    # Azure Dashboard Deployment
    #-------------------------------------------------------------------------------------

        #------------------------------------
        # PreReq
        #------------------------------------

            Write-Output "Building list Azure dashboards to deploy"
            $TempPath = (Get-location).Path + "\" + $Dashboard_Repository_Path
            $Files = Get-ChildItem -Path $TempPath | %{$_.FullName}

        #-------------------------------------------------------------------------------------
        # Create the resource group for Azure Workbooks & Dashboards
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure resource group exist [ $($WorkbookDashboardResourceGroup) ]"
            try {
                Get-AzResourceGroup -Name $WorkbookDashboardResourceGroup -ErrorAction Stop
            } catch {
                Write-Output ""
                Write-Output "Creating Azure resource group [ $($WorkbookDashboardResourceGroup) ]"
                New-AzResourceGroup -Name $WorkbookDashboardResourceGroup -Location $LoganalyticsLocation
            }

        #-------------------------------------------------------------------------------------
        # Deployment of Dashboards (loop)
        #-------------------------------------------------------------------------------------
            ForEach ($File in $Files)
                {
                    $TemplateFileName = $File.Split("\")[-1]
                    $TemplateName = $TemplateFileName.Split(".")[0]

                    Write-Output ""
                    Write-Output "Deployment of Azure Dashboard [ $TemplateName ] in progress .... please wait !"
                    Write-Output "   Adjusting ARM template with LogAnalytics workspace information"

                    # Convert file to JSON
                    $ArmTemplate = Get-Content $File -Raw -Encoding UTF8
                    $ArmTemplateJson = $ArmTemplate | ConvertFrom-Json

                    # Update location and API version
                    $ArmTemplateJson | Add-Member -MemberType NoteProperty -Name "location" -Value $LogAnalyticsLocation -Force
                    $ArmTemplateJson.apiVersion = "2022-12-01-preview"

                    # Convert lenses from hashtable to array
                    $LensesObject = $ArmTemplateJson.properties.lenses
                    $LensesArray = @()

                    foreach ($lenseKey in ($LensesObject.PSObject.Properties.Name | Sort-Object)) {
                        $Lens = $LensesObject.$lenseKey

                        # Convert parts from hashtable to array
                        $PartsObject = $Lens.parts
                        $PartsArray = @()

                        foreach ($partKey in ($PartsObject.PSObject.Properties.Name | Sort-Object)) {
                            $Part = $PartsObject.$partKey

                            # Process each input in the part
                            $Inputs = $Part.metadata.inputs
                            for ($i = 0; $i -lt $Inputs.Count; $i++) {
                                $Entry = $Inputs[$i]

                                if ($Entry.name -eq "ConfigurationId") {
                                    $WorkbookTemplateName = $Entry.value.Split("/")[-1]
                                    $NewValue = "ArmTemplates-/subscriptions/$LogAnalyticsSubscription/resourceGroups/$WorkbookDashboardResourceGroup/providers/microsoft.insights/workbooktemplates/$WorkbookTemplateName"
                                    $Inputs[$i].value = $NewValue
                                }

                                elseif ($Entry.name -eq "StepSettings") {
                                    $StepSettings = $Entry.value | ConvertFrom-Json
                                    $StepSettings.crossComponentResources = @($LogAnalyticsWorkspaceResourceId)
                                    $Inputs[$i].value = $StepSettings | ConvertTo-Json -Depth 50 -Compress
                                }
                            }

                            # Assign modified inputs back
                            $Part.metadata.inputs = $Inputs

                            # Add to parts array
                            $PartsArray += $Part
                        }

                        # Replace parts object with array
                        $Lens.parts = $PartsArray
                        $LensesArray += $Lens
                    }

                    # Replace lenses object with array
                    $ArmTemplateJson.properties.lenses = $LensesArray

                    # Convert updated template back to JSON
                    $ArmTemplateExport = $ArmTemplateJson | ConvertTo-Json -Depth 50

                    # Save updated template
                    $TemplateFile = "$env:TEMP\$TemplateFileName"
                    $ArmTemplateExport | Out-File $TemplateFile -Force

                    Write-Output "   Starting deployment of dashboard [ $TemplateName ]"
                    Write-Output ""

                    # You can add your deployment command here, e.g.:

                    # parameters for ARM deployment

                    $RawJson = Get-Content -Path $TemplateFile -Raw
                    $ArmTemplateJson = $RawJson | ConvertFrom-Json

                    New-AzResource -Properties $ArmTemplateJson.properties  `
                                                -ResourceName $TemplateName  `
                                                -ResourceType "Microsoft.Portal/dashboards" `
                                                -ResourceGroupName $WorkbookDashboardResourceGroup  `
                                                -ApiVersion "2022-12-01-preview" `
                                                -Location $LogAnalyticsLocation `
                                                -Force

                }



#-----------------------------------------------------------------------------------------------
# Building demo-setup
#-----------------------------------------------------------------------------------------------

    Write-Output ""
    Write-Output "Building demo structure in folder"
    Write-Output $ClientFolder

    Write-Output ""
    Write-Output "Downloading latest version of module AzLogDcrIngestPS from https://github.com/KnudsenMorten/AzLogDcrIngestPS"
    Write-Output "into local path $($FolderRoot)"

    # download newest version
    $Download = (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/KnudsenMorten/AzLogDcrIngestPS/main/AzLogDcrIngestPS.psm1", "$($FolderRoot)\AzLogDcrIngestPS.psm1")

    Write-Output ""
    Write-Output "Downloading latest version of module ClientInspectorV2 from https://github.com/KnudsenMorten/ClientInspectorV2"
    Write-Output "into local path $($ClientFolder)"

    # download newest version
    $Download = (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/KnudsenMorten/ClientInspectorV2/main/ClientInspector.ps1", "$($FolderRoot)\ClientInspector.ps1")

    # Changing to directory where files where downloaded
    Cd $FolderRoot

#-------------------------------------------------------------------------------------
# Summarize
#-------------------------------------------------------------------------------------

    # Azure App
        Write-Output ""
        Write-Output "Tenant Id:"
        Write-Output $TenantId

    # Azure App
        $AppInfo  = Get-MgApplication -Filter "DisplayName eq '$AzureAppName'"
        $AppId    = $AppInfo.AppId
        $ObjectId = $AppInfo.Id

        Write-Output ""
        Write-Output "LogIngestion Azure App Name:"
        Write-Output $AzureAppName

        Write-Output ""
        Write-Output "LogIngestion Azure App Id:"
        Write-Output $AppId
        Write-Output ""


        If ($AzAppSecret)
            {
                Write-Output "LogIngestion Azure App Secret:"
                Write-Output $AzAppSecret
            }
        Else
            {
                Write-Output "LogIngestion Azure App Secret:"
                Write-Output "N/A (new secret must be made)"
            }

    # Azure Service Principal for App
        $ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
        Write-Output ""
        Write-Output "LogIngestion Azure Service Principal Object Id for app:"
        Write-Output $ServicePrincipalObjectId

    # Azure Loganalytics
        Write-Output ""
        $LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup
        $LogAnalyticsWorkspaceResourceId = $LogWorkspaceInfo.ResourceId

        Write-Output ""
        Write-Output "Azure LogAnalytics Workspace Resource Id:"
        Write-Output $LogAnalyticsWorkspaceResourceId

    # DCE
        $DceUri = "https://management.azure.com" + "/subscriptions/" + $LogAnalyticsSubscription + "/resourceGroups/" + $AzDceResourceGroup + "/providers/Microsoft.Insights/dataCollectionEndpoints/" + $AzDceName + "?api-version=2022-06-01"
        $DceObj = Invoke-RestMethod -Uri $DceUri -Method GET -Headers $Headers

        $AzDceLogIngestionUri = $DceObj.properties.logsIngestion[0].endpoint

        Write-Output ""
        Write-Output "Azure Data Collection Endpoint Name:"
        Write-Output $AzDceName

        Write-Output ""
        Write-Output "Azure Data Collection Endpoint Log Ingestion Uri:"
        Write-Output $AzDceLogIngestionUri
        Write-Output ""
        Write-Output "-------------------------------------------------"
        Write-Output ""
        Write-Output "Please insert these lines in ClientInspector:"
        Write-Output ""
        Write-Output "`$TenantId                                   = `"$($TenantId)`" "
        Write-Output "`$LogIngestAppId                             = `"$($AppId)`" "
        Write-Output "`$LogIngestAppSecret                         = `"$($AzAppSecret)`" "
        Write-Output ""
        Write-Output "`$DceName                                    = `"$AzDceName`" "
        Write-Output "`$LogAnalyticsWorkspaceResourceId            = "
        Write-Output "`"$($LogAnalyticsWorkspaceResourceId)`" "
        Write-Output ""
        Write-Output "`$AzDcrResourceGroup                         = `"$($AzDcrResourceGroup)`" "
        Write-Output "`$AzDcrPrefix                                = `"$($AzDcrPrefix)`" "
        Write-Output "`$AzDcrSetLogIngestApiAppPermissionsDcrLevel = `$false"
        Write-Output "`$AzDcrLogIngestServicePrincipalObjectId     = `"$($ServicePrincipalObjectId)`" "
        Write-Output "`$AzLogDcrTableCreateFromReferenceMachine    = @()"
        Write-Output "`$AzLogDcrTableCreateFromAnyMachine          = `$true"


        Notepad ClientInspector.ps1

        Write-Output ""
        Write-Output "We are almost done ... we just need to wait 1-1,5 hours for Microsoft to replicate and update RBAC"
        Write-Output "While waiting you have to copy the above variables into the open ClientInspector.ps1 file - and save it "
        Write-Output ""
        Write-Output "You can also prepare the command  .\ClientInspector.ps1 -function:localpath -verbose:$true in the path, where deployment was done"
        Write-Output "NOTE: Powershell session must be running in local admin, when you kick off ClientInspector"
        Write-Output ""
        Write-Output "Feel free to try it a few times until it stops failing .... !"
        Write-Output "When running, if the script throws lots of PUT = 200, then we are happy....it is creating tables and DCRs. It will take 15-20 min. first time !"
        Write-Output ""
        Write-Output "Happy hunting with ClientInspector :-)"
