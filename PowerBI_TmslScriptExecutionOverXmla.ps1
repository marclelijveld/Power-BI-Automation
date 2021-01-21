<<<<<<< Updated upstream
﻿# Install Module (Admin permissions might be required)
# Check for the latest version this documentation: https://www.powershellgallery.com/packages/SqlServer/
Install-Module -Name SqlServer -RequiredVersion 21.1.18230 -Scope CurrentUser

$PbiBaseConnection = "powerbi://api.powerbi.com/v1.0/myorg/"
$WorkspaceName = "QBA-Cellar Planning"
$XmlaEndpoint = $PbiBaseConnection + $WorkspaceName
$DatasetName = "Cellar Planning Dataset" #Also known as database name

# Authentication Using Service Principal
#$TenantId = ""
#$login = Get-Credential

# TMSL Script
# Example TMSL scripts: https://docs.microsoft.com/en-us/analysis-services/tmsl/refresh-command-tmsl?WT.mc_id=DP-MVP-5003435&view=asallproducts-allversions
=======
﻿<#
This script helps you refresh a specified table in a specified dataset. 
Please know this leverages Power BI XMLA endpoints and therefor Power BI Premium or Premium per user.  

For full documenation, please look at: https://docs.microsoft.com/en-us/analysis-services/tmsl/refresh-command-tmsl?WT.mc_id=DP-MVP-5003435&view=asallproducts-allversions
#> 

# Run parameters, please specify below parameters
$WorkspaceName = "{Your workspace name here}" #Here it is the workspace name! Not the id! 
$DatasetName = "{Your dataset name here}" #Also known as database name
$TableName = "{Your Table name here}"

# Base variables
$PbiBaseConnection = "powerbi://api.powerbi.com/v1.0/myorg/"
$XmlaEndpoint = $PbiBaseConnection + $WorkspaceName

# Check whether the Power bI module is installed. If not, it will be installed.
# Install Module (Admin permissions might be required) 
$moduleName = Get-Module -ListAvailable -Verbose:$false | Where-Object { $_.Name -eq "SqlServer" } | Select-Object -ExpandProperty Name;
if ([string]::IsNullOrEmpty($moduleName)) {
    Write-Host -ForegroundColor White "==============================================================================";
    Write-Host -ForegroundColor White  "Install module SqlServer...";
    Install-Module SqlServer -RequiredVersion 21.1.18230 -Scope CurrentUser -SkipPublisherCheck -AllowClobber -Force
    # Check for the latest version this documentation: https://www.powershellgallery.com/packages/SqlServer/
    Write-Host -ForegroundColor White "==============================================================================";
}

# TMSL Script
>>>>>>> Stashed changes
$TmslScript = 
@"
    {  
      "refresh": {  
        "type": "full",  
        "objects": [  
          {  
<<<<<<< Updated upstream
            "database": "Cellar Planning Dataset"  ,  
            "table": "Production Orders"  
=======
            "database": "$DatasetName"  ,  
            "table": "$TableName"
>>>>>>> Stashed changes
          }  
        ]  
      }  
    } 
"@

<<<<<<< Updated upstream
# Helper function that converts a *simple* XML document to a nested hashtable
# with ordered keys.
function ConvertFrom-Xml {
  param([parameter(Mandatory, ValueFromPipeline)] [System.Xml.XmlNode] $node)
  process {
    if ($node.DocumentElement) { $node = $node.DocumentElement }
    $oht = [ordered] @{}
    $name = $node.Name
    if ($node.FirstChild -is [system.xml.xmltext]) {
      $oht.$name = $node.FirstChild.InnerText
    } else {
      $oht.$name = New-Object System.Collections.ArrayList 
      foreach ($child in $node.ChildNodes) {
        $null = $oht.$name.Add((ConvertFrom-Xml $child))
      }
    }
    $oht
  }
}


# Execute TMSL Script Example With DAX
$SampleDax = Invoke-ASCmd -Query "EVALUATE(VALUES(Brand[Brand Desc]))" -Server $XmlaEndpoint -Database $DatasetName
[xml[]] $SampleDax | ConvertFrom-Xml | ConvertTo-Json -Depth 10

# Test Queries (All 3 below work)
Invoke-ASCmd -Query $TmslScript -Server: $XmlaEndpoint -Database $DatasetName
#Invoke-ASCmd -InputFile "C:\temp\testscript.xmla" -Server "powerbi://api.powerbi.com/v1.0/myorg/DSC-DDT-DP Light" 
#Invoke-ProcessTable -TableName "Brand" -Database $DatasetName -Server $XmlaEndpoint -RefreshType Full

# Samples
# Invoke-ASCmd -Server $XmlaEndpoint -Database $DatasetName -Query "SELECT ID, NAME FROM [TMSCHEMA_TABLES].CONTENT"
# Invoke-ASCmd -Database:"Adventure Works DW 2008R2" -Query "SELECT MODEL_CATALOG, MODEL_NAME, ATTRIBUTE_NAME, NODE_NAME FROM [Forecasting].CONTENT"
=======
# Execute refresh trigger on specified table
Try {
    Invoke-ASCmd -Query $TmslScript -Server: $XmlaEndpoint -Database $DatasetName
    # Write message if succeeded
    Write-Host "Table" $TableName "in dataset" $DatasetName "successfully triggered to refresh" -ForegroundColor Green
}
Catch{
    # Write message if error
    Write-Host "An error occured" -ForegroundColor Red
}
>>>>>>> Stashed changes
