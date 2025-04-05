# Last Updated: 2024.06.29
# Version: v2.0
# Author: James Phillips
# Description: This script is designed to add vSphere Tags en masse, in VMware on-prem locations

# Welcome Message
Write-Host "`n`n"
Get-Content -Path $psscriptroot\data\ascii.txt
Write-Host "`n`n"
Write-Host @"
##########################################################################
Welcome to TagAdder v2.0, the Bitey Tag Adder.
##########################################################################
`n`n
"@

# Dot Source functions from functions.ps1
. "$psscriptroot\data\functions.ps1"

# Confirm CSV is ready, import it, and prompt to continue
csv_confirmation

# Connect to vCenter(s)
vcsa_connect

# Check Tag Categories Exist Already
tag_category_check

# Add Tag Assigments
create_TagAssignments

# Print out all Tag Assignments
print_results

# Disconnect Sessions
Write-Host "`nThank you for using TagAdder v2.0.  Goodbye."
Disconnect-VIServer * -Force -Confirm:$false