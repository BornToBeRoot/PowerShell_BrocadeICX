###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Get-ICXVLAN.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Get VLANs from a Brocade ICX Switch
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    Get VLANs from a Brocade ICX Switch

    .DESCRIPTION
    Get VLANs from a Brocade ICX Switch as PSCustomObject, which can be further processed.

    .EXAMPLE
    Get-ICXVLAN -ComputerName megatron

    SessionID ComputerName ID   Name         By   TaggedPort                   UntaggedPort
    --------- ------------ --   ----         --   ----------                   ------------
            2 megatron     1001 Test1        port {0/1/1}                      {0/1/5, 0/1/6, 0/1/7, 0/1/8, ...}
            2 megatron     1002 Test2        port {0/1/1, 0/1/2, 0/1/3, 0/1/4} {0/1/11, 0/1/12, 0/1/13, 0/1/14, ...}
    
    .EXAMPLE
    $Session = Get-ICXSession -SessionID 0,2
    Get-ICXVLAN -Session $Session | Where-Object {$_.Name -eq "Test1"}

    SessionID ComputerName ID   Name         By   TaggedPort                   UntaggedPort
    --------- ------------ --   ----         --   ----------                   ------------
            0 megatron     1001 Test1        port {0/1/1}                      {0/1/5, 0/1/6, 0/1/7, 0/1/8, ...}
            2 megatron     1001 Test1        port {0/1/1}                      {0/1/5, 0/1/6, 0/1/7, 0/1/8, ...}

    .LINK
    https://github.com/BornToBeRoot/PowerShell_BrocadeICX/Documentation/Function/Get-ICXVLAN.README.md
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
        [String[]]$ComputerName,

        [Parameter(
            ParameterSetName='Session',
            Position=0,
            ValueFromPipeline=$true,
            Mandatory=$true,
            HelpMessage='Brocade ICX session')]
        [pscustomobject[]]$Session,
        
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
        function get_ICXVLAN {
            param(
                $Session
            )

            Begin{

            }

            Process{
                $Output = (Invoke-ICXCommand -Command "show running-config" -Session $Session).Output

                ### $Output
                ##################################
                # vlan 1 name DEFAULT-VLAN by port
                # !
                # vlan 1001 name Test1 by port
                #  tagged ethe 0/1/1
                #  untagged ethe 0/1/5 to 0/1/10
                # !
                # vlan 1002 name Test2 by port
                #  tagged ethe 0/1/1 to 0/1/4
                #  untagged ethe 0/1/11 to 0/1/20
                # !

                $VLAN_Detected = $false
                
                $VLAN_ID = [String]::Empty
                $VLAN_Name = [String]::Empty
                $VLAN_By = [String]::Empty   
                $VLAN_TaggedPort = @()
                $VLAN_UntaggedPort = @()

                # Parse the output and create a pscustomobject
                foreach($Line in $Output)
                {                   
                    $Line = $Line.Trim()

                    if($Line.StartsWith("vlan"))
                    {
                        $VLAN_Detected = $true
                        
                        Write-Verbose "VLAN found in line: ""$Line"""

                        $Line_Split = $Line.Split(" ")

                        ### $Line_Split
                        ###############
                        # vlan
                        # 1
                        # name
                        # Test1
                        # by
                        # port                           

                        for($i = 0; $i -lt ($Line_Split.Count - 1); $i++)
                        {
                            if($Line_Split[$i] -eq "vlan")
                            {
                                $VLAN_ID = $Line_Split[$i + 1]
                            }
                            elseif($Line_Split[$i] -eq "name")
                            {
                                $VLAN_Name = $Line_Split[$i + 1]
                            }
                            elseif($Line_Split[$i] -eq "by")
                            {
                                $VLAN_By = $Line_Split[$i + 1]
                            }
                        }
                    }
                    elseif($Line.StartsWith("tagged"))
                    {
                        Write-Verbose "Tagged ports found in line: $Line"

                        # Remove " to " and replace it with "-", then split
                        $Line_Split = $Line.Replace(" to ", "-").Split(" ")
                        
                        ### $Line_Split
                        #############
                        # tagged 
                        # ethe 
                        # 0/1/1-0/1/4              

                        for($i = 0; $i -lt ($Line_Split.Count - 1); $i++)
                        {
                            if($Line_Split[$i] -eq "ethe")
                            {
                                if($Line_Split[$i + 1].Contains("-"))
                                {
                                    $StackID = $Line_Split[$i + 1].Split("-")[0].Split("/")[0] 
                                    $Slot = $Line_Split[$i + 1].Split("-")[0].Split("/")[1]
                                    $StartPort = $Line_Split[$i + 1].Split("-")[0].Split("/")[2]
                                    $EndPort = $Line_Split[$i + 1].Split("-")[1].Split("/")[2]

                                    foreach($Port in $StartPort..$EndPort)
                                    {
                                        $VLAN_TaggedPort += [String]::Format("{0}/{1}/{2}", $StackID, $Slot, $Port)
                                    }
                                }
                                else 
                                {
                                    $VLAN_TaggedPort += $Line_Split[$i + 1]    
                                }
                            }
                        }
                    }
                    elseif($Line.StartsWith("untagged"))
                    {           
                        Write-Verbose "Untagged ports found in line: $Line"

                        # Remove " to " and replace it with "-", then split
                        $Line_Split = $Line.Replace(" to ", "-").Split(" ")
                        
                        ### $Line_Split
                        ###############
                        # untagged 
                        # ethe 
                        # 0/1/5-0/1/10

                        for($i = 0; $i -lt ($Line_Split.Count - 1); $i++)
                        {
                            if($Line_Split[$i] -eq "ethe")
                            {
                                if($Line_Split[$i + 1].Contains("-"))
                                {
                                    $StackID = $Line_Split[$i + 1].Split("-")[0].Split("/")[0] 
                                    $Slot = $Line_Split[$i + 1].Split("-")[0].Split("/")[1]
                                    $StartPort = $Line_Split[$i + 1].Split("-")[0].Split("/")[2]
                                    $EndPort = $Line_Split[$i + 1].Split("-")[1].Split("/")[2]

                                    foreach($Port in $StartPort..$EndPort)
                                    {
                                        $VLAN_UntaggedPort += [String]::Format("{0}/{1}/{2}", $StackID, $Slot, $Port)
                                    }
                                }
                                else 
                                {
                                    $VLAN_UntaggedPort += $Line_Split[$i + 1]    
                                }
                            }
                        }
                    }
                    elseif($VLAN_Detected -and $Line.StartsWith("!"))
                    {
                        $VLAN_Detected = $false

                        Write-Verbose "End of VLAN: $VLAN_ID ($VLAN_Name)!"

                        [pscustomobject] @{
                            SessionID = $Session.SessionID
                            ComputerName = $Session.ComputerName
                            ID = $VLAN_ID
                            Name = $VLAN_Name
                            By = $VLAN_By
                            TaggedPort = $VLAN_TaggedPort
                            UntaggedPort = $VLAN_UntaggedPort
                        }

                        # Clear the variale(s)/array(s)
                        $VLAN_ID = [String]::Empty
                        $VLAN_Name = [String]::Empty
                        $VLAN_By = [String]::Empty   
                        $VLAN_TaggedPort = @()
                        $VLAN_UntaggedPort = @()
                    }
                }
            }

            End{

            }
        }
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
                        throw "Entering credentials has been canceled by user. Can't establish SSH connection without credentials!"
                    }
                }
                       
                foreach($ComputerName2 in $ComputerName)
                {             
                    $ICXSession = New-ICXSession -ComputerName $ComputerName2 -AcceptKey:$AcceptKey -Credential $Credential
            
                    if($null -ne $ICXSession)
                    {
                        get_ICXVLAN -Session $ICXSession
                     
                        Remove-ICXSession -Session $ICXSession
                    }                    
                }                
            }
            
            "Session" {
                foreach($Session2 in $Session)
                {
                    if(Test-ICXSession -Session $Session2)
                    {
                        get_ICXVLAN -Session $Session2
                    }
                    else 
                    {
                        Write-Error -Message "Session ($Session2) is not a valid Brocade ICX session or not managed by the BrocadeICX module!" -Category ConnectionError
                    }
                }
            }
        }     
    }

    End{

    }
}