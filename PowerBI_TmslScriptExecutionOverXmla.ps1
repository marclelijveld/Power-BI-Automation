# TMSL Script
# Example TMSL scripts: https://docs.microsoft.com/en-us/analysis-services/tmsl/refresh-command-tmsl?WT.mc_id=DP-MVP-5003435&view=asallproducts-allversions
# This script helps you refresh a specified table in a specified dataset
# Please know this leverages Power BI XMLA endpoints and therefor Power BI Premium or Premium per user.  
# For full documenation, please look at: https://docs.microsoft.com/en-us/analysis-services/tmsl/refresh-command-tmsl?WT.mc_id=DP-MVP-5003435&view=asallproducts-allversions


# Run parameters, please specify below parameters
$WorkspaceName = "{Your workspace name here}" #Here it is the workspace name! Not the id! 
$DatasetName = "{Your dataset name here}" #Also known as database name
$TableName = "{Your Table name here}" #Table name in the specified dataset

# Base variables
$PbiBaseConnection = "powerbi://api.powerbi.com/v1.0/myorg/"
$XmlaEndpoint = $PbiBaseConnection + $WorkspaceName

# Check whether the SQL Server module is installed. If not, it will be installed.
# Install Module (Admin permissions might be required) 
$moduleName = Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "SqlServer" } | Select-Object -ExpandProperty Name;
if ([string]::IsNullOrEmpty($moduleName)) {
    Write-Host -ForegroundColor White "==============================================================================";
    Write-Host -ForegroundColor White  "Install module SqlServer...";
    Install-Module SqlServer -RequiredVersion 21.1.18230 -Scope CurrentUser -SkipPublisherCheck -AllowClobber -Force
    # Check for the latest version this documentation: https://www.powershellgallery.com/packages/SqlServer/
    Write-Host -ForegroundColor White "==============================================================================";
}

# TMSL Script
$TmslScript = 
@"
    {  
@ -20,14 +51,20 @@ $TmslScript =
        "type": "full",  
        "objects": [  
          {  
            "database": "Cellar Planning Dataset",  
            "table": "Production Orders",
            "database": "$DatasetName",  
            "table": "$TableName"
          }  
        ]  
      }  
    } 
"@

# Execute refresh trigger on specified table
Try {
    Invoke-ASCmd -Query $TmslScript -Server: $XmlaEndpoint -Database $DatasetName
    # Write message if succeeded
    Write-Host "Table" $TableName "in dataset" $DatasetName "successfully triggered to refresh" -ForegroundColor Green
}
Catch{
    # Write message if error
    Write-Host "An error occured" -ForegroundColor Red
}