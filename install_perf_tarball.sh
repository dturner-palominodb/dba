#!/bin/bash

dest_dir=/usr/local/palominodb/scripts
tarball=/tmp/perf_tarball.tar
tarball_dir=/tmp/perf_tarball
mysql_conf_dir=/etc/mysql

mkdir -p ${dest_dir} 2> /dev/null
cd ${dest_dir}

cp ${tarball_dir}/* ${dest_dir}

if [ `ls ${mysql_conf_dir}/my-*33*.cnf 2> /dev/null |wc -l` -lt 1 ];then
  if [ -d /data/admin/conf/ ];then
    mysql_conf_dir="/data/admin/conf"
  else
    echo "Error: problem finding my.cnf files in ${mysql_conf_dir}"
    exit 1
  fi
fi

for conf in `ls ${mysql_conf_dir}/my-*33*.cnf |sort`
do
  echo $conf:$(echo $conf |awk -F"/" '{print $NF}'|sed "s/my-m//;s/.cnf//"):Y:N
done > ${mysql_conf_dir}/vfatab
ln -s ${mysql_conf_dir}/vfatab /etc/vfatab

if [ -e /etc/init.d/mysql ];then
  mv /etc/init.d/mysql /etc/init.d/mysql.old
fi

if [ -e /etc/init.d/mysqld ];then
  mv /etc/init.d/mysqld /etc/init.d/mysqld.old
fi

ln -s /usr/local/palominodb/scripts/mysqld /etc/init.d/mysql
ln -s /usr/local/palominodb/scripts/mysqld /etc/init.d/mysqld


echo "Install complete."