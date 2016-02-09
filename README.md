# PowerShell SSH Brocade

## Description

Module and script collection for PowerShell to administrate Brocade Switches over SSH

---

With the Module "Brocade" you can execute commands over SSH without receiving the following error message: "☺Protocol error, doesn't start with scp!"

## Requirements

- Posh-SSH (https://github.com/darkoperator/Posh-SSH)

## Supported Devices

* ICX6430-24 & ICX6430-48
* FastIron WS 648

## Install

### Brocade Module

1. Copy the folder named "Modules/Brocade" in your Profile under C:\Users\%username%\Documents\WindowsPowerShell\Modules
2. Open a PowerShell Console and import the Module with the command "Import-Module Brocade"

### Brocade Scripts

It doesn't matter where you store the scripts (I only use relative paths) The only thing you need is a working "Brocade" and "Posh-SSH" Module.   

## Syntax

### Brocade Module

#### New-BrocadeSession

```powershell
New-BrocadeSession [-ComputerName] <String[]> [[-Credentials] <PSCredential>] [<CommonParameters>]
```

#### Get-BrocadeSession

```powershell
Get-BrocadeSession [[-SessionID] <Int32[]>] [<CommonParameters>]

Get-BrocadeSession [[-ComputerName] <String[]>] [[-ExactMatch]] [<CommonParameters>]
```

#### Invoke-BrocadeSession

```powershell
Invoke-BrocadeCommand [-Session] <PSObject[]> [-Command] <String> [[-WaitTime] <Int32>] [<CommonParameters>]
```

#### Remove-BrocadeSession

```powershell
Remove-BrocadeSession [-Session] <PSObject[]> [<CommonParameters>]

Remove-BrocadeSession [-SessionID] <Int32[]> [<CommonParameters>]
```

## Example

```powershell
> New-BrocadeSession -ComputerName TEST_DEVICE1

> Invoke-Command -Command "sh clock" -Wait 500 -Session (Get-BrocadeSession -SessionID 0)

sh clock
13:30:47 GMT+01 Tue Feb 09 2016
SSH@TEST_DEVICE1#

> Get-BrocadeSession -SessionID 0 | Remove-BrocadeSession
```

## Output

### Session

```powershell
> Get-BrocadeSession

 SessionID ComputerName                       Session                            Stream
 --------- ------------                       -------                            ------
         0 TEST_DEVICE1                       SSH.SshSession                     Renci.SshNet.ShellStream
         1 TEST_DEVICE2                       SSH.SshSession                     Renci.SshNet.ShellStream
```

# ChangeLog

##Version 1.0
* Release Brocade Module

# Know Issues

---

## More

The basic idea to invoke ssh commands comes from the contributions on StackOverflow and Reddit that describe the procedure:
- https://stackoverflow.com/questions/30603219/executing-command-using-paramiko-on-brocade-switch
- https://www.reddit.com/r/PowerShell/comments/3tgql4/poshssh_shell_reading/