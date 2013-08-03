#!/bin/bash
# In time put this in an array. Then print status
# of each at the end.
#

echo "* Checking for full mount point"
result=`df -h |egrep "100%"`
if [ ! -z "$result" ];then
  echo 'Warning mount point full.       <===================='
  echo "$result"
else
  echo "OK"
fi
echo

echo "* Checking load"
result=`uptime |awk '{print $10}' |sed "s/,//"`
echo "Load is ${result}"
echo

echo "* Checking MySQL uptime"
result=`mysql -sNe 'show global status' |grep -wi uptime |awk '{print $2 "/60"}'  |bc`
echo "MySQL uptime ${result} min"
echo


result=`grep "allocsize=1M" /etc/fstab|wc -l`

if [ $result -gt 0 ];then
  echo "OK : check allocsize succeeded"
else
  echo "WARNING : check allocsize failed"
fi

result=`df -Pk |grep "/var/lib/mysql" |awk '{print $2}'`
expected_size=$(( 1 * 1024 * 1024 * 1024 ))

if [ $result -gt $expected_size ];then
  echo "OK : check expected size of /var/lib/mysql $result > $expected_size"
else
  echo "WARNING : check expected size of /var/lib/mysql < $expected_size"
  echo "Size of /var/lib/mysql = $result"
fi

# Need a check for fio devices

