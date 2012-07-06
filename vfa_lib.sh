#!/bin/bash
#
# Palominodb virtual flexible architecture library
#
# This script is meant to create a consistent shell interface to mysql environments
# similar to the suggestions in OFA, optimal flexible architecture introduced
# by Cary Milsap at Oracle. The virtual is used because the layout can be 
# whatever the administrator has set up while the interaction with the shell
# is consistent across hosts. This should greatly enhance DBAs' productivity.
#
#   
#
# Suggested setup: in your/root's .bashrc add
#
#   home_dir=`ls -d ~`
#   alias dba="source ${home_dir}/palominodb/admin/scripts/vfa_lib.sh"
#   dba
#
#
# Requirements:
#   /etc/mytab
#   mytab is the main file used to determine where the mysql instances
#   my.cnf files live, their port, whether to start them on reboot,
#   and whether it is the default instance for the host. 
#   Example format:   
#     /etc/mysql/my.cnf:3306:Y:Y
#     /tmp/my.cnf:3307:Y
#   Note: if you don't have root ~/mytab or /tmp/mytab will work
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
# Check if port info was passed to this script if not then set 
# port returned to 3306
function get_port {
  if [ -z $1 ];then 
    echo 3306
  else
    echo $1
  fi
}

# The values in this case are not returned but just set as globals.
# I don't like it so if you have ideas on how to clean up great!!
function set_inst_info {
  if [ -z $1 ];then
    echo "Error: usage $0 [port]"
    return 1
  else 
    inst_port=$1
  fi

  result=`grep -v "^#" ${mytab_file}|grep ${inst_port}`

  inst_vfa_cnf=`echo $result|awk -F: '{print $1}'`
  inst_auto_start=`echo $result|awk -F: '{print $3}'`

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

function call_read_ini {
  if [ -z $1 ];then
    echo "Error: usage $0 [port]"
    return 1
  else 
    inst_port=$1
  fi

  set_inst_info ${inst_port}

  read_ini ${inst_vfa_cnf} mysqld 

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

function show_slave_status {
    if [ -z $1 ];then
      conn $default_inst_port "show slave status\G"
    else 
      conn $1 "show slave status\G"
    fi

} 
alias v_s3=show_slave_status

function skip_slave {
  if [ -z $1 ];then
    conn $default_inst_port "SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1; START SLAVE"
  else
    conn $1 "SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1; START SLAVE"
  fi
}

function show_global_status {
  conn $1 'show global status'

}

alias v_sgs="show_global_status"

function show_global_variables {
  conn $1 "show global variables"

}

alias v_sgv="show_global_variables"


function show_my_cnf {
  echo

}

alias v_smc="show_my_cnf"

# Function needs to be actually written. Laine gave me this and it works well.
function get_binlog_summary {
  echo
  # mysqlbinlog mysql-bin.009254 | egrep "^INSERT|^REPLACE|^UPDATE" | sed -e 's/LOW_PRIORITY//' | awk '{print $1 " " $2 " " $3}' | sort | uniq -c | sort > /tmp/mysql-bin.009254.out 

}

# ==================================
# MAIN
# ==================================

# Todo: add a flag to mytab that indicates whether the instance
#       is the default instance to log into on the given host
#

home_dir=`ls -d ~`

if [ -d ${home_dir}/palominodb ];then
  vfa_script_root="${home_dir}/palominodb"
else
  echo "Error: unable to find ${home_dir}/palominodb"
  return 1
fi

alias v_scripts="cd ${vfa_script_root}/admin/scripts"
alias v_sql="cd ${vfa_script_root}/admin/sql"
alias v_ddl="cd ${vfa_script_root}/admin/ddl"

unset default_inst_port

# This allows for an override of the mytab. Often useful
# for hosts with restricted access.
if [ -f ${home_dir}/mytab ];then
  mytab_file=${home_dir}/mytab
elif [ -f /tmp/mytab ];then
  mytab_file=/tmp/mytab
else
  mytab_file=/etc/mytab
fi

# Load read_ini function
# DEBUG before checking in determine how to set location for 
# this script. Possibly have a configure/makefile script.
source ${home_dir}/palominodb/admin/scripts/read_ini.sh

# if no port info passed default to 3306
default_inst_port=$(get_port $1)
default_inst_info=`grep -v "^#" ${mytab_file} |grep ${default_inst_port}`

if [ -z $default_inst_info ];then
  echo "Error: no instance found in $mytab_file with port of $default_inst_port"
  # Unset these variables so none of the functions that may have been previously set correctly work
  unset default_inst_admin_user
  unset default_inst_admin_pass
  unset default_inst_port
  unset default_inst_socket
  # alias conn="echo \"Error: try calling vfa_lib.sh again.\""
  return 1
fi

default_inst_auto_start=`echo ${default_inst_info} | awk -F: '{print $3}'`
default_inst_vfa_cnf=`echo ${default_inst_info} | awk -F: '{print $1}'`

# Set prompt 
# username@hostname:default_inst_port directory
export PS1="[\u@\h:${default_inst_port} \w]#"
# [root@blade01-05 scripts]#
# export PS1="\w \u\$"

# Set my.cnf variables
# Note there is a bug preventing variable that have hyphens from
# being read. Skipping issue until I have time to fix.
read_ini ${default_inst_vfa_cnf} mysqld 

# DEBUG
# echo "INI__mysqld__socket=$INI__mysqld__socket"
# set |grep INI

default_inst_socket=${INI__mysqld__socket}

# Temporary until script figures out 
# user and password
default_inst_admin_user=root
default_inst_admin_pass=""

# Need to fix read_ini to handle hyphens..
function vfa_logdir {
  if [ -z $1 ];then
    call_read_ini ${default_inst_port}
    echo ${INI__mysqld__socket}
    echo ${INI__mysqld__slow_query_log_file}
    echo ${INI__mysqld__log_error}
    echo Use default
  else
    call_read_ini ${1}
    echo ${INI__mysqld__socket}
    echo Use $1
  fi
 
  env

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
      call_read_ini ${inst_port}
      inst_socket=${INI__mysqld__socket}
      # DEBUG - old
      # inst_socket=$(get_socket ${inst_port}) 

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
      call_read_ini ${inst_port}
      inst_socket=${INI__mysqld__socket}
      # DEBUG - old method
      # inst_socket=$(get_socket ${inst_port}) 
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

