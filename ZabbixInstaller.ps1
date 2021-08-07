
<#PSScriptInfo

.VERSION 1.0

.GUID 642fb815-2544-4326-be1f-58ab2fdb54c1

.AUTHOR Rodrigo Cordeiro

.COMPANYNAME Beltis TI

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI https://www.beltis.com.br/

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
Install zabbix. Supports custom port configuration.

#>

<#
.SYNOPSIS
	Automated installation of zabbix agent
.DESCRIPTION
  This script provides automated installation and configuration of zabbix agent, also downloads incrementals scripts and configurations defined for Beltis automation.
.PARAMETER <port>
	Determina uma porta padrão diferente para o agente.
.NOTES
  Version:        1.0
  Author:         rodrigomendoncca@gmail.com
  Creation Date:  01/05/2021
  Purpose/Change: Automated Zabbix installation

.INPUTS
    Não há input necessário para a execução do script
.OUTPUTS
    São exportados os logs de execução das tarefas
.EXAMPLE
  .\ZabbixInstaller.ps1 -port 10050
.EXAMPLE
  .\ZabbixInstaller.ps1 -port 10072
.EXAMPLE
  .\ZabbixInstaller.ps1
#>

param ( [int] $port, [switch] $help)





[string] $zabbixInstallPath = "ZBX_WIN_LOCAL_PATH"
[string] $zabbixAgentURL = "https://cdn.zabbix.com/zabbix/binaries/stable/5.0/5.0.11/zabbix_agent-5.0.11-windows-amd64-openssl.zip"
[string] $zabbixCustomFiles = "ZBX_SERVER"
[string] $AtualVersion = "5.0.11"
[int] $ServerPort = 10071
$proxy = ([System.Net.WebRequest]::GetSystemWebproxy()).GetProxy($zabbixCustomFiles)


$Powershell_version = Get-Host

if (!$port){
  $ListenPort = 10070
} else {
  $ListenPort = $port
}

if($help){
  $script_file = Resolve-Path -Path ".\ZabbixInstaller.ps1"
  Get-Help $script_file.Path
  exit
}


#start logging to log file
Start-Transcript -Path ".\Zabbix-$Env:COMPUTERNAME.log" -Append -NoClobber -IncludeInvocationHeader


function FirewallRules{
<#
.DESCRIPTION
Cria as regras de firewall para o Zabbix, permitindo as conexões entrada e saída nas portas especificadas.
#>
    $rules = Get-NetFirewallRule -DisplayName "Zabbix"
    if($rules){
        Write-Host "Removing existing Firewall rules for update."
        $rules | ForEach-Object {
            Remove-NetFirewallRule -Name $_.InstanceID
        }
    }
    Write-Host "Creating new Firewall rules"
    New-NetFirewallRule -DisplayName "Zabbix" -Description "Zabbix Inbound firewall rules" -Direction Inbound -Action Allow -LocalPort $ListenPort -Protocol TCP -Enabled True
    New-NetFirewallRule -DisplayName "Zabbix" -Description "Zabbix Outbound firewall rules" -Direction Outbound -Action Allow -LocalPort $ServerPort -Protocol TCP -Enabled True
    
}

function DownloadAgent{
    Write-Host "Efetuando o download do agente"
    Invoke-WebRequest -Uri $zabbixAgentURL -outfile "$zabbixInstallPath\zabbix.zip"
    Expand-Archive "$zabbixInstallPath\zabbix.zip" -DestinationPath $zabbixInstallPath
}

if ($Powershell_version.Version.Major -eq 5){
    
  #create agent directory if it doesn't exists
  if (!(Test-Path -Path $zabbixInstallPath))
  {
      Write-Host "Criando pasta Zabbix"
      New-Item $zabbixInstallPath -ItemType Directory
      
      DownloadAgent
      
      Write-Host "Criando pasta de scripts"
      New-Item "$zabbixInstallPath\scripts\" -ItemType Directory
      
      Write-Host "Criando pasta de configurações adicionais"
      New-Item "$zabbixInstallPath\zabbix_agentd.conf.d\" -ItemType Directory

      Write-Host "Efetuando download de scripts"
      Invoke-WebRequest -Proxy $proxy -ProxyUseDefaultCredentials -Uri "$zabbixCustomFiles/Start_agent.ps1" -outfile "$zabbixInstallPath\scripts\Start_agent.ps1" 
      Invoke-WebRequest -Proxy $proxy -ProxyUseDefaultCredentials  -Uri "$zabbixCustomFiles/Restart_agent.ps1" -outfile "$zabbixInstallPath\scripts\Restart_agent.ps1" 
      Invoke-WebRequest -Proxy $proxy -ProxyUseDefaultCredentials  -Uri "$zabbixCustomFiles/Uninstall_zabbix.ps1" -outfile "$zabbixInstallPath\scripts\Uninstall_zabbix.ps1" 
      Invoke-WebRequest -Proxy $proxy -ProxyUseDefaultCredentials  -Uri "$zabbixCustomFiles/Get_inventory.ps1" -outfile "$zabbixInstallPath\scripts\Get_inventory.ps1"
      
      Write-Host "Efetuando o download de template de configuração"
      Remove-Item "$zabbixInstallPath\conf\zabbix_agentd.conf"
      $config = Invoke-WebRequest -Uri "$zabbixCustomFiles/zabbix_agentd.win.conf"
      New-Item -ItemType File -Path "$zabbixInstallPath\conf\zabbix_agentd.conf" -Value $config.Content.Replace("LISTEN_PORT",$ListenPort)
      
      FirewallRules

      Write-Host "Instalando o agente"
      Start-Process -FilePath "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "-c $zabbixInstallPath\conf\zabbix_agentd.conf -i" -NoNewWindow
      Start-Sleep -Seconds 2
      Write-Host "Iniciando o agente"
      Start-Process -FilePath "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "-c $zabbixInstallPath\conf\zabbix_agentd.conf -s" -NoNewWindow    

      Remove-Item "$zabbixInstallPath\zabbix.zip"
  }
  else
  {
      $Version = (Get-Item "$zabbixInstallPath\bin\zabbix_agentd.exe").VersionInfo.FileVersion
      if($Version.StartsWith($AtualVersion)){
          Write-Host "Zabbix Agent already installed with the latest version"
      } else {
          Write-Host "Zabbix Agent already installed but found a new version. Start updating."
          
          Start-Process "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "-c $zabbixInstallPath\conf\zabbix_agentd.conf -x"
          Start-Sleep -Seconds 2
          Start-Process "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "--uninstall"
          Start-Sleep -Seconds 2
          
          Remove-Item "$zabbixInstallPath\bin" -Recurse -Force

          DownloadAgent
          FirewallRules

          Start-Process -FilePath "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "-c $zabbixInstallPath\conf\zabbix_agentd.conf -i" -NoNewWindow
          Start-Sleep -Seconds 2
          Start-Process -FilePath "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "-c $zabbixInstallPath\conf\zabbix_agentd.conf -s" -NoNewWindow    

          Remove-Item "$zabbixInstallPath\zabbix.zip"
      }
  }
} else {
  Write-Host "Por favor, atualize o powershell para a versão 5.1 ou superior para garantir o funcionamento de todas as funcionalidades Zabbix"
}
Stop-Transcript

# SIG # Begin signature block
# MIIFxwYJKoZIhvcNAQcCoIIFuDCCBbQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqUZWXvVoyE+OdvAj97OneUU4
# uLGgggNEMIIDQDCCAiigAwIBAgIQFbxZumfld41MyhiLRz4MmDANBgkqhkiG9w0B
# AQsFADA4MTYwNAYDVQQDDC1Sb2RyaWdvIENvcmRlaXJvIDxyb2RyaWdvbWVuZG9u
# Y2NhQGdtYWlsLmNvbT4wHhcNMjEwODA2MjAwNTIzWhcNMjIwODA2MjAyNTIyWjAn
# MSUwIwYDVQQDDBxSb2RyaWdvIENvcmRlaXJvIHwgQmVsdGlzIFRJMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAn/gVxAhY8+kqJk5Uc3JDD07s0mLqlZSW
# ON5ncH8kiJ6XdmcNfv0nIQTcghBTB70lS1wxC/GWA6FRFm6TkwFj4r72YZN5UVzL
# BSii8dar9rsa9mSLaVdYCzdcbEPJrwt1IhS5hI1Qe87rYArHQw3q+sr2uy8nat+C
# KlPS8UblcQkdm+JCRUwAiarxmQidcfV7RK3boS5B4cgzjnYJVzzn6VERZqYTPhPd
# D97Se94M38xobdcWX46jt31snnOvDeh0BASCepUEN0ZDcoOe8pRDowMdx/862G1c
# hkKe8l20hSlT0zaVqQQbG9yFWcY00akVP9tMHxas2UPkn3IiMe8JXQIDAQABo1cw
# VTATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAWgBQnTyrsdM3l9TfvnRfy
# TwkxrJGaMjAdBgNVHQ4EFgQUFNNPU7+Az+iJkPSna45FxuoLSO0wDQYJKoZIhvcN
# AQELBQADggEBAGyYAKOZykhn208UgaGkxA5Dd8zdp0nGit96vhmWUvR2Gz0zB+D/
# ydGxMkjUS4LoIz81aBydfCBwunpsO/n/3OEW/4YDJoMLNmH//CEHeNMhZ/1cUefJ
# YWSAjTY4BT+zPT8+ad22pa3C6Ciiv5+ySTnfvunVvIbN0CEJTzCqv5tEaKdvo7SG
# YU1wLuOJwMbA1B/XmdWJwrqKD+3KCzKDmuWNQBjf9q1fv0hGKOketKV92RLDpYPw
# F6lQz1JkDM2Mk0q0uwr1RJK3i+lNmY7t0npghX1pCcl4M0Ug25rDK/u5o2XePWdO
# ExKDq4h+bd/ldlhgTNEc5DnmHbwz4lWbUAQxggHtMIIB6QIBATBMMDgxNjA0BgNV
# BAMMLVJvZHJpZ28gQ29yZGVpcm8gPHJvZHJpZ29tZW5kb25jY2FAZ21haWwuY29t
# PgIQFbxZumfld41MyhiLRz4MmDAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUztPGfUCpTuqOyVwG
# pZ6JuXqA7EEwDQYJKoZIhvcNAQEBBQAEggEATqnQHH20jXzEXMJTUyyBhgO3is4o
# kO8k19vhNHrWYiGaErNKmPZ1Y/cGSI122MvM441N00pFqTczdPyi2OD8jsIcfINa
# Wj9ZK/YcjsccUqgae0STNJip09J5lEhIU4dNfA/llbopWh+8sGfNEpkFaEPAltDm
# XMAYoGDEBtzbK47gymAEU5CF54HrDrjSQA6MjzHIaz3fNVrOKFMqHFRBtduTp+Tf
# O+TG2qNa2P5sG5AjOsYtNlcdyJPrLOunrOnwDfiCGwRqol8rIaKElC9INusCLLE/
# +NR3tkrDrwLmy3NmqySlyVCbBkpvKHeV/Y91wwuu1tUwBFCDd7TClvVVUA==
# SIG # End signature block
