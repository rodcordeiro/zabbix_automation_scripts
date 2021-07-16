<#
.SYNOPSIS
	Automated installation of zabbix agent
.DESCRIPTION
  This script provides automate installation and configuration of zabbix agent, also downloads incrementals scripts.
.INPUTS
  No inputs is needed
.OUTPUTS
  Output in JSON format for Zabbix 
.NOTES
  Version:        1.0
  Author:         p.kuznetsov@itmicus.ru
  Creation Date:  07/05/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  PS> .\ZabbixInstaller.ps1
#>



$zabbixInstallPath = "C:\Zabbix"
[string] $zabbixCustomFiles = "http://bmonit.beltis.com.br:81/"

Start-Transcript -Path "C:\WINDOWS\TEMP\zupdate_000_$Env:COMPUTERNAME.log" -Append -NoClobber -IncludeInvocationHeader

Write-Host "Efetuando download de scripts"
Invoke-WebRequest -Uri "$zabbixCustomFiles/Start_agent.ps1" -outfile "$zabbixInstallPath\scripts\Start_agent.ps1" 
Invoke-WebRequest -Uri "$zabbixCustomFiles/Restart_agent.ps1" -outfile "$zabbixInstallPath\scripts\Restart_agent.ps1" 
Invoke-WebRequest -Uri "$zabbixCustomFiles/Uninstall_zabbix.ps1" -outfile "$zabbixInstallPath\scripts\Uninstall_zabbix.ps1" 
Invoke-WebRequest -Uri "$zabbixCustomFiles/Get_inventory.ps1" -outfile "$zabbixInstallPath\scripts\Get_inventory.ps1"

Stop-Transcript
