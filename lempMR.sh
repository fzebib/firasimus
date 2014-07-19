#!/bin/bash


#### Install LEMP


### Define package names

NGINX="nginx"

MYSQL="mysql-server mysql" 

LAMPPHP="php-fpm php-mysql"

MAIL="mail"

NFSUTIL="nfs-utils nfs-utils-lib"

###Define IPs
IP=`cat hostname.txt | while read IPLINE; do echo "$IPLINE";done`


###Deploy Success
function SUCCESS {
echo "Deploy Success" | mail -s "Deploy Success" fzebib@gmail.com
}


### Update DBM
function UPDATEDBM {
echo "Adding repositories and Updating Yum"
echo -ne '#####                     (33%)\r'
sleep 1
ssh root@$IP rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm > /dev/null 2>&1
ssh root@$IP rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm > /dev/null 2>&1
echo -ne '#############             (66%)\r'
sleep 1
ssh root@$IP  yum update -yq > /dev/null 2>&1
echo -ne '#######################   (100%)\r'
echo -ne '\n'
}


### Install of LEMP + NFS + MAIL
function LEMP {
echo "Installing appropriate daemons"
echo -ne '#####                     (33%)\r'
ssh root@$IP yum install -y $NFSUTIL $MAIL $NGINX $MYSQL $LAMPPHP > /dev/null 2>&1
echo -ne '#############             (66%)\r'
echo -ne '#######################   (100%)\r'
echo -ne '\n'
}

###Mounting Remotely via Fstab
function MOUNT {
echo "Mounting NFS"
echo -ne '#####                     (33%)\r'
ssh root@$IP "echo 162.243.67.60:/var/www/html /var/www/html  nfs      auto,noatime,nolock,bg,nfsvers=3,intr,tcp,actimeo=1800 0 0 >> /etc/fstab"
sleep 3s
if (ssh root@$IP '[ -d /var/www/html ]')
echo -ne '#############             (66%)\r'
then
sleep 3s
echo "Directory exists, mounting now"
ssh root@$IP mount -a
echo -ne '#######################   (100%)\r'
echo -ne '\n'
else
echo -n Mount directory does not exist, creating and mounting.
sleep 1
ssh root@$IP  'mkdir -p /var/www/html/'
echo -ne '#############             (66%)\r'
sleep 1
ssh root@$IP mount -a
echo -ne '#######################   (100%)\r'
echo -ne '\n'
fi
}


#### Autostart options for LEMP

function AUTOSTART {
echo "Mysql set for Autostart"
echo -ne '#####                     (33%)\r'
sleep 1
ssh root@$IP chkconfig mysqld on


echo "Nginx set for Autostart"
ssh root@$IP chkconfig nginx on
echo -ne '#############             (66%)\r'
sleep 1
echo "Php-fpm set for Autostart"
ssh root@$IP chkconfig php-fpm on

echo "NFS set for Autostart"
ssh root@$IP chkconfig nfs on && service rpcbind start && service nfs start
echo -ne '#######################   (100%)\r'
echo -ne '\n'
}

##SSH-Key Access
for NFS in $(cat nfs.txt)
do
        for hostname in $(cat hostname.txt)
        do
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub $hostname
ssh-copy-id -i ~/.ssh/id_rsa.pub $NFS
done
done


###NFS Mount access
#### This "nfs.txt" should include the nfs server you are editing. The "hostname.txt" should be the new server you are giving access to.
function NFSMOUNT {
echo "Adding server to NFS"
echo -ne '#####                     (33%)\r'
sleep 1
for NFS in $(cat nfs.txt)
do
	for hostname in $(cat hostname.txt)
	do
IP2=`ssh root@$hostname  ifconfig | grep Bcast | cut -d: -f2 | cut -d" " -f1`
for IPREMOTE in $IP2
do
ssh root@$NFS 'echo -e /var/www/html "'$IPREMOTE'(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports'
echo -ne '#############             (66%)\r'
sleep 1
ssh root@$NFS exportfs -a
echo "NFS updated with additional servers"
echo -ne '#######################   (100%)\r'
echo -ne '\n'
done
done
done
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

NFSMOUNT
MOUNT

SUCCESS
