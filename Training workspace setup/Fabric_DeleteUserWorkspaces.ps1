﻿# =================================================================================================================================================
# Check if Power BI Module is available, if not install
# =================================================================================================================================================
$moduleName = Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "MicrosoftPowerBIMgmt" } | Select-Object -ExpandProperty Name;
if ([string]::IsNullOrEmpty($moduleName)) {
    Write-Host -ForegroundColor White "==============================================================================";
    Write-Host -ForegroundColor White  "Install module MicrosoftPowerBIMgmt...";
    Install-Module MicrosoftPowerBIMgmt -SkipPublisherCheck -AllowClobber -Force
    Write-Host -ForegroundColor White "==============================================================================";
}

﻿# =================================================================================================================================================
# Variables & functions
# =================================================================================================================================================

# Define value to find in workspace name
$workspaceName = "FabFeb - User*" # use * to add wildcards 

# Function to delete workspace matching criteria
function DeleteWorkspace {
    param (
        [string]$id
    )
    Write-Host $id

    # Delete workspace
    try {
        $url = "https://api.fabric.microsoft.com/v1/workspaces/$id"
        Invoke-PowerBIRestMethod -Method DELETE -Url $url  -ErrorAction Stop
        Write-Host "Successfully deleted workspace $workspaceId" -ForegroundColor Green
    } catch {
        Write-Host "Failed deleting $workspaceId : $($_.Exception.Message)" -ForegroundColor Red
        return  # Exit function if assignment fails
    }
}

﻿# =================================================================================================================================================
# Main code
# =================================================================================================================================================

# Connect with admin account
# Note: Make sure this is the same user as used to create workspaces. The user must have workspace administrator permissions to delete.
Connect-PowerBIServiceAccount

# List all workspaces the user has access to
$url = "https://api.fabric.microsoft.com/v1/workspaces"
$WsList = Invoke-PowerBIRestMethod -Method GET -Url $url  -ErrorAction Stop | ConvertFrom-Json

# Filter the list based on name part
$filteredItems = $WsList.value | Where-Object { $_.displayName -like $workspaceName }

# Output the filtered list
$filteredItems
Write-Host "No of items found matching" $workspaceName $filteredItems.Count -ForegroundColor Cyan

foreach ($item in $filteredItems) {
    DeleteWorkspace -id $item.id
}
