#!/bin/bash

# Formatting the Uni Muenchen dictionary.

# To be run from one directory above this script.

. path.sh

#check existing directories
if [ $# !=  2 ]; then
  echo "Usage: vm_prepare_dict.sh /path/to/vm1 /path/to/vm2"
  echo "The arguments should be the top-levels vm1 and vm2 corpus directories."
  echo "The directories should include the dowloaded lex from uni-muenchen."
  exit 1;
fi 

dir=data/local/dict
mkdir -p $dir

vm1_dir=$1
vm2_dir=$2

# Audio data directory check
if [ ! -d $vm1_dir ] || [ ! -d $vm2_dir ]; then
  echo "Error: run.sh requires directory arguments"
  exit 1; 
fi

# Create lexikon for VM1 and VM2 train data
cat $vm2_dir/VM2_TRAIN.lex $vm1_dir/VM1_TRAIN.lex | sort | uniq > $dir/lexicon.txt

echo "Dictionary preparation succeeded"
