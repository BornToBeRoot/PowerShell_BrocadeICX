# PowerShell | BrocadeICX

Module and script collection for PowerShell to administrate Brocade ICX switches over SSH.

## Description

This module and collection of usefull scripts, allows you to administrate your Brocade ICX switches over SSH-Protocol with the Windows PowerShell.

With the "BrocadeICX" module you can establish a connection via SSH to one ore more Brocade ICX switch devices and executing commands without receiving the following error message: `☺Protocol error, doesn't start with scp!`

You can write tasks like backup the configuration to a TFTP server or get and set VLANs on an interface.

## Module

#### How to install the module?

* Download the latest version of the module and all scripts from GitHub ([latest release](https://github.com/BornToBeRoot/PowerShell_BrocadeICX/releases/latest))
* Copy the folder `Module\BrocadeICX` in your profile under `C:\Users\%username%\Documents\WindowsPowerShell\Modules`
* Open up a PowerShell as an admin and set the execution policy: `Set-ExecutionPolicy RemoteSigned`
* Import the "BrocadeICX"-Module with the command `Import-Module BrocadeICX` (Maybe add this command to your PowerShell profile)

#### Available functions:

**Folder: [Core](Module/BrocadeICX/Core)**

| Function | Description | Help | 
| :--- | :--- | :---: |
| [Get-ICXSession](Module/BrocadeICX/Core/Get-ICXSession.ps1) | Get a Brocade ICX session | [:book:](Documentation/Function/Get-ICXSession.README.md) |
| [Invoke-ICXCommand](Module/BrocadeICX/Core/Invoke-ICXCommand.ps1) | Invoke an SSH command in a Brocade ICX sessions | [:book:](Documentation/Function/Invoke-ICXCommand.README.md) |
| [New-ICXSession](Module/BrocadeICX/Core/New-ICXSession.ps1) | Create a new Brocade ICX sessions over SSH | [:book:](Documentation/Function/New-ICXSession.README.md) |
| [Remove-ICXSession](Module/BrocadeICX/Core/Remove-ICXSession.ps1) | Remove a Brocade ICX session | [:book:](Documentation/Function/Remove-ICXSession.README.md) |
| [Test-ICXSession](Module/BrocadeICX/Core/Test-ICXSession.ps1) | Test if a session is a valid Brocade ICX session | [:book:](Documentation/Function/Test-ICXSession.README.md) |

**Folder: [Interface](Module/BrocadeICX/Functions/Interface)**

| Function | Description | Help | 
| :--- | :--- | :---: |
| [Get-ICXInterface](Module/BrocadeICX/Functions/Interface/Get-ICXInterface.ps1) | Get interface(s) from a Brocade ICX switch | [:book:](Documentation/Function/Get-ICXInterface.README.md) |

**Folder: [VLAN](Module/BrocadeICX/Functions/VLAN)**

| Function | Description | Help | 
| :--- | :--- | :---: |
| [Get-ICXVLAN](Module/BrocadeICX/Functions/VLAN/Get-ICXVLAN.ps1) | Get VLAN from a Brocade ICX switch | [:book:](Documentation/Function/Get-ICXVLAN.README.md) |
| [Test-ICXVLAN](Module/BrocadeICX/Functions/VLAN/Test-ICXVLAN.ps1) | Test if a VLAN exist on a Brocade ICX switch | [:book:](Documentation/Function/Test-ICXVLAN.README.md) |

## Scripts

#### How to install the scripts?

* Copy the folder `Scripts` to any location you want.

#### Available scripts:

| Script | Description | Help | 
| :--- | :--- | :---: |

## Requirements

* PowerShell 4.0
* [Posh-SSH](https://github.com/darkoperator/Posh-SSH) by darkoperator to establish an SSH connection ([latest release](https://github.com/darkoperator/Posh-SSH/releases/latest)).

## Supported devices (others may also work)

* ICX6430-24/48
* FastIron WS 624/48

