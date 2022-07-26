# =================================================================================================================================================
# Documentation
# =================================================================================================================================================
<#
This script helps you to find existing Power BI Deployment pipelines and secondly to assign additional users to that pipeline. 
Keep in mind this only relates to the pipeline and not to the linked workspaces. Workspace permissions can be easily granted int he user interface of the admin portal. 
This can be used in case your colleague is on vacation and forgot to grant you permissions to the related deployment pipeline. 

Permission: Power BI Service Administrator
For full documenation on APIs used, please look at: 
- Get pipelines: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/pipelines-get-pipelines-as-admin?WT.mc_id=DP-MVP-5003435
- Add user to pipeline: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/pipelines-update-user-as-admin?WT.mc_id=DP-MVP-5003435
#> 

# =================================================================================================================================================
# General parameters
# =================================================================================================================================================
# Base variables
$BasePowerBIRestApi = "https://api.powerbi.com/v1.0/myorg/"

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

# List all existing Deployment pipelines on screen: 
$ListPipelinesCall = $BasePowerBIRestApi + "admin/pipelines"
$ListPipelines = Invoke-PowerBIRestMethod -Method GET -Url $ListPipelinesCall -ErrorAction Stop | ConvertFrom-Json

Write-Host -ForegroundColor Yellow "Please identify the pipeline you are looking for and copy the id from below list..."
$ListPipelines.value

# Specify variables for pipeline to update
Write-Host -ForegroundColor Yellow "Please specify the following variables in order to update the pipeline permissions"
$PipelineId = Read-Host "Please enter the pipeline Id here" 
$UserName = Read-Host "Please enter the mail address of the user to add to the specified pipeline"

# Update permissions on existing pipeline
$Body = @"
{
  "identifier": "$UserName",
  "accessRight": "Admin",
  "principalType": "User"
}
"@ 
Write-Host -ForegroundColor Yellow "Updating permissions..."
$UpdatePermissionsCall = $BasePowerBIRestApi + "admin/pipelines/" + $PipelineId + "/users"
$UpdatePermissions = Invoke-PowerBIRestMethod -Method POST -Url $UpdatePermissionsCall -Body $body -ErrorAction Stop -Verbose
