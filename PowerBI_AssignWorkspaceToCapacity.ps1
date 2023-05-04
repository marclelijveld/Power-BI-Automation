<# 
All below commands use the Power BI REST API Admin commands.

Specific privileges are required to execute these commands.
For each item, the required permissions are specified in line. 
#>

# =================================================================================================================================================
# Check if Power BI Module is available, if not install
# =================================================================================================================================================
$moduleName = Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "MicrosoftPowerBIMgmt" } | Select-Object -ExpandProperty Name;
if ([string]::IsNullOrEmpty($moduleName)) {
    Write-Host -ForegroundColor White "==============================================================================";
    Write-Host -ForegroundColor White  "Install module MicrosoftPowerBIMgmt...";
    Install-Module MicrosoftPowerBIMgmt -SkipPublisherCheck -AllowClobber -Force
    Write-Host -ForegroundColor White "==============================================================================";
}

# =================================================================================================================================================
# Generic Tasks
# =================================================================================================================================================

# Variables
$CapacityId = "{InsertCapacityId}"
$WorkspaceId = "{InsertWorkspaceId}"
$TenantId = "{InsertTenantId}" #Only applicable with SPN authentication

# Connect to Power BI service Account
Write-Host -ForegroundColor White "Connect to PowerBI service"
Connect-PowerBIServiceAccount #Connect with service account

<# Connect using SPN
Connect-PowerBIServiceAccount -ServicePrincipal -Credential (Get-Credential) -Tenant $TenantId
$ClientId = $SpInlog.ClientId
#>

# =================================================================================================================================================
# Premium Capacity Tasks - Permissions: Capacity.ReadWrite.All or assignment permissions on the capacity
# =================================================================================================================================================

# Assign workspace to capacity
$bodyAssign = 
@"
    {
      "capacityId": "$CapacityId"
    }
"@

$assignPremium = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/AssignToCapacity"
Invoke-PowerBIRestMethod -Method POST -Url $assignPremium -Body $bodyAssign -ErrorAction Stop -Verbose

# Remove workspace from capacity
$bodyUnassign = 
@"
    {
      "capacityId": "00000000-0000-0000-0000-000000000000"
    }
"@

$unassignPremium = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/AssignToCapacity"
Invoke-PowerBIRestMethod -Method POST -Url $unassignPremium -Body $bodyUnassign -ErrorAction Stop
