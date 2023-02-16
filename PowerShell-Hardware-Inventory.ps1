<#
##############################################################
Title: Computer Hardware Inventory
Description:
- Remotely Gather HW Information from Computers
- HW Information gathered:
    Computer Name 
    IP Address
    Model & Manufacturer
    Serial Number
    OS Type 
    OS Version 
    Bitlocker Status 
##############################################################
#> 


## SET Variables and Change Directories
##############################################################
## Variables and Directories for Script
                        ##Unit Name or Section, change accordingly
			   $UNIT = "HRSECTION1"
			   
			   ## AD OU for the Unit 
			   $AD_OU = "OU=NAME,OU=AD,OU=DOMAIN,OU=COMPANY,OU=YOUR"
                        
                        ## Date and Time for New Folder Name Creation at the End of Scirpt 
                        $DateAndTime = (Get-Date).tostring("MM-dd-yyyy@hh-mm-tt")
                        
                        ## Make New Directory When Starting Script 
                        $CN_DIR = mkdir "C:\$($UNIT)_$($DateAndTime)"
                        IF ($CN_DIR) {Write-Host "Created Directory for $ComputerName at:" -ForegroundColor Green;Write-Host "$CN_DIR" -ForegroundColor Cyan }

                        ## Change Working Directory to New Directory 
                        Set-Location "C:\$($UNIT)_$($DateAndTime)"

                        ## Create Export Location for Results 
                        $FileExport = "C:\$($UNIT)_$($DateAndTime)\CPU_HW_Info.csv"
##
## Variables and Directories for Script
##############################################################

## ---------- BREAK ---------- ##
## Script Begins
## ---------- BREAK ---------- ##

## SET Title Box  
#################################################
## Title Box for Script 
Clear-Host
Write-Host "
############################
##                            
## Active Directory Enumeration 
## Remote Hardware Inventory 
## 
############################
" -ForegroundColor Yellow

## Title Box for Script 
################################################

## ---------- BREAK ---------- ##

## Action 1: Get AD Computer Names
##########################################################################################################
## Get AD Computer Names from AD
<###
Comment Box Statement: States AD Computer Export
###>
Write-Host "Importing $UNIT Computers from Active Directory" -ForegroundColor Cyan
<###
Gathers Computer Names in Active Directory from a specific OU and Exports them
###>
(Get-ADComputer -Filter * -Searchbase $AD_OU ).Name | Sort-Object -Descending | Out-File .\$($UNIT)_List.txt
## Get AD Computer Names from AD
##########################################################################################################

## ---------- BREAK ---------- ##

## Action 2: Connection Tests
###############################################################################
## TESTS COMPUTER CONNECTION
<###
Comment Box Statement: States Testing Connection to AD Computers
###>
Write-Host ""
Write-Host "---------------------------------------" -ForegroundColor Magenta
Write-host "TESTING CONNECTION TO $UNIT COMPUTERS" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Magenta
<# 
Get/read the Computers list from the Get-ADComputer output
#>
$CPU_List = Get-Content -Path .\$($UNIT)_List.txt
<## 
- Tests the connection to target computers before gathering inventory information
- Creates an Online and Offine List of Computers
##>
foreach ($Computer in $CPU_List) {
if (Test-Connection -Computername $Computer -Quiet -count 1) { 
Write-Host ""
Write-host "$Computer is Online" -ForegroundColor Green
Write-Host ""
        Add-Content -value $Computer -path .\$($UNIT)_Online.txt 

  } else { 
Write-Host ""
Write-host "$Computer is Offline" -ForegroundColor Red 
Write-Host ""
        Add-Content -value $Computer -path .\$($UNIT)_Offline.txt}
} 
##  TESTS COMPUTER CONNECTION
###############################################################################

## ---------- BREAK ---------- ##

## Action 3: Run Commands against remote online systems
## SET Variables for WMI, NetAdapter, and Child-Item cmdlets 
###############################################################################
##
## Get/read Online Computers
$Online_Computers = Get-Content -Path .\$($UNIT)_Online.txt | Sort-Object -Descending
##
## Count the amount of Computers online 
$NUM = $Online_Computers.Count
<###
Comment Box Statement: States the Counted Amount of Online AD Computers
###>
Write-Host ""
Write-host "$NUM $UNIT Computers are Online. Gathering Computer Information.." -ForegroundColor Yellow
Write-Host ""
##
## Each computer online will be processed remotely
foreach ($Computer in $Online_Computers) {
##
## Computer Name 
$Bios = Get-WmiObject win32_bios -Computername $Computer
##
## IP Address
$IP = (Resolve-DnsName $Computer -Type A).IPAddress
##
## Manufacturer and Model 
$Hardware = Get-WmiObject Win32_computerSystem -Computername $Computer
## 
## Operating System Type
$OS = Get-WmiObject Win32_OperatingSystem -Computername $Computer
$OS_VER = IF ($OS.Version -eq "10.0.19042") {ECHO 20H2} ELSE {IF ($OS.Version -eq "10.0.19044") {ECHO 21H2} ELSE {ECHO $OS.Version}}
##
## Serial Number for the computer 
$systemBios = $Bios.serialnumber
##
## Pull MAC Addressess for the 3 NICs Present on System
## The Standard NIC is the Original "Ethernet" named NIC that came with computer
## Ethernet 2&3 are for the extra Fiber NICs that "should" be present
$MAC1 = IF ($MAC_E1 = Get-NetAdapter Ethernet -CimSession $Computer -ErrorAction SilentlyContinue ) {ECHO $MAC_E1.MacAddress } ELSE {ECHO "NO FIBER NIC"} 
$MAC2 = IF ($MAC_E2 = Get-NetAdapter "Ethernet 2" -CimSession $Computer -ErrorAction SilentlyContinue) {ECHO $MAC_E2.MacAddress } ELSE {ECHO "NO FIBER NIC"} 
$MAC3 = IF ($MAC_E3 = Get-NetAdapter "Ethernet 3" -CimSession $Computer -ErrorAction SilentlyContinue) {ECHO $MAC_E3.MacAddress } ELSE {ECHO "NO FIBER NIC"} 
##
## Bitlocker Protection Status
$BIT_Status = if (winrs -r:$Computer CMD.EXE /C manage-bde.exe -status | findstr "Fully Encrypted") { Write-Output "BITLOCKER ON"} else { Write-Output "BITLOCKER OFF"}
##
## Bitlocker Precentage Status
$BIT_Per = winrs -r:$Computer CMD.EXE /C manage-bde.exe -status | findstr "%"
##
##Status of Computer
Write-host "$Computer ($IP) -- Captured!" -ForegroundColor Green
##
## cmdlet actions and Variables 
###############################################################################

## ---------- BREAK ---------- ##

## Action 4: Export Information to CSV 
###############################################################################
## Information will be exported to CSV output 
$HW_Results  = New-Object -Type PSObject
##
## Each value will be placed underneath their respected columns in the CSV
## Computer Name
$HW_Results | Add-Member -MemberType NoteProperty -Name "Computer Name" -Value $Computer.ToUpper()
##
## IP address
$HW_Results | Add-Member -MemberType NoteProperty -Name "IP Address" -Value "$env:USERDOMAIN\$IP"
##
## All 3 MACs 
$HW_Results | Add-Member -MemberType NoteProperty -Name "Ethernet MAC" -Value $MAC1 
$HW_Results | Add-Member -MemberType NoteProperty -Name "Fiber MAC 1" -Value $MAC2
$HW_Results | Add-Member -MemberType NoteProperty -Name "Fiber MAC 2" -Value $MAC3 
##
## Manufacturer
$HW_Results | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $Hardware.Manufacturer
##
## Model
$HW_Results | Add-Member -MemberType NoteProperty -Name Model -Value $Hardware.Model
##
## Serial Number
$HW_Results | Add-Member -MemberType NoteProperty -Name "Serial Number" -Value $systemBios
##
## OS Type
$HW_Results | Add-Member -MemberType NoteProperty -Name "OS Type" -Value $OS.Caption
##
## The OS build Number 10.0.19042 == Windows Version 20H2
$HW_Results | Add-Member -MemberType NoteProperty -Name "OS Version" -Value $OS_VER
##
## Bitlocker Status
$HW_Results | Add-Member -MemberType NoteProperty -Name "Bitlocker Status" -Value $BIT_Status
##
## Bitlocker Percentage
$HW_Results | Add-Member -MemberType NoteProperty -Name "Encryption Percentage" -Value $BIT_Per
##
##CSV will be exported to location in $FileExport
$HW_Results | Export-Csv $FileExport -Append -NoTypeInformation
##
###############################################################################

}

## ---------- BREAK ---------- ##

## Action 5: verify CSV Export
##########################################################################################################
## VERIFY EXPORTED FILE
if (Get-ChildItem -Path $FileExport) {
## Good OutPut with Location
Write-Host "----------------------------------------" -ForegroundColor Magenta
Write-Host "CPU Info for $UNIT Exported to:" -ForegroundColor Yellow;Write-Host "$FileExport" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Magenta
} ELSE {
Write-Host "---------------------------------------------" -ForegroundColor Magenta
Write-Host "Failed to Export $UNIT Computer Information" -ForegroundColor Red
Write-Host "---------------------------------------------" -ForegroundColor Magenta
}
## VERIFY EXPORTED FILE
##########################################################################################################

#################
##End of Script##
#################
