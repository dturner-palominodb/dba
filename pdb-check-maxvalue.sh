#!/bin/bash
# author: dturner@palominodb.com
# file: pdb-check-maxvalue.sh
# purpose: check for max values in all columns of integer types that have
#          reached N pct of the maximum value for that type of integer.
#
# repo: https://github.com/dturner-palominodb/dba
# 
#       To download just this file do the following:
#       wget --no-check-certificate https://raw.github.com/dturner-palominodb/dba/master/pdb-check-maxvalue.sh
#
# phase II features:
#                   config file  : many options would be good to have as options in a config file
#
#                   store history: the values returned tell us a lot about the growth rate of certain columns.
# 
#                   exlusion list: there will be some columns that clients don't care about.
#
#                   integrate with nagios: we need all clients informed when max values will be reached for their columns
#



vfa_lib_file="/usr/local/palominodb/scripts/vfa_lib.sh"

if [ -z $1 ];then
  echo "Error: usage $0 <PCT_ALLOWED> <PORT>"
  echo "       ie: $0 60 3307               "
  exit 1
else
 pct_allowed=`echo $1 | sed s/%//g`
 port=$2

fi

if [ -e ${vfa_lib_file} ];then
  source ${vfa_lib_file} ''
  socket_info="--socket=$(get_socket ${port:=3306})"
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
      replace(column_type,' zerofill','') regexp '^tinyint\\\([0-9]*\\\)$'          THEN ~0 >> 57 #tiny   int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^tinyint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 56 #tiny   int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^smallint\\\([0-9]*\\\)$'          THEN ~0 >> 49 #small  int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^smallint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 48 #small  int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^mediumint\\\([0-9]*\\\)$'          THEN ~0 >> 41 #medium int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^mediumint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 40 #medium int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^int\\\([0-9]*\\\)$'          THEN ~0 >> 33 #       int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^int\\\([0-9]*\\\) unsigned$' THEN ~0 >> 32 #       int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^bigint\\\([0-9]*\\\)$'          THEN ~0 >>  1 #big    int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^bigint\\\([0-9]*\\\) unsigned$' THEN ~0       #big    int unsigned
    ELSE
      'failed'
  END),
  ' * 100 )', 
  ', round(ifnull(max(\`', column_name, '\`),0)),',
  (CASE
      1
    WHEN
      replace(column_type,' zerofill','') regexp '^tinyint\\\([0-9]*\\\)$'          THEN ~0 >> 57 #tiny   int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^tinyint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 56 #tiny   int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^smallint\\\([0-9]*\\\)$'          THEN ~0 >> 49 #small  int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^smallint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 48 #small  int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^mediumint\\\([0-9]*\\\)$'          THEN ~0 >> 41 #medium int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^mediumint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 40 #medium int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^int\\\([0-9]*\\\)$'          THEN ~0 >> 33 #       int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^int\\\([0-9]*\\\) unsigned$' THEN ~0 >> 32 #       int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^bigint\\\([0-9]*\\\)$'          THEN ~0 >>  1 #big    int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^bigint\\\([0-9]*\\\) unsigned$' THEN ~0       #big    int unsigned
    ELSE
      'failed'
  END),
  ') as INFO ',
  'from \`', table_schema, '\`.\`', table_name, '\` '
  'having round(ifnull(max(\`', column_name, '\`),0) / ',
  (CASE
      1
    WHEN
      replace(column_type,' zerofill','') regexp '^tinyint\\\([0-9]*\\\)$'          THEN ~0 >> 57 #tiny   int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^tinyint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 56 #tiny   int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^smallint\\\([0-9]*\\\)$'          THEN ~0 >> 49 #small  int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^smallint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 48 #small  int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^mediumint\\\([0-9]*\\\)$'          THEN ~0 >> 41 #medium int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^mediumint\\\([0-9]*\\\) unsigned$' THEN ~0 >> 40 #medium int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^int\\\([0-9]*\\\)$'          THEN ~0 >> 33 #       int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^int\\\([0-9]*\\\) unsigned$' THEN ~0 >> 32 #       int unsigned
    WHEN
      replace(column_type,' zerofill','') regexp '^bigint\\\([0-9]*\\\)$'          THEN ~0 >>  1 #big    int signed
    WHEN
      replace(column_type,' zerofill','') regexp '^bigint\\\([0-9]*\\\) unsigned$' THEN ~0       #big    int unsigned
    ELSE
      'failed'
  END),
  ' * 100) > ${pct_allowed} ',
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
