# Last Updated: 2024.06.29
# Version: v2.0
# Author: James Phillips
# Description: This .ps1 script contains functions called by TagMaster.ps1, to work with vSphere Tagging in VMware On-Prem environments.

function vCenter_Check {
    Write-Host "`n`nYou are currently connected to the following vCenters: $global:DefaultVIServers `n"
    $vcenter_selection = (Read-Host "`n`nIn which vCenter(s) would you like to make changes?
        Multiple vCenters can be entered as a comma-separated list,
        or to modify Tag Categories in ALL currently-connected vCenters, enter 'all'").split(",").trim()

    # Set the $server_list variable for user actions to either be all connected vCenters, or above user input
    switch ($vcenter_selection) {
        all { $script:server_list = $vcenter_list }
        default { $script:server_list = $vcenter_selection }
        quit { script_exit }
        menu { choose_your_adventure }
    }
}

function choose_your_adventure {
    $next_action = Read-Host "`n`nPlease select an option:
        1) Work with Tag Categories;
        2) Work with Tags;
        3) Work with Tag Assignments;
        4) Exit
        Your Choice"
    switch ($next_action) {
        1 { TagCategory_Check }
        2 { Tag_Check }
        3 { TagAssignment_Check }
        4 { script_exit }
    }
}

function script_exit {
    Start-Sleep -Seconds 3
    Write-Host "`n`nThank you for using TagMan.  Enjoy your random CatFact:"
    Get-Random -InputObject (Get-Content $PSScriptRoot\data\randomfacts.txt)
    Write-Host "`n"
    exit
}

function TagCategory_Check {
    Write-Host "`n`nThe current vSphere Tag Categories for your connected vCenters are:`n`n"
    foreach ($vcenter in $vcenter_list) {
        Write-Host "vCenter: $vcenter"
        Get-TagCategory -Server $vcenter | Sort-Object Name | Format-Table -AutoSize
        Write-Host "`n"
    }

    $is_correct = Read-Host "`n`nIs the above list of TAG CATEGORIES complete and accurate?"
    switch ($is_correct) {
        yes { 
            Write-Host "`n`nGoood, gooooood.  Moving on to Check TAGS..."
            Tag_Check 
        } 
        no { 
            Write-Host "`n Let's update the Tag Categories, then...."
            TagCategory_Update
        }
        quit { script_exit }
        menu { choose_your_adventure }
        default {
            Write-Host "`n`nYour input was not recognized.  Trying again..."
            TagCategory_Check
        }
    }
}

function TagCategory_Update {
    $user_action = Read-Host "`n`nDo you want to add, remove, or rename a Tag Category?"
    if ($user_action -eq "quit") { script_exit }
    elseif ($user_action -eq "menu") { choose_your_adventure }

    vCenter_Check

    switch ($user_action) {
        add {
            $done_check = 'no'
            while ($done_check -eq 'no') {
                $tagcategory_name = Read-Host "`n`nPlease enter the Tag Category you would like to $user_action"
                $tagcategory_description = Read-Host "`n`nPlease enter a description for your Tag Category"
                New-TagCategory -Name $tagcategory_name -Cardinality 'Single' -Server $server_list -Description $tagcategory_description -Confirm:$true
                $done_check = Read-Host "`n`nAre you finished adding Tag Categories?"
            }
            choose_your_adventure
        }
        remove {
            $done_check = 'no'
            while ($done_check -eq 'no') {
                $tagcategory_name = Read-Host "`n`nPlease enter the Tag Category you would like to $user_action"
                $warning = Read-Host "`n`n
                ############# WARNING #############
                Removing a Tag Category also removes all downstream Tags and Tag Assignments associated with that Category.
                Are you sure you wish to proceed?`n"
                switch ($warning) {
                    yes {
                        Remove-TagCategory -Category $tagcategory_name -Server $server_list -Confirm:$true
                    }
                    quit { script_exit }
                    menu { choose_your_adventure }
                    default { choose_your_adventure }
                }
                $done_check = Read-Host "`n`nAre you finished removing Tag Categories?"
            }
            choose_your_adventure
        }
        rename {
            $done_check = 'no'
            $description_change = Read-Host "`n`nDo you also need to also update the description of the Tag Category?"
            while ($done_check -eq 'no') {
                $tagcategory_oldname = Read-Host "`n`nPlease enter the Tag Category you would like to $user_action"
                $tagcategory_newname = Read-Host "`n`nPlease enter the new name for the Tag Category you would like to $user_action"
                if ($description_change -eq "yes") {
                    $tagcategory_description = Read-Host "`n`nPlease enter the new description of the Tag Category"
                    Set-TagCategory -Category $tagcategory_oldname -Name $tagcategory_newname -Description $tagcategory_description -Server $server_list -Confirm:$true
                }
                else {
                    Set-TagCategory -Category $tagcategory_oldname -Name $tagcategory_newname -Server $server_list -Confirm:$true
                }
                $done_check = Read-Host "`n`nAre you finished renaming Tag Categories?"
            }
            choose_your_adventure
        }
        quit { script_exit }
        menu { choose_your_adventure }
        default {
            Write-Host "`n`nYour input was not recognized.  Trying again..."
            TagCategory_Update
        }
    }
}

function Tag_Check {
    Get-Tag | Sort-Object Name | Format-Table -AutoSize -Wrap
    $is_correct = Read-Host "`n`nIs the above list of TAGS complete and accurate?"
    switch ($is_correct) {
        yes {
            Write-Host "`n`nGoood, gooooood.  Moving on to check TAG ASSIGNMENTS...."
            TagAssignment_Check
        }
        no { 
            Write-Host "`n Let's update the Tags, then...."
            Tag_Update 
        }
        quit { script_exit }
        menu { choose_your_adventure }
        default {
            Write-Host "`n`nYour input was not recognized.  Trying again..."
            Tag_Check
        }
    }
}

function Tag_Update {
    $user_action = Read-Host "`n`nDo you want to add, remove, or rename a Tag?"
    if ($user_action -eq "quit") { script_exit }
    elseif ($user_action -eq "menu") { choose_your_adventure }

    vCenter_Check

    switch ($user_action) {
        add {
            $done_check = 'no'
            while ($done_check -eq 'no') {
                $tag_name = Read-Host "`n`nPlease enter the Tag you would like to $user_action"
                $tag_description = Read-Host "`n`nPlease enter a description for your Tag"
                $tag_category = Read-Host "`n`nPlease enter the Tag Category in which the new tag will be created"
                Get-TagCategory -Name $tag_category | New-Tag -Name $tag_name -Server $server_list -Description $tag_description -Confirm:$true
                $done_check = Read-Host "`n`nAre you finished adding Tags?"
            }
            choose_your_adventure
        }
        remove {
            $done_check = 'no'
            while ($done_check -eq 'no') {
                $tag_name = Read-Host "`n`nPlease enter the Tag you would like to $user_action"
                $tag_category = Read-Host "`n`nPlease enter the Tag Category from which the Tag will be removed"
                $warning = Read-Host "`n`n
                ############# WARNING #############
                Removing a Tag also removes all downstream Tag Assignments associated with that Tag.
                Are you sure you wish to proceed?`n"
                switch ($warning) {
                    yes {
                        Get-Tag -Name $tag_name -Category $tag_category | Remove-Tag -Server $server_list -Confirm:$true
                        Remove-Tag -Tag $tag_name -Server $server_list -Confirm:$true
                    }
                    quit { script_exit }
                    menu { choose_your_adventure }
                    default { choose_your_adventure }
                }
                $done_check = Read-Host "`n`nAre you finished removing Tags?"
            }
            choose_your_adventure
        }
        rename {
            $done_check = 'no'
            $description_change = Read-Host "`n`nDo you also need to update the description of the Tag?"
            while ($done_check -eq 'no') {
                $tag_oldname = Read-Host "`n`nPlease enter the Tag you would like to $user_action"
                $tag_newname = Read-Host "`n`nPlease enter the new name for the Tag you would like to $user_action"
                if ($description_change -eq "yes") {
                    $tag_description = Read-Host "`n`nPlease enter the new description of the Tag"
                    Get-Tag -Name $tag_oldname | Set-Tag -Name $tag_newname -Server $server_list -Description $tag_description -Confirm:$true
                }
                else {
                    Get-Tag -Name $tag_oldname | Set-Tag -Name $tag_newname -Server $server_list -Confirm:$true
                }
                $done_check = Read-Host "`n`nAre you finished renaming Tags?"
            }
            choose_your_adventure
        }
        quit { script_exit }
        menu { choose_your_adventure }
        default {
            Write-Host "`n`nYour input was not recognized.  Trying again..."
            Tag_Update
        }
    }
}

function TagAssignment_Check {
    # Including -ErrorAction 'Ignore' skips entities that are not reporting correctly in vCenter, like inaccessible local datastores
    Get-TagAssignment -ErrorAction 'Ignore' | Select-Object Tag, Entity, Description | Sort-Object Tag | Format-Table -AutoSize -Wrap
    $is_correct = Read-Host "`n`nIs the above list of VM TAG ASSIGNMENTS complete and accurate?"
    switch ($is_correct) {
        yes {
            $done_check = Read-Host "`n`nAre you finished with all your changes?"
            switch ($done_check) {
                yes {
                    Write-Host "`n`nThank you for using TagMan.  Enjoy your random CatFact:"
                    Get-Random -InputObject (Get-Content $PSScriptRoot\data\randomfacts.txt)
                    exit
                }
                no { choose_your_adventure }
                quit { script_exit }
                menu { choose_your_adventure }
                default {
                    Write-Host "`n`nYour input was not recognized.  Trying again..."
                    TagAssignment_Check
                }
            }
        }
        no {
            "`n Let's update the Tag Assignments, then...."
            TagAssignment_Update
        }
        quit { script_exit }
        menu { choose_your_adventure }
        default {
            Write-Host "`n`nYour input was not recognized.  Trying again..."
            TagAssignment_Check
        }
    }
}

function TagAssignment_Update {
    $user_action = Read-Host "`n`nDo you want to add or remove a Tag Assignment on VM(s)?"
    if ($user_action -eq "quit") { script_exit }
    elseif ($user_action -eq "menu") { choose_your_adventure }

    vCenter_Check

    $vm_file = Read-Host "`n`nDo you have a .txt file containing the VMware VM Names of the VMs which you would like to modify?"
    if ($vm_file -eq "yes") {
        $vm_file_location = Read-Host "`n`nWhat is the path to the .txt file for the list of VMs?"
        $vm_list = Get-Content -Path $vm_file_location
    }
    else {
        $vm_list = (Read-Host "`n`nPlease enter the VMs you would like to modify. 
        NOTE: Multiple VMs can be entered as a comma-separated list,
        E.G.: 'testplay001, testdb002, prod-db-003'
        Enter your VM(s) now").split(",").trim()
    }

    switch ($user_action) {
        add {
            $done_check = 'no'
            while ($done_check -eq 'no') {
                $tag_name = Read-Host "`n`nPlease enter the Tag you would like to $user_action to the VM(s)"
                foreach ($vm in $vm_list) {
                    Get-VM -Name $vm | New-TagAssignment -Tag $tag_name -Server $server_list -Confirm:$false
                }
                $done_check = Read-Host "`n`nAre you finished adding Tags to the chosen VM(s)?"
            }
            choose_your_adventure
        }
        remove {
            $done_check = 'no'
            while ($done_check -eq 'no') {
                $tag_name = Read-Host "`n`nPlease enter the Tag Assignment you would like to $user_action from the VM(s)"
                foreach ($vm in $vm_list) {
                   Get-VM -Name $vm -Server $server_list | Remove-TagAssignment -TagAssignment $tag_name -Confirm:$true
                }
                $done_check = Read-Host "`n`nAre you finished removing Tags?"
            }
            choose_your_adventure
        }
        rename {
            $done_check = 'no'
            $description_change = Read-Host "`n`nDo you also need to update the description of the Tag?"
            while ($done_check -eq 'no') {
                $tag_oldname = Read-Host "`n`nPlease enter the Tag you would like to $user_action"
                $tag_newname = Read-Host "`n`nPlease enter the new name for the Tag you would like to $user_action"
                if ($description_change -eq "yes") {
                    $tag_description = Read-Host "`n`nPlease enter the new description of the Tag"
                    foreach ($vm in $vm_list) {
                        Set-Tag -Tag $tag_oldname -Name $tag_newname -Description $tag_description -Server $server_list -Confirm:$false   
                    }
                }
                else {
                    foreach ($vm in $vm_list) {
                        Set-Tag -Tag $tag_oldname -Name $tag_newname -Server $server_list -Confirm:$false
                    }
                }
                $done_check = Read-Host "`n`nAre you finished adding Tags?"
            }
            choose_your_adventure
        }
        quit { script_exit }
        menu { choose_your_adventure }
        default {
            Write-Host "`n`nYour input was not recognized.  Trying again..."
            TagAssignment_Update
        }
    }
}