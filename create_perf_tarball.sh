#!/bin/bash

tarball_dir=/tmp/perf_tarball
tarball_file=perf_tarball.tgz

mkdir -p /tmp/perf_tarball 2> /dev/null

cd ${HOME}/git/ServerAudit/scripts/
cp call_pt-stalk.sh    ${tarball_dir}
cp gen_stalk_report.sh ${tarball_dir}

cd ${HOME}/git/dba/
cp functions               ${tarball_dir}
cp mysqld                  ${tarball_dir}
cp network                 ${tarball_dir}
cp vfa_lib.sh              ${tarball_dir}
cp install_perf_tarball.sh ${tarball_dir}

cd /tmp
tar czvf ${tarball_file} perf_tarball


