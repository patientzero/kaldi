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

mkdir -p $dir $train $test
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
# fixed directory substring, otherwise no data was found
cat $vm1_dir/VM1_TRAIN \
    | awk '{printf("%s '$vm1_dir'/%s/%s\n", $1, substr($1,0,5), $1)}' \
    > $dir/data_uttId_uttP_train_tmp.flist

cat $vm2_dir/VM2_TRAIN \
    | awk '{printf("%s '$vm2_dir'/%s/%s\n", $1, substr($1,0,5), $1)}' \
    >> $dir/data_uttId_uttP_train_tmp.flist

cat $dir/data_uttId_uttP_train_tmp.flist | sort |uniq > $dir/data_uttId_uttP_train.flist
rm $dir/data_uttId_uttP_train_tmp.flist

# split n speaker for testing
n=10
while read uttIduttP
do
    uttId=`echo $uttIduttP | cut -d" " -f1`
    echo ${uttId: (-3)} >> $dir/speakerIds    
done < $dir/data_uttId_uttP_train.flist
cat $dir/speakerIds | sort | uniq | head -$n > $dir/testspeaker
rm $dir/speakerIds

echo "Create train Data for $dir/data_uttId_uttP_train.flist"
while read uttIduttP
do
    uttId=`echo $uttIduttP | cut -d" " -f1`
    uttPath=`echo $uttIduttP | cut -d" " -f2`
    spkId=${uttId: (-3)}
    utt=`cat $uttPath".par" | grep ^ORT \
	| awk '{printf "%s ", $3} END{print ""}' | sed 's/ $//g'`

    if grep -Fq "$spk" $dir/testspeaker; then
        echo $spkId"_"$uttId $utt >> $test/text0
        echo $spkId"_"$uttId $spkId >> $test/utt2spk0
        echo $spkId"_"$uttId $uttPath".wav" >> $test/wav0.scp
    else
        echo $spkId"_"$uttId $utt >> $train/text0
        echo $spkId"_"$uttId $spkId >> $train/utt2spk0
        echo $spkId"_"$uttId $uttPath".wav" >> $train/wav0.scp

    fi
done < $dir/data_uttId_uttP_train.flist

cat $test/text0 | uniq | sort > $test/text
cat $test/utt2spk0 | uniq | sort > $test/utt2spk
cat $test/wav0.scp | uniq | sort > $test/wav.scp
rm $test/text0 $test/utt2spk0 $test/wav0.scp

cat $train/text0 | uniq | sort > $train/text
cat $train/utt2spk0 | uniq | sort > $train/utt2spk
cat $train/wav0.scp | uniq | sort > $train/wav.scp
rm $train/text0 $train/utt2spk0 $train/wav0.scp

# Create spk2utt File from utt2spk
cat $train/utt2spk | utils/utt2spk_to_spk2utt.pl > $train/spk2utt
cat $test/utt2spk | utils/utt2spk_to_spk2utt.pl > $test/spk2utt
