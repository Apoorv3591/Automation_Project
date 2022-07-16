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


echo "maintaining records"
file_access=/tmp/"${myname}-"httpd-access-logs"-${timestamp}.tar"
file_error=/tmp/"${myname}-"httpd-error-logs"-${timestamp}.tar"
filesize_access=$(ls -lh $file_access | awk '{print  $5}')
filesize_error=$(ls -lh $file_error | awk '{print  $5}')
FILERECORD=/var/www/html/inventory.html
if [ -f "$FILERECORD" ]
then
    echo "<p>httpd-access-logs&emsp;&emsp;${timestamp}&emsp;&emsp;tar&emsp;&emsp;${filesize_access}" >> /var/www/html/inventory.html
    echo "<p>httpd-error-logs&ensp;&emsp;&emsp;${timestamp}&emsp;&emsp;tar&emsp;&emsp;${filesize_error}" >> /var/www/html/inventory.html
else
    echo "<p>Log Type&emsp;&emsp;&emsp;&emsp;&emsp;Time Created&emsp;&emsp;&emsp;&emsp;Type&emsp;&emsp;Size</p>" >> /var/www/html/inventory.html
    echo "<p>httpd-access-logs&emsp;&emsp;${timestamp}&emsp;&emsp;tar&emsp;&emsp;${filesize_access}" >> /var/www/html/inventory.html
    echo "<p> httpd-error-logs&ensp;&emsp;&emsp;${timestamp}&emsp;&emsp;tar&emsp;&emsp;${filesize_error}" >> /var/www/html/inventory.html
fi




echo "scheduling jobs every 2 hour"
FILECRON=/etc/cron.d/automation
if [ -f "$FILECRON" ]
then
    echo "job already scheduled"
else
    echo "0 */2 * * * /root/Automation_Project/automation.sh" >> /etc/cron.d/automation
fi
