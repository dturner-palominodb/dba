#!/bin/bash

cd /home/dturner/git/dba
tar cvf /tmp/tarball.tar \
vfa_lib.sh \
functions \
mysqld \
network

cd /home/dturner/git/ServerAudit/scripts
tar rvf /tmp/tarball.tar \
call_pt-stalk.sh \
gen_stalk_report.sh

gzip /tmp/tarball.tar
