#!/bin/bash
# author: dturner@palominodb.com
# title: pdb-manage-relay-logs.sh
# purpose: replicas sometimes fall far behind filling a mount with relay logs.
#          This script manages relay logs until the slave has caught up with the master
#          or is nolonger having an issue with filling the disk.
# note: The script was written in haste and needs the hard coding removed and other cleanup.
#
logfile=pdb-manage-relay-logs.log

slave_status=`echo $(mysql -e 'show slave status\G' |egrep -i "runn|sec")|awk '{print $2 "," $4 "," $6}'`
sbm=`echo $slave_status | cut -d, -f3`

pct_disk_used=`df -Ph |tail -n +2 |grep sda2|awk '{print $5}' |sed "s/%//"`

exec > >(tee -a $logfile) 2>&1

echo slave_status=$slave_status
echo pct_disk_used=$pct_disk_used

while [ $sbm == "NULL" ] || [ $sbm -gt 1000 ]
do

  if [ ${pct_disk_used} -gt 37 ];then
    echo "Stopping io_thread"
    mysql -e 'stop slave io_thread'
    echo $(mysql -e 'show slave status\G' |egrep -i "runn|sec")
    df -k |grep sda2
    date
  else
    if [ ${pct_disk_used} -lt 36 ];then
      echo "Starting io_thread"
      mysql -e 'start slave io_thread'
      echo $(mysql -e 'show slave status\G' |egrep -i "runn|sec")
      df -k |grep sda2
      date
    fi
    echo $(mysql -e 'show slave status\G' |egrep -i "runn|sec")
    df -k |grep sda2
    date
  fi

  slave_status=`echo $(mysql -e 'show slave status\G' |egrep -i "runn|sec")|awk '{print $2 "," $4 "," $6}'`
  sbm=`echo $slave_status | cut -d, -f3`
  pct_disk_used=`df -Ph |tail -n +2 |grep sda2|awk '{print $5}' |sed "s/%//"`

  sleep 120
done
