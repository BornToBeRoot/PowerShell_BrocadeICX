###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Get-ICXSession.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Get a Brocade ICX session
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    Get a Brocade ICX session

    .DESCRIPTION
    Get one or multiple Brocade ICX sessions based on SessionID or ComputerName.
    
    .EXAMPLE
    Get-ICXSession -SessionID 1,2   

    SessionID ComputerName Session        Stream
    --------- ------------ -------        ------
            1 megatron     SSH.SshSession Renci.SshNet.ShellStream
            2 megatron     SSH.SshSession Renci.SshNet.ShellStream

    .EXAMPLE
    Get-ICXSession -ComputerName megatron

    SessionID ComputerName Session        Stream
    --------- ------------ -------        ------
            0 megatron     SSH.SshSession Renci.SshNet.ShellStream
            1 megatron     SSH.SshSession Renci.SshNet.ShellStream
            2 megatron     SSH.SshSession Renci.SshNet.ShellStream

    .EXAMPLE
    Get-ICXSession -Search *mega*

    SessionID ComputerName Session        Stream
    --------- ------------ -------        ------
            0 megatron     SSH.SshSession Renci.SshNet.ShellStream
            1 megatron     SSH.SshSession Renci.SshNet.ShellStream
            2 megatron     SSH.SshSession Renci.SshNet.ShellStream

    .LINK
    https://github.com/BornToBeRoot/PowerShell_BrocadeICX/Documentation/Function/Get-ICXSession.README.md
#>

function Get-ICXSession
{
    [CmdletBinding(DefaultParameterSetName='__AllParameterSets')]
    param(
        [Parameter(
            ParameterSetName='SessionID',
            Position=0,
            Mandatory=$true,
            HelpMessage='ID of the Brocade ICX session')]
        [Int32[]]$SessionID,

        [Parameter(
            ParameterSetName='ComputerName',
            Position=0,
            Mandatory=$true,
            HelpMessage='ComputerName of the Brocade ICX session')]
        [String[]]$ComputerName,

        [Parameter(
            ParameterSetName='ComputerName',
            Position=1,
            HelpMessage='ComputerName must match exactly')]
        [switch]$CaseSensitive,

        [Parameter(
            ParameterSetName='Search',
            Position=0,
            Mandatory=$true,
            HelpMessage='Search with wildcard (like "*")')]
        [String]$Search
    )

    Begin{

    }

    Process{
        # Temporary array to store Brocade ICX sessions - This is necessary to prevent an enumeration error when removing sessions with the pipe
        $ICXSessions = @()

        # Switch between the different parameter sets
        switch($PSCmdlet.ParameterSetName)
        {
            "SessionID" {
                Write-Verbose -Message "Filter Brocade ICX sessions using the ID."

                foreach($SessionID2 in $SessionID)
                {
                    foreach($ICXSession in $Global:BrocadeICXSessions)
                    {
                        if($ICXSession.SessionID -eq $SessionID2)
                        {
                            $ICXSessions += $ICXSession
                        }    
                    }
                }
            }
            "ComputerName" {
                Write-Verbose -Message "Filter Brocade ICX sessions using the ComputerName."

                foreach($ComputerName2 in $ComputerName)
                {
                    foreach($ICXSession in $Global:BrocadeICXSessions)
                    {
                        if((($CaseSensitive -eq $false) -and ($ICXSession.ComputerName -eq $ComputerName2)) -or ($ICXSession.ComputerName -ceq $ComputerName2))
                        {
                            $ICXSessions += $ICXSession
                        }
                    }
                }
            }
            "Search" {
                Write-Verbose -Message "Filter Brocade ICX sessions using the ComputerName. Placeholder like ""*"" will be considered."
                
                foreach($ICXSession in $Global:BrocadeICXSessions)
                {
                    if($ICXSession.ComputerName -like $Search)
                    {
                        $ICXSessions += $ICXSession
                    }
                }
            }
            default {
                Write-Verbose -Message "No Filter used. Return all Brocade ICX sessions."

                $ICXSessions += $Global:BrocadeICXSessions
            }
        }

        Write-Verbose -Message "$($ICXSessions.Count) Brocade ICX session(s) found!"

        $ICXSessions
    }

    End{

    }
}