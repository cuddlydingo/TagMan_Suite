# Last Updated: 2024.06.29
# Version: v2.0
# Author: James Phillips
# Description: This script is designed to list vSphere Tags for a user-defined set of Virtual Machines, in VMware on-prem locations

# Welcome Message
Write-Host "`n`n"
Get-Content -Path $psscriptroot\data\ascii.txt
Write-Host "`n`n"
Write-Host @"
##########################################################################
Welcome to TagLister v2.0, the Totally Not Sarcastic Tag Listing Tool.
##########################################################################
`n`n
"@

# Dot Source functions from functions.ps1
. "$psscriptroot\data\functions.ps1"

# Connect to vCenter(s)
vcsa_connect

# Confirm proceed to collect data for connected vCenters
vCenter_check
confirm_to_proceed

# Get vSphere Tags from VMs
get_vsphere_tags

# Disconnect Sessions
Write-Host "`nThank you for using TagLister v2.0 -- enjoy your random CatFact.  Toodles!"
Disconnect-VIServer * -Force -Confirm:$false

# Add CatFacts
Get-Random -InputObject (Get-Content $PSScriptRoot\data\randomfacts.txt)