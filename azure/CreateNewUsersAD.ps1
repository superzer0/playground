$ADdomain = ''
function CreateNewUser {
  param(
    [string] $userName
  )

  $userPrincipalName = "$userName@$ADdomain"
  $pass = openssl rand -base64 32
  $secureStringPass = ConvertTo-SecureString -String $pass -AsPlainText -Force
  $user = New-AzureADUser -AccountEnabled $true `
    -DisplayName $userName -ForceChangePasswordNextLogin $false -Password $secureStringPass `
    -UserPrincipalName $userPrincipalName `
    -MailNickname $userName

  Set-AzADUser -ObjectId $userPrincipalName -Mail $userPrincipalName

  return [pscustomobject]@{
    "userPrincipalName" = $userPrincipalName
    "password" = $pass
  }
}

function WriteUsersToCsvFile {
  param(
    [string] $fileName,
    [array] $users
  )

  $users | ConvertTo-Csv -NoTypeInformation | Out-File $fileName
}

function CreateUsersBulk {
  param(
    [string] $userNamePrefix,
    [int] $count
  )

  $users = @()
  for ($i = 0; $i -lt $count; $i++) {
    $users += CreateNewUser -userName "$userNamePrefix-$i"
  }

  WriteUsersToCsvFile -fileName "users.csv" -users $users
  Write-Host "Users created: $count. Passwords written to users.csv"
}


# Import-Module -Name AzureAd
# Connect-AzAccount -TenantId $ADdomain
# CreateUsersBulk -userNamePrefix perf-user -count 1     
