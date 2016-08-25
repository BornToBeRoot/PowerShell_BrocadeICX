###############################################################################################################
# Language     :  PowerShell 4.0
# Filename     :  Invoke-ICXCommand.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Invoke an SSH command in a Brocade ICX sessions
# Repository   :  https://github.com/BornToBeRoot/PowerShell_BrocadeICX
###############################################################################################################

<#
    .SYNOPSIS
    Invoke an SSH command in a Brocade ICX sessions

    .DESCRIPTION
    Invoke an SSH command into one or multiple Brocade ICX sessions. By default, the function will try to detect the SSH output automatically based on the first and last string. Normally the output starts with the SSH command (which was passed) and ends with SSH@HOSTNAME#. If the automatic detection fails and the timeout is reached, the output which is currently in the SSH stream will be returned. 
    
    If you have trouble with some commands (such as "copy running-config tftp ...""), you should try the compatibility mode (-CompatibilityMode) and define your own timout values (-Seconds or -Milliseconds). With the compatibility mode, the SSH command ist executed and the output of the SSH stream is returned after a specific time.

    .EXAMPLE
    Get-ICXSession | Invoke-ICXCommand -Command "sh clock"  

    SessionID ComputerName Output
    --------- ------------ ------
            0 megatron     {14:53:53 GMT+01 Thu Aug 25 2016...
            1 megaTRON     {14:53:53 GMT+01 Thu Aug 25 2016...
            2 megatron     {14:53:53 GMT+01 Thu Aug 25 2016...

    .EXAMPLE
    $Session = Get-ICXSession -SessionID 0
    (Invoke-ICXCommand -Command "sh clock" -Session $Session).Output

    14:54:13 GMT+01 Thu Aug 25 2016

    .EXAMPLE
    (Get-ICXSession -SessionID 2 | Invoke-ICXCommand -Command "copy running-config tftp 192.168.XXX.XXX" -CompatibilityMode -Seconds 5).Output

    Upload running-config to TFTP server done.

    .LINK
    https://github.com/BornToBeRoot/PowerShell_BrocadeICX/Documentation/Function/Invoke-ICXCommand.README.md
#>

function Invoke-ICXCommand
{
    [CmdletBinding(DefaultParameterSetName='AutoDetectOutput')]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='SSH command which is executed on the Brocade ICX Switch')]
        [String]$Command,
        
        [Parameter(
            Position=1,
            ValueFromPipeline=$true,
            Mandatory=$true,
            HelpMessage='Brocade ICX session')]
        [pscustomobject[]]$Session,

        [Parameter(
            ParameterSetName='AutoDetectOutput',
            Position=2,
            HelpMessage='Specifies how many seconds to wait before the reading of the output is canceled (Default=10)')]
        [Int32]$Timeout=10,

        [Parameter(
            ParameterSetName='AutoDetectOutput',
            Position=3,
            HelpMessage='Custom string to detect the end of the output (Default=SSH@HOSTNAME#)')]
        [String[]]$EndString,

        [Parameter(
            ParameterSetName='CompatibilityMode_Milliseconds',
            Position=2,
            HelpMessage='Use compatibility mode')]
        [Parameter(
            ParameterSetName='CompatibilityMode_Seconds',
            Position=2,
            HelpMessage='Use compatibility mode')]
        [switch]$CompatibilityMode,

        [Parameter(
            ParameterSetName='CompatibilityMode_Seconds',
            Position=3,
            HelpMessage='Specifies how many seconds to wait before the output is read (Default=1)')]
        [Int32]$Seconds=1,

        [Parameter(
            ParameterSetName='CompatibilityMode_Milliseconds',
            Position=3,
            HelpMessage='Specifies how many milliseconds to wait before the output is read (Default=1000)')]
        [Int32]$Milliseconds=1000
    )

    Begin{

    }

    Process{   
        # Store the original SSH command for later comparison
        $OriginalSSHCommand = $Command.Replace("`n","")

        # Add a line break, to simulate ENTER
        if(-not($Command.EndsWith("`n")))
        {            
            $Command = $Command + "`n"
        }

        # Calculate the timeout in Milliseconds
        $TimeoutMilliseconds = $Timeout * 1000

        # Temporary array to store Brocade ICX sessions which are to be removed later (e.g. if SSH connection was dropped)
        $BadICXSessions = @()

        # Go through each session and execute the SSH command
        foreach($Session2 in $Session)
        {           
            Write-Verbose -Message "Current session: $Session2"

            # Check if session is a valid Brocade ICX session and managed by this module
            if(Test-ICXSession -Session $Session2)
            {
                # Try to write the SSH command in the SSH shell stream
                try{
                    Write-Verbose -Message "Write SSH command ""$OriginalSSHCommand"" in the SSH shell stream..."
                    $Session2.Stream.Write($Command)
                }
                catch{
                    if($_.Exception.Message.Split(':')[1].Trim() -eq '"Client not connected."')
                    {
                        Write-Error -Message "Client ""$($Session2.ComputerName)"" (Session: $Session2)) no longer connected! SSH command can not be executed! The session will be removed from the global Brocade ICX sessions." -Category ConnectionError
                        
                        # Sessions are removed at the end, to prevent an enumeration error
                        $BadICXSessions += $Session2  
                    }
                    else 
                    {
                        Write-Error -Message "Client ""$($Session2.ComputerName)"" (Session: $Session2): $($_.Exception.Message)" -Category ConnectionError
                    }

                    continue
                }

                # Temporary output as array, which is returned from ssh shell stream
                $TemporaryOutput = @()

                # The last line of the output "normally" contains SSH@HOSTNAME> or SSH@HOSTNAME# or SSH@HOSTNAME(config)#
                $RegexSSHatHostname = "(SSH@){1}[0-9A-Z_-]+([(]{1}(config){1}[)]{1})*(>|#){1}"

                # Auto detect output or wait a specific time (compatibility mode)...
                if($PSCmdlet.ParameterSetName -eq 'AutoDetectOutput')
                {
                    # Validate that the stream was read to the end
                    $SSHCommandFoundInOutput = $false
                    $OutputIsComplete = $false                                          

                    # Timeout
                    $TimeoutStartTime = Get-Date
                    $TimeoutHasReached = $false
                                            
                    do{         
                        # Check if timeout is reached, if yes... go the last time through the loop
                        if((New-TimeSpan -Start $TimeoutStartTime -End (Get-Date)).TotalMilliseconds -gt $TimeoutMilliseconds)
                        {
                            
                            Write-Warning -Message "Timeout ($Timeout seconds) was reached! Output may not complete.`nIf you have problems with this command. Try out the compatibility mode. Use Get-Help for more details!"
                            $TimeoutHasReached = $true
                        }
                        else  
                        {   
                            # Wait for new output                        
                            Write-Verbose -Message "Wait 250 Milliseconds."
                            Start-Sleep -Milliseconds 250    
                        }                        

                        # Get the output and split lines into an array
                        $Stream_Read = $Session2.Stream.Read() -split '[\n]' | Where-Object {$_}

                        # Check if output is not null
                        if($Stream_Read -ne $null)
                        {
                            Write-Verbose -Message "Process received output..."

                            # Go through each line
                            foreach($Line in $Stream_Read)
                            {                                    
                                # Add only the output after the SSH command 
                                if(-not($SSHCommandFoundInOutput))
                                {
                                    # If the command was found... we can start building the output! (Use like because the line sometimes starts with "SSH@HOSTNAME#" or "SSH@HOSTNAME(config)#")
                                    if($Line -like "*$OriginalSSHCommand*")
                                    {   
                                        Write-Verbose -Message "SSH command ""$OriginalSSHCommand"" was found in line."
                                        $SSHCommandFoundInOutput = $true
                                    }                                   
                                }                                
                                else 
                                {
                                    # Check if custom end string is used and is present in the current line
                                    if($PSBoundParameters.ContainsKey('EndString'))
                                    {                                    
                                        foreach($EndString2 in $EndString)
                                        {
                                            if($Line -like "*$EndString2*")
                                            {
                                                Write-Verbose -Message "Output is complete! ""$EndString2"" was found in line: $Line"
                                                $OutputIsComplete = $true
                                            }
                                        }
                                    } # Check if line match regex ("SSH@HOSTNAME>" or "SSH@HOSTNAME#" or "SSH@HOSTNAME(config)#"), if so, we have reached the end of the shell stream
                                    elseif($Line -match $RegexSSHatHostname)
                                    {
                                        Write-Verbose -Message "Output is complete!"
                                        $OutputIsComplete = $true
	                                }

                                    $TemporaryOutput += $Line                                      
                                }                            
                            }
                        }
                        else
                        {
                            Write-Verbose -Message "No output received."
                        }                        
                    }while(($OutputIsComplete -eq $false) -and ($TimeoutHasReached -eq $false))                                    
                }
                else 
                {
                    Write-Verbose -Message "Compatibility mode enabled." 

                    if($PSCmdlet.ParameterSetName -eq "CompatibilityMode_Seconds")
                    {
                        $Milliseconds = $Seconds * 1000
                    }

                    Start-Sleep -Milliseconds $Milliseconds

                    $TemporaryOutput += $Session2.Stream.Read() -split '[\n]' | Where-Object {$_}
                }
                
                Write-Verbose -Message "Prepare output..."

                # Output as array, which is returned
                $Output = @()

                # Process the output - replace SSH command and SSH@HOSTNAME#
                foreach($Line in $TemporaryOutput)
                {
                    $Output += $Line -replace $OriginalSSHCommand, "" -replace $RegexSSHatHostname, ""
                }

                $IndexStart = 0
                $IndexEnd = $Output.Length -1

                # Get the index of the first item with content
                for($i = 0; $i -lt $IndexEnd; $i++)
                {                    
                    if($Output[$i] -match '[\S]')
                    {
                        Write-Verbose -Message "Index of the first item with content: $i"
                        $IndexStart = $i
                        break
                    }
                }

                # Get the index of the last item with content
                for($j = $IndexEnd; $j -gt $IndexStart; $j--)
                {
                    if($Output[$j] -match '[\S]')
                    {
                        Write-Verbose -Message "Index of the last item with content: $j"
                        $IndexEnd = $j
                        break 
                    }
                }

                # Build a new array without the empty items at start and end
                $Output = $Output[$IndexStart..$IndexEnd]

                # Build the PSCustomObject and return it
                [pscustomobject] @{
                    SessionID = $Session2.SessionID
                    ComputerName = $Session2.ComputerName
                    Output = $Output
                }
            }            
            else
            {
                Write-Error -Message "Session ($Session2) is not a valid Brocade ICX session or not managed by the BrocadeICX module!" -Category ConnectionError
            } 
        }

        if($BadICXSessions.Count -gt 0)
        {
            # Cleanup Brocade ICX sessions which are no longer available
            Write-Verbose -Message "Removing Brocade ICX sessions which are no longer available."
            $BadICXSessions | Remove-ICXSession
        }
    }

    End{

    }
}