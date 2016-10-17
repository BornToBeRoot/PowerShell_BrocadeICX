# Get-ICXInterface

Get interface(s) from a Brocade ICX Switch.

* [view function](https://github.com/BornToBeRoot/PowerShell_BrocadeICX/blob/master/Module/BrocadeICX/Functions/Interface/Get-ICXInterface.ps1)

## Description

Get interface(s) from a Brocade ICX Switch with status [up|down], speed [1G|100M|10M] etc.

![Screenshot](Images/Get-ICXInterface.png?raw=true)

## Syntax

```powershell
Get-ICXInterface [-ComputerName] <String[]> [[-AcceptKey]] [[-Credential] <PSCredential>] [<CommonParameters>]

Get-ICXInterface [-Session] <PSObject[]> [<CommonParameters>]
```

## Example 1

```powershell
PS> Get-ICXInterface -ComputerName megatron | Select-Object -First 5 | Format-Table

Port  Link State   Duplex Speed Trunk Tag Pvid Priority MAC            Name
----  ---- -----   ------ ----- ----- --- ---- -------- ---            ----
0/1/1 Up   Forward Full   1G    None  Yes N/A  0        0000.0000.0000 UPLINK
0/1/2 Up   Forward Full   1G    None  No  1001 0        0000.0000.0001
0/1/3 Up   Forward Full   100M  None  No  1001 0        0000.0000.0002
0/1/4 Down None    None   None  None  No  1    0        0000.0000.0003
0/1/5 Up   Forward Full   1G    None  No  1001 0        0000.0000.0004
```

## Example 2

```powershell
PS> $Sessions = New-ICXSession -ComputerName MEGATRON, megatron
PS> Get-ICXInterface -Session $Sessions | Format-Table

SessionID ComputerName Port  Link State   Duplex Speed Trunk Tag Pvid Priority MAC            Name
--------- ------------ ----  ---- -----   ------ ----- ----- --- ---- -------- ---            ----
        0 megatron     0/1/1 Up   Forward Full   1G    None  Yes N/A  0        0000.0000.0000 UPLINK
        0 megatron     0/1/2 Up   Forward Full   1G    None  No  1001 0        0000.0000.0001
        0 megatron     0/1/3 Up   Forward Full   100M  None  No  1001 0        0000.0000.0002
        0 megatron     0/1/4 Down None    None   None  None  No  1    0        0000.0000.0003
        0 megatron     0/1/5 Up   Forward Full   1G    None  No  1001 0        0000.0000.0004
        ...
        1 MEGATRON     0/1/1 Up   Forward Full   1G    None  Yes N/A  0        0000.0000.0000 UPLINK
        1 MEGATRON     0/1/2 Up   Forward Full   1G    None  No  1001 0        0000.0000.0001
        1 MEGATRON     0/1/3 Up   Forward Full   100M  None  No  1001 0        0000.0000.0002
        1 MEGATRON     0/1/4 Down None    None   None  None  No  1    0        0000.0000.0003
        1 MEGATRON     0/1/5 Up   Forward Full   1G    None  No  1001 0        0000.0000.0004
        ...        
```