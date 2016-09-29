# Get-ICXSession

Get a Brocade ICX session.

* [view function](https://github.com/BornToBeRoot/PowerShell_BrocadeICX/blob/master/Module/BrocadeICX/Core/Get-ICXSession.ps1)

## Description

Get one or multiple Brocade ICX sessions based on SessionID or ComputerName.

![Screenshot](Images/Get-ICXSession.png?raw=true)

## Syntax

```powershell
Get-ICXSession [<CommonParameters>]

Get-ICXSession [-SessionID] <Int32[]> [<CommonParameters>]

Get-ICXSession [-ComputerName] <String[]> [[-CaseSensitive]] [<CommonParameters>]
```

## Example 1

```powershell
PS> Get-ICXSession -SessionID 1, 2   

SessionID ComputerName AccessMode
--------- ------------ ----------
        1 MEGATRON     Privileged
        2 megatron     Config
```

## Example 2

```powershell
PS> Get-ICXSession -ComputerName MEGATRON | Select-Object * | Format-Table

SessionID ComputerName AccessMode Session        Stream
--------- ------------ ---------- -------        ------
        0 megatron     Privileged SSH.SshSession Renci.SshNet.ShellStream
        1 MEGATRON     Privileged SSH.SshSession Renci.SshNet.ShellStream
        2 megatron     Config     SSH.SshSession Renci.SshNet.ShellStream
```

## Example 3

```powershell
PS> Get-ICXSession -ComputerName MEGATRON -CaseSensitive

SessionID ComputerName AccessMode
--------- ------------ ----------
        1 MEGATRON     Privileged
```