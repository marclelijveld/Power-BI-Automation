# Install Module (Admin permissions might be required)
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
$TmslScript = 
@"
    {  
      "refresh": {  
        "type": "full",  
        "objects": [  
          {  
            "database": "Cellar Planning Dataset"  ,  
            "table": "Production Orders"  
          }  
        ]  
      }  
    } 
"@

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