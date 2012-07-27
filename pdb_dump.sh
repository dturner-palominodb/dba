#!/bin/bash

if [ -z $1 ];then
  echo "Error: usage $0 <port> <backup_dir>"
  echo "       ie: $0 3320 /tmp/backup     "
  exit 1
else
  if [ -z $2 ];then
    echo "Error: usage $0 <port> <backup_dir>"
    echo "       ie: $0 3320 /tmp/backup     "
    exit 1
  else
    port=$1
    backup_dir="${2}/${1}"
  fi
fi

logfile=${backup_dir}/dump.log

mkdir -p ${backup_dir} 2> /dev/null

exec > >(tee $logfile) 2>&1

echo "Start date: `date`"
date +"%s"
  chown -R mysql:mysql ${backup_dir}

db_list=`mysql -sNu root --socket=/data/mysql/m${port}/logs/mysql.sock -e "select distinct table_schema from information_schema.tables where table_schema not in ('information_schema')"`

for db in $db_list
do

  mkdir -p ${backup_dir}/${db} 2> /dev/null
  chown -R mysql:mysql ${backup_dir}
  mysqldump -h localhost -u root --socket=/data/mysql/m${port}/logs/mysql.sock \
            --default-character-set=latin1 -q -Q \
            --tab=${backup_dir}/${db} \
            ${db}

# --no-data \
done

echo "End date: `date`"
date +"%s"

# mysqldump -h localhost -u root --socket=/data/mysql/m${port}/logs/mysql.sock \
#           --default-character-set=latin1 \
#           --no-data -q -Q \
#           --tab=/tmp/backup \
#           --all-databases
            


# mysqldump  Ver 10.11 Distrib 5.0.51a, for unknown-linux-gnu (x86_64)
# By Igor Romanenko, Monty, Jani & Sinisa
# This software comes with ABSOLUTELY NO WARRANTY. This is free software,
# and you are welcome to modify and redistribute it under the GPL license
# 
# Dumping definition and data mysql database or table
# Usage: mysqldump [OPTIONS] database [tables]
# OR     mysqldump [OPTIONS] --databases [OPTIONS] DB1 [DB2 DB3...]
# OR     mysqldump [OPTIONS] --all-databases [OPTIONS]
# 
# Default options are read from the following files in the given order:
# /etc/my.cnf ~/.my.cnf /etc/my.cnf 
# The following groups are read: mysqldump client
# The following options may be given as the first argument:
# --print-defaults	Print the program argument list and exit
# --no-defaults		Don't read default options from any options file
# --defaults-file=#	Only read default options from the given file #
# --defaults-extra-file=# Read this file after the global files are read
#   -a, --all           Deprecated. Use --create-options instead.
#   -A, --all-databases Dump all the databases. This will be same as --databases
#                       with all databases selected.
#   --add-drop-database Add a 'DROP DATABASE' before each create.
#   --add-drop-table    Add a 'drop table' before each create.
#   --add-locks         Add locks around insert statements.
#   --allow-keywords    Allow creation of column names that are keywords.
#   --character-sets-dir=name 
#                       Directory where character sets are.
#   -i, --comments      Write additional information.
#   --compatible=name   Change the dump to be compatible with a given mode. By
#                       default tables are dumped in a format optimized for
#                       MySQL. Legal modes are: ansi, mysql323, mysql40,
#                       postgresql, oracle, mssql, db2, maxdb, no_key_options,
#                       no_table_options, no_field_options. One can use several
#                       modes separated by commas. Note: Requires MySQL server
#                       version 4.1.0 or higher. This option is ignored with
#                       earlier server versions.
#   --compact           Give less verbose output (useful for debugging). Disables
#                       structure comments and header/footer constructs.  Enables
#                       options --skip-add-drop-table --no-set-names
#                       --skip-disable-keys --skip-add-locks
#   -c, --complete-insert 
#                       Use complete insert statements.
#   -C, --compress      Use compression in server/client protocol.
#   --create-options    Include all MySQL specific create options.
#   -B, --databases     To dump several databases. Note the difference in usage;
#                       In this case no tables are given. All name arguments are
#                       regarded as databasenames. 'USE db_name;' will be
#                       included in the output.
#   -#, --debug[=#]     This is a non-debug version. Catch this and exit
#   --debug-info        Print some debug info at exit.
#   --default-character-set=name 
#                       Set the default character set.
#   --delayed-insert    Insert rows with INSERT DELAYED; 
#   --delete-master-logs 
#                       Delete logs on master after backup. This automatically
#                       enables --master-data.
#   -K, --disable-keys  '/*!40000 ALTER TABLE tb_name DISABLE KEYS */; and
#                       '/*!40000 ALTER TABLE tb_name ENABLE KEYS */; will be put
#                       in the output.
#   -e, --extended-insert 
#                       Allows utilization of the new, much faster INSERT syntax.
#   --fields-terminated-by=name 
#                       Fields in the textfile are terminated by ...
#   --fields-enclosed-by=name 
#                       Fields in the importfile are enclosed by ...
#   --fields-optionally-enclosed-by=name 
#                       Fields in the i.file are opt. enclosed by ...
#   --fields-escaped-by=name 
#                       Fields in the i.file are escaped by ...
#   -x, --first-slave   Deprecated, renamed to --lock-all-tables.
#   -F, --flush-logs    Flush logs file in server before starting dump. Note that
#                       if you dump many databases at once (using the option
#                       --databases= or --all-databases), the logs will be
#                       flushed for each database dumped. The exception is when
#                       using --lock-all-tables or --master-data: in this case
#                       the logs will be flushed only once, corresponding to the
#                       moment all tables are locked. So if you want your dump
#                       and the log flush to happen at the same exact moment you
#                       should use --lock-all-tables or --master-data with
#                       --flush-logs
#   --flush-privileges  Emit a FLUSH PRIVILEGES statement after dumping the mysql
#                       database.  This option should be used any time the dump
#                       contains the mysql database and any other database that
#                       depends on the data in the mysql database for proper
#                       restore. 
#   -f, --force         Continue even if we get an sql-error.
#   -?, --help          Display this help message and exit.
#   --hex-blob          Dump binary strings (BINARY, VARBINARY, BLOB) in
#                       hexadecimal format.
#   -h, --host=name     Connect to host.
#   --ignore-table=name Do not dump the specified table. To specify more than one
#                       table to ignore, use the directive multiple times, once
#                       for each table.  Each table must be specified with both
#                       database and table names, e.g.
#                       --ignore-table=database.table
#   --insert-ignore     Insert rows with INSERT IGNORE.
#   --lines-terminated-by=name 
#                       Lines in the i.file are terminated by ...
#   -x, --lock-all-tables 
#                       Locks all tables across all databases. This is achieved
#                       by taking a global read lock for the duration of the
#                       whole dump. Automatically turns --single-transaction and
#                       --lock-tables off.
#   -l, --lock-tables   Lock all tables for read.
#   --log-error=name    Append warnings and errors to given file.
#   --master-data[=#]   This causes the binary log position and filename to be
#                       appended to the output. If equal to 1, will print it as a
#                       CHANGE MASTER command; if equal to 2, that command will
#                       be prefixed with a comment symbol. This option will turn
#                       --lock-all-tables on, unless --single-transaction is
#                       specified too (in which case a global read lock is only
#                       taken a short time at the beginning of the dump - don't
#                       forget to read about --single-transaction below). In all
#                       cases any action on logs will happen at the exact moment
#                       of the dump.Option automatically turns --lock-tables off.
#   --max_allowed_packet=# 
#   --net_buffer_length=# 
#   --no-autocommit     Wrap tables with autocommit/commit statements.
#   -n, --no-create-db  'CREATE DATABASE /*!32312 IF NOT EXISTS*/ db_name;' will
#                       not be put in the output. The above line will be added
#                       otherwise, if --databases or --all-databases option was
#                       given.}.
#   -t, --no-create-info 
#                       Don't write table creation info.
#   -d, --no-data       No row information.
#   -N, --no-set-names  Deprecated. Use --skip-set-charset instead.
#   --opt               Same as --add-drop-table, --add-locks, --create-options,
#                       --quick, --extended-insert, --lock-tables, --set-charset,
#                       and --disable-keys. Enabled by default, disable with
#                       --skip-opt.
#   --order-by-primary  Sorts each table's rows by primary key, or first unique
#                       key, if such a key exists.  Useful when dumping a MyISAM
#                       table to be loaded into an InnoDB table, but will make
#                       the dump itself take considerably longer.
#   -p, --password[=name] 
#                       Password to use when connecting to server. If password is
#                       not given it's solicited on the tty.
#   -P, --port=#        Port number to use for connection.
#   --protocol=name     The protocol of connection (tcp,socket,pipe,memory).
#   -q, --quick         Don't buffer query, dump directly to stdout.
#   -Q, --quote-names   Quote table and column names with backticks (`).
#   -r, --result-file=name 
#                       Direct output to a given file. This option should be used
#                       in MSDOS, because it prevents new line '\n' from being
#                       converted to '\r\n' (carriage return + line feed).
#   -R, --routines      Dump stored routines (functions and procedures).
#   --set-charset       Add 'SET NAMES default_character_set' to the output.
#                       Enabled by default; suppress with --skip-set-charset.
#   -O, --set-variable=name 
#                       Change the value of a variable. Please note that this
#                       option is deprecated; you can set variables directly with
#                       --variable-name=value.
#   --single-transaction 
#                       Creates a consistent snapshot by dumping all tables in a
#                       single transaction. Works ONLY for tables stored in
#                       storage engines which support multiversioning (currently
#                       only InnoDB does); the dump is NOT guaranteed to be
#                       consistent for other storage engines. Option
#                       automatically turns off --lock-tables.
#   --skip-opt          Disable --opt. Disables --add-drop-table, --add-locks,
#                       --create-options, --quick, --extended-insert,
#                       --lock-tables, --set-charset, and --disable-keys.
#   -S, --socket=name   Socket file to use for connection.
#   --ssl               Enable SSL for connection (automatically enabled with
#                       other flags). Disable with --skip-ssl.
#   --ssl-ca=name       CA file in PEM format (check OpenSSL docs, implies
#                       --ssl).
#   --ssl-capath=name   CA directory (check OpenSSL docs, implies --ssl).
#   --ssl-cert=name     X509 cert in PEM format (implies --ssl).
#   --ssl-cipher=name   SSL cipher to use (implies --ssl).
#   --ssl-key=name      X509 key in PEM format (implies --ssl).
#   --ssl-verify-server-cert 
#                       Verify server's "Common Name" in its cert against
#                       hostname used when connecting. This option is disabled by
#                       default.
#   -T, --tab=name      Creates tab separated textfile for each table to given
#                       path. (creates .sql and .txt files). NOTE: This only
#                       works if mysqldump is run on the same machine as the
#                       mysqld daemon.
#   --tables            Overrides option --databases (-B).
#   --triggers          Dump triggers for each dumped table
#   --tz-utc            SET TIME_ZONE='+00:00' at top of dump to allow dumping of
#                       TIMESTAMP data when a server has data in different time
#                       zones or data is being moved between servers with
#                       different time zones.
#   -u, --user=name     User for login if not current user.
#   -v, --verbose       Print info about the various stages.
#   -V, --version       Output version information and exit.
#   -w, --where=name    Dump only selected records; QUOTES mandatory!
#   -X, --xml           Dump a database as well formed XML.
# 
# Variables (--variable-name=value)
# and boolean options {FALSE|TRUE}  Value (after reading options)
# --------------------------------- -----------------------------
# all                               TRUE
# all-databases                     FALSE
# add-drop-database                 FALSE
# add-drop-table                    TRUE
# add-locks                         TRUE
# allow-keywords                    FALSE
# character-sets-dir                (No default value)
# comments                          TRUE
# compatible                        (No default value)
# compact                           FALSE
# complete-insert                   FALSE
# compress                          FALSE
# create-options                    TRUE
# databases                         FALSE
# debug-info                        FALSE
# default-character-set             utf8
# delayed-insert                    FALSE
# delete-master-logs                FALSE
# disable-keys                      TRUE
# extended-insert                   TRUE
# fields-terminated-by              (No default value)
# fields-enclosed-by                (No default value)
# fields-optionally-enclosed-by     (No default value)
# fields-escaped-by                 (No default value)
# first-slave                       FALSE
# flush-logs                        FALSE
# flush-privileges                  FALSE
# force                             FALSE
# hex-blob                          FALSE
# host                              (No default value)
# insert-ignore                     FALSE
# lines-terminated-by               (No default value)
# lock-all-tables                   FALSE
# lock-tables                       TRUE
# log-error                         (No default value)
# master-data                       0
# max_allowed_packet                25165824
# net_buffer_length                 1047551
# no-autocommit                     FALSE
# no-create-db                      FALSE
# no-create-info                    FALSE
# no-data                           FALSE
# order-by-primary                  FALSE
# port                              0
# quick                             TRUE
# quote-names                       TRUE
# routines                          FALSE
# set-charset                       TRUE
# single-transaction                FALSE
# socket                            (No default value)
# ssl                               FALSE
# ssl-ca                            (No default value)
# ssl-capath                        (No default value)
# ssl-cert                          (No default value)
# ssl-cipher                        (No default value)
# ssl-key                           (No default value)
# ssl-verify-server-cert            FALSE
# tab                               (No default value)
# triggers                          TRUE
# tz-utc                            TRUE
# user                              (No default value)
# verbose                           FALSE
# where                             (No default value)
