New-RetentionPolicyTag "3 Months Archive" –Type All –RetentionEnabled $true –AgeLimitForRetention 90 –RetentionAction MoveToArchive

New-RetentionPolicy "3 Months Archive" –RetentionPolicyTagLinks "3 Months Archive"

Set-Mailbox "user name" -RetentionHoldEnabled $false

Set-Mailbox "user@email.com" -RetentionPolicy "3 Months Archive"

Start-ManagedFolderAssistant –Identity "user@email.com"
