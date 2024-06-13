#Connect-account
Connect-AzAccount
# Define the output file path
$outputFile = ""
 
# Initialize an array to store the data
$data = @()
 
# Retrieve all Azure subscriptions
Get-AzSubscription | ForEach-Object {
    $subscriptionName = $_.Name
    Set-AzContext -SubscriptionId $_.SubscriptionId
 
    # Retrieve all resource groups for the current subscription
    (Get-AzResourceGroup).ResourceGroupName | ForEach-Object {
        $data += [PSCustomObject] @{
            Subscription   = $subscriptionName
            ResourceGroup = $_
        }
    }
}
 
# Export the collected data to a CSV file
$data | Export-Csv -Path $outputFile -NoTypeInformation
