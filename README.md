# PowerShell-Windows-Hardware-Inventory

This PowerShell Script is crafted to ultimately gather the following information from remote servers/nodes in any enterprise environment with proper authroization:

Computer Name, IP Address, Model & Manufacturer, Serial Number, OS Type, OS Version, and Bitlocker Status

Must run PowerShell window as administrator prior to execution. 

# PowerShell Version
Must use PowerShell Version 5.1 or earlier. 

# Description

This PowerShell script uses the Get-ADComputer module to enumerate validated Active Directory computers.

For each computer gathered, WinRS will connect to each online system and remotley query Hardware information using the WinRS (Windows Remote Shell) command. 

This is an automated process that outputs the results to a CSV file in the C: drive by default. 

# Credits
Written by: Javier Walters

# Social Network
LinkedIn: https://www.linkedin.com/in/javier-walters/
