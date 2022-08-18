# Templates

## Service Monitoring via systemctl on Linux
 1. Import `service_monitoring_via_systemctl.xml` on zabbix.
 1. On host run: 
 ```shell
cd /etc/zabbix
curl https://raw.githubusercontent.com/catonrug/zabbix_agentd.d/master/service_monitoring_via_systemctl.conf > zabbix_agentd.d/service_monitoring_via_systemctl.conf
systemctl restart zabbix-agent.service
```
3. Include the template on zabbix host and wait for 1m for updating.
> Reference [https://share.zabbix.com/operating-systems/linux/linux-service-monitoring-using-systemctl](https://share.zabbix.com/operating-systems/linux/linux-service-monitoring-using-systemctl)

## Monitoring Hyper-V
1. Import the template XML file using the Zabbix Templates Import feature.

1. Create 2 folders in zabbix agent folder, `scripts\` and `zabbix_agentd.conf.d\` and copy the files `hyperv_host.ps1` to scripts\ and `hyperv_host.conf` to zabbix_agentd.conf.d\  

1. Add these lines to zabbix_agentd.conf if not set:
```conf
Include=C:\Program Files\zabbix-agent\zabbix_agentd.conf.d\*.conf 
UnsafeUserParameters=1  
Timeout=10
```

4. Restart Zabbix Agent
7. All triggers you may change through user macros in host

> Reference [https://github.com/itmicus/zabbix/tree/master/Template%20Microsoft%20Hyper-V](https://github.com/itmicus/zabbix/tree/master/Template%20Microsoft%20Hyper-V)

