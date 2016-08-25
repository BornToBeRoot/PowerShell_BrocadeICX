###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  BrocadeICX.psm1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Module to administrate Brocade ICX Switches over SSH
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

# Global array to store Brocade ICX sessions
if(-not(Test-Path Variable:BrocadeICXSessions))
{
    [System.Collections.ArrayList]$Global:BrocadeICXSessions = @()
}

# Import core functions
Get-ChildItem -Path "$PSScriptRoot\Core" -Recurse | Where-Object {$_.Name.EndsWith(".ps1")} | ForEach-Object {. $_.FullName}

# Import additional functions
Get-ChildItem -Path "$PSScriptRoot\Functions" -Recurse | Where-Object {$_.Name.EndsWith(".ps1")} | ForEach-Object {. $_.FullName}