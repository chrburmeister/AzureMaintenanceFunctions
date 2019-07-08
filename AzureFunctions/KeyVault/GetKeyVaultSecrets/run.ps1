using namespace System.Net

param($Request, $TriggerMetadata)

$vaultName = $Request.Query.vaultName

# Acquire Access Token
$apiVersion = '2017-09-01'
$resourceURI = 'https://vault.azure.net'
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=$apiVersion"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret" = "$env:MSI_SECRET" } -Uri $tokenAuthURI
$authHeader = @{Authorization = "Bearer $($tokenResponse.access_token)" }

$param = @{
    'Uri'         = "https://$vaultName.vault.azure.net/secrets?api-version=7.0"
    'Method'      = 'Get'
    'Header'      = $authHeader
    'ErrorAction' = 'Stop'
}

try {
    $response = Invoke-RestMethod @param
    $status = 200
} catch {
    $status = 500
    $response = @{
        'value' = $_.Exception.Message
    }
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body       = (Convertto-json -inputObject $($response.Value) -depth 10 -compress)
    })
