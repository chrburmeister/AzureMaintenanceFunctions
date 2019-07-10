<#
    .SYNOPSIS
        Recieve a specific secret from a specified Azure Key Vault.
    .DESCRIPTION
        Recieve a specific secret from a specified Azure Key Vault.
    .PARAMETER vaultName
        Specifies the name of the Azure Key Vault you wnat to recieve secrets from.
        Mandatory
    .PARAMETER secretName
        Specifies the name of the Azure Key Vault secret you wnat to recieve.
        Mandatory
    .PARAMETER secretVersion
        Specifies the version of the Azure Key Vault secret you wnat to recieve.
        If you don't add this, the current version will be recieved.
        Optional
    .EXAMPLE
        Invoke-RestMethod -Method Get -Uri 'https://<functionName>.azurewebsites.net/api/GetVaultSecrets?vaultName=[vaultName]&secretName=[secretName]&code=[token]'
    .EXAMPLE
        Invoke-RestMethod -Method Get -Uri 'https://<functionName>.azurewebsites.net/api/GetVaultSecrets?vaultName=[vaultName]&secretName=[secretName]&secretVersion=[secretVersion]&code=[token]'
#>

using namespace System.Net

param($Request, $TriggerMetadata)

$vaultName = $Request.Query.vaultName
$secretName = $Request.Query.secretName
$secretVersion = $Request.Query.secretVersion


# Acquire Access Token
$apiVersion = '2017-09-01'
$resourceURI = 'https://vault.azure.net'
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=$apiVersion"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{ "Secret" = "$env:MSI_SECRET" } -Uri $tokenAuthURI
$authHeader = @{Authorization = "Bearer $($tokenResponse.access_token)" }

if ($secretVersion) {
    $uri = "https://$vaultName.vault.azure.net/secrets/$secretName/$($secretVersion)?api-version=7.0"
} else {
    $uri = "https://$vaultName.vault.azure.net/secrets/$($secretName)?api-version=7.0"
}

$param = @{
    'Uri'         = $uri
    'Method'      = 'Get'
    'Header'      = $authHeader
    'ErrorAction' = 'Stop'
    'ContentType' = 'application/json'
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
        Body       = (Convertto-json -inputObject $($response.value) -depth 10 -compress)
    })
