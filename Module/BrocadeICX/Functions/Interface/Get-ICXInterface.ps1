###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Get-ICXInterface.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Get interface(s) from a Brocade ICX Switch
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    Get interface(s) from a Brocade ICX Switch

    .DESCRIPTION
    Get interface(s) from a Brocade ICX Switch with status [up|down], speed [1G|100M|10M] etc.

    .EXAMPLE
    Get-ICXInterface -ComputerName megatron | Select-Object -First 5 | Format-Table

    Port  Link State   Duplex Speed Trunk Tag Pvid Priority MAC            Name
    ----  ---- -----   ------ ----- ----- --- ---- -------- ---            ----
    0/1/1 Up   Forward Full   1G    None  Yes N/A  0        0000.0000.0000 UPLINK
    0/1/2 Up   Forward Full   1G    None  No  1001 0        0000.0000.0001
    0/1/3 Up   Forward Full   100M  None  No  1001 0        0000.0000.0002
    0/1/4 Down None    None   None  None  No  1    0        0000.0000.0003
    0/1/5 Up   Forward Full   1G    None  No  1001 0        0000.0000.0004

    .LINK
    https://github.com/BornToBeRoot/PowerShell_BrocadeICX/Documentation/Function/Get-ICXInterface.README.md
#>

function Get-ICXInterface
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
        function get_ICXInterface {
            param(
                $Session,
                $DefaultDisplaySet
            )

            $Output = (Invoke-ICXCommand -Command "show interface brief" -Session $Session).Output

            foreach($Line in $Output)
            {
                # Only process lines that start with "x\x\xx"
                if($Line -match "^[0-9]\/[0-9]\/[0-9]{1,2}")
                {
                    # Line looks like this "x/x/xx   Down    None    None None  None  No  1    0   xxxx.xxxx.xxxx
                    # Replace white spaces and split it
                    $Line_Split = ($Line -replace '\s+', ' ').Split(" ")

                    ### $Line_Split 
                    ###############
                    # Port
                    # Link
                    # State
                    # Duplex
                    # Speed
                    # Trunk
                    # Tag
                    # Pvid
                    # Priority
                    # MAC
                    # Name

                    # If port-name has spaces...
                    $Name = [String]::Empty

                    foreach($Line_Name in $Line_Split[10..($Line_Split.Count -1)]) 
                    { 
                        $Name += $Line_Name + " "
                    } 

                    $ICXInterface = [pscustomobject] @{
                        SessionID = $Session.SessionID
                        ComputerName = $Session.ComputerName
                        Port = $Line_Split[0]
                        Link = $Line_Split[1]
                        State = $Line_Split[2]
                        Duplex = $Line_Split[3]
                        Speed = $Line_Split[4]
                        Trunk = $Line_Split[5]
                        Tagged = $Line_Split[6]
                        Pvid = $Line_Split[7]
                        Priority = $Line_Split[8]
                        MAC = $Line_Split[9]
                        Name = $Name.TrimEnd()                   
                    }

                    #  Set the default parameter set
                    $ICXInterface.PSObject.TypeNames.Insert(0,'BrocadeICX.ICXInterface')
                    $DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$DefaultDisplaySet)
                    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)
                    $ICXInterface | Add-Member MemberSet PSStandardMembers $PSStandardMembers

                    $ICXInterface
                }
            }
        }
    }

    Process{
        $DefaultDisplaySet = 'Port', 'Link', 'State', 'Duplex', 'Speed', 'Trunk', 'Tagged', 'Pvid', 'Priority', 'MAC', 'Name'

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
                        get_ICXInterface -Session $ICXSession -DefaultDisplaySet $DefaultDisplaySet
                     
                        Remove-ICXSession -Session $ICXSession
                    }                    
                }                
            }
            
            "Session" {
                foreach($Session2 in $Session)
                {
                    if(Test-ICXSession -Session $Session2)
                    {
                        get_ICXInterface -Session $Session2 -DefaultDisplaySet $DefaultDisplaySet
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
