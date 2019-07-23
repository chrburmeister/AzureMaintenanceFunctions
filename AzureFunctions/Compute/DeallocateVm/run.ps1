<#
    .SYNOPSIS
        Deallocates a virtual machine.
    .DESCRIPTION
        Deallocates a virtual machine.
    .PARAMETER subscriptionId
        Specifies the Id of the Azure Subsciption the VM is located in.
        Mandatory
    .PARAMETER resourceGroup
        Specifies the Resource Group of the Azure Subsciption the VM is located in.
        Mandatory
    .PARAMETER vmName
        Specifies the name of the vm to deallocate.
        Mandatory
    .EXAMPLE
        Invoke-RestMethod -Method Get -Uri 'https://<functionName>.azurewebsites.net/api/DeallocateVm?subscriptionId=[subscriptionId]&resourceGroup=[resourceGroup]&vmName=[vmName]&code=[token]'
#>

using namespace System.Net

param($Request, $TriggerMetadata)

$apiVersion = '2017-09-01'
$resourceURI = 'https://management.azure.com/'
$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=$resourceURI&api-version=$apiVersion"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret" = "$env:MSI_SECRET" } -Uri $tokenAuthURI
$authHeader = @{Authorization = "Bearer $($tokenResponse.access_token)" }

$param = @{
    'Uri'         = "https://management.azure.com/subscriptions/$($Request.Query.subscriptionId)/resourceGroups/$($Request.Query.resourceGroup)/providers/Microsoft.Compute/virtualMachines/$($Request.Query.vmName)/Deallocate?api-version=2018-06-01"
    'Method'      = 'Post'
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
