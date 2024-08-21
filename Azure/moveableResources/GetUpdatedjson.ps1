# Author: @FrankAbebe
# Description: Fetches the list of non-movable resources from the Azure docs and saves them to a JSON file
# Output: NonMovableResources.json
# Notes: This script is provided as a convenience for updating the list of non-movable resources.
# Dependencies: None (uses Invoke-WebRequest and built-in string functions)
# Date: 2024-08-21
# Version: 1.1.0

$url = 'https://raw.githubusercontent.com/MicrosoftDocs/azure-docs/main/articles/azure-resource-manager/management/move-support-resources.md'
$response = Invoke-WebRequest -Uri $url

$nonMovableResourceTypes = @()

$servicePattern = '^##\s+(.*?)$'
$serviceMatches = [regex]::Matches($response.Content, $servicePattern, 'IgnoreCase, Multiline')

$rowPattern = '\|\s*(.*?)\s*\|(.*?)\s*\|(.*?)\s*\|(.*?)\s*\|'
$rowMatches = [regex]::Matches($response.Content, $rowPattern, 'IgnoreCase, Multiline')

$serviceIndex = 0

foreach ($rowMatch in $rowMatches) {
    $rowPos = $rowMatch.Index

    while ($serviceIndex -lt $serviceMatches.Count - 1 -and $rowPos -gt $serviceMatches[$serviceIndex + 1].Index) {
        $serviceIndex++
    }

    $fullResourceType = "$($serviceMatches[$serviceIndex].Groups[1].Value)/$($rowMatch.Groups[1].Value)"
    $fullResourceType = $fullResourceType -replace '>', '/' -replace '\|', '' -replace '\s', '' -replace '//', '/'

    $resourceGroupMove = if ($rowMatch.Groups[2].Value -like '*Yes*') { 'Yes' } else { 'No' }
    $subscriptionMove = if ($rowMatch.Groups[3].Value -like '*Yes*') { 'Yes' } else { 'No' }
    $regionMove = if ($rowMatch.Groups[4].Value -like '*Yes*') { 'Yes' } else { 'No' }

    $nonMovableResourceTypes += [PSCustomObject]@{
        ResourceType   = $fullResourceType.Trim()
        ResourceGroup  = $resourceGroupMove
        Subscription   = $subscriptionMove
        Region         = $regionMove
    }
}

$nonMovableResourceTypes | ConvertTo-Json | Out-File -FilePath "NonMovableResources.json"
