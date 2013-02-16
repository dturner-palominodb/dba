#!/usr/bin/python
# Filename: pdb_dba.py
# Purpose : a module for various functions we perform
#
# Tip: use the following when you call this module so that you don't
#      have to include the module name as well as the function
#
#      from pdb_dba import *
#

import os
import re
import subprocess
import sys
import warnings 
import MySQLdb
warnings.simplefilter("error", MySQLdb.Warning)
# http://python.6.n6.nabble.com/Trapping-warnings-from-MySQLdb-td1735661.html
from os.path import expanduser
from ConfigParser import SafeConfigParser

vfa_cnf_dir="/etc"

def local_exec(cmd):
    # Probably should return the status of the script that was run
    proc = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    return_code = proc.wait()

    for line in proc.stdout:
        print (line.rstrip())
    for line in proc.stderr:
        print (line.rstrip())

    return return_code

def is_mysql_running(port=3306):
    # This should be just the start of what to check. Checking connectivity
    # would be something else to check as well. Port info isn't available via
    # ps consistenly so I'm not sure how useful that is anymore.

    cmd = "lsof -i4 -P | grep -i mysql|grep \":" + str(port) + " \" |grep LISTEN | wc -l"
    proc = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    return_code = proc.wait()

    for line in proc.stdout:
        print line.rstrip()
        return line.rstrip()

def test_conn(user, password, inst='localhost:3306'):
    # return 1 if connect succeeds.
    try:
        result = inst.index(':')
    except:
        result = 0        

    if result > 0: 
      inst_host=inst.split(':')[0]
      inst_port=inst.split(':')[1]
    else:
      inst_host=inst
      inst_port='3306'

    try:
        MySQLdb.connect(host=inst_host, port=int(inst_port), user=user, passwd=password, db='')
        return 1
    except MySQLdb.Error, e:
        return 0
        

def conn_db(host, port, user, password, db):
    try:
        return MySQLdb.connect(host=host, port=port, user=user, passwd=password, db=db)
    except MySQLdb.Error, e:
        sys.stderr.write("[ERROR] %d: %s\n" % (e.args[0], e.args[1]))
        return False

def run_select(host='localhost', port=3306, user='root', password='', stmt=''):
    # Returns a result set from the select.
    # Example use
    # result = run_select(stmt='select 1')
    # for row in result:
    #     print row[0]
    #

    conn = conn_db(host, int(port), user, password, 'mysql')

    cursor = conn.cursor()  
   
    try:
        cursor.execute(stmt)
    except MySQLdb.Warning, e:
        # For now return nothing if there is a warning.
        return 

    result = cursor.fetchall()

    cursor.close
    conn.close

    return result

def show_slave_status(host='localhost', port=3306, user='root', password=''):
    cmd = "show slave status"
    result = run_select(host,port,user,password,cmd)
    return result

def show_master_status(host='localhost', port=3306, user='root', password=''):
    # example usage
    # for row in result:
    #     print "%s,%s,%s,%s" % (row[0],row[1],row[2],row[3])
    #
    cmd = "show master status"
    result = run_select(host,port,user,password,cmd)
    return result



def stop_slave(host='localhost', port=3306, user='root', password=''):
    # todo:
    #      o add a check to confirm io_thread and sql_thread have been stopped
    #        or that replication hasn't been setup. 
    #      o find out how to timeout when the stop slave command hangs.
    #
    cmd = "stop slave"
    result = run_select(host,port,user,password,cmd)

    if not result:
        return 1
    # DEBUG - this needs to be tested with a db that's slaving.
    return result

def set_read_only(host='localhost', port=3306, user='root', password=''):
    cmd = "set global read_only=1"
    result = run_select(host,port,user,password,cmd)
    cmd = "show global variables like 'read_only'"
    result = run_select(host,port,user,password,cmd)

    for row in result:
       if row[1] == "ON":
           return 1
       else:
           return 0

def flush_logs(host='localhost', port=3306, user='root', password=''):
    cmd = "flush logs"
    result = run_select(host,port,user,password,cmd)
    

def get_vfa_cnf_file():

    home = expanduser("~")
    if os.path.isfile( home + "/vfatab" ):
        vfa_cnf_file = home + "/vfatab"
    elif os.path.isfile( "/tmp/vfatab" ):
        vfa_cnf_file = "/tmp/vfatab"
    elif os.path.isfile( "/etc/vfatab" ):
        vfa_cnf_file = "/etc/vfatab"
    else:
        print "Error: /etc/vfatab has not been configured"
        return 1
        
    return vfa_cnf_file

def get_my_cnf_file(port):
    vfa_cnf_file = get_vfa_cnf_file()

    try:
        fr = open(vfa_cnf_file, "r")
    except IOError:
        # I do not think it should return and error. It
        # should just return nothing for the file.
        return

    while 1:
        line = fr.readline()
        if not line:
            break
        if re.match('^.*:' + str(port) + ':',line):
            my_cnf_file = line.split(":")[0]
        else:
            return

    return my_cnf_file

def get_socket(port):
    
    my_cnf_file = get_my_cnf_file(port)

    # Need conditional for when my_cnf_file can't be found 
    # For reference: http://www.doughellmann.com/PyMOTW/ConfigParser/
    parser = SafeConfigParser()

    parser = SafeConfigParser(allow_no_value=True)
    parser.read(my_cnf_file)

    return parser.get('mysqld', 'socket')

def get_mysql_user_and_pass_from_my_cnf(my_cnf_file):

    try:
        fr = open(my_cnf_file, "r")
    except IOError:
        # I do not think it should return and error. It
        # should just return nothing for the password.
        return

    while 1:
        line = fr.readline()
        if not line:
            break
        line = line.strip().replace('"','')
        if re.match("^user",line):
            mysql_user = line.split("=")[1]
        if re.match("^password",line):
            mysql_pass = line.split("=")[1]

    return (mysql_user,mysql_pass)


def is_production_server(server):
    pass

def is_production_instance(inst):
    pass




