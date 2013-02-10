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
import MySQLdb
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
    cursor.execute(stmt)

    result = cursor.fetchall()

    cursor.close
    conn.close

    return result


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


def is_production_server(server):
    pass

def is_production_instance(inst):
    pass




