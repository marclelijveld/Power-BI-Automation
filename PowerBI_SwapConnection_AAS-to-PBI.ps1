<# 
This script helps you swap the connection from Azure Analysis Services to a Power BI Premium dataset. 
Script can be used for single datasets as well as composite models. 
Please define the workspace id in the general parameter section below. 

For full details on the script and corresponding blogpost, please see: 
https://data-marc.com/2021/09/28/swap-connection-from-analysis-services-to-power-bi-dataset/
#>

# In case you do not have the PowerShell Cmdlets for Power BI installed yet, please uncomment below row and install the module first. 
# Install-Module -Name MicrosoftPowerBIMgmt

# =================================================================================================================================================
# General parameters
# =================================================================================================================================================
# Specify Power BI parameters for workspace and dataset where the current dataset is stored
$WorkspaceId = "{Your workspace ID}" 
$DatasetId = "{Your dataset ID}" 

# Specify datasource parameters
$DatasourceType = "AnalysisServices"
$SourceServer = "{Analysis Services connection string to server}"
$SourceDatabase = "{Analysis Services database name}"
$TargetServer = "{Power BI XMLA endpoint to workspace}"
$TargetDatabase = "{Dataset name in the target workspace}"

# Base variables
$BasePowerBIRestApi = "https://api.powerbi.com/v1.0/myorg/"

# =================================================================================================================================================
# Define functions
# =================================================================================================================================================
# Define request body for API call 
$Body = @"
{
   "updateDetails":[
      {
         "datasourceSelector":{
            "datasourceType":"$DatasourceType",
            "connectionDetails":{
               "server":"$SourceServer",
               "database":"$SourceDatabase"
            }
         },
         "connectionDetails":{
            "server":"$TargetServer",
            "database":"$TargetDatabase"
         }
      }
   ]
}
"@ 

# Check whether the Power bI module is installed. If not, it will be installed. 
Function CheckIfPowerBIModuleAvailable {
    $moduleName = Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "MicrosoftPowerBIMgmt" } | Select-Object -ExpandProperty Name;
    if ([string]::IsNullOrEmpty($moduleName)) {
        Write-Host -ForegroundColor White "==============================================================================";
        Write-Host -ForegroundColor White  "Install module MicrosoftPowerBIMgmt...";
        Install-Module MicrosoftPowerBIMgmt -SkipPublisherCheck -AllowClobber -Force
        Write-Host -ForegroundColor White "==============================================================================";
    }
}

Function UpdateDatasetConnectionString{
    try 
    {
# Update datasource API call
        $SpecifyUpdateDataSource = $BasePowerBIRestApi + "groups/" + $WorkspaceId + "/datasets/" + $DatasetId + "/Default.UpdateDatasources" 
        $UpdateDataSource = Invoke-PowerBIRestMethod -Method POST -Url $SpecifyUpdateDataSource -Body $Body -ErrorAction Stop
		# API call used for this execution can be found here: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/update-datasources-in-group?WT.mc_id=DP-MVP-5003435
		
# Get Datasources for dataset to check if datasource is updated
        $SpecifyGetDatasetConnectionDetails = $BasePowerBIRestApi + "groups/" + $WorkspaceId + "/datasets/" + $DatasetId + "/datasources" 
        $GetDatasetConnectionDetails = Invoke-PowerBIRestMethod -Method GET -Url $SpecifyGetDatasetConnectionDetails  | ConvertFrom-Json
		# API call used for this execution can be found here: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/get-datasources-in-group?WT.mc_id=DP-MVP-5003435&		
        Write-Host "Dataset with ID:" $GetDatasetConnectionDetails.value.datasourceId "that is located in Workspace" $WorkspaceId "..." -ForegroundColor Green
        Write-Host "...is now connected to datasource" $GetDatasetConnectionDetails.value.connectionDetails -ForegroundColor Green 	
		Write-Host "Please go to the Power BI Service and re-authenticate the data source from the dataset settings" -ForegroundColor Yellow
    }
    catch 
    {
        # Failed message
        Write-Host "An error occured during updating the datasource. Please investigate details to fix" -ForegroundColor Red
    }
}

# =================================================================================================================================================
# Task execution
# =================================================================================================================================================
# Check if the Power BI Module is available, if not install
Write-Host "Check if the Power BI cmdlets module is installed..."
CheckIfPowerBIModuleAvailable

# Connect with user account that has access to the dataset you want to bind to
Connect-PowerBIServiceAccount

# Execute datasource update
UpdateDatasetConnectionString