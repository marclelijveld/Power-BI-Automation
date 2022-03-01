<# 
    This script helps you to recreate row or object level security roles, and assign users to these roles.  
    
    Also find related documentation here: 
    https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-database-users?WT.mc_id=DP-MVP-5003435&
    https://docs.microsoft.com/en-us/analysis-services/tmsl/createorreplace-command-tmsl?WT.mc_id=DP-MVP-5003435&view=asallproducts-allversions
#>

# Run parameters, please specify below parameters
$WorkspaceName = "YourWorkspaceName" # Here specify the workspace name, not the id! Please replace spaces for %20. This is used to concatenate the XMLA endpoint later. 
$DatasetName = "YourDatasetName" # DatasetName to find the dataset and later to be used in backup filename
$RoleName = "YourRoleName"
$RoleDescription = "YourRoleDescription" # Specify your role description here, as this will be saved in the model too.

# Base variables
$PbiBaseConnection = "powerbi://api.powerbi.com/v1.0/myorg/"
$XmlaEndpoint = $PbiBaseConnection + $WorkspaceName


# Check whether the SQL Server module is installed. If not, it will be installed.
# Install Module (Admin permissions might be required) 
$moduleName = Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "SqlServer" } | Select-Object -ExpandProperty Name;
if ([string]::IsNullOrEmpty($moduleName)) {
    Write-Host -ForegroundColor White "==============================================================================";
    Write-Host -ForegroundColor White  "Install module SqlServer...";
    Install-Module SqlServer -RequiredVersion 21.1.18256 -Scope CurrentUser -SkipPublisherCheck -AllowClobber -Force
    # Check for the latest version this documentation: https://www.powershellgallery.com/packages/SqlServer/
    Write-Host -ForegroundColor White "==============================================================================";
}

# TMSL Script for assign user
$TmslScript = 
@"
{
  "createOrReplace": {
    "object": {
      "database": "$DatasetName",
      "role": "$RoleName"
    },
    "role": {
      "name": "$RoleName",
      "description": "$RoleDescription",
      "modelPermission": "read",
      "tablePermissions": [
        {
          "name": "Geography",
          "filterExpression": "[Country] = \"Canada\"" 
        }
      ],
	        "members": [
        {
          "memberName": "User1@YourTenant.com",
          "identityProvider": "AzureAD"
        },
        {
          "memberName": "User2@YourTenant.com",
          "identityProvider": "AzureAD"
        }
      ]
    }
  }
}
"@
# Please note the example filter expression used above for [Country" = "Canada" in table Geography. 
# Specify your own before executing, as the filter expression will be replaced. 
# Alter commands will not work to update role permissions. Therefore CreateOrReplace is required. 


# Execute Create or Replace role operation
Try {
    Invoke-ASCmd -Query $TmslScript -Server: $XmlaEndpoint
}
Catch{
    # Write message if error
    Write-Host "An error occured" -ForegroundColor Red
}