#!/usr/bin/env bash

##### Variables
ListenPort=10070
custom_files_repository="ZBX_SERVER"

##### Reference
# https://linuxhint.com/replace_string_in_file_bash/
# sed -i "s/$search/$replace/gi" $1

##### Parsing Arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --port=*)
      ListenPort="${1#*=}"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done


##### Identificar gerenciador de pacotes
declare -A osInfo;
osInfo[/etc/redhat-release]=yum
osInfo[/etc/arch-release]=pacman
osInfo[/etc/gentoo-release]=emerge
osInfo[/etc/SuSE-release]=zypp
osInfo[/etc/debian_version]=apt-get

for f in ${!osInfo[@]}
do
    if [[ -f $f ]];then
        pkg_mngr=${osInfo[$f]}
    fi
done


dnf_pkg_installer(){
    rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
    dnf clean all
    dnf install -y zabbix-agent

    systemctl enable zabbix-agent.service
    systemctl start zabbix-agent.service

    wget -c $custom_files_repository/zabbix_agentd.linux.conf -O /etc/zabbix/conf/zabbix_agentd/zabbix_agentd.conf
    wget -c $custom_files_repository/service_monitoring_via_systemctl.conf -O /etc/zabbix/conf/zabbix_agentd/service_monitoring_via_systemctl.conf
    
    systemctl restart zabbix-agent.service

}

apt_pkg_installer(){
    cd /tmp
    mkdir /tmp/zabbix_temp
    wget -c https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+bionic_all.deb -O /tmp/zabbix_temp/zabbix_release.deb
    dpkg -i /tmp/zabbix_temp/zabbix_release.deb
    apt-get update -y

    apt-get install zabbix-agent -y

    systemctl enable zabbix-agent.service
    systemctl start zabbix-agent.service

    wget -c $custom_files_repository/zabbix_agentd.linux.conf -O /etc/zabbix/conf/zabbix_agentd/zabbix_agentd.conf
    wget -c $custom_files_repository/service_monitoring_via_systemctl.conf -O /etc/zabbix/conf/zabbix_agentd/service_monitoring_via_systemctl.conf
    
    systemctl restart zabbix-agent.service

}

zypper_pkg_installer(){
    rpm -Uvh --nosignature https://repo.zabbix.com/zabbix/5.0/sles/15/x86_64/zabbix-release-5.0-1.el15.noarch.rpm
    zypper --gpg-auto-import-keys refresh 'Zabbix Official Repository'
    SUSEConnect -p sle-module-web-scripting/15/x86_64
    SUSEConnect --list-extensions
    zypper install zabbix-agent

    systemctl enable zabbix-agent.service
    systemctl start zabbix-agent.service

    wget -c $custom_files_repository/zabbix_agentd.linux.conf -O /etc/zabbix/conf/zabbix_agentd/zabbix_agentd.conf
    wget -c $custom_files_repository/service_monitoring_via_systemctl.conf -O /etc/zabbix/conf/zabbix_agentd/service_monitoring_via_systemctl.conf
    
    systemctl restart zabbix-agent.service

}

##### Run installer function based on package manager
case $pkg_mngr in
    apt-get)
        apt_pkg_installer
    ;;
    dnf|yum)
        dnf_pkg_installer
    ;;
    zypper)
        zypper_pkg_installer
    ;;
esac
