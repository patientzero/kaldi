#!/bin/bash

. path.sh

#check existing directories
if [ $# !=  2 ]; then
  echo "Usage: vm_data_prep.sh /path/to/vm1 /path/to/vm2"
  echo "The arguments should be the top-levels vm1 and vm2 corpus directories."
  exit 1; 
fi 
export LC_ALL=C
vm1_dir=$1
vm2_dir=$2

dir=data/local/data
train=data/train
test=data/test
dev=data/dev

mkdir -p $dir $train $test $dev
echo "Created $dir $train $test"

# Audio data directory check
if [ ! -d $vm1_dir ] || [ ! -d $vm2_dir ]; then
  echo "Error: run.sh requires directory arguments"
  exit 1; 
fi  

local=`pwd`/local
utils=`pwd`/utils

# Expect vm_dic_download to be run first
# Create flist from VM1 and VM2 with Utterance Infos and
# Path to the utterance Directory
cat $vm1_dir/VM1_TRAIN \
    | awk '{printf("%s '$vm1_dir'/%s/%s\n", $1, substr($1,0,5), $1)}' \
    > $dir/data_uttId_uttP_train_tmp.flist

cat $vm2_dir/VM2_TRAIN \
    | awk '{printf("%s '$vm2_dir'/%s/%s\n", $1, substr($1,0,5), $1)}' \
    >> $dir/data_uttId_uttP_train_tmp.flist

cat $vm1_dir/VM1_TEST \
    | awk '{printf("%s '$vm1_dir'/%s/%s\n", $1, substr($1,0,5), $1)}' \
    > $dir/data_uttId_uttP_test_tmp.flist

cat $vm2_dir/VM2_TEST \
    | awk '{printf("%s '$vm2_dir'/%s/%s\n", $1, substr($1,0,5), $1)}' \
    >> $dir/data_uttId_uttP_test_tmp.flist

cat $vm1_dir/VM1_DEV \
    | awk '{printf("%s '$vm1_dir'/%s/%s\n", $1, substr($1,0,5), $1)}' \
    > $dir/data_uttId_uttP_dev_tmp.flist

cat $vm2_dir/VM2_DEV \
    | awk '{printf("%s '$vm2_dir'/%s/%s\n", $1, substr($1,0,5), $1)}' \
    >> $dir/data_uttId_uttP_dev_tmp.flist
    
for dset in 'test' train dev
do
    cat $dir/data_uttId_uttP_${dset}_tmp.flist | sort | uniq > $dir/data_uttId_uttP_${dset}.flist
    rm $dir/data_uttId_uttP_${dset}_tmp.flist 
done


echo "Create train data for $dir/data_uttId_uttP_train.flist"
while read uttIduttP
do
    uttId=`echo $uttIduttP | cut -d" " -f1`
    uttPath=`echo $uttIduttP | cut -d" " -f2`
    spkId=${uttId: (-3)}
    utt=`cat $uttPath".par" | grep ^ORT \
	| awk '{printf "%s ", $3} END{print ""}' | sed 's/ $//g'`
        echo $spkId"_"$uttId $utt >> $train/text0
        echo $spkId"_"$uttId $spkId >> $train/utt2spk0
        echo $spkId"_"$uttId $uttPath".wav" >> $train/wav0.scp    
done < $dir/data_uttId_uttP_train.flist

while read uttIduttP
do
    uttId=`echo $uttIduttP | cut -d" " -f1`
    uttPath=`echo $uttIduttP | cut -d" " -f2`
    spkId=${uttId: (-3)}
    utt=`cat $uttPath".par" | grep ^ORT \
	| awk '{printf "%s ", $3} END{print ""}' | sed 's/ $//g'`
        echo $spkId"_"$uttId $utt >> $test/text0
        echo $spkId"_"$uttId $spkId >> $test/utt2spk0
        echo $spkId"_"$uttId $uttPath".wav" >> $test/wav0.scp    
done < $dir/data_uttId_uttP_test.flist

while read uttIduttP
do
    uttId=`echo $uttIduttP | cut -d" " -f1`
    uttPath=`echo $uttIduttP | cut -d" " -f2`
    spkId=${uttId: (-3)}
    utt=`cat $uttPath".par" | grep ^ORT \
	| awk '{printf "%s ", $3} END{print ""}' | sed 's/ $//g'`
        echo $spkId"_"$uttId $utt >> $dev/text0
        echo $spkId"_"$uttId $spkId >> $dev/utt2spk0
        echo $spkId"_"$uttId $uttPath".wav" >> $dev/wav0.scp    
done < $dir/data_uttId_uttP_dev.flist

for datdir in $test $train $dev
do
cat $datdir/text0 | uniq | sort > $datdir/text
cat $datdir/utt2spk0 | uniq | sort > $datdir/utt2spk
cat $datdir/wav0.scp | uniq | sort > $datdir/wav.scp

# "Cleanup temporary files"
rm $datdir/text0 $datdir/utt2spk0 $datdir/wav0.scp
# Create spk2utt File from utt2spk
echo "Create Speaker2Utterance file"
cat $datdir/utt2spk | utils/utt2spk_to_spk2utt.pl > $datdir/spk2utt

done
