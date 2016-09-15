###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Remove-ICXSession.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Remove a Brocade ICX session
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    Remove a Brocade ICX session

    .DESCRIPTION
    Remove one or multiple Brocade ICX sessions.

    .EXAMPLE
    Remove-ICXSession -SessionID 1

    .EXAMPLE
    Get-ICXSession | Remove-ICXSession
        
    .EXAMPLE
    Remove-ICXSession -ComputerName megatron
    
    .LINK
    https://github.com/BornToBeRoot/PowerShell_BrocadeICX/Documentation/Function/Remove-ICXSession.README.md
#>

function Remove-ICXSession
{
    [CmdletBinding(DefaultParameterSetName='SessionID')]
    param(
        [Parameter(
            ParameterSetName='SessionID',
            Position=0,
            ValueFromPipelineByPropertyName=$true,
            Mandatory=$true,
            HelpMessage='ID of the Brocade ICX session')]
        [Int32[]]$SessionID,

        [Parameter(
            ParameterSetName='ComputerName',
            Position=0,
            ValueFromPipelineByPropertyName=$true,
            Mandatory=$true,
            HelpMessage='ComputerName of the Brocade ICX session')]
        [String[]]$ComputerName,

        [Parameter(
            ParameterSetName='ComputerName',
            Position=1,
            HelpMessage='ComputerName must match exactly')]
        [switch]$CaseSensitive,

        [Parameter(
            ParameterSetName='Session',
            Position=0,
            ValueFromPipeline=$true,
            Mandatory=$true,
            HelpMessage='Brocade ICX session')]
        [pscustomobject[]]$Session        
    )

    Begin{

    }

    Process{
        # Temporary array to store Brocade ICX sessions which are removed
      	$ICXSessions2Remove = @()

        # Switch between the different parameter sets 
        switch($PSCmdlet.ParameterSetName)
        {
            "SessionID" {   
                $ICXSessions2Remove += Get-ICXSession -SessionID $SessionID
            }
            "ComputerName"{                
                $ICXSessions2Remove += Get-ICXSession -ComputerName $ComputerName -CaseSensitive:$CaseSensitive
            }          
            "Session" {                
                foreach($Session2 in $Session)
                {
                    if(Test-ICXSession -Session $Session2)
                    {                        
                        $ICXSessions2Remove += $Session2
                    }                        
                    else 
                    {                        
                        Write-Host -Object "Session ($Session2) is not a valid Brocade ICX session or not managed by the BrocadeICX module!" -ForegroundColor Red
                    }                       
                }
            }                
        }

        # Remove the Brocade ICX sessions
        if($ICXSessions2Remove.Count -gt 0)
        {
            Write-Verbose -Message "$($ICXSessions2Remove.Count) Brocade ICX session(s) to remove."

            foreach($ICXSession2Remove in $ICXSessions2Remove)
            {      
                Write-Verbose -Message "Remove Brocade ICX session: $ICXSession2Remove"

                # Closing the underlying SSH connection
                Write-Verbose -Message "Closing the underlying SSH session..."
                [void](Remove-SSHSession -SessionId $ICXSession2Remove.SessionID)

                # Remove the Brocade ICX session from the global array
                Write-Verbose -Message "Remove Brocade ICX session from the global Brocade ICX sessions..."
                $Global:BrocadeICXSessions.Remove($ICXSession2Remove)

                Write-Verbose -Message "Brocade ICX session removed!"
            }
        }
    }

    End{

    }
}