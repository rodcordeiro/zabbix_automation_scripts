$zabbixInstallPath = "C:\Zabbix"

Start-Process "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "-c $zabbixInstallPath\conf\zabbix_agentd.conf -x"
Start-Sleep -Seconds 2
Start-Process "$zabbixInstallPath\bin\zabbix_agentd.exe" -ArgumentList "-c $zabbixInstallPath\conf\zabbix_agentd.conf -s"
