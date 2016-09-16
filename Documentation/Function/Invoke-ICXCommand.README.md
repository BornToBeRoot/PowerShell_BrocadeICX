# Invoke-ICXCommand

Invoke an SSH command in a Brocade ICX session.

* [view function](https://github.com/BornToBeRoot/PowerShell_BrocadeICX/blob/master/Module/BrocadeICX/Core/Invoke-ICXCommand.ps1)

## Description

Invoke an SSH command into one or multiple Brocade ICX session(s). By default, the function will try to detect the SSH output automatically based on the first and last string. Normally the output starts with the SSH command (which was passed) and ends with SSH@HOSTNAME#. If the automatic detection fails and the timeout is reached, the output which is currently in the SSH stream will be returned. 

If you have trouble with some commands (such as `copy running-config tftp ...`), you should try the compatibility mode (`-CompatibilityMode`) and define your own timout values (`-Seconds` or `-Milliseconds`). With the compatibility mode, the SSH command ist executed and the output of the SSH stream is returned after a specific time. Or if you know the string(s) which are returned, you can overwrite the endstring (-EndString).

![Screenshot](Images/Invoke-ICXCommand.png?raw=true)

## Syntax

```powershell
Invoke-ICXCommand [-Command] <String> [-Session] <PSObject[]> [[-Timeout] <Int32>] [[-EndString] <String[]>] [<CommonParameters>]

Invoke-ICXCommand [-Command] <String> [-Session] <PSObject[]> [[-CompatibilityMode]] [[-Seconds] <Int32>] [<CommonParameters>]

Invoke-ICXCommand [-Command] <String> [-Session] <PSObject[]> [[-CompatibilityMode]] [[-Milliseconds] <Int32>] [<CommonParameters>]
```

## Example 1

```powershell
PS> Get-ICXSession | Invoke-ICXCommand -Command "sh clock"  

SessionID ComputerName Output
--------- ------------ ------
        0 megatron     {14:53:53 GMT+01 Thu Aug 25 2016...
        1 megaTRON     {14:53:53 GMT+01 Thu Aug 25 2016...
        2 megatron     {14:53:53 GMT+01 Thu Aug 25 2016...
```

## Example 2

```powershell
PS> $Session = Get-ICXSession -SessionID 0
PS> (Invoke-ICXCommand -Command "sh clock" -Session $Session).Output

14:54:13 GMT+01 Thu Aug 25 2016
```

## Example 3
```powershell
PS> (Get-ICXSession -SessionID 2 | Invoke-ICXCommand -Command "copy running-config tftp 192.168.XXX.XXX" -CompatibilityMode -Seconds 5).Output

Upload running-config to TFTP server done.
```