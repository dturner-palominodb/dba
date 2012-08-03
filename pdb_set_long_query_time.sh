#!/bin/bash

# At some point should add a clear slow_log option. So
# it's easier to review a window of time.

if [ -z $1 ];then
  echo "Error: usage $0 <minutes>"
  exit 1
else
  minutes=$1
fi

start_date=`date +"%Y%m%d%H%M%S"`
logfile=/var/log/pdb_set_long_query_time_${start_date}.log
start_unixtime=`date +"%s"`
count=0
max_pct_used=90

exec > >(tee -a $logfile) 2>&1

echo "Start unix time = $start_unixtime"

slow_query_log_file=`mysql -sNe 'show global variables like "slow_query_log_file"' |awk '{print $2}'`


if [ ! -e $slow_query_log_file ];then
  echo "Error: $slow_query_log_file doesn't exist."
  exit 1
else
  echo "Found slow_query_log_file=$slow_query_log_file"
  echo
fi

# Had to have awk convert the float returned from mysql to an int
long_query_time_before=`mysql -sNe 'show global variables like "long_query_time"' |awk '{printf "%.0f",$2}'`
# echo long_query_time_before=$long_query_time_before

# Set long query time = 0
long_query_time_after=`mysql -sNe 'set global long_query_time=0;show global variables like "long_query_time"' |awk '{printf "%.0f",$2}'`
# echo long_query_time_after=$long_query_time_after

sleep_time_in_seconds=$(( $minutes * 60 ))
# DEBUG
# sleep_time_in_seconds=1

echo "The script has set long_query_time = $long_query_time_after. It will reset long_query_time = $long_query_time_before in"
echo "$minutes minutes (${sleep_time_in_seconds}s)."
echo

while [ ${count} -lt ${sleep_time_in_seconds} ]
do
  pct_used=`df -Ph  ${slow_query_log_file}  |grep -v Filesystem |awk '{print $5}' |sed 's/%//'`
  if [ $pct_used -gt ${max_pct_used} ];then
    echo "Error: pct_used = ${pct_used}. Clear up some space before running this script."
    break
  fi

  sleep 1
  count=$(( $count + 1 ))
done

long_query_time_final=`mysql -sNe "set global long_query_time=${long_query_time_before};show global variables like 'long_query_time'" |awk '{printf "%.0f",$2}'`
# echo long_query_time_final=$long_query_time_final

echo "The script has completed. Long_query_time has been set back to long_query_time=${long_query_time_final}."
echo

slow_query_log_file_size=`du -hs ${slow_query_log_file}`

echo "The slow query log, $slow_query_log_file, is now ${slow_query_log_file_size}."

end_unixtime=`date +"%s"`

echo "End unix time = $end_unixtime"
