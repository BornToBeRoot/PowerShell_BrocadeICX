# Remove-ICXSession

Remove a Brocade ICX session.

* [view function](https://github.com/BornToBeRoot/PowerShell_BrocadeICX/blob/master/Module/BrocadeICX/Core/Remove-ICXSession.ps1)

## Description

Remove one or multiple Brocade ICX sessions.

![Screenshot](Images/Remove-ICXSession.png?raw=true)

## Syntax

```powershell
Remove-ICXSession [-SessionID] <Int32[]> [<CommonParameters>]

Remove-ICXSession [-ComputerName] <String[]> [[-CaseSensitive]] [<CommonParameters>]

Remove-ICXSession [-Search] <String> [<CommonParameters>]

Remove-ICXSession [-Session] <PSObject[]> [<CommonParameters>]
```

## Example 1

```powershell
PS> Remove-ICXSession -SessionID 1 
```

## Example 2

```powershell
PS> Get-ICXSession | Remove-ICXSession
```

## Example 3
```powershell
PS> Remove-ICXSession -ComputerName megatron
```

## Example 4

```powershell
PS> Remove-ICXSession -Search *mega*
```