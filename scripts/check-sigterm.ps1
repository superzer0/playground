
function CheckSigTermTiming {

  param(
    [string] $namespace
  )

  [hashtable]$timing = @{}
  $stopwatch = [System.Diagnostics.Stopwatch]::new()
  $pods = (kubectl get pods -n $namespace --output=json | ConvertFrom-Json).items.metadata.name

  $stopwatch.Start()
  foreach ($pod in $pods) {
    
    kubectl delete pod $pod -n $namespace
    $timing.Add($pod, $stopwatch.Elapsed)
    $stopwatch.Restart()
  }

  Write-Host "Time stats. Format HOURS:MINUTES:SECONDS"
  $timing.GetEnumerator() | ForEach-Object {
    Write-Host "$($_.Key) took $($_.Value.ToString('hh\:mm\:ss'))"
  }
}

Write-Host "Checking the delete time for each pod in the namespace."
Write-Host "This is disruptive action that will kill pods one by one"

# CheckSigTermTiming -namespace skylab-test
