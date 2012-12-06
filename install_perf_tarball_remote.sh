#!/bin/bash

if [ -z $1 ];then
  echo "Error: usage $0 <hostlist.file>"
  exit 1
else
  file=$1
  if [ ! -e ${file} ];then
    echo "Error: could not find file ${file}."
    exit 1
  fi
fi


if [ ! -e "create_perf_tarball.sh" ];then
  echo "Error: could not find create_perf_tarball.sh"
  echo "       Run $0 from the dba repo."
  exit 1
fi

perf_dest_dir="/tmp"

echo "Creating the perf tarball.."
sleep 1
./create_perf_tarball.sh

tarfile=`ls /tmp/perf_tarball_[0-9][0-9]*.tgz |tail -1`

for host in $( < ${file} )
do
  echo ${host}
  echo "scp ${tarfile} root@${host}:${perf_dest_dir}"
  scp ${tarfile} root@${host}:${perf_dest_dir}
  echo "ssh root@${host} \"cd ${perf_dest_dir}; tar xzvf ${tarfile}; cd perf_tarball; ./install_perf_tarball.sh\""
  ssh root@${host} "cd ${perf_dest_dir}; tar xzvf ${tarfile}; cd perf_tarball; ./install_perf_tarball.sh"

done



# scp perf_tarball_2012*.tgz root@<hostname>:/tmp

# ssh root@<hostname> "cd /tmp; tar xzvf perf_tarball_2012*.tgz; cd perf_tarball; ./install_perf_tarball.sh"

