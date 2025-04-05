# Last Updated: 2024.06.29
# Version: v2.0
# Author: James Phillips
# Description: This script converts the VMware vRealize Operations ChargeBack Report
#    FROM: having a single, unfriendly column of values in a list for vSphere Tags
#    TO:   each vSphere Tag being listed in its own named column in a new, resultant CSV File

# Welcome Message
Write-Host "`n`n"
Get-Content (Get-Random -InputObject (Get-ChildItem $psscriptroot\data\ascii\))
Write-Host "`n`n"
Write-Host @"
############################################
Welcome to TagSplitter v2.0, tHe SpLiTtEr Of TaGs
############################################
`n`n
"@

# Import Source CSV
$sourcefile_path = Read-Host "What is the full file path to your source vRealize Operations CSV Report?"
$sourcefile_csv = Import-Csv -Path "$sourcefile_path"

# Create clean directory for results and temp usage
$results_folder = (Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")
$null = New-Item -ItemType Directory -Force -Path "./results" -Name $results_folder
New-Item -ItemType Directory -Force -Path ./tempdir
Remove-Item -Force ./tempdir/*

# Create a meaningful name for the result CSV file
$resultfile_name = Read-Host "What would you like to name your end-result CSV file?  Name only, NOT file path.
For example: 'test_result.csv' but **not** './mydirectory/isthebest/directory/test_result.csv'"

# Extract 'vSphere Tags' column from Source CSV into temporary working .txt file
$sourcefile_csv."vSphere Tags" | Set-Content -Path ./tempdir/tagonly_file.csv
Copy-Item -Path ./tempdir/tagonly_file.csv -Destination ./tempdir/tagonly_file.txt -Force
Remove-Item -Path ./tempdir/tagonly_file.csv

# Remove extraneous characters from .tempfile.txt and convert back to CSV format with generic new headers
$character_array = "\[", "\]","<", ">"
foreach ($c in $character_array) {
    Get-Content -Path ./tempdir/tagonly_file.txt | ForEach-Object {$_ -replace $c, ""} | Set-Content -Path ./tempdir/tagonly_file-tmp.txt
    Remove-Item -Path ./tempdir/tagonly_file.txt
    Copy-Item -Path ./tempdir/tagonly_file-tmp.txt -Destination ./tempdir/tagonly_file.txt -Force
    Remove-Item -Path ./tempdir/tagonly_file-tmp.txt -Force
}
@("Column_1, Column_2, Column_3, Column_4, Column_5,") + (Get-Content ./tempdir/tagonly_file.txt) | 
    Set-Content ./tempdir/tagonly_file.csv
$global:raw_tagonly_csv = Import-Csv -Path ./tempdir/tagonly_file.csv

# Create New CSV file for Tags Only, prepare with empty "," cells
$new_headers = "Product,Vendor,Project Code,Product Charge ID,Tier"
$new_headers | Out-File ./tempdir/Taggy_CSV.csv

# Iterate through $raw_tagonly_csv by line and then object in each line, and append data string to CSV file
$raw_tagonly_csv | ForEach-Object {
    $array_collector = @(" ", " ", " ", " ", " ")
    foreach ($property in $_.PSObject.Properties) {
        if ($property.value -like "none") {
            continue
        } elseif ($property.value -like "Product Charge ID*") {
            $hypencutvalue = ($property.value).IndexOf("-")
            $array_collector[0]= ($property.value).Substring($hypencutvalue+1)
        } elseif ($property.value -like "Product*") {
            $hypencutvalue = ($property.value).IndexOf("-")
            $array_collector[1]= ($property.value).Substring($hypencutvalue+1)
        } elseif ($property.value -like "Project Code*") {
            $hypencutvalue = ($property.value).IndexOf("-")
            $array_collector[2]= ($property.value).Substring($hypencutvalue+1)
        } elseif ($property.value -like "Tier*") {
            $hypencutvalue = ($property.value).IndexOf("-")
            $array_collector[3]= ($property.value).Substring($hypencutvalue+1)
        } elseif ($property.value -like "Vendor*") {
            $hypencutvalue = ($property.value).IndexOf("-")
            $array_collector[4]= ($property.value).Substring($hypencutvalue+1)
        }
    }
    $array_writer = $array_collector -join ','
    $array_writer | Out-File -Append -Path ./tempdir/Taggy_CSV.csv
}

# Drop 'vSphere Tags' column from sourcefile.csv
$sourcefile_csv | Select-Object * -ExcludeProperty "vSphere Tags" |
    Export-CSV -Path ./tempdir/original_sans_tags.csv


# Merge CSVs and output to result location
$ContentA = Import-Csv -Path ./tempdir/original_sans_tags.csv -Delimiter ","
$ContentB = Import-Csv -Path ./tempdir/Taggy_CSV.csv -Delimiter ","
$MemberToGet = Get-Member -InputObject $ContentB[0] -MemberType NoteProperty | Sort-Object Name
$i=-1

$ContentA | ForEach-Object{
    $CurrentRowObject=$_
    $i++
    $MemberToGet | ForEach-Object{
        $Name=$_.Name
        Add-Member -InputObject $CurrentRowObject -MemberType NoteProperty -Name $Name -Value $ContentB[$i]."$Name"
    }
    $CurrentRowObject
} | Export-CSV ./results/$results_folder/$resultfile_name -NoTypeInformation

# Finish
Write-Host "`n
---------------------------------------------------------------------
Your resultant data is stored at ./results/$results_folder/$resultfile_name .
---------------------------------------------------------------------
############################## fin ##################################"