#!/bin/bash
###############################
## setup instalacija servera ##
###############################
service elasticsearch stop > /dev/null 2>&1


rhel=$(cat /etc/os-release | grep "rhel" | wc -l)
if [ -f /etc/debian_version ]; then
       #Instalacija Jave
       echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
       echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
       apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
       apt-get update
       echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
       echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
       apt-get install oracle-java8-installer -y
       echo “Java je instalirana...”

       #instalacija Elasticsearcha
       wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
       echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
       chkconfig elasticsearch on
       service elasticsearch stop
       apt-get update && apt-get install elasticsearch -y

       #instalacija Logstasha
       wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
       echo "deb https://packages.elastic.co/logstash/2.3/debian stable main" | sudo tee -a /etc/apt/sources.list
       service logstash stop
       sudo apt-get update && sudo apt-get install logstash -y
       chkconfig --add logstash
       chkconfig logstash on


       #instalacija Kibane
       wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
       echo "deb http://packages.elastic.co/kibana/4.5/debian stable main" | sudo tee -a /etc/apt/sources.list
       service kibana4 stop
       apt-get update && sudo apt-get install kibana -y
       sudo update-rc.d kibana defaults 95 10


elif [ -f /etc/redhat-release ] || [ $rhel > 0 ]; then
       #Instalacija Jave
       cd /opt/
       wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u66-b17/jdk-8u66-linux-x64.tar.gz"
       tar xzf jdk-8u66-linux-x64.tar.gz
       cd /opt/jdk1.8.0_66/
       alternatives --install /usr/bin/java java /opt/jdk1.8.0_66/bin/java 2

       #instalacija Elasticsearcha
       rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
       echo "[elasticsearch-2.x]
name=Elasticsearch repository for 2.x packages
baseurl=http://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1" > /etc/yum.repos.d/es.repo
        yum install elasticsearch -y
        chkconfig elasticsearch on
        service elasticsearch restart

        #instalacija Logstasha
        rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
        echo "[logstash-2.3]
name=Logstash repository for 2.3.x packages
baseurl=https://packages.elastic.co/logstash/2.3/centos
gpgcheck=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1" > /etc/yum.repos.d/logstash.repo
        yum install logstash -y
        chkconfig --add logstash
        chkconfig logstash on

        #instalacija Kibane
        rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
        echo "[kibana-4.5]
name=Kibana repository for 4.5.x packages
baseurl=http://packages.elastic.co/kibana/4.5/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1" > /etc/yum.repos.d/kibana.repo
        yum install kibana -y
        chkconfig --add kibana


fi

## elasticsearch instalacija plugina ##
/usr/share/elasticsearch/bin/plugin install xyu/elasticsearch-whatson/0.1.3bin/plugin
/usr/share/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf/v1.5.8
/usr/share/elasticsearch/bin/plugin install lukas-vlcek/bigdesk/2.4.0
/usr/share/elasticsearch/bin/plugin install mobz/elasticsearch-head
/usr/share/elasticsearch/bin/plugin install royrusso/elasticsearch-HQ
/usr/share/elasticsearch/bin/plugin install elasticsearch/elasticsearch-cloud-aws/2.7.1

## elasticsearch ciscenje logova
rm -rf /var/log/elasticsearch/*

#kopiranje svih konfiguracija za pojedini program
cp /opt/ELK_Stack/scripts/install/logstash.conf /etc/logstash/conf.d/logstash.conf
cp /opt/ELK_Stack/scripts/install/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
cp /opt/ELK_Stack/scripts/install/kibana.yml /etc/init.d/kibana
