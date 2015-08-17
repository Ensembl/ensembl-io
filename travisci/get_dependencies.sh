#!/bin/bash

echo 'Getting BioPerl'
if [ ! -f bioperl-release-1-2-3.zip ]; then 
  wget https://github.com/bioperl/bioperl-live/archive/bioperl-release-1-2-3.zip 
  unzip -q bioperl-release-1-2-3.zip
fi

echo 'Getting tabix'
if [ ! -d tabix ]; then 
  git clone --branch master --depth 1 https://github.com/samtools/tabix.git
fi

echo 'Getting samtools'
if [ ! -d samtools ]; then 
  git clone --branch 0.1.20 --depth 1 https://github.com/samtools/samtools.git
fi

echo 'Getting jksrc'
if [ ! -f jksrc.zip ]; then 
  wget http://hgdownload.cse.ucsc.edu/admin/jksrc.zip
  unzip -q jksrc.zip
fi
