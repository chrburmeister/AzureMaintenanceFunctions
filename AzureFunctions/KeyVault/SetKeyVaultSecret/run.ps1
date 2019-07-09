<#
    .SYNOPSIS
        Recieve all secret verions from a specific Azure Key Vault
    .DESCRIPTION
        Recieve all secrets from a specific Azure Key Vault
    .PARAMETER vaultName
        Specifies the name of the Azure Key Vault you wnat to recieve secrets from.
        Mandatory
    .PARAMETER secretName
        Specifies the name of the Azure Key Vault secret you wnat to recieve.
        Mandatory
    .PARAMETER secretValue
        Specifies the version of the Azure Key Vault secret you wnat to recieve.
        If you don't add this, the current version will be recieved.
        Optional
    .EXAMPLE
        $param = @{
            "secretValue" = "secretValue",
            "vaultName"   = "vaultName",
            "secretName"  = "secretName"
        }

        Invoke-RestMethod -Method Get -Uri 'https://<functionName>.azurewebsites.net/api/GetVaultSecrets?code=[token]' -Body (ConvertTo-Json -InputObject $param)
#>

using namespace System.Net

param($Request, $TriggerMetadata)

$vaultName = $Request.Body.vaultName
$secretName = $Request.Body.secretName
$secretValue = $Request.Body.secretValue

# Acquire Access Token
$apiVersion = '2017-09-01'
$resourceURI = 'https://vault.azure.net'
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=$apiVersion"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{ "Secret" = "$env:MSI_SECRET" } -Uri $tokenAuthURI
$authHeader = @{Authorization = "Bearer $($tokenResponse.access_token)" }

$param = @{
    'Uri'             = "https://$vaultName.vault.azure.net/secrets/$($secretName)?api-version=7.0"
    'Method'          = 'PUT'
    'Header'          = $authHeader
    'ErrorAction'     = 'Stop'
    'Body'            = ConvertTo-Json -InputObject (@{"value" = $secretValue })
    'ContentType'     = 'application/json'
    'UseBasicParsing' = $true
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
