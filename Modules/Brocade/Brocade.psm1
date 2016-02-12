###############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  Brocade.psm1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Module with functions to manage Brocade Switch devices
# Repository   :  https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
###############################################################################################################

### Global array for Brocade sessions #########################################################################

if (!(Test-Path Variable:Global:BrocadeSessions)) 
{
    $Global:BrocadeSessions = New-Object System.Collections.ArrayList
}

### Integrade additional Brocade functions ####################################################################

. "$PSScriptRoot\BrocadeVLAN.ps1" 		   # Get-BrocadeVLAN 

### Function: New-BrocadeSession ##############################################################################

<#
    .SYNOPSIS    
    This function creates a new Brocade Session.
        
    .DESCRIPTION          
    This function creates a new Brocade Session over SSH (requieres the Posh-SSH module).
                    
    .EXAMPLE    
    New-BrocadeSession -ComputerName TEST_DEVICE1
        
    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
#>

function New-BrocadeSession
{
    [CmdletBinding()]
    param
    (
        [Parameter(
	        Position=0,
	        Mandatory=$true,
	        HelpMessage="Hostname or IP-Address of the Brocade Switch device")]
	    [String[]]$ComputerName, 
	  
	    [Parameter(
	        Position=1,
	        Mandatory=$false,
	        HelpMessage="PSCredentials for SSH connection to Brocade Switch device")]
        [System.Management.Automation.PSCredential]$Credentials
	)

    Begin{}
	Process
	{
	    if($Credentials -eq $null)
		{		
			try{
				$Credentials = Get-Credential $null
			}catch{
				Write-Host "Entering credentials was aborted. Can't connect without credentials..." -ForegroundColor Red
				return
			}
	    }	
		
		$Sessions = @()
		
		foreach($CurrentComputerName in $ComputerName)
		{
			try {
			   	$created_SSH_Session = New-SSHSession -ComputerName $CurrentComputerName -Credential $Credentials -AcceptKey
		    	$SSH_Session = Get-SSHSession -SessionId $created_SSH_Session.SessionID
		    	$SSH_Stream = $SSH_Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
		    }catch [Exception]{
				Write-Host $_.Exception.Message -ForegroundColor Red
				return
			}
			
            # Create a new Brocade Session Object
		    $Session = New-Object -TypeName PSObject 
		    Add-Member -InputObject $Session -MemberType NoteProperty -Name SessionID -Value $created_SSH_Session.SessionID
			Add-Member -InputObject $Session -MemberType NoteProperty -Name ComputerName -Value $created_SSH_Session.Host
		    Add-Member -InputObject $Session -MemberType NoteProperty -Name Session -Value $SSH_Session
		    Add-Member -InputObject $Session -MemberType NoteProperty -Name Stream -Value $SSH_Stream
		    
		    Invoke-BrocadeCommand -Session $Session -Command "skip-page-display" -WaitTime 300 | Out-Null
		        
		    $Global:BrocadeSessions.Add($Session) | Out-Null
			$Sessions += $Session
		}
		
	    return $Sessions
	}
	End{}
}


### Function: Get-BrocadeSession ##############################################################################

<#
    .SYNOPSIS    
    This function returns all or specific Brocade Sessions
        
    .DESCRIPTION           
    This function returns all or specific Brocade Sessions with SessionID, ComputerName, 
    Session and Stream
    
    .EXAMPLE    
    Get-BrocadeSession -SessionID 0,2

    .EXAMPLE    
    Get-BrocadeSession -ComputerName *TEST*

    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
#>

function Get-BrocadeSession {
	[CmdletBinding(DefaultParameterSetName='SessionID')]
	param
    (
	    [Parameter(
		    ParameterSetName='SessionID',	
		    Position=0,
		    Mandatory=$false,
            HelpMessage="Session ID of the Brocade Session ")]
		[Int32[]]$SessionID,
	
	    [Parameter(
		    ParameterSetName='ComputerName',
	    	Position=0,
		    Mandatory=$false,
            HelpMessage="Get all Brocade Sessions with specific ComputerName (Placeholder like * can be used)")]
		[String[]]$ComputerName,

        [Parameter(Mandatory=$false,
            ParameterSetName = 'ComputerName',
            Position=1,
            HelpMessage="ComputerName must match 100% (Placeholder are ignored)")]        
        [Switch]$ExactMatch
	)

    Begin{}
    Process
    {
     	$Sessions = @()
        
	    if($PSCmdlet.ParameterSetName -eq 'SessionID')
	    {
		    if($PSBoundParameters.ContainsKey('SessionID'))
		    {
    		    foreach($ID in $SessionID)
			    {
				    foreach($Session in $BrocadeSessions)
				    {
					    if($Session.SessionId -eq $ID)
					    {
						    $Sessions += $Session
					    }
				    }
			    }
		    }
		    else
		    {
			    foreach($Session in $BrocadeSessions) 
			    {
				    $Sessions += $Session
			    }
		    }
	    }
	    else
	    {
		    if($PSBoundParameters.ContainsKey('ComputerName'))
		    {
			    foreach($Name in $ComputerName)
			    {
				    foreach($Session in $BrocadeSessions)
				    {
					    if($Session.ComputerName -like $Name -and (-not $ExactMatch -or $Session.ComputerName -eq $Name))
					    {
						    $Sessions += $Session
					    }
				    }
			    }
		    }
	    } 
	
	    return $Sessions
    }
    End{}
}

### Remove-BrocadeSession #####################################################################################

<#
    .SYNOPSIS    
    This function removes an exiting Brocade Session
        
    .DESCRIPTION                    
    This function removes an exiting Brocade Session. Closing the SSHSession and
    remove the Brocade Session

    .EXAMPLE    
    Get-BrocadeSession | Remove-BrocadeSession

    .EXAMPLE    
    Remove-BrocadeSession -SessionID 0,2

    .EXAMPLE    
    Remove-BrocadeSession -Session $Session

    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
#>

function Remove-BrocadeSession {
	[CmdletBinding(DefaultParameterSetName='Session')]
	param
    (
        [Parameter(
            ParameterSetName='SessionID',
		    Position=0,
			ValueFromPipelineByPropertyName=$true,	
		    Mandatory=$true,
		    HelpMessage="ID of the Brocade Session")]
		[Int32[]]$SessionID,

	    [Parameter(
            ParameterSetName='Session',
		    Position=0,
			ValueFromPipeline=$true,
			Mandatory=$true,
		    HelpMessage="Brocade Session")]
		[PSObject[]]$Session
	)

    Begin{}
    Process{    
        $Sessions2Remove = @()

        if($PSCmdlet.ParameterSetName -eq 'SessionID')
        {
            $Sessions2Remove += Get-BrocadeSession -SessionID $SessionID
        } 
        else
        {
            foreach($CurrentSession in $Session)
            {
                $Sessions2Remove += $CurrentSession
            }
        }
	
	    foreach($Session2Remove in $Sessions2Remove)
	    {
		    Remove-SSHSession -SessionId $Session2Remove.SessionID | Out-Null
	
	        $Global:BrocadeSessions.Remove($Session2Remove)
	    }
    }
    End{}
}

### Invoke-BrocadeCommand #####################################################################################

<#
    .SYNOPSIS    
    This function invokes a commend into an existing Brocade Session.
        
    .DESCRIPTION    
    With this function you can invoke a switch command over SSH into a Brocade Session.
                    
    .EXAMPLE
    Invoke-BrocadeCommand -Session $Session -Command "sh ver" -WaitTime 2000
    
    .EXAMPLE
    Get-BrocadeSession | Invoke-Command -Command "show version" -WaitTime 2000
    
    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
#>

function Invoke-BrocadeCommand
{ 
	[CmdletBinding()]
	param(
	    [Parameter(
		    Position=0,
            ValueFromPipeline=$true,
			Mandatory=$true,
            HelpMessage="Brocade Session")]
		[PSObject[]]$Session,
		
    	[Parameter(
	    	Position=1,
	    	Mandatory=$true,
		    HelpMessage="Command to execute on Brocade Switch device")]
		[String]$Command,
		
	    [Parameter(
	    	Position=2,
		    Mandatory=$false,
		    HelpMessage="Wait time in milliseconds")]
		[Int32]$WaitTime=1000
	)

    Begin{}
    Process{
        
            if(-not($Command.EndsWith("`n")))
            { 
		        $StreamCommand = $Command + "`n" 
	        }
            else
	        { 
		        $StreamCommand = $Command 
	        }

            foreach($CurrentSession in $Session)
            {
                $Session.Stream.Write($StreamCommand)
	
                Start-Sleep -Milliseconds $WaitTime
    
	            $Session.Stream.Read() -split '[\r\n]' |? {$_} 
            }
    }
    End{}
}