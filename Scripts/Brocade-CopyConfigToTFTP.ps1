###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Brocade-CopyConfigToTFTP.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Script to copy startup or running config to a TFTP-Server
# Repository   :  https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
###############################################################################################################


### Requirements ##############################################################################################
#
# - Posh-SSH (Module)
# - Brocade (Module)
# - ScanNetworkAsync.ps1 (Script)
#
###############################################################################################################

<#
    .SYNOPSIS
    Script to copy the running or startup config to a TFTP-Server. Useful as automatic backup using 
	windows task.

    .DESCRIPTION    
    This script allowes you to scan your network (requieres ScanNetworksAsync.ps1) for all active switch devices,
    identify by the Parameter -SwitchIdentifier, and copy the startup or running configuration to a TFTP-Server.
	Useful as automatic backup script using windows task.

	Requirements:
	- Posh-SSH (Module)
    - Brocade (Module)
    - ScanNetworkAsync.ps1 (Script)

    .EXAMPLE
    .\Brocade-CopyConfigToTFTP.ps1 -TFTPServer 192.168.1.2 -StartIPAddress 192.168.2.100 -EndIPAddress 192.168.2.200 
    -ConfigToCopy Running

    .LINK
    https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
    https://github.com/BornToBeRoot
#>

[CmdletBinding()]
param(
	[Parameter(
		Position=0,
		Mandatory=$true,
		HelpMessage='TFTP-Server IP-Address like 192.168.0.10')]
	[String]$TFTPServer,
	
	[Parameter(
		Position=1,
		Mandatory=$true,
		HelpMessage='Start IP-Address like 192.168.0.100')]
	[String]$StartIPAddress,
	
	[Parameter(
		Position=2,
		Mandatory=$true,
		HelpMessage='End IP-Address like 192.168.0.200')]
	[String]$EndIPAddress,

    [Parameter(
        Position=3,
        HelpMessage='Credentials for SSH connection to Brocade switch device')]
    [System.Management.Automation.PSCredential]$Credentials,

	[Parameter(
        Position=4,
        Mandatory=$true,
        HelpMessage='Copy startup or running config to tftp')]
    [ValidateSet('Startup', 'Running')]
    [String]$ConfigToCopy,

    [Parameter(
        Position=5,
        HelpMessage='Switch identifier like XX_ (Only connect to devices whose hostname starts with XX_)')]
    [String]$SwitchIdentifier
)

Begin{	
    $Script_Startup_Path = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ScriptFileName = $MyInvocation.MyCommand.Name  
    $Timestamp = Get-Date -UFormat "%Y%m%d"
	
	# Path to the ScanNetworkAsync.ps1-script (should be placed in the same directory)
	$ScanNetworkAsync_Path = "$Script_Startup_Path\ScanNetworkAsync.ps1"
			
    # Get-Credentials for ssh session
    if($Credentials -eq $null)
	{		
		try{
			$Credentials = Get-Credential $null
		}
		catch{
			Write-Host "Entering credentials was aborted. Can't connect without credentials! Exit script..." -ForegroundColor Red
			exit
		}
	}	
    
    # Check if ScanNetworkAsync.ps1 script exists
	if(-not(Test-Path -Path $ScanNetworkAsync_Path))
	{		
		Write-Host "Async IP-Scanner script not found! Exit script..." -ForegroundColor Red
		exit
	}
	
	# Scan IP-Range with switch devices
    $NetworkScan  = Invoke-Expression -Command "$ScanNetworkAsync_Path -StartIPAddress $StartIPAddress -EndIPAddress $EndIPAddress"

    if($NetworkScan -eq $null) 
    { 
		Write-Host "No devices found! Exit script..." -ForegroundColor Red
		exit
    }
		
    # Start with actual script
    $StartTime = Get-Date
    $DeviceCountSuccess = 0
    $DeviceCountFailed = 0
    
	Write-Host "`n`nScript ($ScriptFileName) started at $StartTime`n" -ForegroundColor Green
    Write-Host "Devices found..." -ForegroundColor Yellow
	$NetworkScan # Show result of the network scan
	Write-Host "`nExecuting Commands on switches..." -ForegroundColor Yellow	
}

Process{    
	# Go through every active Brocade device
    foreach($Switch in ($NetworkScan | Where-Object { $_.Status -eq "Up" -and $_.Hostname.ToLower().StartsWith($SwitchIdentifier.ToLower())}))
    {
		# Get the hostname
        try{
            $Hostname = $Switch.Hostname.Split('.')[0]
        }
		catch{
            $Hostname = $Switch.Hostname
        }
	    		
        Write-Host "`nDevice:`t`t`t$Hostname" -ForegroundColor Cyan
		
	    # Create a new Brocade session	
 	    $Session = New-BrocadeSession -ComputerName $Hostname -Credentials $Credentials

		# Check if session could be established
        if($Session -eq $null)
        {
            $DeviceCountFailed ++
            continue # go to next device
        }

		# Create command
        $Command = [String]::Format("copy {0}-config tftp {1} {2}_{0}-config__{3}.bak", $ConfigToCopy.ToLower(), $TFTPServer, $Timestamp, $Hostname)
        		
		Write-Host "Command:`t`t$Command" -ForegroundColor Cyan
	    Write-Host "`nStart:`tHost output" -ForegroundColor Magenta
		
	    # Execute command on switch
        (Invoke-BrocadeCommand -Session $Session -Command $Command -WaitTime 5000).Result
		
        Write-Host "End:`tHost output" -ForegroundColor Magenta
		
	    # Close Brocade session
        Remove-BrocadeSession -Session $Session

	    $DeviceCountSuccess ++	
    }
}

End{
	# Clear credentials (should be done by garbage collector, but better safe than sorry)
	$Credentials = $null
    
	# Calculate the time between Start and End
	$EndTime = Get-Date
    $ExecutionTimeMinutes = (New-TimeSpan -Start $StartTime -End $EndTime).Minutes
    $ExecutionTimeSeconds = (New-TimeSpan -Start $StartTime -End $EndTime).Seconds

    Write-Host "`nExecuting Commands on Switches finished!" -ForegroundColor Yellow
    Write-Host "`n+=-=-=-=-=-=-=-=-=-=-=-=-=  Result  =-=-=-=-=-=-=-=-=-=-=-=-=`n|"
    Write-Host "|  Successful:`t$DeviceCountSuccess"
    Write-Host "|  Failed:`t$DeviceCountFailed"
    Write-Host "|`n+============================================================`n"
    Write-Host "Script duration:`t$ExecutionTimeMinutes Minutes $ExecutionTimeSeconds Seconds`n" -ForegroundColor Yellow
    Write-Host "Script ($ScriptFileName) exit at $EndTime`n" -ForegroundColor Green
}