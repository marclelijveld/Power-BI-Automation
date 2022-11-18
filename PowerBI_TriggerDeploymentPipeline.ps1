<#
This script automates the deployment of a Power BI Deployment pipeline. The sample below, deploys Dev > Test. 
In case you want to deploy Test > Prod, change the sourceStageOrder to 1. 

Details and docs can be found: https://learn.microsoft.com/en-us/rest/api/power-bi/pipelines/deploy-all?WT.mc_id=DP-MVP-5003435

Sample authentication below, authenticates using a Service Principal. In case you want to authenticate using a named user, you can simplify this part of the script by only calling
Connect-PowerBIServiceAccount without any further specification. After that you will be prompted to authenticate using OAuth. 
#>

# Define variables
$TenantId = "{YourTenantId}"
$PipelineId = "{YourPipelineId}"

# Connect using SPN
Connect-PowerBIServiceAccount -ServicePrincipal -Credential (Get-Credential) -Tenant $TenantId
$ClientId = $SpInlog.ClientId

# Define deployment note
$DeploymentNote = Read-Host Define your note to attache to the deployment

# Define request body, 0 for Dev > Test. 1 for Test > Prod
$body = @"
{
  "sourceStageOrder": 0,
  "options": {
    "allowOverwriteArtifact": true,
    "allowCreateArtifact": true
  },
  "note": "$DeploymentNote"
}
"@

# Send API request to PBI Service
$RequestCall = "https://api.powerbi.com/v1.0/myorg/pipelines/$PipelineId/deployAll"
Invoke-PowerBIRestMethod -Method Post -Url $RequestCall -Body $body -Verbose
