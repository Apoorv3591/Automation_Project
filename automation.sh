#!/bin/bash
myname="Apoorv"
timestamp=$(date '+%d%m%Y-%H%M%S')
s3_bucket="upgrad-apoorv"

echo "updating packages"
sudo apt update -y

echo "installing apache2 if not installed"
if [ $(dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
    apt-get -y install apache2;
fi

echo "restarts apache in case of reboot"
apache_enable_var=$(systemctl is-enabled apache2)
if [ "$apache_enable_var" = "disabled" ]
then
    systemctl enable apache2
fi

echo "starts apache if not running"
apache_status_var=$(systemctl is-active  apache2)
if [ "$apache_status_var" = "inactive" ]
then
    systemctl restart apache2
fi


echo "archiving the log files"
sudo tar -cvf /tmp/"${myname}-"httpd-access-logs"-${timestamp}.tar" /var/log/apache2/access.log
sudo tar -cvf /tmp/"${myname}-"httpd-error-logs"-${timestamp}.tar" /var/log/apache2/error.log

echo "copying archived files to s3"
aws s3 cp /tmp/"${myname}-"httpd-access-logs"-${timestamp}.tar" s3://"${s3_bucket}"/
aws s3 cp /tmp/"${myname}-"httpd-error-logs"-${timestamp}.tar" s3://"${s3_bucket}"/


