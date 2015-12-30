##################################################################################################################
###
### Module for Brocade Switches 
###
##################################################################################################################
#
#
#
##################################################################################################################
### Global Array for Brocade Sessions
##################################################################################################################

if (!(Test-Path Variable:Global:BrocadeSessions)) 
{
    $Global:BrocadeSessions = New-Object System.Collections.ArrayList
}

##################################################################################################################
### New-BrocadeSession
##################################################################################################################

function New-BrocadeSession
{
    [CmdletBinding()]
    param
    (
        [Parameter(
	        Position=0,
	        Mandatory=$true,
	        HelpMessage="Hostname or IP")]
	    [String]$ComputerName, 
	  
	    [Parameter(
	        Position=1,
	        Mandatory=$false,
	        HelpMessage="PSCredentials")]
        [System.Management.Automation.PSCredential]$Credentials
    )
     
    if($Credentials -eq $null)
	{
	    $Credentials = Get-Credential $null
    }	
	
    $created_SSH_Session = New-SSHSession -ComputerName $ComputerName -Credential $Credentials -AcceptKey
    $SSH_Session = Get-SSHSession -Index $created_SSH_Session.SessionID
    $SSH_Stream = $SSH_Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
    
    $Session = New-Object -TypeName PSObject 
    Add-Member -InputObject $Session -MemberType NoteProperty -Name SessionID -Value $created_SSH_Session.SessionID
	Add-Member -InputObject $Session -MemberType NoteProperty -Name Host -Value $created_SSH_Session.Host
    Add-Member -InputObject $Session -MemberType NoteProperty -Name Session -Value $SSH_Session
    Add-Member -InputObject $Session -MemberType NoteProperty -Name Stream -Value $SSH_Stream
    
    Invoke-BrocadeCommand -Session $Session -Command "skip-page-display" -WaitTime 300 | Out-Null
        
    $Global:BrocadeSessions.Add($Session) | Out-Null
	
    return $Session
}

##################################################################################################################
### Get-BrocadeSession
##################################################################################################################

function Get-BrocadeSession {
	[CmdletBinding(
        DefaultParameterSetName='SessionID')]

	param
    (
	    [Parameter(
		    ParameterSetName='SessionID',	
		    Position=0,
		    Mandatory=$false)]
		[Int32[]]$SessionID,
	
	    [Parameter(
		    ParameterSetName='ComputerName',
	    	Position=0,
		    Mandatory=$false)]
		[String[]]$ComputerName,

        [Parameter(Mandatory=$false,
            ParameterSetName = 'ComputerName',
            Position=1)]        
        [Switch]$ExactMatch
	)

	if($PSCmdlet.ParameterSetName -eq 'SessionID')
	{
		if($PSBoundParameters.ContainsKey('SessionID'))
		{
            $Sessions = @()

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

            return $Sessions
		}
		else
		{
			$Sessions = @()

			foreach($Session in $BrocadeSessions) 
			{
				$Sessions += $Session
			}
			
			return $Sessions
		}
	}
	else
	{
        $Sessions = @()

		if($PSBoundParameters.ContainsKey('ComputerName'))
		{
			foreach($Host in $Hostname)
			{
				foreach($Session in $BrocadeSessions)
				{
					if($Session.Host -like $Host -and (-not $ExactMatch -or $Session.Host -eq $Host))
					{
						$Sessions += $Session
					}
				}
			}
		}

        return $Sessions
	}
}

##################################################################################################################
### Remove-BrocadeSession
##################################################################################################################

function Remove-BrocadeSession {
	[CmdletBinding(DefaultParameterSetName='SessionID')]
	param
    (
        [Parameter(
            ParameterSetName='SessionID',
		    Position=0,
		    Mandatory=$true,
		    HelpMessage="Brocade Session")]
		[Int32[]]$SessionID,

	    [Parameter(
            ParameterSetName='Session',
		    Position=0,
		    Mandatory=$true,
		    HelpMessage="Brocade Session")]
		$Session
	)
    
    $Sessions2Remove = @()

    if($PSCmdlet.ParameterSetName -eq 'SessionID')
    {
        $Sessions2Remove = Get-BrocadeSession -SessionID $SessionID                        
    } 
    else
    {
        $Sessions2Remove = $Session
    }

    for($i = $Sessions2Remove.Count -1; $i -ge 0; --$i)
    {
        Remove-SSHSession -SessionId $Sessions2Remove[$i].SessionID | Out-Null
	
	    $Global:BrocadeSessions.Remove($Sessions2Remove[$i])	
    }
}

##################################################################################################################
### Invoke-BrocadeCommand
##################################################################################################################

function Invoke-BrocadeCommand
{ 
	[CmdletBinding()]
	param(
	    [Parameter(
		    Position=0,
		    Mandatory=$true,
		    HelpMessage="Brocade Session")]
		$Session,
		
    	[Parameter(
	    	Position=1,
	    	Mandatory=$true,
		    HelpMessage="Command to execute")]
		[String]$Command,
		
	    [Parameter(
	    	Position=2,
		    Mandatory=$true,
		    HelpMessage="Wait time in milliseconds")]
		[Int32]$WaitTime=0
	)

    if(-not($Command.EndsWith("`n")))
    { 
		$StreamCommand = $Command + "`n" 
	}
    else
	{ 
		$StreamCommand = $Command 
	}
        
    $Session.Stream.Write($StreamCommand)
	
    Start-Sleep -Milliseconds $WaitTime
    
	$Session.Stream.Read() -split '[\r\n]' |? {$_} 
}
