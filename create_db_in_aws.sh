#!/bin/bash

sleep_time=1

echo "Note: This is a destructive script. It will completely remove the database on 3306"
echo "and create a new one. Sleeping ${sleep_time}s in case you want to control-c out."
sleep ${sleep_time}
echo


# Check db to see if it is production.
# 
other_dir_count=`find /var/lib/mysql -mindepth 1 -type d  |egrep -v "/var/lib/mysql/mysql|/var/lib/mysql/test" |wc -l`

if [ ${other_dir_count} -gt 0 ];then
  echo "Error: directories other than mysql found. Possible production host."
  echo "If the host is not production remove the other directories and"
  echo "run $0 again."
  find /var/lib/mysql -mindepth 1 -type d  |grep -v "/var/lib/mysql/mysql" 
  exit 1
fi

echo "Killing mysql"
echo
pkill -9 -f mysqld

echo "Removing database and binary log files."
echo
rm -rf /var/lib/mysql/*
rm -f /data/mysql/bin-log/*

echo "Creating the database."
echo
mysql_install_db

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /data/mysql/bin-log/

/etc/init.d/mysql start


mysql -e 'select "Completed Database Creation."'