#!/bin/bash

. path.sh

#check existing directories
if [ $# != 2 ]; then
  echo "Usage: vm_dic_download.sh /path/to/vm1 /path/to/vm2"
  exit 1; 
fi 

vm1_dir=$1
vm2_dir=$2

# Audio data directory check
if [ ! -d $vm1_dir ] || [ ! -d $vm2_dir ]; then
  echo "Error: run.sh requires directory arguments"
  exit 1; 
fi  

# General source of lex and sets: ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/

cd $vm1_dir
echo " *** Downloading vm1 train dictionary ***" 
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_TRAIN
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_TRAIN.lex
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_TRAIN.list
echo " *** Downloading vm1 test dictionary ***" 
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_TEST
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_TEST.lex
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_TEST.list
echo " *** Downloading vm1 dev dictionary ***" 
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_DEV
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_DEV.lex
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_DEV.list


cd -



cd $vm2_dir
echo " *** Downloading vm2 train dictionary ***" 
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_TRAIN
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_TRAIN.lex
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_TRAIN.list
echo " *** Downloading vm2 test dictionary ***" 
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_TEST
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_TEST.lex
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_TEST.list
echo " *** Downloading vm2 dev dictionary ***" 
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_DEV
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_DEV.lex
wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_DEV.list
cd -
