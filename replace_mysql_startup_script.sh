#!/bin/bash

dest_dir=/usr/local/palominodb/scripts
tarball_dir=`pwd`
mysql_conf_dir=/etc/mysql

mkdir -p ${dest_dir} 2> /dev/null
cd ${dest_dir}

if [ -e /etc/init.d/mysql ];then
  if [ -h /etc/init.d/mysql ];then
    rm -f /etc/init.d/mysql
  else
    mv /etc/init.d/mysql /etc/init.d/mysql.old
  fi
fi

if [ -e /etc/init.d/mysqld ];then
  if [ -h /etc/init.d/mysqld ];then
    rm -f /etc/init.d/mysqld
  else
    mv /etc/init.d/mysqld /etc/init.d/mysqld.old
  fi
fi

ln -s /usr/local/palominodb/scripts/mysqld /etc/init.d/mysql
ln -s /usr/local/palominodb/scripts/mysqld /etc/init.d/mysqld

echo "Replace of mysql startup script complete."
