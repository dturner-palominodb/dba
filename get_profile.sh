#!/bin/bash
nsamples=1
sleeptime=0
pid=$(pgrep mysqld|sort |tail -1)
# pid=$(pidof mysqld)

logfile=get_profile.log

exec > >(tee $logfile) 2>&1

echo "DEBUG : pid=$pid"

for x in $(seq 1 $nsamples)
  do
    gdb -ex "set pagination 0" -ex "thread apply all bt" -batch -p $pid
    sleep $sleeptime
  done | \
awk '
  BEGIN { s = ""; }
  /^Thread/ { print s; s = ""; }
  /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } }
  END { print s }' | \
sort | uniq -c | sort -r -n -k 1,1