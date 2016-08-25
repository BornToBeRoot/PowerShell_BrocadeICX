###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Get-ICXVLAN.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    
    .DESCRIPTION
    
    .EXAMPLE
        
    .EXAMPLE
    
    .LINK
    https://github.com/BornToBeRoot/PowerShell_BrocadeICX
#>

function Get-ICXVLAN
{
    [CmdletBinding(DefaultParameterSetName='ComputerName')]
    param(
        [Parameter(
            ParameterSetName='ComputerName',
            Position=0,
            Mandatory=$true,
            HelpMessage='Hostname or IPv4-Address of the Brocade ICX Switch')]
        [String]$ComputerName,

        [Parameter(
            ParameterSetName='Session',
            Position=0,
            ValueFromPipeline=$true,
            Mandatory=$true,
            HelpMessage='Brocade ICX session')]
        [pscustomobject]$Session,
        
        [Parameter(
            ParameterSetName='ComputerName',
            Position=1,
            HelpMessage='Accept the SSH key')]
        [switch]$AcceptKey,

        [Parameter(
            ParameterSetName='ComputerName',
            Position=2,
            HelpMessage='Credentials to authenticate agains the Brocade ICX Switch (SSH connection)')]
        [System.Management.Automation.PSCredential]
	    [System.Management.Automation.CredentialAttribute()]
	    $Credential
    )

    Begin{

    }

    Process{
        switch($PSCmdlet.ParameterSetName)
        {
            "ComputerName" {
                if($Credential -eq $null)
                {
                    # If no credentials are submitted by parameter, prompt the user to enter them
                    try{
                        $Credential = Get-Credential $null
                    }
                    catch{
                        Write-Error -Message "Entering credentials has been canceled by user. Can't establish SSH connection without credentials!" -Category AuthenticationError
                        return
                    }
                }

                try{
                    $Session = New-ICXSession -ComputerName $ComputerName -AcceptKey:$AcceptKey -Credential $Credential -ErrorAction Stop
                }
                catch
                {
                    Write-Error -Message "$($_.Exception.Message)" -Category ConnectionError                    
                }
            }

            "Session" {
                if(-not(Test-ICXSession -Session $Session))
                {
                    Write-Error -Message "Session ($Session) is not a valid Brocade ICX session or not managed by the BrocadeICX module!" -Category ConnectionError
                }
            }     
        }
    
        (Invoke-ICXCommand -Command "sh vlan" -Session $Session).Output
    }

    End{

    }
}