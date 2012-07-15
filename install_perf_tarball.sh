#!/bin/bash

dest_dir=/usr/local/palominodb/scripts
tarball=/tmp/perf_tarball.tar

mkdir -p ${dest_dir} 2> /dev/null
cd ${dest_dir}

gunzip ${tarball}.gz

tar xvf ${tarball}

echo "Complete"

