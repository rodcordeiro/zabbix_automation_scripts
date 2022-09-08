
<#PSScriptInfo

.VERSION 2.0

.GUID 642fb815-2544-4326-be1f-58ab2fdb54c1

.AUTHOR Rodrigo Cordeiro

.COMPANYNAME DarthC0de

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI https://github.com/DarthC0de

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
  Version:        2.0
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
  .\ZabbixInstaller.ps1 -name 'Test' -port 100
.EXAMPLE
  .\ZabbixInstaller.ps1 -name 'Test'
.EXAMPLE
  .\ZabbixInstaller.ps1
#>

param ( 
  [int]$port,
  [string]$name, 
  [switch]$help)

Add-Type -AssemblyName PresentationFramework
[Console]::OutputEncoding = New-Object System.Text.Utf8Encoding



# configurações gerais
[string] $zabbixInstallPath = "C:\Zabbix"
[string] $zabbixAgentURL = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.1/zabbix_agent-6.2.1-windows-amd64-openssl.zip"
[string] $zabbixCustomFiles = "10.23.1.36"
[string] $AtualVersion = "6.2.1"
[int] $ServerPort = 10051
$proxy = ([System.Net.WebRequest]::GetSystemWebproxy()).GetProxy($zabbixCustomFiles)

#Verifica a versão do powershell
$Powershell_version = Get-Host

if (!$port) {
  $ListenPort = 10050
}
else {
  $ListenPort = $port
}

if ($help) {
  $script_file = Resolve-Path -Path ".\ZabbixInstaller.ps1"
  Get-Help $script_file.Path
  exit
}


Write-Output "Criando pasta Zabbix"
New-Item $zabbixInstallPath -ItemType Directory

[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')


$title = 'Informe o nome a ser utilizado como identificador do host:'
$msg = "Este identificador irá preencher o campo hostname. `nValor default: $Env:COMPUTERNAME"

# Se não tiver passado o parametro name
if (!$Name) {
  # Abre uma tela solicitando o nome
  $HOSTNAME = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
  if (!$HOSTNAME) {
    # Caso não tenha sido passado nenhum valor, usa o hostname do computador como valor
    $HOSTNAME = $Env:COMPUTERNAME
  }
}
else {
  # Se o parametro name for passado, utiliza ele como valor
  $HOSTNAME = $Name 
}

#start logging to log file
Start-Transcript -Path "C:\Zabbix\Zabbix-$Env:COMPUTERNAME.log" -Append -NoClobber -IncludeInvocationHeader



function FirewallRules {
  <#
.DESCRIPTION
Cria as regras de firewall para o Zabbix, permitindo as conexões entrada e saída nas portas especificadas.
#>
  $rules = Get-NetFirewallRule -DisplayName "Zabbix"
  if ($rules) {
    Write-Output "Removing existing Firewall rules for update."
    $rules | ForEach-Object {
      Remove-NetFirewallRule -Name $_.InstanceID
    }
  }
  Write-Output "Creating new Firewall rules"
  New-NetFirewallRule -DisplayName "Zabbix" -Description "Zabbix Inbound firewall rules" -Direction Inbound -Action Allow -LocalPort $ListenPort -Protocol TCP -Enabled True
  New-NetFirewallRule -DisplayName "Zabbix" -Description "Zabbix Outbound firewall rules" -Direction Outbound -Action Allow -LocalPort $ServerPort -Protocol TCP -Enabled True
    
}

function DownloadAgent {
  Write-Output "Efetuando o download do agente"
  Invoke-WebRequest -Uri $zabbixAgentURL -outfile "$zabbixInstallPath\zabbix.zip"
  Expand-Archive "$zabbixInstallPath\zabbix.zip" -DestinationPath $zabbixInstallPath
}

#Valida se a versão do powershell é maior ou igual a 5, pois alguns comandos não funcionam em versões inferiores
if ($Powershell_version.Version.Major -ge 5) {
    
  #Cria a pasta para armazenamento caso não encontre
  if (!(Test-Path -Path $zabbixInstallPath)) {
    Write-Output "Criando pasta Zabbix"
    New-Item $zabbixInstallPath -ItemType Directory
      
    DownloadAgent
      
    Write-Output "Criando pasta de scripts"
    New-Item "$zabbixInstallPath\scripts\" -ItemType Directory
      
    Write-Output "Criando pasta de configurações adicionais"
    New-Item "$zabbixInstallPath\zabbix_agentd.conf.d\" -ItemType Directory

    Write-Output "Efetuando download de scripts"
    Invoke-WebRequest -Proxy $proxy -ProxyUseDefaultCredentials  -Uri "$zabbixCustomFiles/Get_inventory.ps1" -outfile "$zabbixInstallPath\scripts\Get_inventory.ps1"
      
    Write-Output "Efetuando o download de template de configuração"
    Remove-Item "$zabbixInstallPath\conf\zabbix_agentd.conf"
    $config = Invoke-WebRequest -Uri "$zabbixCustomFiles/zabbix_agentd.conf"
    New-Item -ItemType File -Path "$zabbixInstallPath\conf\zabbix_agentd.conf" -Value $config.Content.Replace("HOSTNAME_INDICATOR", $HOSTNAME)
      
    FirewallRules

    Write-Output "Instalando o agente"
    Start-Process -FilePath "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "-c $zabbixInstallPath\conf\zabbix_agentd.conf -i" -NoNewWindow
    Start-Sleep -Seconds 2
    Write-Output "Iniciando o agente"
    Start-Process -FilePath "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "-c $zabbixInstallPath\conf\zabbix_agentd.conf -s" -NoNewWindow    

    Remove-Item "$zabbixInstallPath\zabbix.zip"
  }
  else {
    $Version = (Get-Item "$zabbixInstallPath\bin\zabbix_agentd.exe").VersionInfo.FileVersion
    if ($Version.StartsWith($AtualVersion)) {
      Write-Output "Zabbix Agent already installed with the latest version"
    }
    else {
      Write-Output "Zabbix Agent already installed but found a new version. Start updating."
          
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
}
else {
  Write-Output "Por favor, atualize o powershell para a versão 5.1 ou superior para garantir o funcionamento de todas as funcionalidades Zabbix"
}
Stop-Transcript
