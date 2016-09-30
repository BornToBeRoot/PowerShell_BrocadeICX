###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Get-ICXVLAN.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Get VLAN(s) from a Brocade ICX Switch
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    Get VLAN(s) from a Brocade ICX Switch

    .DESCRIPTION
    Get VLAN(s) from a Brocade ICX Switch as PSCustomObject, which can be further processed.

    .EXAMPLE
    Get-ICXVLAN -ComputerName megatron | ? {$_.Name -eq "Test1"} | ft

    ID   Name  By   TaggedPort UntaggedPort
    --   ----  --   ---------- ------------
    1001 Test1 port {0/1/4}    {0/1/37, 0/1/39, 0/1/45, 0/1/46}
    
    .EXAMPLE
    New-ICXSession -ComputerName MEGATRON, megatron
    Get-ICXVLAN -Session (Get-ICXSession) | ? {$_.Name -eq "Test1"} | ft

    SessionID ComputerName ID   Name  By   TaggedPort UntaggedPort
    --------- ------------ --   ----  --   ---------- ------------
            0 MEGATRON     1001 Test1 port {0/1/4}    {0/1/37, 0/1/39, 0/1/45, 0/1/46}
            1 megatron     1001 Test1 port {0/1/4}    {0/1/37, 0/1/39, 0/1/45, 0/1/46}

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
                $Session,
                $DefaultDisplaySet
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

                        $ICXVLAN = [pscustomobject] @{
                            SessionID = $Session.SessionID
                            ComputerName = $Session.ComputerName
                            Id = $VLAN_ID
                            Name = $VLAN_Name
                            By = $VLAN_By
                            TaggedPort = $VLAN_TaggedPort
                            UntaggedPort = $VLAN_UntaggedPort
                        }

                        #  Set the default parameter set
                        $ICXVLAN.PSObject.TypeNames.Insert(0,'BrocadeICX.ICXVLAN')
                        $DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$DefaultDisplaySet)
                        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)
                        $ICXVLAN | Add-Member MemberSet PSStandardMembers $PSStandardMembers

                        $ICXVLAN

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
        
        $DefaultDisplaySet = 'ID', 'Name', 'By', 'TaggedPort', 'UntaggedPort'

        if($Session.Count -gt 1 -or $ComputerName.Count -gt 1)
        {
            $DefaultDisplaySet = 'SessionID', 'ComputerName' + $DefaultDisplaySet
        }

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
                        get_ICXVLAN -Session $ICXSession -DefaultDisplaySet $DefaultDisplaySet
                     
                        Remove-ICXSession -Session $ICXSession
                    }                    
                }                
            }
            
            "Session" {
                foreach($Session2 in $Session)
                {
                    if(Test-ICXSession -Session $Session2)
                    {
                        get_ICXVLAN -Session $Session2 -DefaultDisplaySet $DefaultDisplaySet
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