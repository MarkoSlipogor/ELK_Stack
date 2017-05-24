#!/bin/bash
################################
## setup instalacija klijenta ##
################################
#varijable za izradu okruzenja
#ENV_NAME=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id) |grep 'TAGS' |grep 'elasticbeanstalk:environment-name' | awk '{print $3}'|head -n1)
#INSTANCE_NAME=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id) |grep 'TAGS' |grep -v 'aws:autoscaling:groupName' |grep 'Name' | awk '{print $3}'|head -n1)
#ENV_ID=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id) |grep 'TAGS'|grep 'elasticbeanstalk:environment-id' | awk '{print $3}'|head -n1)
#INSTANCE_INT_IP=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id)|grep 'PRIVATEIPADDRESSES' |awk '{print $4}' |head -n1)
#INSTANCE_AZ=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id)|grep 'PLACEMENT'|awk '{print $2}' |head -n1)
#INSTANCE_EXT_IP=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id)|grep 'ASSOCIATION'|awk '{print $4}' |head -n1)
#if [ -z "$INSTANCE_EXT_IP" ]; then INSTANCE_EXT_IP="aws-no-external-network"; fi
#INSTANCE_SUBNET_ID=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id)|grep 'NETWORKINTERFACES'|awk '{print $10}' |head -n1)
#INSTANCE_VPC_ID=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id)|grep 'NETWORKINTERFACES'|awk '{print $11}' |head -n1)
#INSTANCE_AMI_ID=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id)|grep 'INSTANCES'|awk '{print $7}' |head -n1)
#INSTANCE_ID=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id)|grep 'INSTANCES'|awk '{print $8}' |head -n1)
#INSTANCE_SIZE=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id)|grep 'INSTANCES'|awk '{print $9}' |head -n1)
#INSTANCE_KEY=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id)|grep 'INSTANCES'|awk '{print $10}' |head -n1)
#kreiranje tagova za konfiguraciju
#ELK_RPL1="\"$INSTANCE_NAME\", \"$ENV_NAME\", \"$ENV_ID\", \"$INSTANCE_INT_IP\", \"$INSTANCE_AZ\", \"$INSTANCE_EXT_IP\", \"$INSTANCE_SUBNET_ID\", \"$INSTANCE_VPC_ID\", \"$INSTANCE_AMI_ID\", \"$INSTANCE_ID\", \"$INSTANCE_SIZE\", \"$INSTANCE_KEY\""
#ELK_RPL=$(echo ${ELK_RPL1} | sed -e 's/"",//g' -e 's/""//g')

#provjera root privilegija
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 2>&1
  exit 1
fi

#kreiranje datoteke s podatcima o instanci
#aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id) >/var/log/instance


#provjera wget instalacije
command -v wget &>/dev/null
if [ $? -ne 0 ]; then
  echo "wget not found, please install wget" 2>&1
  exit 1
fi

#debian install
rhel=$(cat /etc/os-release | grep "rhel" | wc -l)
if [ -f "/etc/debian_version" ]; then
  mkdir -p /etc/opt/
  cd /etc/opt/

  wget -q https://download.elastic.co/beats/topbeat/topbeat_1.3.1_amd64.deb
  wget -q https://download.elastic.co/beats/filebeat/filebeat_1.3.1_amd64.deb

  dpkg -i topbeat_1.3.1_amd64.deb 2>&1 >>/dev/null
  dpkg -i filebeat_1.3.1_amd64.deb 2>&1 >>/dev/null

  update-rc.d topbeat defaults 95 10 2>&1 >>/dev/null
  update-rc.d filebeat defaults 95 10 2>&1 >>/dev/null

#centos install
elif [ -f /etc/redhat-release ] || [ $rhel > 0 ]; then
    mkdir -p /etc/opt/
    cd /etc/opt/

    wget -q https://download.elastic.co/beats/topbeat/topbeat-1.3.1-x86_64.rpm
    wget -q https://download.elastic.co/beats/filebeat/filebeat-1.3.1-x86_64.rpm

    yum -y install ./filebeat-1.3.1-x86_64.rpm 2>&1 >>/dev/null
    yum -y install ./topbeat-1.3.1-x86_64.rpm 2>&1 >>/dev/null

    chkconfig --add topbeat 2>&1 >>/dev/null
    chkconfig --add filebeat 2>&1 >>/dev/null

    chkconfig topbeat on 2>&1 >>/dev/null
    chkconfig filebeat on 2>&1 >>/dev/null
fi

service topbeat stop 2>&1 >>/dev/null
service filebeat stop 2>&1 >>/dev/null


#kopiranje konfiguracija te njihovo postavljanje
cp /opt/ELK_Stack/scripts/install/etc/filebeat.yml /etc/filebeat/filebeat.yml
#cp /opt/ELK_Stack/scripts/install/etc/packetbeat.yml /etc/packetbeat/packetbeat.yml
cp /opt/ELK_Stack/scripts/install/etc/topbeat.yml /etc/topbeat/topbeat.yml

#replace vars in the configs before starting
#sed -i "s/CLUSTERRR/$ELK_RPL/" /etc/filebeat/filebeat.yml
#sed -i "s/CLUSTERRR/$ELK_RPL/" /etc/topbeat/topbeat.yml

sleep 1

service topbeat start 2>&1 >>/dev/null
service filebeat start 2>&1 >>/dev/null
