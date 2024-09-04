#!/bin/bash

# HTSlib first
cd htslib
if [ ! -f libhts.a ]; then
  make
fi
cd $DEPS



# kent src
export MACHTYPE=$(uname -m)
export MYSQLINC=`mysql_config --include | sed -e 's/^-I//g'`
export MYSQLLIBS=`mysql_config --libs`

# Build kent src
cd kent-335_base/src/lib
sed -i "s/CC=gcc/CC=gcc -fPIC/g" ../inc/common.mk
sed -i "1109s/my_bool/bool/" ../hg/lib/jksql.c
sed -i "1110s/MYSQL_OPT_SSL_VERIFY_SERVER_CERT/CLIENT_SSL_VERIFY_SERVER_CERT/" ../hg/lib/jksql.c
make
cd ../jkOwnLib
make
