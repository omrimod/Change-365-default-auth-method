[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

 
$configPath = "path\to\config\json"

$config = Get-Content $configPath | ConvertFrom-Json

$tenent_id = $config.tenent_id
$client_id = $config.client_id
$client_secret = $config.client_secret
$doNotTouchUsers = $config.doNotTouchUsers
$use_proxy = $false

if (($config.proxy.use_proxy -eq $true) -and ($config.proxy.proxy_server -ne $null)) {
    $use_proxy = $true
    $proxy_server = $config.proxy.proxy_server
}

function get-Token(){
    $body = @{
        "client_id" = "$client_id"
        "client_secret" = "$client_secret"
        "scope" = "https://graph.microsoft.com/.default"
        "grant_type" = "client_credentials"
    }
    if ($use_proxy) {
        $response = Invoke-RestMethod "https://login.microsoftonline.com/$tenent_id/oauth2/v2.0/token" -Method 'POST' -Headers $headers -Body $body -Proxy $proxy_server -UseDefaultCredentials
        return $response.access_token
    }
    $response = Invoke-RestMethod "https://login.microsoftonline.com/$tenent_id/oauth2/v2.0/token" -Method 'POST' -Headers $headers -Body $body
    return $response.access_token
}

function get-Report(){
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")
    if ($use_proxy) {
        $response = Invoke-RestMethod 'https://graph.microsoft.com/v1.0/reports/authenticationMethods/userRegistrationDetails' -Method 'GET' -Headers $headers -Proxy $proxy_server -UseDefaultCredentials
        return $response.value | where UserPreferredMethodForSecondaryAuthentication -eq 'push' | where MethodsRegistered -Contains 'mobilePhone' | select UserPrincipalName
    }

    $response = Invoke-RestMethod 'https://graph.microsoft.com/v1.0/reports/authenticationMethods/userRegistrationDetails' -Method 'GET' -Headers $headers
    return $response.value | where UserPreferredMethodForSecondaryAuthentication -eq 'push' | where MethodsRegistered -Contains 'mobilePhone' | select UserPrincipalName
}

 

function set-DefaultMethod($userID){
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")
    $headers.Add("Content-Type", "application/json")
    $body = @"
{
  `"userPreferredMethodForSecondaryAuthentication`": `"sms`"
}
"@
    $url = "https://graph.microsoft.com/beta/users/$userID/authentication/signInPreferences"
    if ($use_proxy) {
        $response = Invoke-WebRequest -Uri $url -Method 'PATCH' -Headers $headers -Body $body -Proxy $proxy_server -UseDefaultCredentials
    }
    else {
        $response = Invoke-WebRequest -Uri $url -Method 'PATCH' -Headers $headers -Body $body
    }
}

$token = get-Token
$report = get-Report
foreach ($line in $report) {
    if ($doNotTouchUsers -contains $line.userPrincipalName) {
        continue
    }
    set-DefaultMethod -userID $line.userPrincipalName
}
