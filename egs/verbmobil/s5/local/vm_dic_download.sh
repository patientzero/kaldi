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

for set in TRAIN TEST DEV
do
  echo " *** Downloading vm1 ${set} dictionary ***" 
  wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_${set}
  wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_${set}.lex
  wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM1_${set}.list
done
# echo "Downloading German lexicon"
# wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/vm_ger.lex
# echo "Downloading German phone set"
# wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/vm_ger.set
# echo "Downloading documentation"
# # Documentation contains VM_Bonus material which conbtains german trigramm language model 
# wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/vm2.documentation.zip
# unzip ./vm2.documentation.zip
# cd ./vm2.documentation/VMBONUS
# tar xzvf VM2-LM-2.4.tgz.
# echo "Downloading documentation"
# # Documentation contains VM_Bonus material which conbtains german trigramm language model 
# wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/vm2.documentation.zip
# unzip ./vm2.documentation.zip
# cd ./vm2.documentation/VMBONUS
# tar xzvf VM2-LM-2.4.tgz.
# echo "Downloading documentation"
# # Documentation contains VM_Bonus material which conbtains german trigramm language model 
# wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/vm2.documentation.zip
# unzip ./vm2.documentation.zip
# cd ./vm2.documentation/VMBONUS
# tar xzvf VM2-LM-2.4.tgz.

# echo "Downloading german pronounciation alternatives"
# wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/VM.German.Wordforms
cd - 
cd $vm2_dir

for set in TRAIN TEST DEV 
do
  echo " *** Downloading vm2 ${set} dictionary ***" 
  wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_${set}
  wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_${set}.lex
  wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/SETS/VM2_${set}.list
done
# echo "Downloading documentation"
# # Documentation contains VM_Bonus material which conbtains german trigramm language model 
# wget ftp://ftp.bas.uni-muenchen.de/pub/BAS/VM/vm2.documentation.zip
# unzip ./vm2.documentation.zip ./vm2.documentation
# cd - 
# cd $vm2_dir/vm2.documentation/VMBONUS/LanguageModel 
# # This extracts: VM2-2.4.lm.cs VM2-2.4.lm.map VM2-2.4.lm.wl and VM2-2.4.M3.lm.gz.
# tar xzvf ./VM2-LM-2.4.tgz

cd -
