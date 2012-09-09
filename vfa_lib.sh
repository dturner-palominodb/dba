#!/bin/bash
#
# Palominodb virtual flexible architecture library
#
# This script is meant to create a consistent shell interface to mysql environments
# similar to the suggestions in OFA, optimal flexible architecture introduced
# by Cary Milsap at Oracle. The virtual is used because the layout can be 
# whatever the administrator has set up while the interaction with the shell
# is consistent across hosts. This should greatly enhance a DBA's productivity.
#
# Download this file from
# wget --no-check-certificate https://raw.github.com/dturner-palominodb/dba/master/vfa_lib.sh
#
# Suggested setup: in your/root's .bashrc add
#
#   alias dba="source /usr/local/palominodb/scripts/vfa_lib.sh"
#   dba
#
#
# Requirements:
#   /etc/vfatab
#   vfatab is the main file used to determine where the mysql instances
#   my.cnf files live, their port, whether to start them on reboot,
#   and whether it is the default instance for the host. 
#   Example format:   
#     /etc/mysql/my.cnf:3306:Y:Y
#     /tmp/my.cnf:3307:Y
#   Note: if you don't have root ~/vfatab or /tmp/vfatab will work
#
# VARIABLE DEFAULTS
# =====================
# VFA_LIB_COLUMN_NAMES=1
# VFA_LIB_SILENT=0
#
# Fun with vfa_lib.sh:
#
# Switch ports:
#              dba 3309
#              dba 3310
#
#
# ==================================
# FUNCTIONS
# ==================================

function private_setup_vfa {

  # Need a function, check_for_instances, which checks
  # for all the running mysqld processes and creates a vfatab.cnf
  # if it doesn't already exist.

  mkdir -p ${HOME}/palominodb/admin/ddl
  mkdir -p ${HOME}/palominodb/admin/scripts
  mkdir -p ${HOME}/palominodb/admin/sql

  private_create_vfatab

}

function private_get_instances {
  # ps -ef and digg out the the instances to add to vfatab
  echo 
}

function private_create_vfatab {

  # Use get_instances to list all the instances that need to
  # be written to the vfatab file. For now just write 3306

  if [ `touch /etc/vfatab 2>&1 |wc -l` -gt 0 ];then
    vfatab_file=/tmp/vfatab
  fi

  echo "Creating ${vfatab_file}"
  echo "# This file auto generated by vfa_lib.sh" >  ${vfatab_file}
  echo "#`date`"                                  >> ${vfatab_file}

  if [ -e /etc/my.cnf ];then
    echo "/etc/my.cnf:3306:Y:Y"               >> ${vfatab_file}
  elif [ -e /etc/mysql/my.cnf ];then
    echo "/etc/mysql/my.cnf:3306:Y:Y"               >> ${vfatab_file}
  else
    echo "# Needs to be manually changed."          >> ${vfatab_file}
    echo "/etc/mysql/my.cnf:3306:Y:Y"               >> ${vfatab_file}
  fi
}

# This function borrowed from centos based mysqld script
# extract value of a MySQL option from config files
# Usage: get_mysql_option SECTION VARNAME DEFAULT
# result is returned in $result
# We use my_print_defaults which prints all options from multiple files,
# with the more specific ones later; hence take the last match.
get_mysql_option(){
  conf_file=`show_my_cnf ${interim_port}`
  if [ -e $conf_file ];then
        result=`/usr/bin/my_print_defaults --defaults-file=$conf_file "$1" | sed -n "s/^--$2=//p" | tail -n 1`
        if [ -z "$result" ]; then
            # not found, use default
            result="$3"
        fi
   else
     echo "Error: $conf_file for port does not exist."
# DEBUG
# Bug. Need to set prompt back to default after this. Othewise it will be wrong.
     return 1
   fi
}

# Get the default port if none is specified. Otherwise just set to
# what the user passed.
function get_port {
  if [ -z $1 ];then
    port_list=( `grep -i ":Y$" ${vfatab_file} |grep -v "#" |cut -d: -f2` )
  
    # Default to port 3306 if not set in vfatab.
    if [ ${#port_list[@]} -eq 0 ];then
      echo 3306
    elif [ ${#port_list[@]} -eq 1 ];then
      echo "${port_list[0]}"
    else
      echo "Error: more than one instance is set as the default."
      return 1
    fi
  else
    echo $1
  fi

}

# REPLACED
# Check if port info was passed to this script if not then set 
# port returned to 3306
# function get_port {
#   if [ -z $1 ];then 
#     echo 3306
#   else
#     echo $1
#   fi
# }

# The values in this case are not returned but just set as globals.
# I don't like it so if you have ideas on how to clean up great!!
function set_inst_info {
  if [ -z $1 ];then
    echo "Error: usage $0 [port]"
    return 1
  else 
    inst_port=$1
  fi

  result=`grep -v "^#" ${vfatab_file}|grep ${inst_port}`

  inst_vfa_cnf=`echo $result|awk -F: '{print $1}'`
  inst_auto_start=`echo $result|awk -F: '{print $3}'`

}

function get_latest_vfa_lib {
  vfa_script_dir="${vfa_script_root}/admin/scripts}"

  cp ${vfa_script_dir}/vfa_lib.sh /tmp/bak.vfa_lib.sh

  wget --no-check-certificate https://raw.github.com/dturner-palominodb/dba/master/vfa_lib.sh

  if [ `pwd` != "${vfa_script_dir}" ];then
    cp vfa_lib.sh ${vfa_script_dir}/
  fi

}

# get the socket based off the port passed
function get_socket {
  if [ -z $1 ];then
    echo "Error: usage $0 [port]"
    return 1
  else 
    inst_port=$1
  fi

  # set inst_vfa_cnf variable
  set_inst_info ${inst_port}

  if [ -z $inst_vfa_cnf ];then
    echo "/dev/null"
  else
    grep ^socket ${inst_vfa_cnf} | head -1|awk -F= '{print $2}'|sed "s/ //g"
  fi

}

# Unsure how this fits into the script. Likely used
# by other scripts that need to reference .my.cnf 
function get_mysql_login_info {
  vfa_cnf_dir=`ls -d ~`
  my_cnf_file="${vfa_cnf_dir}/.my.cnf"

  if [ ! -f ${my_cnf_file} ];then
    echo "Error: $my_cnf_file does not exist."
    return
  fi

  user=`grep "^user" ${my_cnf_file} | cut -d= -f2 |sed s"/ //g"`
  pass=`grep "^pass" ${my_cnf_file} | cut -d= -f2 |sed s"/ //g"`
  echo "${user} ${pass}"

  # Use the following to call the function and
  # return output to an array.
  # credentials=( $(get_mysql_login_info) )

}

function check_and_set_environment_variables {
  if [ -z $VFA_LIB_COLUMN_NAMES ];then
    VFA_LIB_COLUMN_NAMES=1
  fi

  if [ -z $VFA_LIB_SILENT ];then
    VFA_LIB_SILENT=0
  fi

}

# When running exec don't show additional info
function quiet_exec {
  VFA_LIB_COLUMN_NAMES=0
  VFA_LIB_SILENT=1
}

# When running exec show additional info
# Default mode
function loud_exec {
  VFA_LIB_COLUMN_NAMES=1
  VFA_LIB_SILENT=0
}

function show_db_size {
    if [ -z $1 ];then
      conn $default_inst_port "select round(sum(data_length)/1024/1024) as data_mb, round(sum(index_length)/1024/1024) as index_mb, \
                                      round(sum(data_length)/1024/1024) + round(sum(index_length)/1024/1024) as total_mb \
                               from information_schema.tables"
    else
      conn $1                 "select round(sum(data_length)/1024/1024) as data_mb, round(sum(index_length)/1024/1024) as index_mb, \
                                      round(sum(data_length)/1024/1024) + round(sum(index_length)/1024/1024) as total_mb \
                               from information_schema.tables"
    fi

}

function show_db_sizes {
    if [ -z $1 ];then
      conn $default_inst_port "select table_schema, round(sum(data_length)/1024/1024) as data_mb, round(sum(index_length)/1024/1024) as index_mb, \
                                                    round(sum(data_length)/1024/1024) + round(sum(index_length)/1024/1024) as total_mb \
                               from information_schema.tables group by table_schema"
    else
      conn $1                 "select table_schema, round(sum(data_length)/1024/1024) as data_mb, round(sum(index_length)/1024/1024) as index_mb, \
                                                    round(sum(data_length)/1024/1024) + round(sum(index_length)/1024/1024) as total_mb \
                               from information_schema.tables group by table_schema"
    fi

}

function show_slave_status {
    if [ -z $1 ];then
      conn $default_inst_port "show slave status\G"
    else 
      conn $1 "show slave status\G"
    fi

} 
alias v_s3=show_slave_status

function show_processlist {
    if [ -z $1 ];then
      conn $default_inst_port "show processlist"
    else 
      conn $1 "show processlist"
    fi

}

function show_full_processlist {
    if [ -z $1 ];then
      conn $default_inst_port "show full processlist"
    else
      conn $1 "show full processlist"
    fi

}

function skip_slave {
  if [ -z $1 ];then
    conn $default_inst_port "SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1; START SLAVE"
  else
    conn $1 "SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1; START SLAVE"
  fi
}

function show_slaves {
  stmt="show processlist"
  filter="grep | bleh"

  if [ -z $1 ];then
    conn $default_inst_port "$stmt"
  else
    conn $1 "$stmt"
  fi


}

function show_global_status {
  stmt="show global status"

  if [ -z $1 ];then
    conn $default_inst_port "$stmt"
  else
    conn $1 "$stmt"
  fi

}

alias v_sgs="show_global_status"

function show_global_variables {
  stmt="show global variables"
  if [ -z $1 ];then
    conn $default_inst_port "$stmt"
  else
    conn $1 "$stmt"
  fi


}

alias v_sgv="show_global_variables"


function show_my_cnf {
  if [ -z $1 ];then
    grep -v "#" ${vfatab_file} |grep $default_inst_port |cut -d: -f1

  else
    grep -v "#" ${vfatab_file} |grep $1 |cut -d: -f1

  fi
}

alias v_smc="show_my_cnf"

function show_my_cnfs {
    grep -v "#" ${vfatab_file} |cut -d: -f1

}


# Function needs to be actually written. Laine gave me this and it works well.
function get_binlog_summary {
  echo
  # mysqlbinlog mysql-bin.009254 | egrep "^INSERT|^REPLACE|^UPDATE" | sed -e 's/LOW_PRIORITY//' | awk '{print $1 " " $2 " " $3}' | sort | uniq -c | sort > /tmp/mysql-bin.009254.out 

}

# Show the ports available on a host
function show_ports {
  grep -v "#" ${vfatab_file} |cut -d: -f2

}


# The third field in vfatab specifies whether the port should
# be managed by this script.
function show_managed_ports {
  grep -i ":Y:" ${vfatab_file} |grep -v "#" |cut -d: -f2

}

# Show the sockets available on a host
function show_sockets {
 
  for cnf in `grep -v "#" ${vfatab_file} |cut -d: -f1`
  do 
    grep socket ${cnf} |sort -u |awk '{print $3}'
  done

}

# Show the datadir even if the db is down.
function show_datadir {
  if [ -z $1 ];then
    show_global_variables $default_inst_port 2> /dev/null|grep datadir |awk '{print $2}'
    if [ ${PIPESTATUS[1]} -gt 0 ];then
      egrep datadir `show_my_cnf $default_inst_port` |awk '{print $3}'
    fi
  else
    show_global_variables $1 2> /dev/null|grep datadir |awk '{print $2}'
    if [ ${PIPESTATUS[1]} -gt 0 ];then
      egrep datadir `show_my_cnf $1` |awk '{print $3}'
    fi
  fi
}

function show_error_log {
  if [ -z $1 ];then
    show_global_variables $default_inst_port |grep log_err |awk '{print $2}'
  else
    show_global_variables $1 |grep log_err |awk '{print $2}'
  fi
}

alias show_errorlog="show_error_log"

function show_error_logs {
  for port in `show_ports`
  do 
    show_global_variables $port |grep log_err |awk '{print $2}'
  done

}

function show_binlog_dir {
  if [ -z $1 ];then
    egrep log_bin `show_my_cnf $default_inst_port`|grep -v "#" |awk '{print $3}' | sed "s/\/$//"|awk -F"/" '{gsub($NF,"");print}'
  else
    egrep log_bin `show_my_cnf $1` |grep -v "#"|awk '{print $3}' | sed "s/\/$//"|awk -F"/" '{gsub($NF,"");print}'
  fi
}

function show_binlog_dirs {
  for port in `show_ports`
  do
    show_binlog_dir ${port}
  done
}

function show_slow_log {
# under construction
  if [ -z $1 ];then
    egrep log-slow-queries  `show_my_cnf $default_inst_port` |awk '{print $3}'
  else
    egrep log-slow-queries  `show_my_cnf $1` |awk '{print $3}'
  fi
}

function show_slow_logs {
  for port in `show_ports`
  do
    egrep log-slow-queries  `show_my_cnf $port` |awk '{print $3}'
  done
}



function show_functions {
  egrep "^function " ${vfa_script_root}/vfa_lib.sh | \
    grep -v private_ | cut -d" " -f2

}

# ==================================
# MAIN
# ==================================

# Todo: add a flag to vfatab that indicates whether the instance
#       is the default instance to log into on the given host
#

# This allows for an override of the vfatab. Often useful
# for hosts with restricted access.
if [ -f ${HOME}/vfatab ];then
  vfatab_file=${HOME}/vfatab

elif [ -f /tmp/vfatab ];then
  vfatab_file=/tmp/vfatab

elif [ -f /etc/vfatab ];then
  vfatab_file=/etc/vfatab

else
  vfatab_file=/etc/vfatab
  private_setup_vfa

fi

if [ -d /usr/local/palominodb/scripts ];then
  vfa_script_root="/usr/local/palominodb/scripts"
else
  vfa_script_root=`pwd`
# else
#   echo "Error: unable to find /usr/local/palominodb/scripts" 
#   return 1
fi

# With new root need to rethink this. Commenting out for now
# alias v_scripts="cd ${vfa_script_root}/admin/scripts"
# alias v_sql="cd ${vfa_script_root}/admin/sql"
# alias v_ddl="cd ${vfa_script_root}/admin/ddl"

unset default_inst_port

# if no port info passed default to 3306
# trying to get it to work with a default set in vfatab as well.
default_inst_port=$(get_port $1)
default_inst_info=`grep -v "^#" ${vfatab_file} |grep ${default_inst_port}`

if [ -z $default_inst_info ];then
  echo "Error: no instance found in $vfatab_file with port of $default_inst_port"
  # Unset these variables so none of the functions that may have been previously set correctly work
  unset default_inst_admin_user
  unset default_inst_admin_pass
  unset default_inst_port
  unset default_inst_socket
  return 1
fi


default_inst_auto_start=`echo ${default_inst_info} | awk -F: '{print $3}'`
default_inst_vfa_cnf=`echo ${default_inst_info} | awk -F: '{print $1}'`

# Set prompt 
# username@hostname:default_inst_port directory
export PS1="[\u@\h:${default_inst_port} \w]#"
# [root@blade01-05 scripts]#
# export PS1="\w \u\$"

interim_port=${inst_port}
get_mysql_option mysqld socket 
default_inst_socket="$result"

# Temporary until script figures out 
# user and password
default_inst_admin_user=root
default_inst_admin_pass=""

# UNDER CONSTRUCTION. REMOVE INI__, deprecated
# function vfa_logdir {
#   if [ -z $1 ];then
#     call_read_ini ${default_inst_port}
#     echo ${INI__mysqld__socket}
#     echo ${INI__mysqld__slow_query_log_file}
#     echo ${INI__mysqld__log_error}
#     echo Use default
#   else
#     call_read_ini ${1}
#     echo ${INI__mysqld__socket}
#     echo Use $1
#   fi
#  
#   env
# 
# }

function convert_array_to_in_list() {
# A script that's useful for converting lists/arrays
# to sql in lists
# 
# example array for testing:
# table_list=( `echo "a b c d"` ) 

  echo $@ | sed "s/^/('/;s/ /','/g;s/$/')/"

}


# conn - a function to log into instances for the most part without a password
function conn {

  # localhost        - connect to localhost via default socket
  # localhost:3306   - connect to localhost via specified socket
  # 3307             - treat same as previous line. 
  # hostname:3307    - connect to hostnmae via port
  # hostname         - connect to hostname via port 3306
  if [ -z ${default_inst_admin_pass} ];then
    password_arg=""
  else
    password_arg="-p${default_inst_admin_pass}"
  fi

  #
  # Make $3 check for --verbose or better yet have a vfa_lib.rc file
  # and variables that you can set. Variables should take precedence
  #

  # If no port passed use default and do not execute anything
  if [ -z $1 ];then
      inst_host=localhost
      inst_port="$default_inst_port"
      inst_socket="${default_inst_socket}" 
  # Else see if port info or a request to execute sql is passed
  else
    if [[ $1 =~ ^localhost:33[0-9][0-9]$ ]];then
      inst_host=`echo $1 | awk -F: '{print $1}'` 
      inst_port=`echo $1 | awk -F: '{print $2}'` 

      interim_port=${inst_port}
      get_mysql_option mysqld socket 
      inst_socket="$result"

    elif [[ $1 =~ ^localhost$ ]];then
      inst_host="localhost"
      inst_port="${default_inst_port}"
      inst_socket="${default_inst_socket}"

    elif [[ $1 =~ :33[0-9][0-9]$ ]];then
      inst_host=`echo $1 | awk -F: '{print $1}'` 
      inst_port=`echo $1 | awk -F: '{print $2}'` 
      inst_socket=""

    elif [[ $1 =~ ^33[0-9][0-9]$ ]];then
      inst_host="localhost"
      inst_port=$1

      interim_port=${inst_port}
      get_mysql_option mysqld socket 
      inst_socket="$result"

    # Assume $1 is the hostname to connect to
    else
      inst_host="$1"
      inst_port=3306
      inst_socket=""

    fi

  fi

  [ ! -z ${inst_port} ] && port_arg="--port=${inst_port}"
  [ ! -z ${inst_socket} ] && socket_arg="--socket=${inst_socket}"

  check_and_set_environment_variables

  # Set exec_arg_list NULL
  exec_arg_list=""

  if [ $VFA_LIB_COLUMN_NAMES -lt 1 ];then
     exec_arg_list="$exec_arg_list -N"
  fi

  if [ $VFA_LIB_SILENT -gt 0 ];then
     exec_arg_list="$exec_arg_list -s"
  fi

  # Check for a sql statement. If so set silent execute options 
  if [ -z "$2" ];then
    stmt=""
    exec_arg_list=""
  else
    stmt=$2
    # Always put -e flag last in exec_arg_list
    exec_arg_list="$exec_arg_list -e"
  fi

  mysql -u ${default_inst_admin_user} ${password_arg} --host=${inst_host} ${port_arg} ${socket_arg} ${exec_arg_list} "${stmt}"


# echo "inst_host=$inst_host"
# echo "inst_port=$inst_port"
# echo "inst_socket=$inst_socket"

  # Globals can suck. Unsetting.
  unset inst_host
  unset inst_port
  unset inst_socket

}

