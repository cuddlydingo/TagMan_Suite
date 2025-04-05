# Last Updated: 2024.06.29
# Version: v2.0
# Author: James Phillips
# Description: This script is designed to add/remove/modify vSphere Tags in VMware on-prem locations

# Welcome Message
Write-Host "`n`n"
Get-Content (Get-Random -InputObject (Get-ChildItem $psscriptroot\data\ascii\))
Write-Host "`n`n"
Write-Host @"
##########################################################################
Welcome to TagMan v2.0, the Taggiest Tagging Tool that ever Tagged (or Tooled).
##########################################################################
`n`n
"@

# Get Credentials and Connect to vCenter
Write-host "Please enter vCenter credentials to connect to vCenter...."
$vis_creds = Get-Credential
$script:vcenter_list = (Read-Host "To which vCenter(s) would you like to connect? 
    NOTE: Multiple vCenters can be entered as a comma-separated list
    E.G.: 'vcenter-001.example-domain.com, 10.10.10.10'
`nEnter your vCenter(s) now").split(",").trim()

Write-Host "`nConnecting to vCenter..."
Connect-VIServer -Server $vcenter_list -Credential $vis_creds -Verbose

Write-Host @"
`n#################### NOTE ####################
Tag Categories ***MUST*** exist prior to creating new Tags, and Tags ***MUST*** exist before they can be assigned to VMs.

The REQUIRED order of operations is:
1. Create Tag Categories;
2. Create Tags;
3. Assign Tags to VMs.

This script will help you to confirm that the correct categories/tags exist, and create them if needed, before assigning tags to VMs.

Please type 'quit' at any time to exit the script, or 'menu' to see the menu options.
##############################################`n
"@

# Call Functions from functions.ps1
. "$psscriptroot\functions.ps1"

# Call the Choose Your Adventure function to ask the user what they want to do.
choose_your_adventure

# Disconnect Sessions
Disconnect-VIServer * -Force -Confirm:$false