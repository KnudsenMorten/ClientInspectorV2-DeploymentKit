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

Write-Output "ClientInspector-DeploymentKit | Inventory of Operational & Security-related information"
Write-Output ""
Write-Output "Developed by Morten Knudsen, Microsoft MVP"
Write-Output ""
Write-Output "More information:"
Write-Output "https://github.com/KnudsenMorten/ClientInspectorV2-DeploymentKit"
Write-Output ""


#------------------------------------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------------------------------------

    $UseRandomNumber                       = $false
    If ($UseRandomNumber)
        {
            $Number                        = [string](Get-Random -Minimum 1000 -Maximum 10000)
        }
    Else
        {
            $Number                        = "999"
        }

    # put in your path where ClientInspector, AzLogDcrIngestPS and workbooks/dashboards will be downloaded to !
    $FolderRoot                            = (Get-location).Path + "\" + "Demo" + $Number
    
    MD $FolderRoot -ErrorAction SilentlyContinue -Force | Out-Null
    CD $FolderRoot | Out-Null


    # Azure App
    $AzureAppName                          = "Demo" + $Number + " - Automation - Log-Ingestion"
    $AzAppSecretName                       = "Secret used for Log-Ingestion"

    # Azure Active Directory (AAD)
    $TenantId                              = "f0fa27a0-8e7c-4f63-9a77-ec94786b7c9e" # "<put in your Azure AD TenantId>"

    # Azure LogAnalytics
    $LogAnalyticsSubscription              = "fce4f282-fcc6-43fb-94d8-bf1701b862c3" # "<put in the SubId of where to place environment>"
    $LogAnalyticsResourceGroup             = "rg-logworkspaces-client-demo" + $Number  + "-t"
    $LoganalyticsWorkspaceName             = "log-management-client-demo" + $Number + "-t"
    $LoganalyticsLocation                  = "westeurope"


    # Azure Data Collection Endpoint
    $AzDceName                             = "dce-" + $LoganalyticsWorkspaceName
    $AzDceResourceGroup                    = "rg-dce-" + $LoganalyticsWorkspaceName

    # Azure Data Collection Rules
    $AzDcrResourceGroup                    = "rg-dcr-" + $LoganalyticsWorkspaceName
    $AzDcrPrefix                           = "clt"

    # Azure Workbooks & Dashboards
    $TemplateCategory                      = "Demo" + $Number + " IT Operation Security Templates"
    $WorkbookDashboardResourceGroup        = "rg-dashboards-workbooks-demo" + $Number + "-t"

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
# Downloading newest versions of workbooks fra ClientInspector-DeploymentKit Github
#------------------------------------------------------------------------------------------------------------

    # path to store files
    $TempPath = (Get-location).Path + "\" + $WorkBook_Repository_Path

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
    $TempPath = (Get-location).Path + "\" + $Dashboard_Repository_Path

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

