# Preserve Exchange Online Before Unassigning a Microsoft 365 License

## Purpose

Use this procedure when replacing or removing a user's current Microsoft 365 license while protecting mailbox continuity.

> **Important:** Leaving only Exchange Online enabled under the old license is a temporary preparation step. If the old license is ultimately removed, the user must already have another license that includes Exchange Online. Otherwise, the mailbox becomes unlicensed and may enter the Exchange Online delicensing grace period.

## Prerequisites

- Microsoft 365 **License Administrator**, **User Administrator**, or **Global Administrator** role.
- Microsoft Graph PowerShell SDK installed.
- The user's sign-in name, for example `user@contoso.com`.
- The SKU part number of the current license and, if applicable, the replacement license.
- Confirm whether the license is assigned directly or inherited from a Microsoft Entra group. Group-based assignments must be changed on the group.

---

## Option 1: Microsoft 365 Admin Center

1. Sign in to the Microsoft 365 admin center.
2. Open **Users** > **Active users**.
3. Select the affected user.
4. Open **Licenses and apps**.
5. Under **Licenses**, keep the existing product selected temporarily.
6. Expand **Apps**.
7. Clear all apps except the required **Exchange Online** plan, such as **Exchange Online (Plan 1)** or **Exchange Online (Plan 2)**.
8. Select **Save changes**.
9. Assign the replacement license and confirm that its Exchange Online app is enabled.
10. After the replacement license is successfully assigned, clear the old product license and select **Save changes**.

> **Do not remove the old license before assigning the replacement Exchange Online entitlement.**

---

## Option 2: Microsoft Graph PowerShell

### 1. Connect to Microsoft Graph

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All","Organization.Read.All"
```

Confirm the connection:

```powershell
Get-MgContext
```

### 2. Set the user and review available SKUs

```powershell
$userUPN = "user@contoso.com"

Get-MgSubscribedSku -All |
    Select-Object SkuPartNumber, SkuId, ConsumedUnits
```

Review the user's current licenses and service plans:

```powershell
Get-MgUserLicenseDetail -UserId $userUPN |
    Select-Object SkuPartNumber, SkuId, ServicePlans
```

To display the service plans more clearly:

```powershell
Get-MgUserLicenseDetail -UserId $userUPN |
    ForEach-Object {
        $sku = $_
        $sku.ServicePlans | Select-Object `
            @{Name='SkuPartNumber';Expression={$sku.SkuPartNumber}}, `
            ServicePlanName, ServicePlanId, ProvisioningStatus
    } |
    Format-Table -AutoSize
```

### 3. Keep only Exchange Online enabled under the old license

Replace `OLD_SKU_PART_NUMBER` with the actual SKU, such as `ENTERPRISEPACK`, `SPE_E3`, or the value displayed in your tenant.

```powershell
$oldSkuPartNumber = "OLD_SKU_PART_NUMBER"
$oldSku = Get-MgSubscribedSku -All |
    Where-Object SkuPartNumber -eq $oldSkuPartNumber

if (-not $oldSku) {
    throw "SKU '$oldSkuPartNumber' was not found in this tenant."
}

# Identify Exchange Online service plans dynamically.
$exchangePlans = @(
    $oldSku.ServicePlans |
        Where-Object ServicePlanName -like "EXCHANGE_S_*"
)

if ($exchangePlans.Count -eq 0) {
    throw "No Exchange Online service plan was found in SKU '$oldSkuPartNumber'."
}

# Disable every service plan except Exchange Online.
$disabledPlans = @(
    $oldSku.ServicePlans |
        Where-Object ServicePlanId -notin $exchangePlans.ServicePlanId |
        Select-Object -ExpandProperty ServicePlanId
)

$licenseUpdate = @(
    @{
        SkuId         = $oldSku.SkuId
        DisabledPlans = $disabledPlans
    }
)

Set-MgUserLicense `
    -UserId $userUPN `
    -AddLicenses $licenseUpdate `
    -RemoveLicenses @()
```

### 4. Verify that only Exchange Online remains enabled

```powershell
Get-MgUserLicenseDetail -UserId $userUPN |
    Where-Object SkuId -eq $oldSku.SkuId |
    ForEach-Object {
        $_.ServicePlans |
            Select-Object ServicePlanName, ProvisioningStatus
    } |
    Sort-Object ProvisioningStatus, ServicePlanName |
    Format-Table -AutoSize
```

Check that the required `EXCHANGE_S_*` plan shows `Success` and the other apps show `Disabled`.

### 5. Assign the replacement license before removing the old license

Replace `NEW_SKU_PART_NUMBER` with the replacement SKU.

```powershell
$newSkuPartNumber = "NEW_SKU_PART_NUMBER"
$newSku = Get-MgSubscribedSku -All |
    Where-Object SkuPartNumber -eq $newSkuPartNumber

if (-not $newSku) {
    throw "Replacement SKU '$newSkuPartNumber' was not found in this tenant."
}

Set-MgUserLicense `
    -UserId $userUPN `
    -AddLicenses @(@{SkuId = $newSku.SkuId}) `
    -RemoveLicenses @()
```

Verify that the replacement license includes an enabled Exchange Online service plan:

```powershell
Get-MgUserLicenseDetail -UserId $userUPN |
    Where-Object SkuId -eq $newSku.SkuId |
    ForEach-Object {
        $_.ServicePlans |
            Where-Object ServicePlanName -like "EXCHANGE_S_*" |
            Select-Object ServicePlanName, ProvisioningStatus
    } |
    Format-Table -AutoSize
```

### 6. Remove the old license

Run this only after the replacement Exchange Online entitlement is confirmed:

```powershell
Set-MgUserLicense `
    -UserId $userUPN `
    -AddLicenses @() `
    -RemoveLicenses @($oldSku.SkuId)
```

### 7. Final verification

```powershell
Get-MgUserLicenseDetail -UserId $userUPN |
    Select-Object SkuPartNumber, SkuId
```

Confirm mailbox availability separately if required:

```powershell
Connect-ExchangeOnline
Get-EXOMailbox -Identity $userUPN |
    Select-Object DisplayName, UserPrincipalName, PrimarySmtpAddress, RecipientTypeDetails
Disconnect-ExchangeOnline -Confirm:$false
```

Disconnect from Microsoft Graph when finished:

```powershell
Disconnect-MgGraph
```

---

## Important Checks and Common Issues

- **Group-based license:** If the license is inherited from a group, changing the user directly may fail or be overwritten. Update the license configuration on the assigning Microsoft Entra group.
- **Multiple Exchange entitlements:** A user can temporarily receive Exchange Online from both old and replacement licenses during the transition.
- **Service dependencies:** Microsoft 365 may prevent certain service plans from being disabled when another enabled service depends on them.
- **Provisioning delay:** License changes may take several minutes and, in some cases, longer to synchronize.
- **Do not rely on the grace period:** Exchange Online may retain mailbox functionality temporarily after delicensing, but this is not a replacement for assigning a valid Exchange Online license.
- **Preserve exact disabled-plan settings:** The `DisabledPlans` value replaces the existing disabled-plan list for that SKU. The script deliberately builds the full list so every non-Exchange plan remains disabled.

## Recommended Change Sequence

1. Record the user's current licenses and apps.
2. Keep only Exchange Online enabled under the old license.
3. Assign the replacement license with Exchange Online enabled.
4. Verify the replacement Exchange service plan.
5. Remove the old license.
6. Verify the user's final licenses and mailbox.
