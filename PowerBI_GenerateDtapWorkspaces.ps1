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
$workspaceName = "sample workspace"
$capacityId = "5ABEFB55-8DFB-42D0-B2A2-A6720D45A8A8"
$tenantId = "{InsertTenantId}" #Only applicable with SPN authentication

# DTAP stages setup 
$dev = "$workspaceName" + "-dev"
$tst = "$workspaceName" + "-tst"
$prd = "$workspaceName"

$stages = @($dev, $tst, $prd)

# Create empty json array
$wsCreated = @()

# =================================================================================================================================================
# Authentication
# =================================================================================================================================================

#Connect to Power BI service Account
Write-Host -ForegroundColor White "Connect to PowerBI service"
Connect-PowerBIServiceAccount #Connect with service account

#Connect using SPN
Connect-PowerBIServiceAccount -ServicePrincipal -Credential (Get-Credential) -Tenant $tenantId
$ClientId = $SpInlog.ClientId
# Note: This SPN should have Tenant.ReadWriteAll permissions to execute this script

# =================================================================================================================================================
# Workspace actions
# =================================================================================================================================================
Function SetupWorkspace {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)][string]$wsName
    )

# Create workspace
$bodyCreate =
@"
{
  "name": "$wsName"
}
"@

$createWs = Invoke-PowerBIRestMethod -Method POST -Url "https://api.powerbi.com/v1.0/myorg/groups" -Body $bodyCreate | ConvertFrom-Json
$wsId = $createWs.id
Write-Host "Workspace '$workspaceName' created with id $wsId" -ForegroundColor Green

# Assign workspace to capacity
$bodyAssign = 
@"
    {
      "capacityId": "$capacityId"
    }
"@

$assign = "https://api.powerbi.com/v1.0/myorg/groups/" + $createWs.id + "/AssignToCapacity"
$assignToCapacity = Invoke-PowerBIRestMethod -Method POST -Url $assign -Body $bodyAssign | ConvertFrom-Json
Write-Host "$wsId assigned to capacity $capacityId" -ForegroundColor Green

# Set storage format to large
$bodyStorageFormat = 
@"
{
  "defaultDatasetStorageFormat": "Large"
}
"@

$storageformat = "https://api.powerbi.com/v1.0/myorg/groups/" + $createWs.id
$changeStorageFormat = Invoke-PowerBIRestMethod -Method PATCH -Url $storageformat -Body $bodyStorageFormat | ConvertFrom-Json
Write-Host "$wsId storage format set to Large" -ForegroundColor Green
}

# =================================================================================================================================================
# Generate workspaces
# =================================================================================================================================================

# Generate Workspaces
foreach($wsName in $stages) {
    Write-Host "Identified stage workspace: $wsName"
    $CreateWorkspaces = SetupWorkspace -WsName $wsName
        foreach($wsCreated in $CreateWorkspaces) {
        Add-Member -InputObject $wsId -NotePropertyName 'WorkspaceId' -NotePropertyValue $wsId
        $wsCreated += $wsId
    }
 }
 # filling above array with all generated workspaces is not yet working properly, array contains same value all the time