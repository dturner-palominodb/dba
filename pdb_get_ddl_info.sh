#!/bin/bash
# filename:  pdb_get_ddl_info.sh
# purpose: return global status for com_alter_table and com_create_table
#          in a format cacti will use.
# author : dturner@palominodb.com
# source :

if [ -z $1 ];then
  echo "Error: Usage $0 <host:port>"
  exit 1
else
  if [[ "$1" =~ ":"  ]];then
    inst_host=`echo $1 |cut -d: -f1`
    inst_port=`echo $1 |cut -d: -f2`
    inst="${inst_host}:${inst_port}"
  else
    inst_host=$1
    inst_port=3306
    inst="${inst_host}:${inst_port}"

  fi
fi

com_alter_table=$(mysql --defaults-file=/root/.my.cnf.cactiuser -h ${inst_host} -P${inst_port} -e 'show global status' |egrep -wi "com_alter_table" | awk '{print $2}')
com_create_table=$(mysql --defaults-file=/root/.my.cnf.cactiuser -h ${inst_host} -P${inst_port} -e 'show global status' |egrep -wi "com_create_table" | awk '{print $2}')

echo "com_alter_table:${com_alter_table} com_create_table:${com_create_table}"

