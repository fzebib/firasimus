#!/bin/bash


#### Install LEMP


### Define package names

NGINX="nginx"

MYSQL="mysql-server mysql" 

LAMPPHP="php-fpm php-mysql"

MAIL="mail"



###Deploy Success
function SUCCESS {
echo "Deploy Success" | mail -s "Deploy Success" fzebib@gmail.com
}


### Update DBM
function UPDATEDBM {
echo "#################"
echo "Adding repositories and Updating Yum"
rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm > /dev/null 2>&1
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm > /dev/null 2>&1
sudo yum update -yq
}


### Install of LEMP
function LEMP {
echo "##############"
echo "Installing appropriate daemons"
sudo yum install -yq $MYSQL $LAMPPHP $NGINX $MAIL
}



#### Autostart options for LEMP

function AUTOSTART {
echo "######################"
echo "Mysql set for Autostart"
echo "#####################"
chkconfig mysqld on

echo "####################"
echo "Nginx set for Autostart"
echo "####################"
chkconfig nginx on


echo "####################"
echo "Php-fpm set for Autostart"
echo "####################"
chkconfig php-fpm on
}

if UPDATEDBM ;
then
echo ".. Success"
else
echo " Yum update did not complete"
echo "Deploy failed at Yum update" | mail -s "Deploy Fail" fzebib@gmail.com
exit 1
fi

if LEMP ;
then
echo "..Success"
else
echo " LEMP install fail"
echo "Deploy fail at LEMP install" | mail -s "Deploy Fail" fzebib@gmail.com
exit 1
fi

if AUTOSTART ;
then
echo "..Success"
else
echo "Problem with setting daemons for autostart"
echo "Deploy fail at Runlevel update" | mail -s "Deploy Fail" fzebib@gmail.com
exit 1
fi

SUCCESS
