<# 
This script helps you to get the refresh history of all dataflows in the specified workspace. 
Please define the workspace id in the parameter below. 

All results captured will be dumped in a json file on the defined location below. This allows you to run the script multiple times without overwriting history. 
#>

# Define workspace to cature the results from
$WorkspaceId = "5d9e5023-3810-4cfa-abaf-4f0494b31404"

# Sign in to the Power BI Service using OAuth
Write-Host -ForegroundColor White "Sign in to connect to the Power BI Service";
Connect-PowerBIServiceAccount

# Base API for Power BI REST API
$PbiRestApi = "https://api.powerbi.com/v1.0/myorg/"

# List all dataflows in specified workspace
$GetDataflowsApiCall = $PbiRestApi + "groups/" + $WorkspaceId + "/dataflows"
$AllDataflows = Invoke-PowerBIRestMethod -Method GET -Url $GetDataflowsApiCall | ConvertFrom-Json
$ListAllDataflows = $AllDataflows.value

# Function to get dataflow refresh results
Function GetDataflowRefreshResults {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)][string]$DataflowId
    )
    $GetDataflowRefreshHistory = $PbiRestApi + "groups/" + $WorkspaceId + "/dataflows/" + $DataflowId + "/transactions"
    $DataflowRefreshHistory = Invoke-PowerBIRestMethod -Method GET -Url $GetDataflowRefreshHistory | ConvertFrom-Json
    return $DataflowRefreshHistory.value
}

# Create empty json array
$results = @()

# Get refresh history for each dataflow in defined workspace
foreach($dataflow in $ListAllDataflows) {
    $flowHistory = GetDataflowRefreshResults -DataflowId $dataflow.objectId
    $results += $flowHistory
}

# Create folder to dump results
$FolderName = "RefreshHistoryDump"
$OutputLocation = "c:\"
$Fullpath = $OutputLocation + $FolderName
 if (-not (Test-Path $Fullpath)) {
        # Destination path does not exist, let's create it
        try {
            New-Item -Path $Fullpath -ItemType Directory -ErrorAction Stop
        } catch {
            throw "Could not create path '$Fullpath'!"
        }
    }

# Write json file to output location
$DatePrefix = Get-Date -Format "yyyyMMdd_HHmm" 
$OutputLocation = $Fullpath + "\" + $DatePrefix + "_" + $WorkspaceId + "_" + 'DataflowRefreshHistory.json'
$results  | ConvertTo-Json  | Out-File $OutputLocation