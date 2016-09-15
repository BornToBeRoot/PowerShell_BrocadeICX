# Test-ICXSession

Test if a session is a valid Brocade ICX session.

* [view function](https://github.com/BornToBeRoot/PowerShell_BrocadeICX/blob/master/Module/BrocadeICX/Core/Test-ICXSession.ps1)

## Description

Test if a session is a valid Brocade ICX session and managed by the BrocadeICX module.

![Screenshot](Images/Test-ICXSession.png?raw=true)

## Syntax

```powershell
Test-ICXSession [-Session] <PSObject> [<CommonParameters>]
```

## Example 1

```powershell
PS> $Session = Get-ICXSession -SessionID 0
PS> Test-ICXSession -Session $Session
    
true
```

## Example 2

```powershell
PS> "Test" | Test-ICXSessions

false
```
