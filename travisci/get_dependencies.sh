#!/bin/bash

echo 'Getting BioPerl'
if [ ! -f bioperl-release-1-2-3.zip ]; then
  wget https://github.com/bioperl/bioperl-live/archive/bioperl-release-1-2-3.zip
  unzip -q bioperl-release-1-2-3.zip
fi

echo 'Getting HTSlib'
if [ ! -d htslib ]; then
  url=$(curl -s https://api.github.com/repos/samtools/htslib/releases | grep browser_download_url | head -n 1 | cut -d '"' -f 4)
  curl -sL $url > htslib.tar.bz2
  tar jxf htslib.tar.bz2
  htslib=$(find . -name 'htslib*' -type d -depth 1)
  mv $htslib htslib
fi

echo 'Getting jksrc'
if [ ! -f jksrc.zip ]; then
  wget http://hgdownload.cse.ucsc.edu/admin/jksrc.zip
  unzip -q jksrc.zip
fi
