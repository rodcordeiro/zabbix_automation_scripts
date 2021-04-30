#!/usr/bin/env bash

linux=$(lsb_release -a | grep "Description")

wget http://repo.zabbix.com/zabbix/3.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_3.0-2+bionic_all.deb
sudo dpkg -i zabbix-release*.deb
sudo apt-get update

sudo apt-get install zabbix-agent -y

systemctl enable zabbix-agent.service
systemctl start zabbix-agent.service

cd /etc/zabbix
sudo wget -c https://raw.githubusercontent.com/catonrug/zabbix_agentd.d/master/service_monitoring_via_systemctl.conf -O zabbix_agentd.conf.d/service_monitoring_via_systemctl.conf
sudo systemctl restart zabbix-agent.service
