###############################################################################
#
#   Deployment of environment for demonstration :
#   Inventory of Clients via ClientInspector (Powershell script).
#   Script runs via Intune Remediation Tasks.
#   Communication happens with Azure App.
#
#   Upload of inventory data to Loganalytics via Log Ingestion API &
#   Azure Data Collection Rules (DCR) and Azure Data Collection Endpoint (DCE)
#
#   Furthermore, +20 Azure Workbooks + Azure Dashboards will also be deployed
#
#   Developed by Morten Knudsen, Micrsoft MVP - mok@mortenknudsen.net
#
###############################################################################


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

    $ScriptDirectory                       = $PSScriptRoot
    $WorkBook_Repository_Path              = "$($ScriptDirectory)\AZURE_WORKBOOKS_LATEST_RELEASE_V2"
    $Dashboard_Repository_Path             = "$($ScriptDirectory)\AZURE_DASHBOARDS_LATEST_RELEASE_v2"
    

#------------------------------------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------------------------------------

    Write-Output "Loading functions ... Please Wait !"
    <#
        Install-module Az
        Install-module Microsoft.Graph
        install-module Az.portal

        Import-module Az
        Import-module Az.Accounts
        Import-module Az.Resources
        Import-module Microsoft.Graph.Applications
        Import-Module Microsoft.Graph.DeviceManagement.Enrolment
    #>


#------------------------------------------------------------------------------------------------------------
# Connection
#------------------------------------------------------------------------------------------------------------

    #---------------------------------------------------------
    # Connect to Azure
    #---------------------------------------------------------
        Connect-AzAccount -Tenant $TenantId

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


        Connect-MgGraph -TenantId $TenantId -ForceRefresh -Scopes $MgScope


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
    # Create the resource group for Data Collection Endpoints (DCE) in same region af LA
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
    # Create the resource group for Data Collection Rules (DCR) in same region af LA
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
    # Delegation permissions for Azure App on LogAnalytics workspace
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
            $Files = Get-ChildItem -Path $WorkBook_Repository_Path | %{$_.FullName}


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
            $Files = Get-ChildItem -Path $Dashboard_Repository_Path | %{$_.FullName}

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
                    # read ARM file
                    $TemplateFileName    = $File.Split("\")[-1]
                    $TemplateName        = $TemplateFileName.Split(".")[0]

                    $DashboardName      = ($TemplateName.replace("-","_"))
                    $DashboardName      = ($TemplateName.replace(" ","_"))

                    Write-Output ""
                    Write-Output "Deployment of Azure Dashboard [ $($TemplateName) ] in progress .... please wait !"

                    Write-Output "   Adjusting ARM template with LogAnalytics workspace information"

                    # convert file to JSON
                        $ArmTemplate         = Get-Content $File -Raw -Encoding UTF8
                        $ArmTemplateJson     = $ArmTemplate | ConvertFrom-Json

                    # tell ARM template location
                        $ArmTemplateJson | Add-Member -MemberType NoteProperty -Name "location" -Value $LogAnalyticsLocation -Force

                    $ArrayLenses = ($ArmTemplateJson.properties.lenses | get-member -MemberType NoteProperty).name
                    ForEach ($Lense in $ArrayLenses)
                        {
                            $indexParts  = 0
                            $ArrayParts = ($ArmTemplateJson.properties.lenses.$Lense.parts | get-member -MemberType NoteProperty).name

                                ForEach ($Part in $ArrayParts)
                                    {
                                        Write-Output "lense $($lense)"
                                        Write-Output "part  $($part)"

                                        $ArrayData = $ArmTemplateJson.properties.lenses.$Lense.parts.$Part.metadata.inputs.name
                                        $Index = 0
                                            Foreach ($Entry in $ArrayData)
                                                {
                                                    If ($Entry -eq "ConfigurationId")
                                                        {
                                                            $WorkbookTemplateName = $ArmTemplateJson.properties.lenses.$Lense.parts.$Part.metadata.inputs.value[$index].split("/")[-1]
                                                            $ReplaceData = "ArmTemplates-/subscriptions/$($LogAnalyticsSubscription)/resourceGroups/$($WorkbookDashboardResourceGroup)/providers/microsoft.insights/workbooktemplates/" + $WorkbookTemplateName
                                                            $ArmTemplateJson.properties.lenses.$Lense.parts.$Part.metadata.inputs[$Index].value = $ReplaceData
                                                        }

                                                    ElseIf ($Entry -eq "StepSettings")
                                                        {
                                                            $Data = $ArmTemplateJson.properties.lenses.$Lense.parts.$Part.metadata.inputs.value[$index] | ConvertFrom-Json
                                                            $Data.crossComponentResources = @("$LogAnalyticsWorkspaceResourceId")

                                                            # Converting modified PSCustomObject data to compressed JSON
                                                            $Data = $Data | ConvertTo-Json -Depth 50 -Compress

                                                            # Updating ARM template object with modified data
                                                            $ArmTemplateJson.properties.lenses.$Lense.parts.$Part.metadata.inputs[$index].value = $Data
                                                        }
                                                    
                                                    # index is needed to read the value of the entry
                                                    $index += 1
                                                }
                                    }
                        }


                    $ArmTemplateExport = $ArmTemplateJson | ConvertTo-Json -Depth 50
                    $TemplateFile      = $Env:TEMP + "\" + $TemplateFileName
                    $ArmTemplateExport | out-file $TemplateFile -Force

                    Write-Output "   Starting deployment of dashboard [ $($TemplateName) ] "
                    Write-Output ""

                    # parameters for ARM deployment
                    New-AzPortalDashboard `
                        -DashboardPath $TemplateFile `
                        -ResourceGroupName $WorkbookDashboardResourceGroup `
                        -DashboardName $DashboardName
                }

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
        Write-Output "`$AzDcrPrefixClient                          = `"$($AzDcrPrefixClient)`" "
        Write-Output "`$AzDcrSetLogIngestApiAppPermissionsDcrLevel = `$false"
        Write-Output "`$AzDcrLogIngestServicePrincipalObjectId     = `"$($ServicePrincipalObjectId)`" "
        Write-Output "`$AzDcrDceTableCreateFromReferenceMachine    = @()"
        Write-Output "`$AzDcrDceTableCreateFromAnyMachine          = `$true"

