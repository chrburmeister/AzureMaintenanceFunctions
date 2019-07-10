<#
    .SYNOPSIS
        Recieve all secret verions from a specific Azure Key Vault secret.
    .DESCRIPTION
        Recieve all secret verions from a specific Azure Key Vault secret.
    .PARAMETER vaultName
        Specifies the name of the Azure Key Vault you wnat to recieve secret versions from.
        Mandatory
    .PARAMETER secretName
        Specifies the name of the Azure Key Vault secret you wnat to recieve all versions from.
        Mandatory
    .EXAMPLE
        Invoke-RestMethod -Method Get -Uri 'https://<functionName>.azurewebsites.net/api/GetVaultSecrets?vaultName=[vaultName]&secretName=[secretName]&code=[token]'
#>

using namespace System.Net

param($Request, $TriggerMetadata)

$vaultName = $Request.Query.vaultName
$secretName = $Request.Query.secretName

# Acquire Access Token
$apiVersion = '2017-09-01'
$resourceURI = 'https://vault.azure.net'
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=$apiVersion"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret" = "$env:MSI_SECRET" } -Uri $tokenAuthURI
$authHeader = @{Authorization = "Bearer $($tokenResponse.access_token)" }

$param = @{
    'Uri'         = "https://$vaultName.vault.azure.net/secrets/$secretName/versions?api-version=7.0"
    'Method'      = 'Get'
    'Header'      = $authHeader
    'ErrorAction' = 'Stop'
    'ContentType' = 'application/josn'
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
