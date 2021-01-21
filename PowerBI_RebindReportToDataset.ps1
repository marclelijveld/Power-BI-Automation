<#
This script helps you to rebind an existing already published report to another dataset in the Power BI Service. 
Please specify the parameters below and make sure that the account has access to the workspaces where the datast and report are located. 

In case of a service principal or app registration, make sure that the required scope and persmissons is matched: 
Scope: Report.ReadWrite.All
Permission: Report - Write permissions. Target dataset - Build permissions

For full documenation, please look at: https://docs.microsoft.com/en-us/rest/api/power-bi/reports/rebindreportingroup?WT.mc_id=DP-MVP-5003435
#> 

# Run parameters, please specify below parameters
$WorkspaceId = "{Your workspace id}"
$ReportId = "{Report id to rebind}"
$TargetDatasetId = "{Dataset Id where you want the report to bind to}"

# Base variables
$BasePowerBIRestApi = "https://api.powerbi.com/v1.0/myorg/"

# Check whether the Power bI module is installed. If not, it will be installed. 
$moduleName = Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "MicrosoftPowerBIMgmt" } | Select-Object -ExpandProperty Name;
if ([string]::IsNullOrEmpty($moduleName)) {
    Write-Host -ForegroundColor White "==============================================================================";
    Write-Host -ForegroundColor White  "Install module MicrosoftPowerBIMgmt...";
    Install-Module MicrosoftPowerBIMgmt -SkipPublisherCheck -AllowClobber -Force
    Write-Host -ForegroundColor White "==============================================================================";
}

# Connect to Power BI service Account
Write-Host -ForegroundColor White "Connect to PowerBI service"
Connect-PowerBIServiceAccount

# Body to push in the Power BI API call
$body = 
@"
    {
	    datasetId: "$TargetDatasetId"
    }
"@ 

# Rebind report task
Write-Host -ForegroundColor White "Rebind report to specified dataset..."
Try {
    $RebindApiCall = $BasePowerBIRestApi + "groups/" + $WorkspaceId + "/reports/" + $ReportId + "/Rebind"
    Invoke-PowerBIRestMethod -Method POST -Url $RebindApiCall -Body $body -ErrorAction Stop
    # Write message if succeeded
    Write-Host "Report" $ReportId "successfully binded to dataset" $TargetDatasetId -ForegroundColor Green
}
Catch{
    # Write message if error
    Write-Host "Unable to rebind report. An error occured" -ForegroundColor Red
}