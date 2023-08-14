$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$directorypath

$ExcelFile="C:\temp\Users.csv" # Path to the excel file
$InviteRedirectURL="https://mycompany.com" # Redirect url after the first logon
$WorkSheetNum="Users" # Name of the table in the excel file

if (!$lastLogin) {
   # put your Azure AD tenant id here (Azure portal / Azure Active Directory / Properties / Directory ID)
   $global:lastLogin=Connect-AzureAD -TenantId "52c19be3-03a6-4923-844c-0af0653b8842"
}

$Excel = New-Object -ComObject Excel.Application

$WorkBook = $Excel.Workbooks.Open($ExcelFile)
$WorkSheet = $WorkBook.WorkSheets.Item($WorkSheetNum)

$RowNum = 2

While ($WorkSheet.Cells.Item($RowNum, 1).Text -ne "") {
  # Read the first line from sheet
  $Company = "Ext: "+$WorkSheet.Cells.Item($RowNum, 1).Text.trim()
  $Surname = $WorkSheet.Cells.Item($RowNum, 2).Text.trim()
  $Name = $WorkSheet.Cells.Item($RowNum, 3).Text.trim()
  $Mailadress = $WorkSheet.Cells.Item($RowNum, 4).Text.trim()
  $JobTitle = $WorkSheet.Cells.Item($RowNum, 5).Text.trim()
  $userFullName=$Name+", "+$Surname

  Write-Output("Adding user: "+$userFullName+" ("+$Mailadress+")")
  $invitation=New-AzureADMSInvitation -InvitedUserDisplayName $userFullName -InvitedUserEmailAddress $Mailadress -SendInvitationMessage $false -InviteRedirectURL $InviteRedirectURL
  $user = Get-AzureADUser -ObjectId $invitation.InvitedUser.Id
  Set-AzureADUser -ObjectId $invitation.InvitedUser.Id -Surname $Name
  Set-AzureADUser -ObjectId $invitation.InvitedUser.Id -GivenName $Surname
  Set-AzureADUser -ObjectId $invitation.InvitedUser.Id -JobTitle $JobTitle
  Set-AzureADUser -ObjectId $invitation.InvitedUser.Id -Department $Company
  Set-AzureADUser -ObjectId $invitation.InvitedUser.Id -Displayname $user.Displayname
  $RowNum++
}