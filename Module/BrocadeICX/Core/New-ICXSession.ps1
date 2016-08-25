###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  New-ICXSession.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Create a new Brocade ICX sessions over SSH
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    Create a new Brocade ICX sessions over SSH

    .DESCRIPTION
    Create one or multiple Brocade ICX session over SSH. If no credentials are submitted, a credential popup will appear.

    .EXAMPLE
    New-ICXSession -ComputerName megatron  
    
    SessionID ComputerName Session        Stream
    --------- ------------ -------        ------
            0 megatron     SSH.SshSession Renci.SshNet.ShellStream

    .LINK
    https://github.com/BornToBeRoot/PowerShell_BrocadeICX/Documentation/Function/New-ICXSession.README.md
#>

function New-ICXSession
{
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='Hostname or IPv4-Address of the Brocade ICX Switch')]
        [String[]]$ComputerName,

        [Parameter(
            Position=1,
            Mandatory=$false,
            HelpMessage='Accept the SSH key')]
        [switch]$AcceptKey,

        [Parameter(
            Position=2,
            Mandatory=$false,
            HelpMessage='Credentials to authenticate agains a Brocade ICX Switch (SSH connection)')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )

    Begin{

    }

    Process{
        # If no credentials are submitted by parameter, prompt the user to enter them
        if($Credential -eq $null)
        {
            try{
                $Credential = Get-Credential $null
            }
            catch{
                throw "Entering credentials has been canceled by user. Can't establish SSH connection without credentials!"
            }
        }
        
        Write-Verbose -Message "Accept key is set to: $AcceptKey"

        # Create a new Brocade ICX session for each Switch
        foreach($ComputerName2 in $ComputerName)
        {
            Write-Verbose -Message "Create new SSH session for ""$ComputerName2""."

            try{
                if($AcceptKey)
                {
                    $Created_SSHSession = New-SSHSession -ComputerName $ComputerName2 -Credential $Credential -AcceptKey -ErrorAction Stop
                }
                else 
                {
                    $Created_SSHSession = New-SSHSession -ComputerName $ComputerName2 -Credential $Credential -ErrorAction Stop
                }

                $SSHSession = Get-SSHSession -SessionId $Created_SSHSession.SessionID

                Write-Verbose -Message "Creating shell stream for ""$ComputerName2""..."
                $SSHStream = $SSHSession.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
            }
            catch{
                Write-Error -Message "$($_.Exception.Message)" -Category ConnectionError
                continue
            }

            # Create a new Brocade ICX session object
            $ICXSession = [pscustomobject] @{
                SessionID = $Created_SSHSession.SessionID
                ComputerName = $ComputerName2
                Session = $SSHSession
                Stream = $SSHStream
            }
                    
            # Add it to the global Brocade ICX sessions array
            Write-Verbose -Message "Add session ($ICXSession) to global Brocade ICX sessions..."
         	[void]$Global:BrocadeICXSessions.Add($ICXSession)

            # Make output easier to process
            [void](Invoke-ICXCommand -Session $ICXSession -Command "skip-page-display")
            
            Write-Verbose -Message "Brocade ICX session created!"

            # Return the created Brocade ICX session
            $ICXSession
        }       
    }

    End{

    }
}