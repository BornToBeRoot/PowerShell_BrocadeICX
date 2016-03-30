###############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  Brocade.psm1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  : 
# Repository   :  https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
###############################################################################################################

function Get-BrocadeSysteminfo
{
    [CmdletBinding(DefaultParameterSetName='ComputerName')]
    param(
        [Parameter(
            Position=0,
            ParameterSetName='Session',
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage="Brocade Session")]
            [PSObject]$Session,

        [Parameter(
            Position=0,
            ParameterSetName='ComputerName',
            Mandatory=$true,
            HelpMessage="Hostname or IP-Address of the Brocade Switch device")]
            [String]$ComputerName,

        [Parameter(
            Position=1,
            ParameterSetName='ComputerName',
            HelpMessage="PSCredentials for SSH connection to Brocade Switch device")]
            [System.Management.Automation.PSCredential]$Credentials                       
    )

    



}