#Sign in with Power BI Admin Account of SPN with TenantRead.All permissions
Connect-PowerBIServiceAccount

#Get Workspace info for top 1500 workspaces (if more, adjust call and include skip parameter)
#This call only looks at WS users, datasets and reports. 
$GetWorkspaceInfo = Invoke-PowerBIRestMethod -Method GET -Url "https://api.powerbi.com/v1.0/myorg/admin/groups?%24top=1500&%24expand=users%2Cdatasets%2Creports" 

#Save the WS info to json file on desktop. Please adjust output location accordingly. 
$GetWorkspaceInfo | Out-File "C:\Users\MarcL\OneDrive - Macaw\Bureaublad\WsDump.json"

