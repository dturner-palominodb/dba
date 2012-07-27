#!/bin/bash
# author: dturner@palominodb.com
# purpose: load multiple tables in parallel for faster
#          restore times.
#

if [ -z $1 ];then
  echo "Error: usage $0 <port> <source_dir> <dest_dir>"
  echo "       ie: $0 3318 /data/backup /data/mysql"
  echo "       Note: source and dest will default to the"
  echo "             example above.                     "
  exit 1
else
  port=$1

  if [ -z $2 ];then
    source_dir=/data/backup/${port}
  else
    source_dir=${2}/${port}
  fi

  if [ -z $3 ];then
    dest_dir=/data/mysql/m${port}
  else
    dest_dir=${3}/m${port}
  fi
 
fi  

# This specifies the number of mysqlimports to run in parallel.
#
parallelism=4

source /usr/local/palominodb/scripts/vfa_lib.sh ""

# This assumes a mysql dictionary has been created in /var/lib/mysql/mysql
#
create_template_db() {

  dir_list="admin  binlog  data  ib  logs  relay  tmp"

  echo "cd ${dest_dir}"
  cd ${dest_dir}

  echo "mkdir ${dir_list}"
  mkdir ${dir_list}


  echo "cp -r /var/lib/mysql/mysql ${dest_dir}/data"
  cp -r /var/lib/mysql/mysql ${dest_dir}/data


  echo "cp -r /var/lib/mysql/test ${dest_dir}/data"
  cp -r /var/lib/mysql/test ${dest_dir}/data

  echo "cp -r /var/lib/mysql/performance_schema ${dest_dir}/data"
  cp -r /var/lib/mysql/performance_schema ${dest_dir}/data

  echo "chown -R mysql:mysql ${dest_dir}"
  chown -R mysql:mysql ${dest_dir}

  /etc/init.d/mysql start ${port}

}

# Remove this from future versions. We just need to figure out why the dump is setting the character set
# in the .sql files to utf8 and correct it.
fix_character_set_issue() {
  echo "Changing character set from utf8 to latin1 in ${source_dir}."
  echo

  find ${source_dir} -name "*.sql" -exec sed -i 's/character_set_client = utf8/character_set_client = latin1/' {} \;

}

# Create the databases for tables 
create_databases() {

  socket=$(get_socket ${port})

  echo 
  
  for schema in ${schema_list}
  do
    echo "conn ${port} \"create database if not exists ${schema}\""
    conn ${port} "create database if not exists ${schema}"

  done

  echo 

}

create_tables() {
  for schema in ${schema_list}
  do 
    echo
    echo "Creating tables in ${schema}"
    for ddl_file in `ls   ${source_dir}/${schema}/*.sql 2> /dev/null`
    do 
      echo "mysql --socket=$(get_socket ${port}) -fsN ${schema} ${ddl_file} "
      mysql --socket=$(get_socket ${port}) -fsN ${schema} < ${ddl_file} 
    done
    echo
  done
  echo

}

# Remove this from future versions.
grants_kludge() {

  echo "Granting privileges"
  echo

mysql --socket=$(get_socket ${port}) -sN <<EOF
-- Grants dumped by pt-show-grants
-- Dumped from server Localhost via UNIX socket, MySQL 5.0.51a-3ubuntu5.8-log at 2012-07-26 19:51:18
-- Grants for ''@'devdb01.care2.com'
GRANT USAGE ON *.* TO ''@'devdb01.care2.com';
-- Grants for ''@'localhost'
GRANT USAGE ON *.* TO ''@'localhost';
-- Grants for 'debian-sys-maint'@'localhost'
GRANT ALTER, CREATE, CREATE TEMPORARY TABLES, DELETE, DROP, EXECUTE, FILE, INDEX, INSERT, LOCK TABLES, PROCESS, REFERENCES, RELOAD, REPLICATION CLIENT, REPLICATION SLAVE, SELECT, SHOW DATABASES, SHUTDOWN, SUPER, UPDATE ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY PASSWORD '*F55CF3D16331230BFF254FFA24AB8C4CE36EA4D2' WITH GRANT OPTION;
-- Grants for 'nobody'@'%'
GRANT ALL PRIVILEGES ON *.* TO 'nobody'@'%';
-- Grants for 'nobody'@'localhost'
GRANT ALL PRIVILEGES ON *.* TO 'nobody'@'localhost';
-- Grants for 'ops'@'%'
GRANT ALL PRIVILEGES ON *.* TO 'ops'@'%';
-- Grants for 'ops'@'localhost'
GRANT ALL PRIVILEGES ON *.* TO 'ops'@'localhost';
-- Grants for 'repli'@'%'
GRANT ALL PRIVILEGES ON *.* TO 'repli'@'%' IDENTIFIED BY PASSWORD '7ac8154017aaccfb';
-- Grants for 'repli'@'localhost'
GRANT ALL PRIVILEGES ON *.* TO 'repli'@'localhost' IDENTIFIED BY PASSWORD '7ac8154017aaccfb';
-- Grants for 'richard'@'%'
GRANT ALL PRIVILEGES ON *.* TO 'richard'@'%';
-- Grants for 'root'@'127.0.0.1'
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
-- Grants for 'root'@'devdb01.care2.com'
GRANT ALL PRIVILEGES ON *.* TO 'root'@'devdb01.care2.com' WITH GRANT OPTION;
-- Grants for 'root'@'localhost'
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
EOF

}

load_tables() {

  echo "Starting table loads"
  echo

  # Initialize task list array
  task_list=()

  for schema in ${schema_list}
  do
    for dml_file in `ls   ${source_dir}/${schema}/*.txt 2> /dev/null`
    do
      task_list=("${task_list[@]}" "mysqlimport --socket=$(get_socket ${port}) ${schema} ${dml_file}")
    done
  done

  counter=0
  start_time=`date +"%s"`
  for task in "${task_list[@]}"
  do
    counter=$(( counter + 1 ))
    echo "$task"
    $task
    if [ $counter -eq $parallelism ];then
      echo "Waiting"
      wait
      counter=0
    fi
  done
  # Add an additional wait in case their aren't enough files
  # to trigger the wait.
  wait
  end_time=`date +"%s"`
  total_time=$(( ($end_time - $start_time) / 60 ))

  echo "Checking for issues with load. It's highly recommended you perform a manual check as well."
  echo
  # Put this in load_tables when you get back.
  if [ `grep "Deleted" ${logfile} | grep -v "Deleted: 0  Skipped: 0  Warnings: 0" |wc -l` -gt 0 ];then
    echo "Error: check ${logfile} for warnings in the load, skipped, or deleted rows."
    echo
  fi

  echo "${schema} completed in ${total_time} minutes"

}

# MAIN

if [ -d ${dest_dir} ];then
  echo "Error: ${dest_dir} exists. Remove the destination directory before restoring."
  exit 1
else
  echo "mkdir -p ${dest_dir}"
  mkdir -p ${dest_dir} 2> /dev/null

fi

logfile=${dest_dir}/load.log

exec > >(tee $logfile) 2>&1

date

# Need mysql and test database created and the database
# started before we can load.
create_template_db 

fix_character_set_issue

schema_list=`find ${source_dir} -mindepth 1 -maxdepth 1 -type d |egrep -wv "mysql|performance_schema"|awk -F"/" '{print $NF}'`

create_databases 
create_tables

# Probably should replace using grants
grants_kludge

load_tables


date
