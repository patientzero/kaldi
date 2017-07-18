#!/bin/bash

. cmd.sh
. path.sh

set -e # exit on error
decode=true

#vm1=/export/VM1/
#vm2=/export/VM2/
vm1=/scratch/audio_data/VM1/
vm2=/scratch/audio_data/VM2/

#local/vm_dic_download.sh $vm1 $vm2

# Usage: local/vm_data_prep.sh 
echo "data_prep"
local/vm_data_prep.sh $vm1 $vm2

# prepare vm dictionary
# before mapping lexicon
echo "prepare_dict"
local/vm_prepare_dict.sh $vm1 $vm2

# prepare language
echo "prepare_lang"
utils/prepare_lang.sh data/local/dict_nosp \
    "<unk>" data/local/lang_nosp data/lang_nosp

local/vm_train_lms.sh
local/vm_format_data.sh

# create MFCC features
steps/make_mfcc.sh --cmd "$train_cmd" --nj 20 data/train
steps/compute_cmvn_stats.sh data/train

# 24425 data count
utils/subset_data_dir.sh --first data/train 6000 data/train_6k
utils/subset_data_dir.sh --shortest data/train 2000 data/train_2kshort
utils/subset_data_dir.sh data/train 12200 data/train_half

# train Mono
steps/train_mono.sh --boost-silence 1.25 --nj 20 --cmd "$train_cmd" \
    data/train_2kshort data/lang_nosp exp/mono0a

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/mono0a exp/mono0a/graph_nosp

    steps/decode.sh --nj 20 --cmd "$decode_cmd" exp/mono0a/graph_nosp \
	data/train_2kshort exp/mono0a/decode_nosp_train
fi


# train tri1
steps/align_si.sh --boost-silence 1.25 --nj 10 --cmd "$train_cmd" \
    data/train_6k data/lang_nosp exp/mono0a exp/mono0a_ali

steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 data/train_6k data/lang_nosp exp/mono0a_ali exp/tri1

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/tri1 exp/tri1/graph_nosp

    steps/decode.sh --nj 20 --cmd "$decode_cmd" exp/tri1/graph_nosp \
	data/train_6k exp/tri1/decode_nosp_train6k
fi


# train tri2b
steps/align_si.sh --nj 20 --cmd "$train_cmd" \
    data/train_half data/lang_nosp exp/tri1 exp/tri1_ali

steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" \
    2500 15000 data/train_half data/lang_nosp exp/tri1_ali exp/tri2b

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/tri2b exp/tri2b/graph_nosp

    steps/decode.sh --nj 20 --cmd "$decode_cmd" exp/tri2b/graph_nosp \
	data/train_half exp/tri2b/decode_nosp_train2kshort
fi


# train tri3b
steps/align_si.sh --nj 20 --cmd "$train_cmd" \
    data/train data/lang_nosp exp/tri2b exp/tri2b_ali

steps/train_sat.sh --cmd "$train_cmd" 4200 40000 \
    data/train data/lang_nosp exp/tri2b_ali exp/tri3b

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/tri3b exp/tri3b/graph_nosp

    steps/decode.sh --nj 20 --cmd "$decode_cmd" exp/tri3b/graph_nosp \
	data/train exp/tri3b/decode_nosp_train
fi
