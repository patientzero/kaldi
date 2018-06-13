#!/bin/bash

. cmd.sh
. path.sh

export LC_ALL=C

set -e # exit on error
decode=true

nj=40
#vm1=/export/VM1/
#vm2=/export/VM2/
vm1=/mnt/raid0/data/VM1
vm2=/mnt/raid0/data/VM2

#local/vm_dic_download.sh $vm1 $vm2

# Usage: local/vm_data_prep.sh 
echo "***** data_prep ***** "
local/vm_data_prep.sh $vm1 $vm2

# prepare vm dictionary
# before mapping lexicon
echo "***** prepare_dict ***** "
local/vm_prepare_dict.sh $vm1 $vm2

# prepare language
pos_dep_phones=false

echo "***** prepare_lang ***** "
utils/prepare_lang.sh --position-dependent-phones $pos_dep_phones \
    data/local/dict_nosp "<unk>" data/local/lang_nosp data/lang_nosp 


# make configurable with src directory of text and data, so it can be easily switchted between train/all/etc for splitting
local/vm_train_lms.sh
local/vm_format_data.sh

# create cleaned datasubsets, cause length differs extremely
# python local/create_subset_data_dir(srcdir, targetdir, subsetsize=1000, uttminlength=4, uttmaxlength=10):

python local/create_subset_data_dir data/train data/train_2kshort 2000 5 10
python local/create_subset_data_dir data/train data/train_6k subsetsize=6000 5 50
python local/create_subset_data_dir data/train data/train_half 12000 5 50

# create spk2utt for datasubdirectories
cat data/train_2kshort/utt2spk | utils/utt2spk_to_spk2utt.pl > data/train_2kshort/spk2utt
cat data/train_6k/utt2spk | utils/utt2spk_to_spk2utt.pl > data/train_6k/spk2utt
cat data/train_half/utt2spk | utils/utt2spk_to_spk2utt.pl > data/train_half/spk2utt

# create MFCC features and compute cmvn for train an testdata
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/train
steps/compute_cmvn_stats.sh data/train
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/train_2kshort
steps/compute_cmvn_stats.sh data/train_2kshort
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/train_6k
steps/compute_cmvn_stats.sh data/train_6k
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/train_half
steps/compute_cmvn_stats.sh data/train_half
steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/test
steps/compute_cmvn_stats.sh data/test



# 24425 data count in trainset, split 6k utterances for monophone training
# https://stackoverflow.com/questions/46202653/bash-error-in-sort-sort-write-failed-standard-output-broken-pipe
# utils/subset_data_dir.sh data/train 2000 data/train_2kshort
# utils/subset_data_dir.sh data/train 6000 data/train_6k
# utils/subset_data_dir.sh data/train 12000 data/train_half


# train mono
echo "***** Start monophone training ***** " 

steps/train_mono.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
    data/train_2kshort data/lang_nosp exp/mono0a

if $decode; then
    utils/mkgraph.sh data/lang_nosp exp/mono0a exp/mono0a/graph_nosp

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/mono0a/graph_nosp \
	data/test exp/mono0a/decode_nosp_test # local score could not be called, also score basic and sclite could not be called
fi

# steps/diagnostic/analyze_lats.sh --cmd run.pl exp/mono0a/graph_nosp exp/mono0a/decode_nosp_train
# analyze_phone_length_stats.py: WARNING: optional-silence sil is seen only 67.95% of the time at utterance end.  This may not be optimal.
# steps/diagnostic/analyze_lats.sh: see stats in exp/mono0a/decode_nosp_train/log/analyze_alignments.log
# Overall, lattice depth (10,50,90-percentile)=(1,1,7) and mean=3.4
# steps/diagnostic/analyze_lats.sh: see stats in exp/mono0a/decode_nosp_train/log/analyze_lattice_depth_stats.log
# data/train_2kshort/stm does not exist: using local/score_basic.sh

# train tri1
echo "***** Align monophones ***** "
steps/align_si.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
    data/train_2kshort data/lang_nosp exp/mono0a exp/mono0a_ali

echo "***** Start training delta based triphones ***** "

steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
    2000 10000 data/train_6k data/lang_nosp  exp/mono0a_ali exp/tri1

if $decode; then
    echo "***** Decoding ***** "
    utils/mkgraph.sh data/lang_nosp exp/tri1 exp/tri1/graph_nosp

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri1/graph_nosp \
	data/test exp/tri1/decode_nosp_test
    # steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri1/graph_nosp \
	# data/train_6k exp/tri1/decode_nosp_train6k
fi

# train tri2a
echo "***** Aligning delta based triphones ***** "

steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    --use-graphs true data/train_6k data/lang_nosp exp/tri1 exp/tri1_ali
echo "***** Train delta+delta based triphones ***** "

steps/train_deltas.sh --cmd "$train_cmd" \
    2500 15000 data/train_6k data/lang_nosp exp/tri1_ali exp/tri2a 

if $decode; then
    echo "***** Decoding ***** "
    utils/mkgraph.sh data/lang_nosp exp/tri2a exp/tri2a/graph_nosp 

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri2a/graph_nosp \
    data/test exp/tri2a/decode_nosp_test
fi

# train tri3a 
echo "***** Align delta+delta based triphones ***** "

steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train_6k data/lang_nosp exp/tri2a exp/tri2a_ali

echo "***** Train LDA-MLLT triphones***** "
steps/train_lda_mllt.sh --cmd "$train_cmd" \
    --splice-opts "--left-context=3 --right-context=3" \
    3500 20000 data/train_half data/lang_nosp exp/tri2a_ali exp/tri3a

# exp/tri2b: nj=20 align prob=-49.05 over 22.61h [retry=10.8%, fail=0.8%] states=2064 gauss=15034 tree-impr=3.85 lda-sum=16.01 mllt:impr,logdet=1.14,1.65
# steps/train_lda_mllt.sh: Done training system with LDA+MLLT features in exp/tri2b

if $decode; then
    echo "Decoding"
    utils/mkgraph.sh data/lang_nosp exp/tri3a exp/tri3a/graph_nosp

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri3a/graph_nosp \
	data/test exp/tri3a/decode_nosp_test

fi

# train tri4a
echo "***** Align LDA-MLLT triphones ***** " #better with align_fmllr.sh?

steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
    data/train_half data/lang_nosp exp/tri3a exp/tri3a_ali

echo "***** Train SAT triphones ***** " 
steps/train_sat.sh --cmd "$train_cmd" 4200 40000 \
    data/train data/lang_nosp exp/tri3a_ali exp/tri4a

if $decode; then
    echo "***** Decoding ***** "
    utils/mkgraph.sh data/lang_nosp exp/tri4a exp/tri4a/graph_nosp

    steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri4a/graph_nosp \
	data/test exp/tri4a/decode_nosp_test

fi

# YOU ARE HERE AT THE MOMENT
# Make final alignements for further training in a neural net
echo "***** Align SAT triphones ***** " # better with aling_fmlrr.sh ? 
steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang_nosp exp/tri4a exp/tri4a_ali

# Estimate pronunciation and silence probabilities.
# steps/get_prons.sh --cmd "$train_cmd" \
#     data/train data/lang_nosp exp/tri3b

# utils/dict_dir_add_pronprobs.sh --max-normalize true \
#     data/local/dict_nosp \
#     exp/tri3b/pron_counts_nowb.txt exp/tri3b/sil_counts_nowb.txt \
#     exp/tri3b/pron_bigram_counts_nowb.txt data/local/dict

# utils/prepare_lang.sh data/local/dict_nosp \
#   "<SPOKEN_NOISE>" data/local/lang_nosp data/lang_nosp # macht shit, why?
