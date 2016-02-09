###############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  Manage-Credentials.ps1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Script to Encrypt/Decrypt Credentials and save them as variable or xml-file
# Repository   :  https://github.com/BornToBeRoot/PowerShell-Manage-Credentials
###############################################################################################################
# Date copied  : 09.02.2015 

<#
    .SYNOPSIS
    Script to Encrypt/Decrypt Credentials (Username and Password) and save them as xml-file using SecureStrings
    .DESCRIPTION
    With this script, you can encrypt your credentials (username and password) as SecureStrings and save them 
    as a variable or xml-file. You can also decrypt the variable or xml-file and return a PSCredential-Object
    or username and password in plain text.
    The encrypted credentials can only be decrypted on the same computer and under the same user, which encrypted
    them. 
    For exmaple: 
    If user A encrypt the credentials on computer A, user B cannot decrypt the credentials on 
    computer A and also user A cannot decrypt the credentials on Computer B.
        
    If you found a bug or have some ideas to improve this script... Let me know. You find my Github profile in
    the links below.
    .EXAMPLE
    $Test_Cred = .\Manage-Credentials.ps1 -Encrypt
    
    .EXAMPLE
    .\Manage-Credentials.ps1 -Encrypt -OutFile Test_Cred.xml
    .EXAMPLE
    .\Manage-Credentials.ps1 -Decrypt -EncryptedCredentials $Test_Cred
    .EXAMPLE
    .\Manage-Credentials.ps1 -Decrypt -FilePath .\Test_Cred.xml -PasswordAsPlainText
    
    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell-Manage-Credentials
#>


[CmdletBinding(DefaultParameterSetName='Encrypt')]
Param(
	[Parameter(
		ParameterSetName='Encrypt',
		HelpMessage='Encrypt Credentials')]
	[switch]$Encrypt,

    [Parameter(
		ParameterSetName='Encrypt',
		Position=0,
		HelpMessage='PSCredential-Object (e.g. Get-Credentials)')]
	[System.Management.Automation.PSCredential]$Credentials,
	
    [Parameter(
		ParameterSetName='Encrypt',
		Position=1,
		HelpMessage='Path to the xml-file where the encrypted credentials will be saved')]
	[String]$OutFile,
		
	[Parameter(
		ParameterSetName='Decrypt',
		HelpMessage='Decrypt Credentials')]
	[switch]$Decrypt,
	
    [Parameter(
		ParameterSetName='Decrypt',
		Position=0,
		HelpMessage='PSObject with encrypted credentials to decrypt them')]
	[System.Object]$EncryptedCredentials,	

    [Parameter(
		ParameterSetName='Decrypt',
		Position=1,
		HelpMessage='Path to the xml-file where the encrypted credentials are saved')]
	[String]$FilePath,

    [Parameter(
        ParameterSetName='Decrypt',
        Position=2,
        HelpMessage='Return password as plain text')]
    [switch]$PasswordAsPlainText
)

Begin{}
Process
{
    if($Encrypt)
    {
        if($Credentials -eq $null)
        {
            try{
                $Credentials = Get-Credential $null 
            } catch {
                Write-Host "Canceled by User." -ForegroundColor Yellow
                return
            }      
        }
            
        $EncryptedCredentials = New-Object -Type PSObject
        Add-Member -InputObject $EncryptedCredentials -MemberType NoteProperty -Name UsernameAsSecureString -Value ($Credentials.Username | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString)
	    Add-Member -InputObject $EncryptedCredentials -MemberType NoteProperty -Name PasswordAsSecureString -Value ($Credentials.Password | ConvertFrom-SecureString)
    
        if(-not[String]::IsNullOrEmpty($OutFile))
        {        
            $FilePath = $OutFile.Replace(".\","").Replace("\","") 
                
            if(-not([System.IO.Path]::IsPathRooted($FilePath))) 
            { 
                $ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

                $FilePath = Join-Path -Path $ScriptPath -ChildPath $FilePath
            }
	    
            if(-not($FilePath.ToLower().EndsWith(".xml"))) 
            { 
                $FilePath += ".xml" 
            }

            if([System.IO.File]::Exists($FilePath))
            {
                Write-Host "Overwriting existing file ($FilePath)" -ForegroundColor Yellow
            }           
        
            $FilePath

            $EncryptedCredentials | Export-Clixml -Path $FilePath
        }
        else
        {
            return $EncryptedCredentials   
        }    
    }
    elseif($Decrypt)
    {
        if(-not([String]::IsNullOrEmpty($FilePath)))
        {
            if($EncryptedCredentials -ne $null)
            {
                Write-Host 'Both parameters ("-EncryptedCredentials" and "-FilePath") are not allowed. Using parameter "-FilePath"' -ForegroundColor Yellow
            }

            $EncryptedCredentials = Import-Clixml -Path $FilePath
        }
    
        if($EncryptedCredentials -eq $null)
        {
            Write-Host 'Nothing to decrypt! Try "-EncryptedCredentials" or "-FilePath"' -ForegroundColor Yellow
            Write-Host 'Try "Get-Help .\Manage-Credentials.ps1" for more details'
            return
        }    

        $SecureString_Password = $EncryptedCredentials.PasswordAsSecureString | ConvertTo-SecureString 
        $SecureString_Username = $EncryptedCredentials.UsernameAsSecureString | ConvertTo-SecureString
    
        $BSTR_Username = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString_Username)
        $Username = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR_Username) 
     
       
        if($PasswordAsPlainText) 
        {
            $BSTR_Password = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString_Password)
            $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR_Password)

            $PlainText_Credentials = New-Object -Type PSObject
            Add-Member -InputObject $PlainText_Credentials -MemberType NoteProperty -Name Username -Value $Username
	        Add-Member -InputObject $PlainText_Credentials -MemberType NoteProperty -Name Password -Value $Password

            return $PlainText_Credentials
        }
        else
        {
            return New-Object System.Management.Automation.PSCredential($Username , $SecureString_Password)
        }
    }
    else
    {
        Write-Host 'No parameters detected! Use "-Encrypt" or "-Decrypt"' -ForegroundColor Yellow
        Write-Host 'Try "Get-Help .\Manage-Credentials.ps1" for more details'        
    }
}
End{}