<# 
This script helps you to get insights in the current parameter values for a Power BI dataset.
If you are not the owner of the dataset, you will not be able to see the parameter values in the Power BI Service. 
Use this code snippet instead to get insights!  

More details about this script and the use case behind it, please read this blog post: 
https://data-marc.com/2021/10/13/insights-in-power-bi-dataset-parameters-and-refresh-schedule/
#>

# =================================================================================================================================================
# General parameters
# =================================================================================================================================================
# Specify Power BI parameters for workspace and dataset where the current dataset is stored
$WorkspaceID = ""
$DatasetID = ""

# =================================================================================================================================================
# Task execution
# =================================================================================================================================================

# Connect to Power BI Service using OAuth
Connect-PowerBIServiceAccount

# Get parameter values
$GetParameterValues = Invoke-PowerBIRestMethod -Method GET -Url "groups/$WorkspaceID/datasets/$DatasetID/parameters" | ConvertFrom-Json

# Display parameter values and settings on screen
$GetParameterValues.Value