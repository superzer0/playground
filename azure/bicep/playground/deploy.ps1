
function Deploy-Cli {
  $deploymentName = "Playground" + $(Get-Random -Maximum 1000)
  az deployment group create --resource-group aks-jka-westeurope --template-file "$PSScriptRoot/playground.bicep" `
    --parameters storagePrefix=tempstore --name $deploymentName
}
function DeployPowershell {
  # on local firstly install AZ ps module
  # Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

  $deploymentName = "Playground" + $(Get-Random -Maximum 1000)
  $parameters = @{ storagePrefix = 'tempstore' }
  New-AzresourceGroupDeployment -ResourceGroupName aks-jka-westeurope -TemplateFile "$PSScriptRoot/playground.bicep" `
    -Name $deploymentName -TemplateParameterObject $parameters
}

# DeployPowershell

# https://tempstorencdbttnwx2hak.blob.core.windows.net/test/duze_oczy.jpg
