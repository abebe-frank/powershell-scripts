# Author: @seanvoda
# Company: @GobiIt
# Description: Checks if a resource can be moved to another resource group, subscription, or region.
# Version: 1.1.0
# Date: 2023-05-04


$SourceSubscriptionId = "subscription-id"
$OutputFile = "c:\temp\Test-AzResourceMove.csv"

$nonMovableResourcesJsonPath = ".\NonMovableResources.json"
$nonMovableResourceData = (Get-Content $nonMovableResourcesJsonPath | ConvertFrom-Json).ResourceTypes

Connect-AzAccount

Set-AzContext -SubscriptionId $SourceSubscriptionId

$resourceGroups = Get-AzResourceGroup

$results = @()

foreach ($resourceGroup in $resourceGroups) {
    Write-Host "Checking resource group: $($resourceGroup.ResourceGroupName)"

    $resources = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName

    foreach ($resource in $resources) {
        $resourceData = $nonMovableResourceData | Where-Object { $resource.ResourceType -eq $_.ResourceType } | Select-Object -First 1

        $result = New-Object -TypeName PSObject -Property @{
            ResourceId          = $resource.ResourceId
            ResourceType        = $resource.ResourceType
            ResourceGroupName   = $resourceGroup.ResourceGroupName
            ResourceGroupMove   = [string]"Yes"
            SubscriptionMove    = [string]"Yes"
            RegionMove          = [string]"Yes"
        }

        if ($resourceData) {
            $result.ResourceGroupMove = [string]$resourceData.ResourceGroup
            $result.SubscriptionMove = [string]$resourceData.Subscription
            $result.RegionMove = [string]$resourceData.Region
        }

        try {
            Move-AzResource -DestinationResourceGroupName $resourceGroup.ResourceGroupName -DestinationSubscriptionId $targetSubscriptionId -ResourceId $resource.ResourceId -WhatIf -ErrorAction Stop
            Write-Host "Resource $($resource.ResourceId) can be moved"
        }
        catch {
            Write-Host "Resource $($resource.ResourceId) cannot be moved" -ForegroundColor Red
        }

        $results += $result
    }
}

Write-Host "Saving results to $OutputFile"
$results | Select-Object ResourceId, ResourceType, ResourceGroupName, ResourceGroupMove, SubscriptionMove, RegionMove | Export-Csv -Path $OutputFile -NoTypeInformation
