<# 
    This script helps you to perform backup operations for your Power BI Premium dataset. 
    Read more about backup and restore for Power BI in this documenation: https://docs.microsoft.com/en-us/power-bi/admin/service-premium-backup-restore-dataset?WT.mc_id=DP-MVP-5003435&
    In case you want to tweak the TMSL, go checkout this documentation: https://docs.microsoft.com/en-us/analysis-services/multidimensional-models-scripting-language-assl-xmla/backing-up-restoring-and-synchronizing-databases-xmla?WT.mc_id=DP-MVP-5003435&view=asallproducts-allversions#backing_up_databases
#>

# Run parameters, please specify below parameters
$WorkspaceName = "DEMO%20-%20Advanced%20data%20modeling" #Here it is the workspace name! Not the id! Please replace spaces for %20 
$DatasetName = "UltimateModel" #DatasetName to find the dataset and later to be used in backup filename

# Base variables
$PbiBaseConnection = "powerbi://api.powerbi.com/v1.0/myorg/"
$XmlaEndpoint = $PbiBaseConnection + $WorkspaceName

$NamePrefix = Get-Date -Format "yyyyMMdd-HHmmss" #Gets Date and Time on which the backup is performed as prefix to list backups easily in order
$BackupFileName = $NamePrefix + "_" + $DatasetName

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

# TMSL Script for backup
$TmslScript = 
@"
{
  "backup": {
    "database": "$DatasetName",
    "file": "$BackupFileName.abf",
    "allowOverwrite": false,
    "applyCompression": true
  }
}
"@

# Execute backup operation
Try {
    Invoke-ASCmd -Query $TmslScript -Server: $XmlaEndpoint
}
Catch{
    # Write message if error
    Write-Host "An error occured" -ForegroundColor Red
}