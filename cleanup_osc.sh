#!/bin/bash

source /usr/local/palominodb/scripts/vfa_lib.sh ''

port=$1
port=${port:=3306}

out_file=/tmp/cleanup_osc_${port}.sql
echo "set sql_log_bin=0;" > ${out_file}

stmt="select concat(table_schema,'.', table_name) from information_schema.tables where table_name like '__osc%'"


table_list=`mysql --socket=$(get_socket $port) -sNe "$stmt"`

for table in ${table_list}
do
  echo "drop table ${table};" >> ${out_file}

done

cat ${out_file}

echo "mysql -vvv < ${out_file}"
