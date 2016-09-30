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
PS> Get-ICXVLAN -ComputerName megatron | ? {$_.Name -eq "Test1"} | ft

ID   Name  By   TaggedPort UntaggedPort
--   ----  --   ---------- ------------
1001 Test1 port {0/1/4}    {0/1/37, 0/1/39, 0/1/45, 0/1/46}
```

## Example 2

```powershell
PS> New-ICXSession -ComputerName MEGATRON, megatron
PS> Get-ICXVLAN -Session (Get-ICXSession) | ? {$_.Name -eq "Test1"} | ft

SessionID ComputerName ID   Name  By   TaggedPort UntaggedPort
--------- ------------ --   ----  --   ---------- ------------
        0 MEGATRON     1001 Test1 port {0/1/4}    {0/1/37, 0/1/39, 0/1/45, 0/1/46}
        1 megatron     1001 Test1 port {0/1/4}    {0/1/37, 0/1/39, 0/1/45, 0/1/46}
```