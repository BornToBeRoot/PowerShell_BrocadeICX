# Test-ICXVLAN

Test if a VLAN exist on a Brocade ICX Switch.

* [view function](https://github.com/BornToBeRoot/PowerShell_BrocadeICX/blob/master/Module/BrocadeICX/Functions/VLAN/Test-ICXVLAN.ps1)

## Description

Test if a VLAN exist on a Brocade ICX Switch.

![Screenshot](Images/Test-ICXVLAN.png?raw=true)

## Syntax

```powershell
Get-ICXVLAN [-ComputerName] <String[]> [[-AcceptKey]] [[-Credential] <PSCredential>] [<CommonParameters>]

Get-ICXVLAN [-Session] <PSObject[]> [<CommonParameters>]
```

## Example 1

```powershell
PS> Test-ICXVLAN -ComputerName megatron -VlanId 1
    
true
```

## Example 2

```powershell
PS> $Cred = Get-Credential $null
PS> Test-ICXVLAN -ComputerName megatron -VlanId 2 -Credential $Cred

false
```
