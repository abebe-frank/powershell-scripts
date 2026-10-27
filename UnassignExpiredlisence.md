# Retain Exchange Online and Remove the Old Microsoft 365 License

## Purpose

Use this guide to disable all applications under a user's existing Microsoft 365 license except Exchange Online, and then remove the old license using Microsoft Graph PowerShell.

> **Important:** Before removing the old license, make sure the user has another active license containing Exchange Online. If the old license is the user's only Exchange Online entitlement, removing it will leave the mailbox unlicensed.

---

# Step 1: Microsoft 365 Admin Center

## Remove Microsoft 365 Apps and Retain Only Exchange Online

1. Sign in to the **Microsoft 365 Admin Center**.
2. Navigate to **Users** > **Active users**.
3. Select the affected user.
4. Select **Licenses and apps**.
5. Expand the assigned license.
6. Under **Apps**, clear **Microsoft 365 Apps for enterprise** and all other applications that need to be removed.
7. Leave only the required **Exchange Online** service enabled, such as:
   - **Exchange Online (Plan 1)**, or
   - **Exchange Online (Plan 2)**.
8. Select **Save changes**.
9. Wait a few minutes for the changes to propagate.

## Verification

1. Refresh the user's **Licenses and apps** page.
2. Confirm that **Microsoft 365 Apps for enterprise** and the other unwanted applications are no longer assigned.
3. Confirm that the required **Exchange Online** plan remains enabled.
4. Verify that the user can continue using Outlook and the remaining licensed services.

---

# Step 2: Microsoft Graph PowerShell

## Unassign the Old License Using PowerShell

### 1. Install Microsoft Graph PowerShell

Run PowerShell as an administrator, and then run:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

If the module is already installed, you do not need to install it again.

### 2. Connect to Microsoft Graph

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.ReadWrite.All"
```

Confirm the connection:

```powershell
Get-MgContext
```

### 3. Obtain the User's Object ID

Replace `user@domain.com` with the affected user's User Principal Name:

```powershell
Get-MgUser -UserId "user@domain.com" |
    Select-Object Id, DisplayName, UserPrincipalName
```

You can save the user details in a variable:

```powershell
$user = Get-MgUser -UserId "user@domain.com"
$user.Id
```

### 4. View the User's Assigned Licenses

```powershell
Get-MgUserLicenseDetail -UserId "user@domain.com" |
    Select-Object SkuPartNumber, SkuId
```

To view the license and all service plans under it:

```powershell
Get-MgUserLicenseDetail -UserId "user@domain.com" |
    ForEach-Object {
        $license = $_
        $license.ServicePlans | Select-Object `
            @{Name='SkuPartNumber';Expression={$license.SkuPartNumber}}, `
            @{Name='SkuId';Expression={$license.SkuId}}, `
            ServicePlanName, ProvisioningStatus
    } |
    Format-Table -AutoSize
```

### 5. Find the SKU ID to Remove

List the licenses available in the tenant:

```powershell
Get-MgSubscribedSku -All |
    Select-Object SkuPartNumber, SkuId, ConsumedUnits
```

Identify the old license and copy its `SkuId` value.

### 6. Remove the Old License

Replace `SKU-GUID` with the actual license SKU ID to be removed:

```powershell
Set-MgUserLicense `
    -UserId "user@domain.com" `
    -AddLicenses @() `
    -RemoveLicenses @("SKU-GUID")
```

Alternatively, use a variable:

```powershell
$oldSkuId = "SKU-GUID"

Set-MgUserLicense `
    -UserId "user@domain.com" `
    -AddLicenses @() `
    -RemoveLicenses @($oldSkuId)
```

> **Important:** Run this removal command only after confirming that the replacement license has been assigned and provides an active Exchange Online service plan.

---

# Remove the Old License and Verification

## Verify License Removal

Run:

```powershell
Get-MgUserLicenseDetail -UserId "user@domain.com" |
    Select-Object SkuPartNumber, SkuId
```

Confirm that the old license no longer appears in the output.

## Verify Exchange Online Is Still Licensed

```powershell
Get-MgUserLicenseDetail -UserId "user@domain.com" |
    ForEach-Object {
        $_.ServicePlans |
            Where-Object ServicePlanName -like "EXCHANGE_S_*" |
            Select-Object ServicePlanName, ProvisioningStatus
    } |
    Format-Table -AutoSize
```

Confirm that the required Exchange Online plan appears and that its `ProvisioningStatus` is `Success`.

## Disconnect from Microsoft Graph

```powershell
Disconnect-MgGraph
```

---

# Recommended Sequence

1. In the Microsoft 365 Admin Center, disable Microsoft 365 Apps and all unwanted services under the old license.
2. Retain only Exchange Online under the old license temporarily.
3. Assign the replacement license.
4. Confirm that Exchange Online is active under the replacement license.
5. Use Microsoft Graph PowerShell to remove the old license.
6. Verify that the old license is gone and Exchange Online remains active.

# Important Notes

- If the license is assigned through a Microsoft Entra group, update the license assignment on the group instead of removing it directly from the user.
- License changes may take several minutes to propagate.
- Do not remove the user's only Exchange Online license if mailbox access must continue.
- Record the user's existing SKU and service-plan configuration before making changes.
