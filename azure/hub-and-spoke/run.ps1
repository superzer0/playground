
# create what-if
. "$PSScriptRoot/settings.private.ps1"

function DeployFwPolicies {
  az account set --subscription $subId
  az deployment group create -f $PSScriptRoot/fw-policies.bicep `
      -g $rgName `
      --mode Incremental `
      --verbose `
      --name "$workloadName-fw-policies" `
      --parameters `
        workloadName=$workloadName
}

function DeployHub {
  az account set --subscription $subId
  az deployment group create -f $PSScriptRoot/hub.bicep `
      -g $rgName `
      --mode Incremental `
      --verbose `
      --name "$workloadName-hub" `
      --parameters `
        workloadName=$workloadName `
        azureTenantId=$tenant
}

function DeploySpokes {
  az account set --subscription $subId
  az deployment group create -f $PSScriptRoot/spokes.bicep `
      -g $rgName `
      --mode Incremental `
      --verbose `
      --name "$workloadName-spokes" `
      --parameters `
        workloadName=$workloadName
}

function DeployAll {
  DeployFwPolicies
  DeployHub
  DeploySpokes
}
