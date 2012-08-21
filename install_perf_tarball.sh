#!/bin/bash

dest_dir=/usr/local/palominodb/scripts
tarball_dir=`pwd`
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

rm -f /etc/vfatab
ln -s ${mysql_conf_dir}/vfatab /etc/vfatab

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

# Check for bashrc and add dba alias if it doesn't already exist

if [ -e ${HOME}/.bashrc ];then
  if [ `grep "alias dba" ${HOME}/.bashrc | wc -l` -lt 1 ];then
    echo >> ${HOME}/.bashrc
    echo "# Added by palominodb for vfa_lib.sh `date`" >> ${HOME}/.bashrc
    echo "alias dba=\"source ${dest_dir}/vfa_lib.sh\"" >> ${HOME}/.bashrc

  fi
fi

echo "Install complete."