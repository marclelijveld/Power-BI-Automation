# This script generates a Fabric working environment automatically

# =================================================================================================================================================
# Config
# =================================================================================================================================================
$workspaceId = "abc123"
$capacityId = "5ABEFB55-8DFB-42D0-B2A2-A6720D45A8A8"

$stages = 'dev', 'tst', 'prd'
$layers = 'bronze', 'silver', 'gold'

# =================================================================================================================================================
# Authentication
# =================================================================================================================================================
 Write-Host "Please connect your account" -ForegroundColor Yellow
 try {
    Connect-AzAccount
    $GetToken = Get-AzAccessToken
    $accessToken = $GetToken.Token
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $($accessToken)")

    Write-Host "Successfully signed in" -ForegroundColor Green
 }
     
catch {
    Write-Host "An error occured during authentication" -ForegroundColor Red
}

# =================================================================================================================================================
# Functions
# =================================================================================================================================================
function create-workspace {
    $workspaceBody = @"
    {
        "displayName": "New workspace",
        "capacityId": "$capacityId"
    }   
"@
    try {
            Invoke-RestMethod -Method POST -Uri "https://api.fabric.microsoft.com/v1/workspaces" -Body $workspaceBody -ContentType "application/json" -Headers $headers -Verbose
            Write-Host "Created workspace A" -ForegroundColor Green
    }
    catch { Write-Host "An error occured creating the workspace" -ForegroundColor Red}
}

Invoke-RestMethod -Method GET -Uri "https://api.fabric.microsoft.com/v1/workspaces/e3593024-9cab-49f6-801c-1f0ee13bc902" -ContentType "application/json" -Headers $headers -Verbose

function create-lakehouse {
    $lakehouseBody = @"
    {
      "displayName": "$layer",
      "type": "Lakehouse",
      "description": "This item is automatically generated through a template"
    }
"@ 
    try {
            Invoke-RestMethod -Method POST -Uri "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/items" -Body $lakehouseBody
            Write-Host "Created lakehouse $layer" -ForegroundColor Green
        }
    catch { Write-Host "An error occured creating lakehouse $layer" -ForegroundColor Red }
}

function create-notebook {
    $notebookBody = @"
    {
      "displayName": "Ingest - $layer",
      "type": "Notebook",
      "description": "This item is automatically generated through a template"
    }
"@ 
    try {
            Invoke-RestMethod -Method POST -Uri "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/items" -Body $notebookBody
            Write-Host "Created notebook Ingest - $layer" -ForegroundColor Green
        }
    catch { Write-Host "An error occured creating Notebook Ingest - $layer" -ForegroundColor Red }
}

# =================================================================================================================================================
# Main code
# =================================================================================================================================================

# Generate lakehouses
foreach( $layer in $layers)
{
    create-lakehouse
    create-notebook
}

    $GetToken = Get-AzAccessToken
    $accessToken = $GetToken.Token

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $($accessToken)")

# set the endpoint
$endpoint = "https://api.fabric.microsoft.com/v1/workspaces/e3593024-9cab-49f6-801c-1f0ee13bc902"

# get the report properties, including the embed URL
$report = Invoke-RestMethod -Method Get -Headers $headers -Uri $endpoint