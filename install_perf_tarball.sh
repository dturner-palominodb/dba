#!/bin/bash

dest_dir=/usr/local/palominodb/scripts
tarball=/tmp/perf_tarball.tar
tarball_dir=/tmp/perf_tarball

mkdir -p ${dest_dir} 2> /dev/null
cd ${dest_dir}

cp ${tarball_dir}/* ${dest_dir}

echo "Install complete."

