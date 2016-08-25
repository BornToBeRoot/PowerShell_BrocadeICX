###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Test-ICXSession.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Test if a session is a valid Brocade ICX session
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    Test if a session is a valid Brocade ICX session

    .DESCRIPTION
    Test if a session is a valid Brocade ICX session and managed by the BrocadeICX module.

    .EXAMPLE
    $Session = Get-ICXSession -SessionID 0
    Test-ICXSession -Session $Session
    
    true

    .EXAMPLE
    "Test" | Test-ICXSessions

    false

    .LINK
     https://github.com/BornToBeRoot/PowerShell_BrocadeICX/Documentation/Function/Test-ICXSession.README.md
#>

function Test-ICXSession
{
    [CmdletBinding()]
    [OutputType('System.Boolean')]
    param(
        [Parameter(
            Position=0,
            ValueFromPipeline=$true,
            Mandatory=$true,
            HelpMessage='Brocade ICX session')]
        [pscustomobject]$Session        
    )

    Begin{

    }

    Process{
        Write-Verbose -Message "Check if session is a valid Brocade ICX session..."

        # Go through each Brocade ICX session
        foreach($ICXSession in $Global:BrocadeICXSessions)
        {             
            if($ICXSession -eq $Session)
            {
                Write-Verbose -Message "Valid Brocade ICX session found!"
                return $true
            }
        }       

        Write-Verbose -Message "No valid Brocade ICX session found!"
        return $false
    }

    End{

    }
}