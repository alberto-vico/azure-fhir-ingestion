# Federal Health Vertical Ecosystem

## Introduction
One of the most challenging aspects of communicating the value of the Microsoft platform is telling an end-to-end story. While extensibility is one of our greatest assets, it is also one of our greatest challenges. For federal healthcare organizations this is a even more challenging endeavor as they are often bombarded with vendor presentations that claim to ingest, harmonize (standardize, normalize), analyze, and inject insight back into workflows.

In this demonstration, we would like to show the ingestion of multiple disparate data sets, the harmonization of those data sets in our Azure Health Data Services product line, and finally the analysis of said data to produce meaningful and actionable results that are presented in meaningful workflows. These workflows (use cases) will all follow a similar pattern (ingestion, harmonization, analysis) however, be presented in unique and meaningful ways.

## Architecture Overview
TODO

## Deployment

### 01 - Deploy components
Edit file `template_deploy.ps1` and use your own prefix for deployed components:

```
$prefix = '<your_prefix>'
$suffix = Get-Date -Format "yyyyMMddHHmmss"
$resourceGroupName = $prefix + 'rg'
$deploymentName = $prefix + "deploy" + "$suffix"

New-AzResourceGroup -Name $resourceGroupName -Location westeurope -Force

New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile '.\template.bicep' `
    -deploymentPrefix $prefix `
    -Confirm
```

Save your changes and execute the script:
```console
cd <your_local_repo_path>
.\template_deploy.ps1
```

You will get prompted with the changes and will be asked for confirmation. Type `Y` and press `Enter`.

Deployment will then start. It will take around 20 minutes to complete. You can check the state of the deployment by navigating to the new resource group:
![alt](media/az_check_deployments.jpg) 

### 02 - Permissions to access FHIR service
FHIR Data Contributor
![alt](media/az_add_role_fhir.jpg) 
TODO
