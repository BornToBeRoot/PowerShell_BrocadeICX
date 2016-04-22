###############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  Get-BrocadeVLAN.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Function to get all VLANs of the Brocade switch device
# Repository   :  https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
###############################################################################################################

<#
    .SYNOPSIS    
    Function to get all VLANs of a Brocade switch device

    .DESCRIPTION                    
    Function to get all VLANs (with settings) of a Brocade switch device, include
    VLAN ID, Name, Tagged and Untagged Ports

    .EXAMPLE    
    Get-BrocadeVLAN -Session $Session

    .EXAMPLE
    Get-BrocadeVLAN -ComputerName TEST_DEVICE1

    .EXAMPLE
    Get-BrocadeSession | Get-BrocadeVLAN
    
    .LINK    
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell-SSH-Brocade
#>
function Get-BrocadeVLAN 
{
    [CmdletBinding(DefaultParameterSetName='ComputerName')]
    param(
        [Parameter(
            Position=0,
            ParameterSetName='Session',
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage="Brocade-Session")]
            [PSObject]$Session,

        [Parameter(
            Position=0,
            ParameterSetName='ComputerName',
            Mandatory=$true,
            HelpMessage="Hostname or IP-Address of the Brocade Switch device")]
            [String]$ComputerName,

        [Parameter(
            Position=1,
            ParameterSetName='ComputerName',
            HelpMessage="PSCredentials for SSH-Connection to Brocade Switch device")]
            [System.Management.Automation.PSCredential]$Credentials                       
    )

    Begin{}
    Process
    {
		# Create a new Brocade session
        if($PSCmdlet.ParameterSetName -eq 'ComputerName')
        {
            $Session = New-BrocadeSession -ComputerName $ComputerName -Credentials $Credentials
        }

        # Check if Session is created   
        if($Session -eq $null)
        {
            return
        }    

		# Get running config from Brocade switch
        $RunningConfig = (Invoke-BrocadeCommand -Session $Session -Command "show running-config").Result

        $Raw_VLANs = @()
        $LineBelongsToVLAN = $false
    
        ### Filter Running Config for ###
        # !
        # vlan 1111 name TEST by port
        #  tagged ethe 1/1/1
        #  untagged ethe 1/1/2 to 1/1/48
        # !
         
        foreach($Line in $RunningConfig)
        {
            if($Line.StartsWith('vlan'))
            {
                $LineBelongsToVLAN = $true

                $Raw_VLAN = $Line.Trim()
            }
            elseif(($Line.StartsWith('!')) -and ($LineBelongsToVLAN -eq $true))
            {
                $Raw_VLANs += $Raw_VLAN

                $LineBelongsToVLAN = $false
            }
            else
            {
                $Raw_VLAN += ";" + $Line.Trim()
            }
        } 
           
        ### Raw_VLAN ###
        # vlan 1111 name TEST by port;tagged ethe 1/1/1;untagged ethe 1/1/2 to 1/1/48
  
        $VLANs = @()   
    
        # Get Values from each VLAN
        foreach($Raw_VLAN in $Raw_VLANs)
        {     
            $VLAN_ID = [String]::Empty
            $VLAN_NAME = [String]::Empty
            $VLAN_BY = [String]::Empty
            $VLAN_TAGGED_PORT = @()
            $VLAN_UNTAGGED_PORT = @()
                        
            foreach($Line in $Raw_VLAN.Split(';'))
            {
                ### Raw_VLAN Split ###
                # vlan 1111 name TEST by port
                # tagged ethe 1/1/1
                # untagged ethe 1/1/2 to 1/1/48

                if($Line.StartsWith('vlan'))
                {
                    $Line_Split = $Line.Split(' ')
                    
                    ### Line Split ###
                    # vlan
                    # 1111
                    # name
                    # TEST
                    # by 
                    # port
                    
                    for($i = 0; $i -lt $Line_Split.Count ; $i++)
                    {
                        if($Line_Split[$i] -eq 'vlan')
                        {
                            $VLAN_ID = $Line_Split[$i + 1]
                        }
                        elseif($Line_Split[$i] -eq 'name')
                        {
                            $VLAN_NAME = $Line_Split[$i + 1]
                        }
                        elseif($Line_Split[$i] -eq 'by')
                        {
                            $VLAN_BY = $Line_Split[$i + 1]
                        }
                    }
                }
			    elseif($Line.StartsWith('tagged'))
			    {
                    $Line = $Line.Replace(" to ",  "-")

                    $Line_Split = $Line.Split(' ')
                
                    ### Line Split ###
                    # tagged 
                    # ethe
                    # 1/1/1
                    
                    for($i = 0; $i -lt $Line_Split.Count; $i++)
                    {
                        if($Line_Split[$i] -eq 'ethe')
                        {
                            if($Line_Split[$i + 1].Contains('-'))
                            {              
                                # Split Ranges in indiviudal Ports (1/1/2-1/1/4 >> 1/1/2,1/1/3,1/1/4)
                                $StartAndEndPort = $Line_Split[$i + 1].Split('-')

                                $StartPort = $StartAndEndPort[0].Split('/')
                                $EndPort = $StartAndEndPort[1].Split('/')

                                foreach($Port in $StartPort[2]..$EndPort[2])
                                {
                                   $VLAN_TAGGED_PORT += $StartPort[0] + "/" + $StartPort[1] + "/" + $Port
                                }
                            }
                            else
                            {
                                $VLAN_TAGGED_PORT += $Line_Split[$i + 1]
                            }
                        }
                    }                
			    }
        	    elseif($Line.StartsWith('untagged'))
			    {
			        $Line = $Line.Replace(" to ", "-")

                    $Line_Split = $Line.Split(' ')

                    ### Line Split ###
                    # untagged
                    # ethe
                    # 1/1/2-1/1/48
                    
                    for($i = 0; $i -lt $Line_Split.Count; $i++)
                    {
                        if($Line_Split[$i] -eq 'ethe')
                        {
                            if($Line_Split[$i + 1].Contains('-'))
                            {              
                                # Split Ranges in indiviudal Ports (1/1/2-1/1/4 >> 1/1/2,1/1/3,1/1/4)
                                $StartAndEndPort = $Line_Split[$i + 1].Split('-')

                                $StartPort = $StartAndEndPort[0].Split('/')
                                $EndPort = $StartAndEndPort[1].Split('/')

                                foreach($Port in $StartPort[2]..$EndPort[2])
                                {
                                   $VLAN_UNTAGGED_PORT += $StartPort[0] + "/" + $StartPort[1] + "/" + $Port
                                }
                            }
                            else
                            {
                                $VLAN_UNTAGGED_PORT += $Line_Split[$i + 1]
                            }
                        }
                    }
			    }
		    } 
        
            # Create VLAN Object
            $VLAN = New-Object -TypeName PSObject 
            Add-Member -InputObject $VLAN -MemberType NoteProperty -Name Id -Value $VLAN_ID
            Add-Member -InputObject $VLAN -MemberType NoteProperty -Name Name -Value $VLAN_NAME
            Add-Member -InputObject $VLAN -MemberType NoteProperty -Name By -Value $VLAN_BY
            Add-Member -InputObject $VLAN -MemberType NoteProperty -Name Tagged -Value $VLAN_TAGGED_PORT
            Add-Member -InputObject $VLAN -MemberType NoteProperty -Name Untagged -Value $VLAN_UNTAGGED_PORT
            
            $VLANs += $VLAN
        }

        # Remove Brocade session if it was created by this function
        if($PSCmdlet.ParameterSetName -eq 'ComputerName')
        {
            Remove-BrocadeSession -Session $Session		
        }

        return $VLANs
    }
    End{}
}