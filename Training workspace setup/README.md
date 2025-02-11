# Fabric workspace tools
This folder contains scripts to help you setup training workspaces for either Power BI or Fabric training. 
These scripts will help trainers to setup their environment for a training where each attendee requires a dedicated workspace for exercises. The second script will help to clean up the environment and delete all that was created. 

## Fabric_GenerateUserWorkspaces.ps1
This script is intended to generate workspaces in bulk to prepare empty workspaces for a training, event precon or postcon. 

It is entirely based on a generic setup, in which user accounts have already been created with the the following setup: 'user{number}@domain.com'. In the setup of the script, you can define the number of users for which you want to generate a workspace. The script will itterate over this number to execute the following steps: 
- Create a workspace with the name '{prefix} - user {number}' 
- Assign the created workspace to a capacity. Capacity Id specified in variable will be used
- Add user 'user{number}@domain.com to newly created workspace with Member permissions (permissions can be updated if desired)

### Note:
The user executing the script...
- ...must have workspace creator permissions
- ...must have capacity assignment permissions
- ...will also be administrator on each of the workspaces


## Fabric_DeleteUserWorkspaces.ps1
After the training, you want to clean up your environment again. This script helps to bulk delete all workspaces created by the other script. Specify the variable to define the {prefix} or a certain text to look for in the workspace names. The user executing the script must be administrator on each of these workspaces. 

### Note: 
The user executing the script...
- ...must have administrator permissions on the workspaces to be deleted