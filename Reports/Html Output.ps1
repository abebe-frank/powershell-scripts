# Get Html Output(https://github.com/EvotecIT/PSWriteHTML?tab=readme-ov-file)
Install-Module -Name PSWriteHTML -AllowClobber -Force
Update-Module -Name PSWriteHTML

#example 
Get-User |Out-HtmlView
