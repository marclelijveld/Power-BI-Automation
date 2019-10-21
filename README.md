# Power-BI-Automation
Automate tasks in Power BI based on the Power BI Powershell cmdlets and the Power BI REST API

In order to make this work for you, replace the values provided as variables in: 
$SourceWorkspaceName = "DP_DEMO_dev" 
$DestinationWorkspaceName = "DP_DEMO_acc" 
$DataflowName = "DemoEntity"

Script to move dataflows across Power BI workspaces. 
Please know that: 
- The workspace name will be used to lookup the workspace id (for both source and destination workspace).
- The dataflow name will be used to lookup the dataflow id.
- If the dataflow already exists, it will be replaced. 

The tasks applied in this Powershells script are described in detail on https://data-marc.com/2019/10/22/move-dataflows-across-workspaces-with-the-power-bi-rest-api
