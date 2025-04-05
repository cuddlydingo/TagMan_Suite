function csv_confirmation {
    Write-Host @"
##########################################################################
NOTES:
    - This script expects you to have a valid .csv file available, with correct data in the following **EXACT** columns (The column names are SPECIFIC):
        - VM_Name
        - Parent_vCenter_IP
        - Product
        - Vendor
        - Project Code
        - Product Charge ID
        - Tier

        Here is a small CSV file example, if you want to play hard and build your own:
            VM_Name,Parent_vCenter_IP,Product,Vendor,Project Code,Product Charge ID,Tier
            test-vm-01,10.10.10.2,DB_Server,DBA_Team,123456,ABCDEF,Bronze
            test-vm-02,10.10.10.3,DB_Server,DBA_Team,123456,ABCDEF,Bronze
            test-vm-03,10.10.10.4,APP_Server,FrontEnd_Dev,123456,ABCDEF,Gold
            test-vm-04,10.10.10.5,APP_Server,FrontEnd_Dev,123456,ABCDEF,Gold
        
    - This script ***ONLY ADDS*** vSphere Tags (creating them if necessary) to VMs as defined in the user-provided CSV file.
    - This script REQUIRES Tag Categories to already be created.
    - To create/modify/remove Categories/Tags/Assignments, please use the TagMan tool.

##########################################################################`n`n
"@
    $script:csv_source_path = Read-Host "What is the path to your source CSV file?"
    $script:csv_source = Import-Csv -Path $csv_source_path
    
    Write-Host "`n`nThis is the source data you have defined.  Please review and confirm that it is accurate before proceeding...`n"
    $csv_source | Format-Table -AutoSize

    confirm_to_proceed
}

function vcsa_connect {
    Write-host "`nPlease enter vCenter credentials to connect to vCenter...."
    $script:vis_creds = Get-Credential
    $script:vcenter_list = $csv_source.Parent_vCenter_IP | Sort-Object | Get-Unique

    Write-Host "`nConnecting to the following vCenter(s)..." $vcenter_list
    Connect-VIServer -Server $vcenter_list -Credential $vis_creds -Verbose
}

function tag_category_check {
    Write-Host "`n`nThe current vSphere Tag Categories for your connected vCenters are:`n`n"
    foreach ($vcenter in $vcenter_list) {
        Write-Host "vCenter: $vcenter"
        Get-TagCategory -Server $vcenter | Sort-Object Name | Format-Table -AutoSize
        Write-Host "`n"
    }

    switch (Read-Host "`n`nAre all TAG CATEGORIES for the data above good and accurate?") {
        yes {
            continue
        }
        no {
            Write-Host "`nTo add, remove, or modify/update TAG CATEGORIES, please use the TagMan tool."
            Write-Host "`nThank you for using TagAdder.  Goodbye."
            Exit
        }
        default {
            Write-Host "`nThank you for using TagAdder.  Goodbye."
            Exit
        }
    }
}

function vCenter_check {
    Write-Host "`nYou are currently connected to the following vCenters:"
    Write-Host $Global:DefaultVIServers
}

function confirm_to_proceed {
    if ((Read-Host "`n`nWould you like to proceed?  Please enter 'yes' to continue") -eq "yes") {
    }
    else { 
        Write-Host "`nThank you for using TagAdder.  Goodbye."
        exit
    }
}

function create_TagAssignments {
    vCenter_check
    confirm_to_proceed

    $category_list = ("Product","Vendor","Project Code","Product Charge ID","Tier")

    foreach ($line in $csv_source) {
        foreach ($category in $category_list) {
            # Visual display of progress
            Write-Host -NoNewLine "."
            # If CSV cell for each line/column has a value to write
            if ($line.$category) { 
                # Create Tag (if tag category already exists, it will throw an error which will be ignored by "-ErrorAction" parameter)
                Get-TagCategory -Name $category | New-Tag -Name $line.$category -Server $line.Parent_vCenter_IP -Confirm:$false -ErrorAction SilentlyContinue
                # assign tag to VM
                Get-VM -Name $line.VM_Name | New-TagAssignment -Tag $line.$category -Server $line.Parent_vCenter_IP -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }
}

function print_results {
    Write-Host "`n`nThe current Tag Assignments after your changes are:"
    foreach ($vcenter in $vcenter_list) {
        Write-Host "vCenter: $vcenter"
        Get-TagAssignment -Server $vcenter -ErrorAction SilentlyContinue | Format-Table -AutoSize
        Write-Host "`n"
    }
}