
# Connect to Power BI service Account
Write-Host -ForegroundColor White "Connect to PowerBI service"
Connect-PowerBIServiceAccount #Connect with service account

# Get list of Premium capacity assigned workspaces as admin
$top = 100 # TODO: adjust number based on your needs
$skip = 0
$iterations = 0
$filter = "isOnDedicatedCapacity eq true"
$url = "admin/groups?`$top={0}&`$skip={1}&`$filter={2}" -f ($top), ($skip + $top * $iterations), $filter
$WsOnPremium = Invoke-PowerBIRestMethod -Url $url -Method GET -Verbose | ConvertFrom-Json

# Return number of premium workspaces
$WsOnPremium.value.count 

<#
Example based on this blog post: 
https://powerbi.microsoft.com/en-us/blog/best-practices-to-prevent-getgroupsasadmin-api-timeout/
#>