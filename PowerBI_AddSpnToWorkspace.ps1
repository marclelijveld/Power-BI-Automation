﻿<# 
This script helps you to get add a service principal to a Power BI / Fabric workspace. 
Please be aware that the identifier refered to below, should be the object id from the enterprise application, not from the app registration!
More details about this script and the use case behind it, please read this blog post: 
https://data-marc.com/2023/09/12/add-service-principal-to-fabric-workspace-using-power-bi-rest-api/
#>

# =================================================================================================================================================
# General parameters
# =================================================================================================================================================
# Specify Power BI parameters for workspace and dataset where the current dataset is stored
$WorkspaceId = "{InsertWorkspaceId}"
$ObjectId = "{EnterpriseApplicationObjectId}"
$PermissionLevel = "{SpecifyPermissionLevel}" # Specify the level of permissions for the workspace, Admin, Member, Contributor or Viewer are allowed values.

# =================================================================================================================================================
# Check task for Power BI Module
# =================================================================================================================================================
# Check whether the Power bI module is installed. If not, it will be installed. 
$moduleName = Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "MicrosoftPowerBIMgmt" } | Select-Object -ExpandProperty Name;
if ([string]::IsNullOrEmpty($moduleName)) {
    Write-Host -ForegroundColor White "==============================================================================";
    Write-Host -ForegroundColor White  "Install module MicrosoftPowerBIMgmt...";
    Install-Module MicrosoftPowerBIMgmt -SkipPublisherCheck -AllowClobber -Force
    Write-Host -ForegroundColor White "==============================================================================";
}

# =================================================================================================================================================
# Task execution
# =================================================================================================================================================

# Connect to Power BI service Account
Write-Host -ForegroundColor Yellow "Connect to PowerBI service with an account with Power BI Service Administrator permissions..."
Connect-PowerBIServiceAccount

# Define API body
$Body = @"
{
  "identifier": "$ObjectId",
  "groupUserAccessRight": "$PermissionLevel",
  "principalType": "App"
}
"@ 

# Actual api call
$ApiDefinition = $BasePowerBIRestApi + "admin/groups/" + $WorkspaceId + "/users"
Invoke-PowerBIRestMethod -Method POST -Url $ApiDefinition -Body $body -Verbose
# Please note above call uses the Admin API. In case you want to execute this for your workspace only, remove the admin part from the API definition.
