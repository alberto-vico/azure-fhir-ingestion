#Connect-AzAccount

$prefix = "gnodev"
$suffix = Get-Date -Format "yyyyMMddHHmmss"
$resourceGroupName = $prefix + "rg"
$deploymentName = $resourceGroupName + $suffix

Get-AzResourceGroup -Name $resourceGroupName -Location westeurope
if($notPresent)
{
    New-AzResourceGroup -Name $resourceGroupName -Location westeurope
}

New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile ".\template.bicep" `
    -deploymentPrefix $prefix `
    -Confirm

