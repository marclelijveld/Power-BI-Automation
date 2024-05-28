# Fabric notebook source

# METADATA ********************

# META {
# META   "dependencies": {
# META     "environment": {
# META       "environmentId": "036b9baa-ddb4-433e-9fdb-364a9ba3cb70",
# META       "workspaceId": "a63d0986-6351-414f-8807-7b2a2d53a487"
# META     }
# META   }
# META }

# MARKDOWN ********************

# # Refresh specific partitions in Semantic Model
# This notebook makes use of Fabric Semantic-Link (sempy) to query semantic model meta data, followed by finding the partitions belonging to the current year (dynamically). Once the partitions are identified, these will be refreshed bypassing potential incremental refresh policies. Therefore, this notebook will help to run full refreshes of models or selected partitions, ignoring policies to update data changes in historical partitions for example. 
# 
# Throughout this notebook, the term dataset is still used intentionally, given parameters in Semantic Link module still use this


# CELL ********************

# Set the bases
workspace_name = "Semantic Link for Power BI folks" # Fill in your workspace name here.
dataset_name = "IncrementalRefreshPartitioning" # Fill in your semantic model name here. 

# CELL ********************

# import libraries
import sempy.fabric as fabric
import pandas as pd
import datetime
import json

# MARKDOWN ********************

# #### Read meta data
# Below section reads semantic model meta data using the [evaluate_dax](https://learn.microsoft.com/en-us/python/api/semantic-link-sempy/sempy.fabric?view=semantic-link-python#sempy-fabric-evaluate-dax) function in Semantic Link. Based on this function, Dynamic Management Views can be queries, such as Tables and Partitions. 

# CELL ********************

## Get tables through DMV
dftablesraw = (fabric
    .evaluate_dax(
        dataset = dataset_name,
        dax_string=
        """
        select * from $SYSTEM.TMSCHEMA_TABLES
        """  
       )  
)
dftablesraw.rename(columns={"Name": "TableName"}, inplace=True)
dftables = dftablesraw[["ID", "TableName", "Description"]]

dftables.head(20)

# CELL ********************

## Get tables partitions through DMV
dfpartitionsraw = (fabric
    .evaluate_dax(
        dataset = dataset_name,
        dax_string=
        """
        select * from $SYSTEM.TMSCHEMA_PARTITIONS
        """  
       )  
)
dfpartitionsraw.rename(columns={"Name": "PartitionName"}, inplace=True)
dfpartitions = dfpartitionsraw[["TableID", "PartitionName", "RangeStart", "RangeEnd"]]
dfpartitions.head(20)

# CELL ********************

# Join table and partition dataframes based on TableID
dfoverview = pd.merge(dftables, dfpartitions, left_on='ID', right_on='TableID', how='inner')
dfoverview.head(20)

# CELL ********************

# Get the current year as a string
current_year = str(datetime.datetime.now().year)

# Add the new column based on whether the first 4 characters of 'PartitionName' match the current year
dfoverview['PartitionCY'] = dfoverview['PartitionName'].str[:4] == current_year

#print(dfoverview)
dfoverview.head(20)

# CELL ********************

# Define relevant columns for json message
dfrelevant = dfoverview[["TableName", "PartitionName"]].copy()

# Define the condition
condition = dfoverview['PartitionCY'] == True

# Use .loc to apply the condition and modify the DataFrame
filtered_df = dfrelevant.loc[condition].copy()

# Define columns to rename
columns_to_rename = {
    "TableName": "table",
    "PartitionName": "partition"
}

# Rename columns
filtered_df.rename(columns=columns_to_rename, inplace=True)

# Convert the modified DataFrame to a list of dictionaries
filtered_dicts = filtered_df.to_dict(orient='records')

# Convert the list of dictionaries to a JSON string
json_string = json.dumps(filtered_dicts, indent=4)

# Print the JSON string properly formatted
print(json_string)

# MARKDOWN ********************

# #### Refresh semantic model
# Below section refreshes the semantic model. Additional properties can be found via [this documentation](https://learn.microsoft.com/en-us/python/api/semantic-link-sempy/sempy.fabric?view=semantic-link-python#sempy-fabric-refresh-dataset). 

# CELL ********************

# Refresh the dataset
fabric.refresh_dataset(
    workspace=workspace_name,
    dataset=dataset_name, 
    objects=json.loads(json_string), # Since the function requests a dictionairy, converted it from string to dictionairy
    refresh_type = "full",
    apply_refresh_policy = False
)

# CELL ********************

# List the refresh requests
dflistrefreshrequests = fabric.list_refresh_requests(dataset=dataset_name, workspace=workspace_name)

# show last 5 requests
dflistrefreshrequests.head(5) 

# CELL ********************

# Get details about the refresh
fabric.get_refresh_execution_details(
    dataset=dataset_name, 
    workspace=workspace_name, 
    refresh_request_id = dflistrefreshrequests.iloc[0]["Request Id"] # Filters the latest request ID based on the refresh requests
    )
