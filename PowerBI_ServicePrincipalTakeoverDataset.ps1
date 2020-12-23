@@ -1,145 +0,0 @@
﻿# =================================================================================================================================================
# DEFINE VARIABLES TO RUN SCRIPT
# =================================================================================================================================================
# General variables
$WorkspaceId = "2029446a-2b03-4db3-a230-e850471b1256" 
$DatasetId = "7c512bfe-e869-458d-981d-a11aca1f16c5" 
$GatewayId = "00780c2a-9953-4b41-bc9e-c7d92ba26eee" 
$GatewayDataSourceId = "SourceID"

# Base variables
$BasePowerBIRestApi = "https://api.powerbi.com/v1.0/myorg/"

# =================================================================================================================================================
# MENU
# =================================================================================================================================================
Function StartMenu {
    [int]$xMenuChoiceA = 0
    while ( $xMenuChoiceA -lt 1 -or $xMenuChoiceA -gt 2 ){
    Write-host "1. Takeover dataset with other account (UPN)"
    Write-host "2. Takeover dataset with Service Principal"
    [Int]$xMenuChoiceA = read-host "Please enter an option 1 or 2..." }
    Switch( $xMenuChoiceA ){
      1{ 
        Write-Host "`n"'You chose option #1, Service Account'
        OAuthSignIn
        AddServiceAccountToWorkspace
        Write-Host "Please now login with the account that needs to perform the take-over" 
        OAuthSignIn
        TakeOverDataset
        }
      2{
        Write-Host "`n"'You chose option #2, Service Principal'
        OAuthSignIn
        AddServicePrincipalToWorkspace
        ServicePrincipalSignIn
        TakeOverDataset
        }
    # default{<#run a default action or call a function here #>}
    }
}

# =================================================================================================================================================
# AUTHORIZATION FUNCTIONS
# =================================================================================================================================================
# Sign in with OAuth authorized user
Function OAuthSignIn {
    Disconnect-PowerBIServiceAccount
    Read-Host "You will now be prompted to authorized with an user account that has access to the defined workspace. 
Please hit any key to sign-in" 
    $UpnInlog = Connect-PowerBIServiceAccount
    $TenantId = $UpnInlog.TenantId
}

# Sign in with Service Princpal
Function ServicePrincipalSignIn {
    Disconnect-PowerBIServiceAccount
    Read-Host 
    "You will be prompted to authorized with the Service Principal. 
    You must use the Application ID and Secret here. 

    Please hit any key to sign-in"
    $SpInlog = Connect-PowerBIServiceAccount -ServicePrincipal -Credential (Get-Credential) -Tenant $TenantId
    $ClientId = $SpInlog.ClientId
}

# =================================================================================================================================================
# WORKSPACE PERMISSION FUNCTIONS
# =================================================================================================================================================
# Add Service Account to workspace
function AddServiceAccountToWorkspace{
# Ask for service account 
$ServiceAccountUpn = Read-Host -Prompt 'Please enter the Service Account mail address that you want to add'
try {
$JsonUserBody = @"
    {
      "emailAddress": "$ServiceAccountUpn",
      "groupUserAccessRight": "Admin"
    }
"@
    $ApiUrlAddWorkspaceMembership = $BasePowerBIRestApi + "groups/" + $WorkspaceId + "/users"
    Invoke-PowerBIRestMethod -Method POST -Url $ApiUrlAddWorkspaceMembership -Body "$JsonUserBody" -ERRORAction Stop
    Write-Host "Account" $ServiceAccountUpn "is successfully added to workspace" $WorkspaceId -BackgroundColor Green -ForegroundColor White
}
catch {
    Write-Host "ERROR: Failed to add" $ServiceAccountUpn "to workspace" $WorkspaceId -BackgroundColor Red -ForegroundColor White
    }
}

# Add Service Principal to workspace
function AddServicePrincipalToWorkspace{
OAuthSignIn

# Ask for service Principal Object Id
$ServicePrincipalId = Read-Host -Prompt 'Please enter the ObjectId of Service Principal (find this in the "Enterprise applications" in Azure Active Directory)'

try {
$JsonBody = @"
    {
      "identifier": "$ServicePrincipalId",
      "groupUserAccessRight": "Admin",
      "principalType": "App"
    }
"@

Invoke-PowerBIRestMethod -Method POST -Url $ApiUrlAddWorkspaceMembership -Body "$JsonBody" -ERRORAction Stop
Write-Host "Service Principal" $ServicePrincipalId "is successfully added to workspace" $WorkspaceId -BackgroundColor Green -ForegroundColor White

}
catch {
    Write-Host "ERROR: Failed to add" $ServicePrincipalId "to workspace" $WorkspaceId -BackgroundColor Red -ForegroundColor White 
    } 
}

# =================================================================================================================================================
# DATASET FUNCTIONS
# =================================================================================================================================================
# Take over dataset 
Function TakeOverDataset {
try {
    $ApiUrlTakeoverDataset = $BasePowerBIRestApi + "groups/" + $WorkspaceId + "/datasets/" + $DatasetId + "/Default.TakeOver"
    Invoke-PowerBIRestMethod -Method POST -Url $ApiUrlTakeoverDataset -ERRORAction Stop
    Write-Host "Succesfully taken over dataset with ID:" $DatasetId -BackgroundColor Green -ForegroundColor White 
    } 
catch {
        Write-Host "ERROR: Failed to takeover dataset" -BackgroundColor Red -ForegroundColor White 
    }
}

# Bind dataset to gateway
Function BindToGateway {
try{
$GatewayAssignmentBody = @"
    {
    "gatewayObjectId": $GatewayId
    }
"@    
    $ApiBindToGateway = $BasePowerBIRestApi + "groups/" + $WorkspaceId + "/datasets/" + $DatasetId + "/Default.BindToGateway"
    Invoke-PowerBIRestMethod -Method POST -Url $ApiBindToGateway -Body "$GatewayAssignmentBody" -ERRORAction Stop
    Write-Host "Dataset" $DatasetId "is successfully binded to gateway" $GatewayId -BackgroundColor Green -ForegroundColor White

    }
catch {
        Write-Host "ERROR: Failed to assing dataset to gateway" -BackgroundColor Red -ForegroundColor White
    }
}