###############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  BrocadeConfigToTFTP.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Copy startup or running config to a TFTP-Server
# Repository   :  https://github.com/BornToBeRoot/..
###############################################################################################################

<#
    .SYNOPSIS
    Copy the running or startup configuration of all active brocade switch devices to a TFTP-Server.

    .DESCRIPTION    
    This script allowes you to scan your network (requieres ScanNetworksAsync.ps1) for all active switch devices,
    identify by the Parameter -SwitchIdentifier, and copy the startup or running configuration to a TFTP-Server.

    .EXAMPLE
    .\BrocadeConfigToTFTP.ps1 -TFTPServer 192.168.1.2 -StartIPAddress 192.168.2.100 -EndIPAddress 192.168.2.200 
    -ConfigToCopy Running

    .LINK

    https://github.com/BornToBeRoot/PowerShell-Async-IPScanner
    https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
    https://github.com/BornToBeRoot
#>

### Parameter ####################################################################################################

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
        Mandatory=$false,
        HelpMessage='Credentials for SSH connection to Brocade switch device')]
    [System.Management.Automation.PSCredential]$Credentials,

    [Parameter(
        Position=4,
        Mandatory=$false,
        HelpMessage='Switch Identifiert like XX_ (Only connect to devices whose hostname starts with XX_)')]
    [String]$SwitchIdentifier,
    
    [Parameter(
        Position=5,
        Mandatory=$true,
        HelpMessage='Copy startup or running config to tftp')]
    [ValidateSet('Startup', 'Running')]
    [String]$ConfigToCopy
)

##################################################################################################################
### Basic Informations to execute Script + Network Scan
##################################################################################################################

Begin{
    $Script_Startup_Path = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ScriptFileName = $MyInvocation.MyCommand.Name  
    $Timestamp = Get-Date -UFormat "%Y%m%d"

    # Get Credentials
    if($Credentials -eq $null)
		{		
			try{
				$Credentials = Get-Credential $null
			}catch{
				Write-Host "Entering credentials was aborted. Can't connect without credentials..." -ForegroundColor Red
				return
			}
	    }	
    
    # Scanning Network...
    $NetworkScan  = Invoke-Expression -Command "$Script_Startup_Path\ScanNetworkAsync.ps1 -StartIPAddress $StartIPAddress -EndIPAddress $EndIPAddress"
    if($NetworkScan -eq $null) 
    { 
        Write-Host "No active device found! Exit script..." -ForegroundColor Red
        exit
    }
        
    # Start with actual script
    $StartTime = Get-Date
    $DeviceCountSuccess = 0
    $DeviceCountFailed = 0
    
    Write-Host "`n`nStart: Script ($ScriptFileName) at $StartTime`n" -ForegroundColor Green
    
    Write-Host "Devices found..." -ForegroundColor Yellow
    
    $NetworkScan

    Write-Host "`nExecuting Commands on Switches..." -ForegroundColor Yellow
}

##################################################################################################################
### SSH Session, Save RunningConfig to TFTP, Close Session
##################################################################################################################

Process{    
    foreach($Switch in ($NetworkScan | Where-Object { $_.Status -eq "Up" -and $_.Hostname.ToLower().StartsWith($SwitchIdentifier.ToLower())}))
    {
        try{
            $Hostname = $Switch.Hostname.Split('.')[0]
        }catch{
            $Hostname = $Switch.Hostname
        }
	    
        Write-Host "`nDevice:`t`t`t$Hostname" -ForegroundColor Cyan
		
	    # Create new Brocade Session	
 	    $Session = New-BrocadeSession -ComputerName $Hostname -Credentials $Credentials

        if($Session -eq $null)
        {
            $DeviceCountFailed ++
            continue
        }

        $Command = [String]::Format("copy {0}-config tftp {1} {2}_{0}-config__{3}.bak", $ConfigToCopy.ToLower(), $TFTPServer, $Timestamp, $Hostname)
        Write-Host "Command:`t`t$Command" -ForegroundColor Cyan
	    Write-Host "`nStart:`tHost Output" -ForegroundColor Magenta

	    # Execute Command in Session
        Invoke-BrocadeCommand -Session $Session -Command $Command -WaitTime 5000

        Write-Host "End:`tHost Output" -ForegroundColor Magenta

	    # Close Brocade Session
        Remove-BrocadeSession -Session $Session

	    $DeviceCountSuccess ++	
	
	    Start-Sleep -Seconds 1
    }
}

##################################################################################################################
### Some cleanup and user output
##################################################################################################################
End{
    $Credentials = $null
    $EndTime = Get-Date
    
    # Calculate the time between Start and End
    $ExecutionTimeMinutes = (New-TimeSpan -Start $StartTime -End $EndTime).Minutes
    $ExecutionTimeSeconds = (New-TimeSpan -Start $StartTime -End $EndTime).Seconds

    Write-Host "`nExecuting Commands on Switches finished!" -ForegroundColor Yellow
    Write-Host "`n+----------------------------------------Result-----------------------------------------"
    Write-Host "|"
    Write-Host "|  Successful:`t$DeviceCountSuccess"
    Write-Host "|  Failed:`t$DeviceCountFailed"
    Write-Host "|"
    Write-Host "+---------------------------------------------------------------------------------------`n"
    Write-Host "Script duration:`t$ExecutionTimeMinutes Minutes $ExecutionTimeSeconds Seconds`n" -ForegroundColor Yellow
    Write-Host "End:`tScript ($ScriptFileName) at $EndTime" -ForegroundColor Green
}