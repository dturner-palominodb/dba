#!/bin/bash
# author: dturner@palominodb.com
# purpose: create a file with all the tables and their
#          coresponding checksums. The file can be then
#          used to compare with another database using
#          standard utilities like diff.

if [ -z $1 ];then
  echo "Error: usage $0 <port>"
  exit 1
else
  port=$1
fi

source /usr/local/palominodb/scripts/vfa_lib.sh ""

hostname=`hostname`

cmd="select concat(table_schema,'.',table_name) \
     from information_schema.tables where table_schema \
     not in ('mysql','performance_schema','information_schema') \
     order by table_schema, table_name"

table_list=$(mysql --socket=$(get_socket ${port}) -sNe "$cmd")

for table in $table_list
do
 cmd="CHECKSUM TABLE ${table}"
 mysql --socket=$(get_socket ${port}) -sNe "$cmd"
done  2>&1 | tee pdb_checksum_to_file_${hostname}_${port}.txt


