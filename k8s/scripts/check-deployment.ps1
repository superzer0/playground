function Get-DeploymentStrategies {

    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $matchExpressions
    )

    $deployments = (kubectl get deployments --all-namespaces --output=json | ConvertFrom-Json)
    
    $arr = @()
    $deployments.items | ForEach-Object {
        $deployment = $_
        $isMatch = $false
        $matchExpressions | Where-Object { $deployment.metadata.name -like $_ } | ForEach-Object { $isMatch = $true }
        if ($isMatch) {
            $arr += "$($deployment.spec.strategy.type) $($deployment.metadata.namespace) $($deployment.metadata.name) "
        }
    }
    $arr | Sort-Object | ForEach-Object {
        Write-Host $_
    }

}

Get-DeploymentStrategies -matchExpressions @("*nats", "*mssql")

