# Sign in with Fabric / Power BI Admin account
Connect-PowerBIServiceAccount

# List deployment pipelines + stages
$AllPipelines = Invoke-PowerBIRestMethod -Method GET -Url "https://api.powerbi.com/v1.0/myorg/admin/pipelines?$expand=stages"
$pipelines = $AllPipelines | ConvertFrom-Json

# Filter list on specific keyword
$pipelines.value | where {$_ -match 'cash'} #replace the filter value if you're looking for a pipeline with a certain name

# Investigate current users of a certain pipeline
$PipelineId = "{id}" #Fill in the pipeline id from the response of above API
Invoke-PowerBIRestMethod -Method GET -Url "https://api.powerbi.com/v1.0/myorg/admin/pipelines/$PipelineId/users"

# Update users of a certain pipeline
$UPN = "{UPN}" #Fill in the user principal name of the user you want to add to the pipeline

$body = @"
{
  "identifier": "$UPN",
  "accessRight": "Admin",
  "principalType": "User"
}
"@

Invoke-PowerBIRestMethod -Method POST -Body $body -Url "https://api.powerbi.com/v1.0/myorg/admin/pipelines/$PipelineId/users"