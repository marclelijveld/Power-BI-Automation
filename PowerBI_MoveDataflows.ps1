<# 
In order to make this work for you, replace the values provided as variables in: $SourceWorkspaceName, $DestinationWorkspaceName and $DataflowName

Script to move dataflows across Power BI workspaces. Please know that:
- The workspace name will be used to lookup the workspace id (for both source and destination workspace).
- The dataflows are defined in the $dataflowItems variable. All dataflows listed here, will be moved. 
- It is possible to dynamically replace connectionstrings during deployment. Please see the $replaceItems variable to define the search and replace value. 
- If the dataflow already exists, it will be replaced.

Check this blogpost for more details on recent changes: https://data-marc.com/2020/12/02/update-move-dataflows-across-workspaces/

The tasks applied in this Powershells script are described in detail on https://data-marc.com/2019/10/22/move-dataflows-across-workspaces-with-the-power-bi-rest-api 
Also check the ConflictHandlerMode options you have in the Microsoft documemtation: https://docs.microsoft.com/en-us/rest/api/power-bi/imports/postimport?WT.mc_id=DP-MVP-5003435&#importconflicthandlermode 
These properties can be changed in the code according to your preference.
#>





# [OutputType([Void])]
# Param (
#     [Parameter(Mandatory = $true, Position = 0)]
#     [ValidateNotNullOrEmpty()]
#     [String] 
#     $SourceWorkspaceName,

#     [Parameter(Mandatory = $true, Position = 1)]
#     [ValidateNotNullOrEmpty()]
#     [String] 
#     $DestinationWorkspaceName,

#     [Parameter(Mandatory = $true, Position = 2)]
#     [ValidateNotNullOrEmpty()]
#     [String] 
#     $DataflowName"
# )

# =================================================================================================================================================
# General parameters
# =================================================================================================================================================
# Define workspace to cature the results from
$sourceWorkspace = "QFI-KPI-Tree"
$destinationWorkspace = "QFI_Copy_Test"
# Base API for Power BI REST API
$PbiRestApi = "https://api.powerbi.com/v1.0/myorg/"





class DataFlow {
    [string]$SourceWorkspaceName
    [string]$DestinationWorkspaceName
    [string]$DataflowName
`
    DataFlow([string]$SourceWorkspaceName, [string]$DestinationWorkspaceName,[string]$DataflowName) {
        $this.SourceWorkspaceName = $SourceWorkspaceName
        $this.DestinationWorkspaceName = $DestinationWorkspaceName
        $this.DataflowName = $DataflowName
    }
}

class Replacement {
    [string]$SearchValue
    [string]$ReplaceValue
`
    Replacement([string]$SearchValue, [string]$ReplaceValue) {
        $this.SearchValue = $SearchValue
        $this.ReplaceValue = $ReplaceValue
    }
}


$replaceItems =@(
    [Replacement]::new("https://yourconnectionindev.blob.core.windows.net","https://yourconnectioninprod.blob.core.windows.net")
)

#
# Script functions
#
function _getPowerBINameConflict([string] $GroupID, [string]$DataflowName) {
    $url = [string]::Format("groups/{0}/dataflows", $GroupID);
    $flowItems = Invoke-PowerBIRestMethod -Method GET -Url $url | ConvertFrom-Json
    $flow = $flowItems.value | Where-Object { $_.name -eq $DataflowName }

    if($flow) { 
        return "Overwrite"
    } else {
        return "Ignore"
    }   
}

function _getPowerBIDataflowDefinition([string] $GroupID, [string]$DataflowName) {
    $url = [string]::Format("groups/{0}/dataflows", $GroupID);
    $flowItems = Invoke-PowerBIRestMethod -Method GET -Url $url | ConvertFrom-Json
    $flow = $flowItems.value | Where-Object { $_.name -eq $DataflowName }

    if ($flow) {
        $url = [string]::Format("groups/{0}/dataflows/{1}", $GroupID, $flow.objectId);
        $flowdefinition = Invoke-PowerBIRestMethod -Method GET -Url $url | ConvertFrom-Json

        # check for allowNativeQueries
        #    "pbi:mashup": {
        #    "allowNativeQueries": false,
        if ($flowdefinition.'pbi:mashup'.'allowNativeQueries')
        {
            $flowdefinition.'pbi:mashup'.'allowNativeQueries'= $FALSE
        }

        forEach ($entity in $flowdefinition.entities) {
            if (Get-Member -InputObject $entity -Name "partitions" -MemberType Properties) {
                $entity.partitions = @()
            }
        }
        return $flowdefinition
    }
    else {
        return $null
    }
}

function _postDataflowDefinition([string] $GroupID, [string]$DataflowDefinition, [string]$NameConflict) {

    $UserAccessToken = Get-PowerBIAccessToken
    $bearer = $UserAccessToken.Authorization.ToString()
    
    $url = [string]::Format("https://api.powerbi.com/v1.0/myorg/groups/{0}/imports?datasetDisplayName=model.json&nameConflict={1}", $GroupID, $NameConflict);

    $boundary = [System.Guid]::NewGuid().ToString("N")
    $LF = [System.Environment]::NewLine
		
    $body = (
        "--$boundary",
        "Content-Disposition: form-data; name=`"`"; filename=`"model.json`"",
        "Content-Type: application/json$LF",
        $DataflowDefinition,
        "--$boundary--$LF"
    ) -join $LF

    $headers = @{
        'Authorization' = "$bearer"
        'Content-Type'  = "multipart/form-data; boundary=--$boundary"
    }
    
    $postFlow = Invoke-RestMethod -Uri $url -ContentType 'multipart/form-data' -Method POST -Headers $headers -Body $body;

    return $postFlow;
}


#
#
# Main code
#
#
$moduleName = Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "MicrosoftPowerBIMgmt" } | Select-Object -ExpandProperty Name;
if ([string]::IsNullOrEmpty($moduleName)) {
    Write-Host -ForegroundColor White "==============================================================================";
    Write-Host -ForegroundColor White  "Install module MicrosoftPowerBIMgmt...";
    Install-Module MicrosoftPowerBIMgmt -SkipPublisherCheck -AllowClobber -Force
    Write-Host -ForegroundColor White "==============================================================================";
}

Write-Host -ForegroundColor White "Connect to PowerBI service";
Connect-PowerBIServiceAccount


$sourceWorkspace = Get-PowerBIWorkspace -Name $sourceWorkspace| Select-Object -First 1
$destinationWorkspace = Get-PowerBIWorkspace -Name $destinationWorkspace| Select-Object -First 1

# List all dataflows in specified workspace

Write-Host "Collecting dataflow metadata..."
$GetDataflowsApiCall = $PbiRestApi + "groups/" + $SourceWorkspace.Id + "/dataflows"
$AllDataflows = Invoke-PowerBIRestMethod -Method GET -Url $GetDataflowsApiCall | ConvertFrom-Json
$ListAllDataflows = $AllDataflows.value;



$dataFlowItems =New-Object System.Collections.ArrayList;

foreach ($dataflow in $ListAllDataflows) {
$dataFlowItems.Add([DataFlow]::new($SourceWorkspace.name,$destinationWorkspace.name,$dataflow.name))
}




foreach ($dataflowitem in $dataFlowItems) {
   
    #
    # Get source workspace
    #
    Write-Host -ForegroundColor White ( [string]::Format("Get Power BI workspace '{0}'", $dataflowitem.SourceWorkspaceName) )
    Write-Host -ForegroundColor White ( [string]::Format("Get Power BI dataflow '{0}'",$dataflowitem.DataflowName) )
    
    $sourceWorkspace = Get-PowerBIWorkspace -Name $dataflowitem.SourceWorkspaceName;

    if ($sourceWorkspace) {
        #
        # Get destination workspace
        #
        $destinationWorkspace = Get-PowerBIWorkspace -Name $dataflowitem.DestinationWorkspaceName;
        if ($destinationWorkspace) {
            #
            # Get dataflow object from source workspace
            #
            $dataflowobject = _getPowerBIDataflowDefinition -GroupID $sourceWorkspace.Id -DataflowName $dataflowitem.DataflowName
            
            #
            # Check if destination workflow exists
            #
            $conflictName = _getPowerBINameConflict -GroupID $destinationWorkspace.Id -DataflowName $dataflowitem.DataflowName

            if ($dataflowobject) {
                $dataflowJSON = $dataflowobject | ConvertTo-Json -Depth 100 -Compress

                foreach ($replace in $replaceItems) {
                    $dataflowJSON = $dataflowJSON.Replace($replace.SearchValue,$replace.ReplaceValue)
                }               

                $newDataFlow = _postDataflowDefinition -GroupID $destinationWorkspace.Id -DataflowDefinition $dataflowJSON -NameConflict $conflictName
                Write-Host -ForegroundColor Black -BackgroundColor Green ( [string]::Format("New dataflow with id '{0}' created in workspace '{1}'", $newDataFlow.id, $dataflowitem.DestinationWorkspaceName ) )
            }
            else {
                Write-Host -ForegroundColor Red -BackgroundColor Yellow ( [string]::Format("Dataflow '{0}' not found!", $dataflowitem.DataflowName ) );
            }    
        }
        else {
            Write-Host -ForegroundColor Red -BackgroundColor Yellow ( [string]::Format("Destination workspace '{0}' not found!", $dataflowitem.DestinationWorkspaceName ) );
        }
    }
    else {
        Write-Host -ForegroundColor Red -BackgroundColor Yellow ( [string]::Format("Source workspace '{0}' not found!", $dataflowitem.SourceWorkspaceName ) );
    }
}
