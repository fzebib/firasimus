#!/bin/bash


#### Install LEMP


### Define package names

NGINX="nginx"

MYSQL="mysql-server mysql" 

LAMPPHP="php-fpm php-mysql"

MAIL="mail"

NFS="nfs-utils nfs-utils-lib"

###Define IPs
IP=`cat hostname.txt | while read IPLINE; do echo "$IPLINE";done`


###Deploy Success
function SUCCESS {
echo "Deploy Success" | mail -s "Deploy Success" fzebib@gmail.com
}


### Update DBM
function UPDATEDBM {
echo "#################"
echo "Adding repositories and Updating Yum"
ssh root@$IP rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm > /dev/null 2>&1
ssh root@$IP rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm > /dev/null 2>&1
ssh root@$IP  yum update -yq > /dev/null 2>&1
}


### Install of LEMP + NFS + MAIL
function LEMP {
echo "##############"
echo "Installing appropriate daemons"
ssh root@$IP yum install -yq $NFS $MYSQL $LAMPPHP $NGINX $MAIL > /dev/null 2>&1
}

###Mounting Remotely via Fstab
function MOUNT {
echo "################"
echo "Mounting NFS"
ssh root@$IP "echo 162.243.67.60:/var/www/html   nfs      auto,noatime,nolock,bg,nfsvers=3,intr,tcp,actimeo=1800 0 0 >> /etc/fstab" 
ssh root@$IP mount -a
}



#### Autostart options for LEMP

function AUTOSTART {
echo "######################"
echo "Mysql set for Autostart"
echo "#####################"
ssh root@$IP chkconfig mysqld on
sleep 3s

echo "####################"
echo "Nginx set for Autostart"
echo "####################"
ssh root@$IP chkconfig nginx on
sleep 3s

echo "####################"
echo "Php-fpm set for Autostart"
echo "####################"
ssh root@$IP chkconfig php-fpm on
sleep 3s

echo "####################"
echo "NFS set for Autostart"
echo "######################"
ssh root@$IP chkconfig nfs on && service rpcbind start && service nfs start
sleep 3s
}



###SSH-Key Access
#for hostname in $(cat hostname.txt)
#do
#ssh-keygen -t rsa
#ssh root@$hostname mkdir -p .ssh
#cat .ssh/id_rsa.pub | ssh root@$hostname 'cat >> .ssh/authorized_keys'
#ssh root@$hostname "chmod 700 .ssh; chmod 640 .ssh/authorized_keys"
#done


###NFS Mount access
#### This "nfs.txt" should include the nfs server you are editing. The "hostname.txt" should be the new server you are giving access to.
for NFS in $(cat nfs.txt)
do
	for hostname in $(cat hostname.txt)
	do
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub $hostname
ssh-copy-id -i ~/.ssh/id_rsa.pub $NFS
IP2=`ssh root@$hostname  ifconfig | grep Bcast | cut -d: -f2 | cut -d" " -f1`
echo $IP2 > ip.txt
scp ip.txt root@$NFS:ip.txt > /dev/null 2>&1
ssh root@$NFS  'cat ip.txt | while read IPLOCAL; do echo "/var/www/html      $IPLOCAL(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports;done'    
ssh root@$NFS exportfs -a
sleep 3s
echo "###########"
echo "NFS updated with additional servers"
echo "###########"
sleep 3s
done
done


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

MOUNT

SUCCESS
