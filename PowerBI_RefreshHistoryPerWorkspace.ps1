<# 
This script helps you to get the refresh history of all dataflows and datasets in the specified workspace. 
Please define the workspace id in the general parameter section below. 

The results of this script will contain multiple files all in the context of the workspace defined: 
- Dataset metadata, including all the dataset names and properties
- Dataset refresh history
- Dataflow metadata, including all dataflow names and properties
- Dataflow refresh history
All results captured will be dumped in a sepatate json file on the defined location in the script. The default location is c:\RefreshHistoryDump. 

For full details on the script and corresponding blogpost, please see: 
https://data-marc.com/2021/01/07/extract-refresh-metrics-for-your-entire-power-bi-workspace/
#>

# In case you do not have the PowerShell Cmdlets for Power BI installed yet, please uncomment below row and install the module first. 
# Install-Module -Name MicrosoftPowerBIMgmt

# =================================================================================================================================================
# General parameters
# =================================================================================================================================================
# Define workspace to cature the results from
$WorkspaceId = "{Enter your Workspace ID here}"

# Base API for Power BI REST API
$PbiRestApi = "https://api.powerbi.com/v1.0/myorg/"

# Export data parameters
$FolderName = "RefreshHistoryDump"
$OutputLocation = "c:\"
$DatePrefix = Get-Date -Format "yyyyMMdd_HHmm" 
$DefaultFilePath = $Fullpath + "\" + $DatePrefix + "_" + $WorkspaceId + "_"
# All exported files will be prefixed with above mentioned date and Workspace Id. 
# This allows you to run the script multiple times without overwriting history. 

# =================================================================================================================================================
# General tasks
# =================================================================================================================================================
# Sign in to the Power BI Service using OAuth
Write-Host -ForegroundColor White "Sign in to connect to the Power BI Service";
Connect-PowerBIServiceAccount

# Create folder to dump results
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
Write-Host "Collecting dataflow metadata..."
$GetDataflowsApiCall = $PbiRestApi + "groups/" + $WorkspaceId + "/dataflows"
$AllDataflows = Invoke-PowerBIRestMethod -Method GET -Url $GetDataflowsApiCall | ConvertFrom-Json
$ListAllDataflows = $AllDataflows.value

# Write dataflow metadata json
$DataflowMetadataOutputLocation = $DefaultFilePath + 'DataflowMetadata.json'
$ListAllDataflows | ConvertTo-Json  | Out-File $DataflowMetadataOutputLocation -ErrorAction Stop
Write-Host "Dataflow metadata saved on defined location" -ForegroundColor Green

# Function to get dataflow refresh results
Function GetDataflowRefreshResults {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)][string]$DataflowId
    )
    Write-Host "Collecting dataflow refresh history..." $DataflowId
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
$DataflowResults  | ConvertTo-Json  | Out-File $DataflowRefreshOutputLocation -ErrorAction Stop
Write-Host "Dataflow refresh history saved on defined location" -ForegroundColor Green

# =================================================================================================================================================
# Dataset tasks
# =================================================================================================================================================
# List all datasets in specified workspace
Write-Host "Collecting dataset metadata..."
$GetDatasetsApiCall = $PbiRestApi + "groups/" + $WorkspaceId + "/datasets"
$AllDatasets = Invoke-PowerBIRestMethod -Method GET -Url $GetDatasetsApiCall | ConvertFrom-Json
$ListAllDatasets = $AllDatasets.value

# Write dataset metadata json
$DatasetsMetadataOutputLocation = $DefaultFilePath + 'DatasetsMetadata.json'
$ListAllDatasets | ConvertTo-Json  | Out-File $DatasetsMetadataOutputLocation -ErrorAction Stop
Write-Host "Dataset metadata saved on defined location" -ForegroundColor Green

# Function to get dataset refresh results
Function GetDatasetRefreshResults {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)][string]$DatasetId
    )
    Write-Host "Collecting dataset refresh history..." $DatasetId
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
$DatasetResults  | ConvertTo-Json  | Out-File $DatasetRefreshOutputLocation -ErrorAction Stop
Write-Host "Dataset refresh history saved on defined location" -ForegroundColor Green

# =================================================================================================================================================
# Closing script
# =================================================================================================================================================
Read-Host "Script finished. Press any key to close and open file location"
# Open file location
Invoke-Item $Fullpath