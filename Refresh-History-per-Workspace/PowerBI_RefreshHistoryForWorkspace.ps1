<# 
This script helps you to get the refresh history of all dataflows and datasets in the specified workspace. 
Please define the workspace id in the parameter below. 

All results captured will be dumped in a json file on the defined location below. This allows you to run the script multiple times without overwriting history. 
#>

# =================================================================================================================================================
# General parameters
# =================================================================================================================================================
# Define workspace to cature the results from
$WorkspaceId = "{Your workspace id here}"

# Base API for Power BI REST API
$PbiRestApi = "https://api.powerbi.com/v1.0/myorg/"

# Export data parameters
$DatePrefix = Get-Date -Format "yyyyMMdd_HHmm" 
$DefaultFilePath = $Fullpath + "\" + $DatePrefix + "_" + $WorkspaceId + "_"

# =================================================================================================================================================
# General tasks
# =================================================================================================================================================
# Sign in to the Power BI Service using OAuth
Write-Host -ForegroundColor White "Sign in to connect to the Power BI Service";
Connect-PowerBIServiceAccount

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

# =================================================================================================================================================
# Dataflow tasks
# =================================================================================================================================================
# List all dataflows in specified workspace
$GetDataflowsApiCall = $PbiRestApi + "groups/" + $WorkspaceId + "/dataflows"
$AllDataflows = Invoke-PowerBIRestMethod -Method GET -Url $GetDataflowsApiCall | ConvertFrom-Json
$ListAllDataflows = $AllDataflows.value

# Write dataflow metadata json
$DataflowMetadataOutputLocation = $DefaultFilePath + 'DataflowMetadata.json'
$ListAllDataflows | ConvertTo-Json  | Out-File $DataflowMetadataOutputLocation

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
$DataflowResults = @()

# Get refresh history for each dataflow in defined workspace
foreach($dataflow in $ListAllDataflows) {
    $DataflowHistories = GetDataflowRefreshResults -DataflowId $dataflow.objectId
    foreach($DataflowHistory in $DataflowHistories) {
        Add-Member -InputObject $DataflowHistory -NotePropertyName 'DataflowId' -NotePropertyValue $dataflow.objectId
        $DataflowResults += $DataflowHistory
    }  
}

# Write dataflow refresh history json to output location
$DataflowRefreshOutputLocation =  $DefaultFilePath + 'DataflowRefreshHistory.json'
$DataflowResults  | ConvertTo-Json  | Out-File $DataflowRefreshOutputLocation

# =================================================================================================================================================
# Dataset tasks
# =================================================================================================================================================
# List all datasets in specified workspace
$GetDatasetsApiCall = $PbiRestApi + "groups/" + $WorkspaceId + "/datasets"
$AllDatasets = Invoke-PowerBIRestMethod -Method GET -Url $GetDatasetsApiCall | ConvertFrom-Json
$ListAllDatasets = $AllDatasets.value

# Write dataset metadata json
$DatasetsMetadataOutputLocation = $DefaultFilePath + 'DatasetsMetadata.json'
$ListAllDatasets | ConvertTo-Json  | Out-File $DatasetsMetadataOutputLocation

# Function to get dataset refresh results
Function GetDatasetRefreshResults {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)][string]$DatasetId
    )
    $GetDatasetRefreshHistory = $PbiRestApi + "groups/" + $WorkspaceId + "/datasets/" + $DatasetId + "/refreshes"
    $DatasetRefreshHistory = Invoke-PowerBIRestMethod -Method GET -Url $GetDatasetRefreshHistory | ConvertFrom-Json
    return $DatasetRefreshHistory.value
}

# Create empty json array
$DatasetResults = @()

# Get refresh history for each dataset in defined workspace
foreach($Dataset in $ListAllDatasets) {
    $DatasetHistories = GetDatasetRefreshResults -DatasetId $Dataset.id
    foreach($DatasetHistory in $DatasetHistories) {
        Add-Member -InputObject $DatasetHistory -NotePropertyName 'DatasetId' -NotePropertyValue $Dataset.id
        $DatasetResults += $DatasetHistory
    }
}

# Write dataset refresh history json to output location
$DatasetRefreshOutputLocation =  $DefaultFilePath + 'DatasetRefreshHistory.json'
$DatasetResults  | ConvertTo-Json  | Out-File $DatasetRefreshOutputLocation