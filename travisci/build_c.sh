#!/bin/bash

# Tabix first
cd tabix
if [ ! -f tabix ]; then
  make
fi

cd perl
if [ ! -d blib ]; then
  perl Makefile.PL
  make
fi
cd $DEPS

# subshell for samtools
cd samtools
if [ ! -f libbam.a ]; then
  make dylib
  make
fi
cd $DEPS

# kent src
export MACHTYPE=$(uname -m)
export MYSQLINC=`mysql_config --include | sed -e 's/^-I//g'`
export MYSQLLIBS=`mysql_config --libs`

# Build kent src
cd kent/src/lib
echo 'CFLAGS="-fPIC"' > ../inc/localEnvironment.mk
make
cd ../jkOwnLib 
make
