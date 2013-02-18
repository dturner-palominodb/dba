#!/bin/bash

tarball_dir=/tmp/perf_tarball
date=`date +"%Y%m%d%H%M%S"`
tarball_file=perf_tarball_${date}.tgz
perf_dest_dir="/tmp"

# Removing previous versions of perf_tarball.
rm -vf ${perf_dest_dir}/perf_tarball_[0-9][0-9]*.tgz

mkdir -p /tmp/perf_tarball 2> /dev/null

# Deprecated. Removing after there is a replacement
# cd ${HOME}/git/ServerAudit/scripts/
# cp call_pt-stalk.sh    ${tarball_dir}
# cp gen_stalk_report.sh ${tarball_dir}

cd ${HOME}/git/dba/
cp * ${tarball_dir}

cd /tmp
tar czvf ${tarball_file} perf_tarball
echo ${tarball_file} 

