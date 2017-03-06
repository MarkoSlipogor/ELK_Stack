#!/bin/bash
################################
## setup instalacija klijenta ##
################################

rhel=$(cat /etc/os-release | grep "rhel" | wc -l)
if [ -f /etc/debian_version ]; then

    #instalacija Filebeata
    curl https://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb https://packages.elastic.co/beats/apt stable main" |  sudo tee -a /etc/apt/sources.list.d/beats.list
    service filebeat stop
    sudo apt-get update && sudo apt-get install filebeat -y
    sudo update-rc.d filebeat defaults 95 10

    #instalacija Topbeata
    service topbeat stop
    sudo apt-get update && sudo apt-get install topbeat -y
    sudo update-rc.d topbeat defaults 95 10

    #instalacija Packetbeata
    service packetbeat stop
    sudo apt-get update && sudo apt-get install packetbeat -y
    sudo update-rc.d packetbeat defaults 95 10

elif [ -f /etc/redhat-release ] || [ $rhel > 0 ]; then

    #instalacija Filebeata
    sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
    echo "[beats]
name=Elastic Beats Repository
baseurl=https://packages.elastic.co/beats/yum/el/$basearch
enabled=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
gpgcheck=1" > /etc/yum.repos.d/beats.repo
    sudo yum install filebeat -y
    sudo chkconfig --add filebeat

    #instalacija Topbeata
    sudo yum install topbeat -y
    sudo chkconfig --add topbeat

    #instalacija Packetbeata
    sudo yum install packetbeat -y
    sudo chkconfig --add packetbeat

fi

#kopiranje konfiguracija te njihovo postavljanje
cp /opt/ELK_Stack/scripts/install/etc/filebeat.yml /etc/filebeat/filebeat.yml
cp /opt/ELK_Stack/scripts/install/etc/packetbeat.yml /etc/packetbeat/packetbeat.yml
cp /opt/ELK_Stack/scripts/install/etc/topbeat.yml /etc/topbeat/topbeat.yml
