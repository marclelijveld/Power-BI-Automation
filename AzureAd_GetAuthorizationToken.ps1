# Connect to account using OAuth
Connect-AzAccount

# Define audience
<#
Audience or resource should exactly match to one of below options (including forward slash) 
Please specify in audience variable. 

'https://analysis.windows.net/powerbi/api'. 
'https://service.powerapps.com/'
'https://management.core.windows.net/'
'https://management.azure.com/'
'https://service.flow.microsoft.com/'
'https://web.powerapps.com'
'https://apps.powerapps.com'
'https://api.bap.microsoft.com/'."
#>

$audience = "https://service.powerapps.com/"

# Define call
$token = (Get-AzAccessToken -ResourceUrl $audience).Token
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization","Bearer $token")

$url = $audience + "tenants?api-version=2020-01-01"

# Send the request
$resultset = Invoke-RestMethod $url -Method 'Get' -Headers $headers
$resultset.value

# Print token to file
$token | Out-File -FilePath "C:\Users\MarcL\OneDrive - Macaw\Bureaublad\token.txt"
