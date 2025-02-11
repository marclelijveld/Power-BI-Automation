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

#All workspaces created will be part of this capacity. If no capacity is desired, specify "00000000-0000-0000-0000-000000000000"
$CapacityId = "{insertcapacityid}" 

# Function to create workspace, assign to capacity, and add user
function CreateItems {
    param ($index)
    # Make sure to add the domain name and adjust user name if needed.
    # Example: user1@domainname.com will be added to workspace "FabFeb - User 1", user2@domainname.com to workspace "FabFeb - User 2" and so forward.
    $userName =  "user$index@{domainname}.com".Trim() 
    $workspaceName = "FabFeb - User $index"
    
    try {
        # Create workspace
        $CreateWorkspace = New-PowerBIWorkspace -Name $workspaceName -ErrorAction Stop
        $workspaceId = $CreateWorkspace.Id
        Write-Host "Workspace '$workspaceName' successfully created with ID: $workspaceId" -ForegroundColor Green
    } catch {
        Write-Host "Failed creating workspace '$workspaceName': $($_.Exception.Message)" -ForegroundColor Red
        return  # Exit function if workspace creation fails
    }

    # Assign workspace to capacity
    try {
        $body = @"
        {
          "capacityId": "$CapacityId"
        }
"@
        $url = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/assignToCapacity"
        Invoke-PowerBIRestMethod -Method POST -Url $url -Body $body -ErrorAction Stop
        Write-Host "Workspace ID $workspaceId assigned to capacity $CapacityId" -ForegroundColor Green
    } catch {
        Write-Host "Failed assigning workspace ID $workspaceId to capacity: $($_.Exception.Message)" -ForegroundColor Red
        return  # Exit function if assignment fails
    }

    # Add user to workspace
    try {
        Add-PowerBIWorkspaceUser -Scope Individual -Id $workspaceId -UserEmailAddress $userName -AccessRight Member -ErrorAction Stop
        Write-Host "User $userName assigned as Member to workspace $workspaceId" -ForegroundColor Green 
    } catch {
        Write-Host "Failed to assign user $userName to workspace ID $workspaceId : $($_.Exception.Message)" -ForegroundColor Red
    }
}

﻿# =================================================================================================================================================
# Main code
# =================================================================================================================================================

# Connect with account, this account will also have access to all workspaces
# Note: The account used must have workspace creation permissions + capacity assignment permissions
Connect-PowerBIServiceAccount

# Generate series, specify number of iterations (current sample is between 1 and 3, will generate 3 workspaces)
for ($i = 1; $i -le 3; $i++) {
    Write-Output "Processing user $i"
    
    CreateItems -index $i

    Write-Output "Finished processing user $i"
    Write-Output "----------------------"
}
