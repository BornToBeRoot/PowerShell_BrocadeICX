##################################################################################################################
###
### Module for Brocade Switches 
###
##################################################################################################################
#
#
#
##################################################################################################################
### Global Array for BrocadeSessions
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
	  [String]$Hostname, 
	  
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
	
  $created_SSH_Session = New-SSHSession -ComputerName $Hostname -Credential $Credentials -AcceptKey
  $SSH_Session = Get-SSHSession -Index $created_SSH_Session.SessionID
  $SSH_Stream = $SSH_Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
    
  $Session = New-Object -TypeName PSObject 
  Add-Member -InputObject $Session -MemberType NoteProperty -Name SessionID -Value $created_SSH_Session.SessionID
	 Add-Member -InputObject $Session -MemberType NoteProperty -Name Host -Value $created_SSH_Session.Host
  Add-Member -InputObject $Session -MemberType NoteProperty -Name Session -Value $SSH_Session
  Add-Member -InputObject $Session -MemberType NoteProperty -Name Stream -Value $SSH_Stream
    
  Invoke-BrocadeCommand $Session "skip-page-display" 300 | Out-Null
    
  $Global:BrocadeSessions.Add($Session) | Out-Null
	
  return $Session
}

##################################################################################################################
### Get-BrocadeSession
##################################################################################################################

function Get-BrocadeSession 
{
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
		    ParameterSetName='Hostname',
	    	Position=0,
		    Mandatory=$false)]
		[String[]]$Hostname,

    [Parameter(Mandatory=$false,
        ParameterSetName = 'Hostname',
        Position=1)]        
    [Switch]$ExactMatch
	)

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
						return $Session
					}
				}
			}
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

		if($PSBoundParameters.ContainsKey('Hostname'))
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

function Remove-BrocadeSession 
{
	[CmdletBinding()]
	param
  (
	  [Parameter(
		    Position=0,
		    Mandatory=$true,
		    HelpMessage="Brocade Session")]
		$Session
	)
	
	Remove-SSHSession -SessionId $Session.SessionID | Out-Null
	
	$Global:BrocadeSessions.Remove($Session)
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
		$Command,
		
	  [Parameter(
	    	Position=2,
		    Mandatory=$true,
		    HelpMessage="Wait time in milliseconds")]
		$WaitTime=0
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
    
	($Session.Stream.Read() -split '[\r\n]') |? {$_} 
}
