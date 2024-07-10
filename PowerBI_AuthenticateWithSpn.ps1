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

# Define variables
$TenantId = "{YourTenantId}"

# Connect using SPN
Connect-PowerBIServiceAccount -ServicePrincipal -Credential (Get-Credential) -Tenant $TenantId
$ClientId = $SpInlog.ClientId