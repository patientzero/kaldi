#!/bin/bash

. path.sh

#check existing directories
if [ $# !=  2 ]; then
  echo "Usage: vm_data_prep.sh /path/to/vm1 /path/to/vm2"
  echo "The arguments should be the top-levels vm1 and vm2 corpus directories."
  exit 1; 
fi 

vm1_dir=$1
vm2_dir=$2

dir=data/local/data
train=data/train

mkdir -p $dir $train
echo "Created $dir $train"

# Audio data directory check
if [ ! -d $vm1_dir ] || [ ! -d $vm2_dir ]; then
  echo "Error: run.sh requires directory arguments"
  exit 1; 
fi  

links=$dir/links

rm -r $links 2>/dev/null
mkdir $links $links/train_vm1 $links/train_vm2

# Create Symlinks
for train_data in `ls $vm1_dir | grep -P '^[a-z]\d{3}[a-z]'`
do
    ln -s $vm1_dir/$train_data $links/train_vm1/
done

for train_data in `ls $vm2_dir | grep -P '^[a-z]\d{3}[a-z]'`
do
    ln -s $vm2_dir/$train_data $links/train_vm2/
done

local=`pwd`/local
utils=`pwd`/utils

# Expect vm_dic_download to be run first
# Create flist from VM1 and VM2 with Utterance Infos and
# Path to the utterance Directory
cat $vm1_dir/VM1_TRAIN \
    | awk '{printf("%s '$vm1_dir'/%s/%s\n", $1, substr($1,0,6), $1)}' \
    > $dir/data_uttId_uttP_train_tmp.flist

cat $vm2_dir/VM2_TRAIN \
    | awk '{printf("%s '$vm2_dir'/%s/%s\n", $1, substr($1,0,6), $1)}' \
    >> $dir/data_uttId_uttP_train_tmp.flist

cat $dir/data_uttId_uttP_train_tmp.flist | sort |uniq > $dir/data_uttId_uttP_train.flist
rm $dir/data_uttId_uttP_train_tmp.flist

echo "Create train Data for $dir/data_uttId_uttP_train.flist"
while read uttIduttP
do
    uttId=`echo $uttIduttP | cut -d" " -f1`
    uttPath=`echo $uttIduttP | cut -d" " -f2`
    spkId=${uttId: (-3)}
    utt=`cat $uttPath".par" | grep ^ORT \
	| awk '{printf "%s ", $3} END{print ""}' | sed 's/ $//g'`

    echo "$uttId $utt" >> $train/text
    echo "$uttId $spkId" >> $train/utt2spk
    echo "$uttId $uttPath.wav |" >> $train/wav.scp
done < $dir/data_uttId_uttP_train.flist

# Create spk2utt File from utt2spk
cat $train/utt2spk | $util/utt2spk_to_spk2utt.pl > $train/spk2utt
