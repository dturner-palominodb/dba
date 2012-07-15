#!/bin/bash

tarball=/tmp/perf_tarball.tar

cd ${HOME}/git/ServerAudit/scripts/
tar cvf ${tarball} \
call_pt-stalk.sh \
gen_stalk_report.sh

cd ${HOME}/git/dba/
tar rvf ${tarball} \
functions \
mysqld \
network \
vfa_lib.sh \
install_perf_tarball.sh

gzip ${tarball}


