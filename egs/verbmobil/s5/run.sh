#!/bin/bash

. cmd.sh
. path.sh

export LC_ALL=C

set -e # exit on error
decode=true

nj=20
#vm1=/export/VM1/
#vm2=/export/VM2/
vm1=/mnt/raid0/data/VM1
vm2=/mnt/raid0/data/VM2

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
# note to self: works till here, LC_ALL must be introduced in prepare_lang and or prepare dict, after that problems with sort, broken pipe, duplciates
# create MFCC features
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/train
steps/compute_cmvn_stats.sh data/train

# 24425 data count
utils/subset_data_dir.sh --first data/train 6000 data/train_6k
utils/subset_data_dir.sh --shortest data/train 2000 data/train_2kshort #https://stackoverflow.com/questions/46202653/bash-error-in-sort-sort-write-failed-standard-output-broken-pipe
utils/subset_data_dir.sh data/train 12200 data/train_half


# train Mono
steps/train_mono.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
    data/train_2kshort data/lang_nosp exp/mono0a

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/mono0a exp/mono0a/graph_nosp

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/mono0a/graph_nosp \
	data/train_2kshort exp/mono0a/decode_nosp_train # local score could not be called, also score basic and sclite could not be called
fi


# train tri1
steps/align_si.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
    data/train_6k data/lang_nosp exp/mono0a exp/mono0a_ali

steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 data/train_6k data/lang_nosp  exp/mono0a_ali exp/tri1

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/tri1 exp/tri1/graph_nosp

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri1/graph_nosp \
	data/train_6k exp/tri1/decode_nosp_train6k
fi
## Ende 08.05.18 17h

# train tri2b
steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train_half data/lang_nosp exp/tri1 exp/tri1_ali

steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" \
    2500 15000 data/train_half data/lang_nosp exp/tri1_ali exp/tri2b

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/tri2b exp/tri2b/graph_nosp

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri2b/graph_nosp \
	data/train_half exp/tri2b/decode_nosp_train2kshort
fi

# train tri3b
steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang_nosp exp/tri2b exp/tri2b_ali

steps/train_sat.sh --cmd "$train_cmd" 4200 40000 \
    data/train data/lang_nosp exp/tri2b_ali exp/tri3b

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/tri3b exp/tri3b/graph_nosp

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri3b/graph_nosp \
	data/train exp/tri3b/decode_nosp_train
fi
## Ende 09.05.18
# Estimate pronunciation and silence probabilities.
# steps/get_prons.sh --cmd "$train_cmd" \
#     data/train data/lang_nosp exp/tri3b

# utils/dict_dir_add_pronprobs.sh --max-normalize true \
#     data/local/dict_nosp \
#     exp/tri3b/pron_counts_nowb.txt exp/tri3b/sil_counts_nowb.txt \
#     exp/tri3b/pron_bigram_counts_nowb.txt data/local/dict

# utils/prepare_lang.sh data/local/dict_nosp \
#   "<SPOKEN_NOISE>" data/local/lang_nosp data/lang_nosp # macht shit, why?


# mkdir -p data/lang_test/
# cp -r data/lang/* data/lang_test/
# rm -rf data/lang_test/tmp
# cp data/lang_nosp/G.* data/lang_test/

# From 3b system, now using data/lang as the lang directory (we have now added
# pronunciation and silence probabilities), train another SAT system (tri4b).
#train tri4b
steps/align_si.sh --nj 20 --cmd "$train_cmd" \
    data/train data/lang_nosp exp/tri3b exp/tri3b_ali

steps/train_sat.sh --cmd "$train_cmd" \
    4200 40000 data/train data/lang_nosp exp/tri3b_ali exp/tri4b 

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/tri4b exp/tri4b/graph_nosp

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri4b/graph_nosp \
	data/train exp/tri4b/decode_nosp_train
fi
