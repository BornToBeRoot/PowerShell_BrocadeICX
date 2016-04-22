###############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  Add-BrocadeVLAN.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Function to add a VLAN to a Brocade switch device
# Repository   :  https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
###############################################################################################################

<#
    .SYNOPSIS    
    Function to add a new VLAN to a Brocade switch device

    .DESCRIPTION                    
    Function to add a new VLAN to a Brocade switch device, with VLAN ID, VLAN Name and
	assign tagged and untagged ports. Before adding a new VLAN, it checks if the VLAN ID
	already exists.

    .EXAMPLE    
    Add-BrocadeVLAN -ComuterName TEST_DEVICE1 -VlanId 2222 -VlanName TestVLAN -VlanBy Port -Tagged 1/1/1 -Untagged 1/1/2-1/1/10,1/1/15,1/1/17

    .EXAMPLE
    Get-BrocadeSession | Add-BrocadeVLAN -VlanId 2222 -VlanName TestVLAN -VlanBy Port -Tagged 1/1/1 -Untagged 1/1/2-1/1/10,1/1/15,1/1/17
    
    .LINK    
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
#>
function Add-BrocadeVLAN
{
    [CmdletBinding(DefaultParameterSetName='ComputerName')]
    param(	
		[Parameter(
            Position=0,
            ParameterSetName='Session',
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage="Brocade session")]
		[PSObject]$Session,

		[Parameter(
            Position=0,
            ParameterSetName='ComputerName',
            Mandatory=$true,
            HelpMessage="Hostname or IP-Address of the Brocade switch device")]
		[String]$ComputerName,

        [Parameter(
            Position=1,
            Mandatory=$true,
            HelpMessage="VLAN ID")]
        [Int32]$VlanId,

        [Parameter(
            Position=2,
            Mandatory=$true,
            HelpMessage="VLAN Name")]
        [String]$VlanName,

        [Parameter(
            Position=3,
            Mandatory=$true,
            HelpMessage="By Port")]
        [ValidateSet('Port')]
        [String]$VlanBy,
       
        [Parameter(
            Position=4,
            Mandatory=$true,
            HelpMessage="Tagged Port")]    
        [String[]]$Tagged,

        [Parameter(
            Position=5,
            Mandatory=$false,
            HelpMessage="Untagged Ports")]
        [String[]]$Untagged,

		[Parameter(
            Position=6,
            ParameterSetName='ComputerName',
            HelpMessage="PSCredentials for SSH connection to Brocade switch device")]
		[System.Management.Automation.PSCredential]$Credentials
    ) 
    
    Begin{}
    Process
    {
        # Validate user input
        $Regex_Port = "[0-1]\/[0-1]\/[0-9]{1,2}"
        $Regex_PortRange = "[0-1]\/[0-1]\/[0-9]{1,2}-[0-1]\/[0-1]\/[0-9]{1,2}"        

        # Create command add vlan
        $Command_CreateVLAN = [String]::Format("vlan {0} name {1} by {2}", $VlanId, $VlanName, $VlanBy)        
       
        # Create command add tagged ports
        $Command_AddTagged = [String]::Format("tagged")

        foreach($TaggedPort in $Tagged)
        {
            if($TaggedPort -match $Regex_PortRange)
            {
                $Command_AddTagged += " ethernet " + $TaggedPort.Replace("-"," to ")
            }
            elseif($TaggedPort -match $Regex_Port)
            {
                $Command_AddTagged += " ethernet " + $TaggedPort
            }            
            else
            {
                Write-Host "Invalid input: $TaggedPort" -ForegroundColor Red
				return
			}            
        }

		if($Untagged -ne $null)
		{
			# Create command add untagged ports
			$Command_AddUntagged = [String]::Format("untagged")

			foreach($UntaggedPort in $Untagged)
			{
				if($UntaggedPort -match $Regex_PortRange)
				{
					$Command_AddUntagged += " ethernet " + $UntaggedPort.Replace("-"," to ")
				}
				elseif($UntaggedPort -match $Regex_Port)
				{
					$Command_AddUntagged += " ethernet " + $UntaggedPort    
				}
				else
				{
					Write-Host "Invalid input: $UntaggedPort" -ForegroundColor Red       
					return
				}       
			}
		}
		else
		{
			Write-Host "No untagged port is set" -ForegroundColor Yellow
		}

		# Create a new Brocade session
        if(($Session -eq $null) -and ($PSCmdlet.ParameterSetName -eq  'ComputerName'))
        {
			$Session = New-BrocadeSession -ComputerName $ComputerName -Credentials $Credentials
        }

        # Check if Brocade session is created
        if($Session -eq $null)
        {
			return 
        }

		# Check if Brocde 
		if((Get-BrocadeVLAN -Session $Session).Id -contains $VlanId)
		{
			Write-Host "VLAN $VlanId vorhanden" -ForegroundColor Red
		}
		else
		{
			# Invoke commands in Brocade session
			(Invoke-BrocadeCommand -Session $Session -Command "configure terminal" -WaitTime 500 -ShowExecutedCommand).Result
			(Invoke-BrocadeCommand -Session $Session -Command $Command_CreateVLAN -WaitTime 1000 -ShowExecutedCommand).Result
			(Invoke-BrocadeCommand -Session $Session -Command $Command_AddTagged -WaitTime 2000 -ShowExecutedCommand).Result

			if($Untagged -ne $null)
			{
				(Invoke-BrocadeCommand -Session $Session -Command $Command_AddUntagged -WaitTime 2000 -ShowExecutedCommand).Result
			}

			(Invoke-BrocadeCommand -Session $Session -Command "write memory" -WaitTime 1000 -ShowExecutedCommand).Result
			(Invoke-BrocadeCommand -Session $Session -Command "exit" -WaitTime 500 -ShowExecutedCommand).Result
				
			# Remove Brocade session if it was created by this function
			if($PSCmdlet.ParameterSetName -eq 'ComputerName')
			{
				Remove-BrocadeSession -Session $Session		
			} 			
		}
    }
    End{}
}