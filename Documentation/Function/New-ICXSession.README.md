# New-ICXSession

Create a new Brocade ICX sessions over SSH.

* [view function](https://github.com/BornToBeRoot/PowerShell_BrocadeICX/blob/master/Module/BrocadeICX/Core/New-ICXSession.ps1)

## Description

Create one or multiple Brocade ICX session over SSH. If no credentials are submitted, a credential popup will appear.

![Screenshot](Images/New-ICXSession.png?raw=true)

## Syntax

```powershell
New-ICXSession [-ComputerName] <String[]> [[-AcceptKey]] [[-Credential] <PSCredential>] [<CommonParameters>]
```

## Example

```powershell
PS> New-ICXSession -ComputerName megatron  
    
SessionID ComputerName AccessMode
--------- ------------ ----------
        0 megatron     Privileged
```