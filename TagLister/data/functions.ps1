function vcsa_connect {
    $script:vcenter_list = (Read-Host "To which vCenter(s) would you like to connect? 
      NOTE: Multiple vCenters can be entered as a comma-separated list
      E.G.: 10.0.0.10, 10.0.0.11
      Enter your vCenter(s) now").split(",").trim()
    
    Write-host "`nPlease enter vCenter credentials to connect to vCenter...."
    $script:vis_creds = Get-Credential

    Write-Host "`nConnecting to the following vCenter(s)..." $vcenter_list
    Connect-VIServer -Server $vcenter_list -Credential $vis_creds -Verbose
}

function vCenter_check {
    Write-Host "`nYou are currently connected to the following vCenters:"
    Write-Host $Global:DefaultVIServers
}

function confirm_to_proceed {
    if ((Read-Host "`n`nWould you like to proceed?  Please enter 'yes' to continue") -eq "yes") {
        continue
    }
    else { 
        Write-Host "`nThank you for using TagLister.  Goodbye."
        exit
    }
}

function get_vsphere_tags {
    $csv_output_location = Read-Host "Please enter the location for the CSV file output:"

    foreach ($vm in ((Get-VM | Sort-Object Name).Name | Where-Object { $_ -notlike "vCLS*" })) {
        Write-Host "Working on $vm..."
        Get-VM -Name $vm | Select-Object Name,
        @{Name = "VM_Name"; Expression = { ((Get-VM -Name $vm | Get-TagAssignment).Tag | Where-Object { $_.Category -like "VM_Name" }).Name } },
        @{Name = "Parent_vCenter_IP"; Expression = { ((Get-VM -Name $vm | Get-TagAssignment).Tag | Where-Object { $_.Category -like "Parent_vCenter_IP" }).Name } },
        @{Name = "Product"; Expression = { ((Get-VM -Name $vm | Get-TagAssignment).Tag | Where-Object { $_.Category -like "Product" }).Name } },
        @{Name = "Vendor"; Expression = { ((Get-VM -Name $vm | Get-TagAssignment).Tag | Where-Object { $_.Category -like "Vendor" }).Name } },
        @{Name = "Project Code"; Expression = { ((Get-VM -Name $vm | Get-TagAssignment).Tag | Where-Object { $_.Category -like "Project Code" }).Name } },
        @{Name = "Product Charge ID"; Expression = { ((Get-VM -Name $vm | Get-TagAssignment).Tag | Where-Object { $_.Category -like "Product Charge ID" }).Name } },
        @{Name = "Tier"; Expression = { ((Get-VM -Name $vm | Get-TagAssignment).Tag | Where-Object { $_.Category -like "Tier" }).Name } } |
        Export-Csv -Path $csv_output_location -NoTypeInformation -Append
    }
    Write-Host "`nYour CSV file is located at $csv_output_location.`n"
}