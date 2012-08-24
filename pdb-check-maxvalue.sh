#!/bin/bash
# author: dturner@palominodb.com
# file: pdb-check-maxvalue.sh
# purpose: check all int columns and if the max value in that column is greater than
#          N pct allowed print that column to stdout.
# repo: https://github.com/dturner-palominodb/dba
#

vfa_lib_file="/usr/local/palominodb/scripts/vfa_lib.sh"

if [ -z $1 ];then
  echo "Error: usage $0 <PCT_ALLOWED> <PORT>"
  echo "       ie: $0 60 3307               "
  exit 1
else
 pct_allowed=`echo $1 | sed s/%//g`

fi

if [ -z $2 ];then
  port=3306
else
  port=$2
fi

if [ -e ${vfa_lib_file} ];then
  source ${vfa_lib_file} ''
  socket_info="--socket=$(get_socket ${port})"
else
  socket_info=""  
fi

sql_file="pdb-check-maxvalue.sql"
# The generated statements
proc_file="pdb-check-maxvalue.proc"

cat > ${sql_file} <<EOF
select 
  concat('select CONCAT_WS('':'',''',
  table_schema,'.',table_name,'.',column_name,
  ''', ',
  'round(ifnull(max(\`', column_name, '\`),0) / ',
  (CASE
      1
    WHEN
      column_type regexp '^tinyint\\\([0-9]*\\\)$'          THEN ~0 >> 57 #tiny   int signed
    WHEN
      column_type regexp '^tinyint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 56 #tiny   int unsigned
    WHEN
      column_type regexp '^smallint\\\([0-9]*\\\)$'          THEN ~0 >> 49 #small  int signed
    WHEN
      column_type regexp '^smallint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 48 #small  int unsigned
    WHEN
      column_type regexp '^mediumint\\\([0-9]*\\\)$'          THEN ~0 >> 41 #medium int signed
    WHEN
      column_type regexp '^mediumint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 40 #medium int unsigned
    WHEN
      column_type regexp '^int\\\([0-9]*\\\)$'          THEN ~0 >> 33 #       int signed
    WHEN
      column_type regexp '^int\\\([0-9]*\\\) unsigned$' THEN ~0 >> 32 #       int unsigned
    WHEN
      column_type regexp '^bigint\\\([0-9]*\\\)$'          THEN ~0 >>  1 #big    int signed
    WHEN
      column_type regexp '^bigint\\\([0-9]*\\\) unsigned$' THEN ~0       #big    int unsigned
    ELSE
      'failed'
  END),
  ' * 100 )', 
  ', round(ifnull(max(\`', column_name, '\`),0)),',
  (CASE
      1
    WHEN
      column_type regexp '^tinyint\\\([0-9]*\\\)$'          THEN ~0 >> 57 #tiny   int signed
    WHEN
      column_type regexp '^tinyint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 56 #tiny   int unsigned
    WHEN
      column_type regexp '^smallint\\\([0-9]*\\\)$'          THEN ~0 >> 49 #small  int signed
    WHEN
      column_type regexp '^smallint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 48 #small  int unsigned
    WHEN
      column_type regexp '^mediumint\\\([0-9]*\\\)$'          THEN ~0 >> 41 #medium int signed
    WHEN
      column_type regexp '^mediumint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 40 #medium int unsigned
    WHEN
      column_type regexp '^int\\\([0-9]*\\\)$'          THEN ~0 >> 33 #       int signed
    WHEN
      column_type regexp '^int\\\([0-9]*\\\) unsigned$' THEN ~0 >> 32 #       int unsigned
    WHEN
      column_type regexp '^bigint\\\([0-9]*\\\)$'          THEN ~0 >>  1 #big    int signed
    WHEN
      column_type regexp '^bigint\\\([0-9]*\\\) unsigned$' THEN ~0       #big    int unsigned
    ELSE
      'failed'
  END),
  ') as INFO ',
  'from \`', table_schema, '\`.\`', table_name, '\` '
  'having round(ifnull(max(\`', column_name, '\`),0) / ',
  (CASE
      1
    WHEN
      column_type regexp '^tinyint\\\([0-9]*\\\)$'          THEN ~0 >> 57 #tiny   int signed
    WHEN
      column_type regexp '^tinyint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 56 #tiny   int unsigned
    WHEN
      column_type regexp '^smallint\\\([0-9]*\\\)$'          THEN ~0 >> 49 #small  int signed
    WHEN
      column_type regexp '^smallint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 48 #small  int unsigned
    WHEN
      column_type regexp '^mediumint\\\([0-9]*\\\)$'          THEN ~0 >> 41 #medium int signed
    WHEN
      column_type regexp '^mediumint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 40 #medium int unsigned
    WHEN
      column_type regexp '^int\\\([0-9]*\\\)$'          THEN ~0 >> 33 #       int signed
    WHEN
      column_type regexp '^int\\\([0-9]*\\\) unsigned$' THEN ~0 >> 32 #       int unsigned
    WHEN
      column_type regexp '^bigint\\\([0-9]*\\\)$'          THEN ~0 >>  1 #big    int signed
    WHEN
      column_type regexp '^bigint\\\([0-9]*\\\) unsigned$' THEN ~0       #big    int unsigned
    ELSE
      'failed'
  END),
  ' * 100) > 0 ',
  ';')
from 
  information_schema.columns 
where 
  # data_type in ('tinyint')
  data_type in ('tinyint','smallint','mediumint','int','integer','bigint')
and
  table_schema not in ('VALUE WILL BE AN OPTION IN FUTURE VERSION. HARD CODE IF NECESSARY');
  # table_schema not in ('mysql','information_schema','VALUE WILL BE AN OPTION IN FUTURE VERSION. HARD CODE IF NECESSARY');

EOF

mysql -sN ${socket_info} < ${sql_file} > ${proc_file}

# For debugging
# cat ${proc_file}

mysql -sN ${socket_info} < ${proc_file}  |sort -t: -nk2

