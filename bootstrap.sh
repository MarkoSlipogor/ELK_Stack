#!/bin/bash
#########################
## ELK_Stack Bootstrap ##
#########################
#pocetak instalacije programa

## Update repozitorija ##
echo "git pull debug" >> /var/log/bootstrap
mkdir /opt/ELK_Stack
cd /opt/ELK_Stack
gitv=$(git rev-parse --verify HEAD)
sudo -u mslipogor -- git reset --hard HEAD
sudo -u mslipogor -- git checkout master
sudo -u mslipogor -- git pull --no-edit

if [ "$gitv" = "$(git rev-parse --verify HEAD)" ]
then
    echo "Repozitorij je nadogradjen na zadnju verziju"
else
    echo "Ponovno pokretanje skripte radi nadogradnje repozitorija"
    sh /opt/ELK_Stack/bootstrap.sh
    exit
fi

echo "os debug" >> /var/log/bootstrap
#Provjera operacijskog sustava radi buduceg koristenja package managera za instalacije
rhel=$(cat /etc/os-release | grep "rhel" | wc -l)
if [ -f /etc/debian_version ]; then
    os="1"
    PKG_MANAGER="apt-get"
    REPO_REFRESH="apt-get update"

    wget -O /tmp/chkconfig.deb http://security.ubuntu.com/ubuntu/pool/universe/c/chkconfig/chkconfig_11.0-79.1-2_all.deb
    dpkg -i /tmp/chkconfig.deb

elif [ -f /etc/redhat-release ] || [ $rhel > 0 ]; then
    os="2"
    PKG_MANAGER="yum"
    REPO_REFRESH=""

else
    os="3"
    PKG_MANAGER="yum"
    REPO_REFRESH=""

fi


#instalacija AWS konfiguracije
echo "aws debug" >> /var/log/bootstrap
sh /opt/ELK_Stack/scripts/install/aws.sh

COLO=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document --connect-timeout 1)
if [ ! -z "$COLO" ]; then
    COLO="aws"
else
    COLO="null"
fi

if [ "$COLO" = "aws" ]; then
    cluster=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id) | grep TAGS | grep Cluster | awk '{print $3}')
    env=$(aws ec2 describe-instances --instance-id $(curl --silent http://169.254.169.254/latest/meta-data/instance-id) | grep TAGS | grep Environment | awk '{print $3}')
fi

##### OS 1=Debian 2=CentOs 3=break
$PKG_MANAGER update -y
$PKG_MANAGER install awscli htop -y

#postavljanje limita na AWS instancama za Linux okruzenje
grep -q -F '* soft nproc 1048576' /etc/security/limits.conf || echo '* soft nproc 1048576' >> /etc/security/limits.conf
grep -q -F '* hard nproc 1048576' /etc/security/limits.conf || echo '* hard nproc 1048576' >> /etc/security/limits.conf
grep -q -F 'root soft nproc 1048576' /etc/security/limits.conf || echo 'root soft nproc 1048576' >> /etc/security/limits.conf
grep -q -F 'root hard nproc 1048576' /etc/security/limits.conf || echo 'root hard nproc 1048576' >> /etc/security/limits.conf
grep -q -F '* soft nofile 1048576' /etc/security/limits.conf || echo '* soft nofile 1048576' >> /etc/security/limits.conf
grep -q -F '* hard nofile 1048576' /etc/security/limits.conf || echo '* hard nofile 1048576' >> /etc/security/limits.conf
grep -q -F 'root soft nofile 1048576' /etc/security/limits.conf || echo 'root soft nofile 1048576' >> /etc/security/limits.conf
grep -q -F 'root hard nofile 1048576' /etc/security/limits.conf || echo 'root hard nofile 1048576' >> /etc/security/limits.conf

#instalacija alata za monitoriranje sustava
echo "logging debug" >> /var/log/bootstrap
sh /opt/ELK_Stack/scripts/install/logging.sh

#instalacija odabranog clustera
if [ -f /etc/ELK_Stack.env ]; then
    source /etc/ELK_Stack.env
fi

if [ -z "$cluster" ]; then
    echo "Cluster nije definiran u tagovima ili u varijabli!"
    exit
fi
echo "cluster setup debug" >> /var/log/bootstrap
#write the vuirrent vars then run setup script
( set -o posix ; set ) > /var/run/ELK_Stack-bootstrap

echo "cluster script" > /var/log/bootstrap
cd /opt/ELK_Stack/$cluster/
bash setup.sh

exit 0
