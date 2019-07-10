<#
    .SYNOPSIS
        Recieve all secrets from a specific Azure Key Vault.
    .DESCRIPTION
        Recieve all secrets from a specific Azure Key Vault.
    .PARAMETER vaultName
        Specifies the name of the Azure Key Vault you wnat to recieve secrets from.
        Mandatory
    .EXAMPLE
        Invoke-RestMethod -Method Get -Uri 'https://<functionName>.azurewebsites.net/api/GetVaultSecrets?vaultName=[vaultName]code=[token]'
#>

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

[System.Collections.ArrayList]$arr = @()
if ($status -eq 200) {
    foreach ($secret in $($response.Value)) {
        $name = $secret.id -replace "https://$vaultName.vault.azure.net/secrets/"

        Add-Member -MemberType NoteProperty -Name 'Name' -Value $name -InputObject $secret
        $arr.Add($secret) | Out-Null
    }
}

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body       = (Convertto-json -inputObject $arr -depth 10 -compress)
    })
