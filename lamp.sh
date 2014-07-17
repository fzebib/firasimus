#!/bin/bash


#### Install LEMP


### Define package names

NGINX="nginx"

MYSQL="mysql-server mysql" 

LAMPPHP="php-fpm php-mysql"



### Update DBM
function UPDATEDBM {
echo "#################"
echo "Updating Yum"
sudo yum update -y
}


### Install of LEMP
function LEMP {
echo "##############"
echo "Installing appropriate daemons"
sudo yum install -y $MYSQL $LAMPPHP $NGINX
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
echo " Yum update Successful"
else
echo " Yum update did not complete"
exit 1
fi

if LEMP ;
then
echo " LEMP install successful"
else
echo " LEMP install did not complete"
fi
