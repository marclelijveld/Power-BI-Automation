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
$UPN = "{InsertUpn}"
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
# Workspace Permission Tasks - Permissions: Tenant.ReadWrite.All
# =================================================================================================================================================

# Assign user to workspace
$bodyAddUser = 
@"
    {
      "emailAddress": "$UPN",
      "groupUserAccessRight": "Admin"
    }
"@ 

$addUser = "https://api.powerbi.com/v1.0/myorg/admin/groups/$WorkspaceId/users"
Invoke-PowerBIRestMethod -Method POST -Url $addUser -Body $bodyAddUser -ErrorAction Stop

# Remove user from workspace
$removePremissions = "https://api.powerbi.com/v1.0/myorg/admin/groups/$WorkspaceId/users/$UPN"
Invoke-PowerBIRestMethod -Method DELETE -Url $removePremissions -ErrorAction Stop
