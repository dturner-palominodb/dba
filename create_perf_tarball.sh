#!/bin/bash

tarball_dir=/tmp/perf_tarball
date=`date +"%Y%m%d%H%M%S"`
tarball_file=perf_tarball_${date}.tgz

mkdir -p /tmp/perf_tarball 2> /dev/null

# Deprecated. Removing after there is a replacement
# cd ${HOME}/git/ServerAudit/scripts/
# cp call_pt-stalk.sh    ${tarball_dir}
# cp gen_stalk_report.sh ${tarball_dir}

cd ${HOME}/git/dba/
cleanup_osc.sh
cp functions                       ${tarball_dir}
cp install_perf_tarball.sh         ${tarball_dir}
cp mysqld                          ${tarball_dir}
cp pdb-check-maxvalue.sh           ${tarball_dir}
cp pdb-defrag.sh                   ${tarball_dir}
cp pdb-local-reorg.sh              ${tarball_dir}
cp pdb-track-table-usage.sh        ${tarball_dir}
cp pdb-track-user-stats.sh         ${tarball_dir}
cp pdb_checksum_to_file.sh         ${tarball_dir}
cp pdb_checksum_to_file.sh         ${tarball_dir}
cp pdb_dump.sh                     ${tarball_dir}
cp pdb_set_long_query_time.sh      ${tarball_dir}
cp replace_mysql_startup_script.sh ${tarball_dir}
cp vfa_lib.sh                      ${tarball_dir}

cd /tmp
tar czvf ${tarball_file} perf_tarball

