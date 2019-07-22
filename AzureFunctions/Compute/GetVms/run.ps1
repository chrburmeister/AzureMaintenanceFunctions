<#
    .SYNOPSIS
        Recieve all virtual machines in a subscription.
    .DESCRIPTION
        Recieve all virtual machines in a subscription.
    .PARAMETER subscriptionId
        Specifies the name of the Azure Key Vault you wnat to recieve secrets from.
        Mandatory
    .EXAMPLE
        Invoke-RestMethod -Method Get -Uri 'https://<functionName>.azurewebsites.net/api/GetVms?subscriptionId=[subscriptionId]&code=[token]'
#>

using namespace System.Net

param($Request, $TriggerMetadata)

$apiVersion = '2017-09-01'
$resourceURI = 'https://management.azure.com/'
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=$apiVersion"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret" = "$env:MSI_SECRET" } -Uri $tokenAuthURI
$authHeader = @{Authorization = "Bearer $($tokenResponse.access_token)" }

$param = @{
    'Uri'         = "https://management.azure.com/subscriptions/$($Request.Query.subscriptionId)/providers/Microsoft.Compute/virtualMachines?api-version=2018-06-01"
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
        Body       = (Convertto-json -inputObject $($response.Value) -depth 10 -compress)
    })
