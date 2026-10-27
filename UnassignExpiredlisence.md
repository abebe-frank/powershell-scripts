#  Remove the Expired Old Microsoft 365 License

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
Connect-MgGraph -Scopes User.ReadWrite.All, Directory.ReadWrite.All
Get-MgUserLicenseDetail -UserId mebel.darlene@capitalpayinternational.com
$userId = "user@domain.com"
$skuIds = (Get-MgUserLicenseDetail -UserId $userId).SkuId
Set-MgUserLicense -UserId $userId -AddLicenses @() -RemoveLicenses $skuIds
```

