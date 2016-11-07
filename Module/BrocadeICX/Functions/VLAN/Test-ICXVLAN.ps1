###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Get-ICXVLAN.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Test if a VLAN exist on a Brocade ICX Switch
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    Test if a VLAN exist on a Brocade ICX Switch

    .DESCRIPTION
    Test if a VLAN exist on a Brocade ICX Switch. 

    .EXAMPLE
    Test-ICXVLAN -ComputerName megatron -VlanId 1

    True
    
    .EXAMPLE
    $Cred = Get-Credentials $null
    Test-ICXVLAN -ComputerName megatron -VlanId 2 -Credentials $Cred
    
    False

    .LINK
    https://github.com/BornToBeRoot/PowerShell_BrocadeICX/blob/master/Documentation/Function/Get-ICXVLAN.README.md
#>

function Test-ICXVLAN
{
    [CmdletBinding(DefaultParameterSetName='ComputerName')]
    param(
        [Parameter(
            ParameterSetName='ComputerName',
            Position=0,
            Mandatory=$true,
            HelpMessage='Hostname or IPv4-Address of the Brocade ICX Switch')]
        [String]$ComputerName,

        [Parameter(
            ParameterSetName='Session',
            Position=0,
            ValueFromPipeline=$true,
            Mandatory=$true,
            HelpMessage='Brocade ICX session')]
        [pscustomobject]$Session,
        
        [Parameter(
            ParameterSetName='ComputerName',
            Position=1,
            Mandatory=$true,
            HelpMessage='VLAN ID which is to tested')]
        [Parameter(
            ParameterSetName='Session',
            Position=1,
            Mandatory=$true,
            HelpMessage='VLAN ID which is to tested')]
        [Int32]$VlanId,

        [Parameter(
            ParameterSetName='ComputerName',
            Position=2,
            HelpMessage='Accept the SSH key')]
        [switch]$AcceptKey,

        [Parameter(
            ParameterSetName='ComputerName',
            Position=3,
            HelpMessage='Credentials to authenticate agains the Brocade ICX Switch (SSH connection)')]
        [System.Management.Automation.PSCredential]
	    [System.Management.Automation.CredentialAttribute()]
	    $Credential
    )

    Begin{
        function test_ICXVLAN {
            param(
               $Session,
               $VlanId
            )

            Begin{

            }

            Process{
                [Int32[]]$VlanIds = (Get-ICXVLAN -Session $Session).Id

                return $VlanIds.Contains($VlanId)
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
                        test_ICXVLAN -Session $ICXSession -VlanId $VlanId
                     
                        Remove-ICXSession -Session $ICXSession
                    }                    
                }                
            }
            
            "Session" {
                foreach($Session2 in $Session)
                {
                    if(Test-ICXSession -Session $Session2)
                    {
                        test_ICXVLAN -Session $Session2 -VlanId $VlanId
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