# Get-ICXVLAN

Get VLAN(s) from a Brocade ICX Switch.

* [view function](https://github.com/BornToBeRoot/PowerShell_BrocadeICX/blob/master/Module/BrocadeICX/Functions/VLAN/Get-ICXVLAN.ps1)

## Description

Get VLAN(s) from a Brocade ICX Switch as PSCustomObject, which can be further processed.

![Screenshot](Images/Get-ICXVLAN.png?raw=true)

## Syntax

```powershell
Get-ICXVLAN [-ComputerName] <String[]> [[-AcceptKey]] [[-Credential] <PSCredential>] [<CommonParameters>]

Get-ICXVLAN [-Session] <PSObject[]> [<CommonParameters>]
```

## Example 1

```powershell
PS> Get-ICXVLAN -ComputerName megatron

SessionID ComputerName ID   Name         By   TaggedPort                   UntaggedPort
--------- ------------ --   ----         --   ----------                   ------------
        2 megatron     1001 Test1        port {0/1/1}                      {0/1/5, 0/1/6, 0/1/7, 0/1/8, ...}
        2 megatron     1002 Test2        port {0/1/1, 0/1/2, 0/1/3, 0/1/4} {0/1/11, 0/1/12, 0/1/13, 0/1/14, ...}
```

## Example 2

```powershell
PS> $Session = Get-ICXSession -SessionID 0,2
PS> Get-ICXVLAN -Session $Session | Where-Object {$_.Name -eq "Test1"}

SessionID ComputerName ID   Name         By   TaggedPort                   UntaggedPort
--------- ------------ --   ----         --   ----------                   ------------
        0 megatron     1001 Test1        port {0/1/1}                      {0/1/5, 0/1/6, 0/1/7, 0/1/8, ...}
        2 megatron     1001 Test1        port {0/1/1}                      {0/1/5, 0/1/6, 0/1/7, 0/1/8, ...}
```