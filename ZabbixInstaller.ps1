param ( [int] $port, [switch] $help)

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
.EXAMPLE
  .\ZabbixInstaller.ps1 -port 10050
  .\ZabbixInstaller.ps1 -port 10072
#>



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
  Write-Host "This script provides automated installation and configuration of zabbix agent, also downloads incrementals scripts and configurations defined for Beltis automation."
  Write-Host "-port: permite alteracao da porta padrao"
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
