#!/usr/bin/python
# purpose perform a parallel backup of databases.
#
import filecmp
import os
import sys
import subprocess
import time
from optparse import OptionParser
import grp, pwd
from pwd import getpwnam
from pdb_dba import *
# specify individually, comma separated.
# start writing the unix utilities in python to get experience
# chip - helped with globals
# juan - leader
# mike - student
#
#
# Loading table
# time mysql -e 'insert into shard01.voice_calls select * from shard03.voice_calls; insert into shard03.voice_calls select * from shard01.voice_calls '
#
# features I would like to add:
#
#    x store pt-show-grants in a file for later loading.
#    x put in read only
#    o flush logs
#    x stop replication 
#    x store starting slave position
#    o remove all grants except for those that were used to log into the db.
#    x store starting master position.
#    o As dumps complete add dump processes to the queue
#    o Add and option to perform parallel checksums of tables to a file, sorting after for an easy diff on import.
#    x store ending slave posiition.
#    x store ending master posiition.
#    o compare start and end slave 
#    o compare start and end master 
# Addtional features
#    o Confirm all pt tools are installed before running. This could save some headache
#    o Add exit codes with useful numbers(Work with Emanuel)
#    o Better logging/handling of failures
#    o Read user and pass from defaults-file
#    o Accept user and pass on command line
#    o The script should estimate completion time and show progress.
#    o Support views, triggers, stored proc, etc (low pri)
#    o Support running this script remotely.
#    
# Import
#    o Modify my.cnf and restart db.


# Globals
mysql_user="root"
mysql_pass=""
unix_user = "mysql"

# Example : ./pdb_dump.py --instance=localhost -b /tmp/dump  -p 3

# Some variables should be included as command line args when you have time.

# Ask about timing out a stop slave statement when it hangs.

def parse():
    parser = OptionParser(usage="usage: %prog -i [host:port] -b [backup_dir]",
                          version="%prog 0.1")
    parser.add_option("-i", "--instance",
                      action="store", # optional because it could be blank or use cluster instead
                      dest="inst",
                      default=False,
                      help="The instance to dump.")
    parser.add_option("-b", "--backup-directory",
                      action="store", 
                      dest="backup_dir",
                      default=False,
                      help="The directory to dump to.",)
    parser.add_option("-p", "--parallelism",
                      action="store", 
                      dest="parallelism",
                      default=2,
                      help="The number of dump processes to run in parallel.",)
    (options, args) = parser.parse_args()


    if options.inst == False:
        parser.error("Error: instance is required.")
    if options.backup_dir == False:
        parser.error("Error: backup directory must be given.")

    return (options, args)

def parse_inst_info(inst):
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

    return (inst_host, inst_port)

def create_backup_dirs_for_dbs(db_list, unix_user, backup_dir):
    for db in db_list:
        backup_dir_for_db = backup_dir + "/" + db[0]
        if not os.path.exists(backup_dir_for_db):
            print "mkdir " + backup_dir_for_db
            os.makedirs(backup_dir_for_db)
            os.chown(backup_dir_for_db , getpwnam(unix_user).pw_uid, pwd.getpwnam(unix_user).pw_gid)
        else:
            print "Warning: " + backup_dir_for_db + " exists."

def get_table_list(inst_host, inst_port, db_list):

    table_list = []

    for db in db_list:
         stmt = "SELECT table_name FROM information_schema.tables WHERE table_schema = '" + db[0] + "' AND table_type='BASE TABLE'"
         result = run_select(inst_host, int(inst_port), mysql_user, mysql_pass, stmt)
         for row in result:
             table_list.append(db[0] + "." + row[0])

    return table_list

def dump_tables(inst_host, inst_port, mysql_user, mysql_pass, table_list, backup_dir, parallelism):

    socket = get_socket(inst_port)

    # Perform the logical dump
    for table in table_list:
        db = table.split(".")[0]
        table_name = table.split(".")[1]

        # DEBUG this needs to handle passwords.
        cmd = "mysqldump -h " + inst_host + " -u " + mysql_user + " --socket=" + get_socket(inst_port) + " -q -Q -e --no-data " +  db + " " + table_name + " > " + backup_dir + "/" + db + "/" + table_name + ".sql"

        proc = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        return_code = proc.wait()
   
        if return_code > 0:
            for line in proc.stderr:
                print ("stderr: " + line.rstrip())
            sys.exit(1)

        for line in proc.stdout:
            print line.rstrip()
        for line in proc.stderr:
            print ("stderr: " + line.rstrip())

    # Perform the data dump    
    parallel_count = 0
    
    for table in table_list:
        db = table.split(".")[0]
        table_name = table.split(".")[1]
      
        ps = {}
        args = ['mysqldump', '-h', inst_host,'-u', mysql_user, '--socket', get_socket(inst_port), '-q', '-Q', '-e', '--order-by-primary', '--no-create-info','-r', backup_dir + "/" + db + "/" + table_name + ".txt", db, table_name]
        p = subprocess.Popen(args)
        ps[p.pid] = p
        print ps
    
        parallel_count = parallel_count + 1
    
        if parallel_count >= parallelism:
            print "Waiting for %d processes..." % len(ps)
            while ps:
                pid, status = os.wait()
                if pid in ps:
                    del ps[pid]
                    print "Waiting for %d processes..." % len(ps)
                else:
                    parallel_count = 0

def call_pt_show_grants(inst_host, inst_port, mysql_user, mysql_pass, backup_dir):
    # When you have time make sure this works with ports as well as sockets.
    # Get this handling blank passwords
    cmd = "pt-show-grants -h " + inst_host + " -u " + mysql_user + " --socket=" + get_socket(inst_port) + " > " + backup_dir + "/" + "pt_show_grants.sql"
   
    print cmd  

    proc = subprocess.Popen(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    return_code = proc.wait()
  
    if return_code > 0:
        for line in proc.stderr:
            print ("stderr: " + line.rstrip())
        sys.exit(1)

    for line in proc.stdout:
        print line.rstrip()
    for line in proc.stderr:
        print ("stderr: " + line.rstrip())
     

def main():
    (options, args) = parse()
    # print options
    # print args 
  
    inst = options.inst 
    (inst_host, inst_port) = parse_inst_info(inst)
    backup_dir = options.backup_dir
    parallelism = options.parallelism
    program_name_stripped = os.path.basename(__file__).split(".")[0]

    log_file = backup_dir + "/" + program_name_stripped + ".log"

    # If the directory does not exist create it and chown to mysql:mysql
    if not os.path.exists(backup_dir):
        os.makedirs(backup_dir)
        os.chown(backup_dir, getpwnam(unix_user).pw_uid, pwd.getpwnam(unix_user).pw_gid)

    if test_conn(mysql_user, mysql_pass, inst) < 1:
        print "Error: unable to connect to the instance. Check to confirm that it is available."
        sys.exit(1)

    # set read_only
    if set_read_only(host='localhost', port=3306, user='root', password='') == 1:
        print "Instance is in read_only mode."
    else:
        print "Error: problem enabling read_only."
        sys.exit(1)

    # flush logs

    # stop replication - needs to return 1 or 0
    stop_slave(inst_host, inst_port, mysql_user, mysql_pass)

    # store master status
    master_status_start_file = backup_dir + "/" + "master_status_start.txt"
    fo = open(master_status_start_file,'w')
    result = show_master_status(inst_host, inst_port, mysql_user, mysql_pass)
    for row in result:
        fo.write(
            row[0] + ',' + 
            str(row[1]) + ',' +
            str(row[2]) + ',' +
            str(row[3]) + 
            '\n')
    fo.close

    # store slave status 
    slave_status_start_file = backup_dir + "/" + "slave_status_start.txt"
    fo = open(slave_status_start_file,'w')
    result = show_slave_status(inst_host, inst_port, mysql_user, mysql_pass)
    # This may be prone to errors. Take some time later to examine values that may come back as ints or null. May want to cast all to str to avoid
    # wasting time.
    for row in result:
        pass
        fo.write(
            row[0] + ',' +
            row[1] + ',' +
            row[2] + ',' +
            str(row[3]) + ',' +
            str(row[4]) + ',' +
            row[5] + ',' +
            str(row[6]) + ',' +
            row[7] + ',' +
            str(row[8]) + ',' +
            row[9] + ',' +
            row[10] + ',' +
            row[11] + ',' +
            row[12] + ',' +
            row[13] + ',' +
            row[14] + ',' +
            row[15] + ',' +
            row[16] + ',' +
            row[17] + ',' +
            str(row[18]) + ',' +
            row[19] + ',' +
            str(row[20]) + ',' +
            str(row[21]) + ',' +
            str(row[22]) + ',' +
            row[23] + ',' +
            row[24] + ',' +
            str(row[25]) + ',' +
            row[26] + ',' +
            row[27] + ',' +
            row[28] + ',' +
            row[29] + ',' +
            row[30] + ',' +
            row[31] + ',' +
            str(row[32]) + ',' +
            row[33] + ',' +
            str(row[34]) + ',' +
            row[35] + ',' +
            str(row[36]) + ',' +
            row[37] +
            '\n'
                )
    fo.close

    # use pt-show-grants to get mysql privs
    call_pt_show_grants(inst_host, inst_port, mysql_user, mysql_pass, backup_dir)


    # get list of databases    
    stmt = "select schema_name from information_schema.schemata where schema_name not in ('information_schema','performance_schema','mysql') and schema_name not like '#%'"
    db_list = run_select(inst_host, inst_port, mysql_user, mysql_pass, stmt)

    create_backup_dirs_for_dbs(db_list, unix_user, backup_dir)

    print inst_host + ":" + inst_port
 
    table_list = get_table_list(inst_host, inst_port, db_list)
    # At some point need to support views, triggers, etc. Possibly just let user preimport empty schema objects to handle that. And may want to take a logical
    # dump just in case.
    dump_tables(inst_host, inst_port, mysql_user, mysql_pass, table_list, backup_dir, parallelism)
    
    
    # store ending master status
    master_status_end_file = backup_dir + "/" + "master_status_end.txt"
    fo = open(master_status_end_file,'w')
    result = show_master_status(inst_host, inst_port, mysql_user, mysql_pass)
    for row in result:
        fo.write(
            row[0] + ',' + 
            str(row[1]) + ',' +
            str(row[2]) + ',' +
            str(row[3]) + 
            '\n')
    fo.close

    # store ending slave status 
    slave_status_end_file = backup_dir + "/" + "slave_status_end.txt"
    fo = open(slave_status_end_file,'w')
    result = show_slave_status(inst_host, inst_port, mysql_user, mysql_pass)
    # This may be prone to errors. Take some time later to examine values that may come back as ints or null. May want to cast all to str to avoid
    # wasting time.
    for row in result:
        pass
        fo.write(
            row[0] + ',' +
            row[1] + ',' +
            row[2] + ',' +
            str(row[3]) + ',' +
            str(row[4]) + ',' +
            row[5] + ',' +
            str(row[6]) + ',' +
            row[7] + ',' +
            str(row[8]) + ',' +
            row[9] + ',' +
            row[10] + ',' +
            row[11] + ',' +
            row[12] + ',' +
            row[13] + ',' +
            row[14] + ',' +
            row[15] + ',' +
            row[16] + ',' +
            row[17] + ',' +
            str(row[18]) + ',' +
            row[19] + ',' +
            str(row[20]) + ',' +
            str(row[21]) + ',' +
            str(row[22]) + ',' +
            row[23] + ',' +
            row[24] + ',' +
            str(row[25]) + ',' +
            row[26] + ',' +
            row[27] + ',' +
            row[28] + ',' +
            row[29] + ',' +
            row[30] + ',' +
            row[31] + ',' +
            str(row[32]) + ',' +
            row[33] + ',' +
            str(row[34]) + ',' +
            row[35] + ',' +
            str(row[36]) + ',' +
            row[37] +
            '\n'
                )
    fo.close

    # Hack for now. st_size was not registering the file
    # size. Reopens for reads then closes.
    fo = open(slave_status_end_file,'r')
    fo.close

    if filecmp.cmp(slave_status_start_file, slave_status_end_file):
        print "OK, slave status unchanged." 
    else:
        print "Warning, slave status changed. See slave start and end files for differences." 

    if filecmp.cmp(master_status_start_file, master_status_end_file):
        print "OK, master status unchanged." 
    else:
        print "Warning, master status changed. See master start and end files for differences." 

# call main 
if __name__ == '__main__':
    main()

