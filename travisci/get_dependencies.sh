#!/bin/bash

echo 'Getting BioPerl'
if [ ! -d bioperl-live ]; then
  git clone -b release-1-6-924 --depth 1 https://github.com/bioperl/bioperl-live.git
fi

echo 'Getting HTSlib'
if [ ! -d htslib ]; then
  git clone --branch 1.13 --depth 1 https://github.com/samtools/htslib.git
fi

echo 'Getting jksrc'
if [ ! -f v335_base.tar.gz ]; then
  wget https://github.com/ucscGenomeBrowser/kent/archive/v335_base.tar.gz
  tar xzf v335_base.tar.gz
fi
