#!/bin/bash

. cmd.sh
. path.sh

export LC_ALL=C

set -e # exit on error
decode=true

nj=40
stage=0
download_dict=false
score_sclite=true
#vm1=/export/VM1/
#vm2=/export/VM2/
vm1=/mnt/raid0/data/VM1
vm2=/mnt/raid0/data/VM2

pos_dep_phones=false

. ./utils/parse_options.sh

if [ "$download_dict" = true ]; then
    local/vm_dic_download.sh $vm1 $vm2
fi

# Usage: local/vm_data_prep.sh 
echo "***** data_prep ***** "
local/vm_data_prep.sh $vm1 $vm2

# prepare vm dictionary
# before mapping lexicon
echo "***** prepare_dict ***** "
local/vm_prepare_dict.sh $vm1 $vm2

# prepare language
echo "***** prepare_lang ***** "
utils/prepare_lang.sh --position-dependent-phones $pos_dep_phones \
    data/local/dict_nosp "<unk>" data/local/lang_nosp data/lang_nosp 


# make configurable with src directory of text and data, so it can be easily switchted between train/all/etc for splitting
local/vm_train_lms.sh
local/vm_format_data.sh

# create cleaned datasubsets, cause length differs extremely
# python local/create_subset_data_dir(srcdir, targetdir, subsetsize=1000, uttminlength=4, uttmaxlength=10):

python local/create_subset_datadir.py data/train data/train_2kshort 2000 5 10
python local/create_subset_datadir.py data/train data/train_6k 6000 5 50
python local/create_subset_datadir.py data/train data/train_half 12000 5 50

for train in data/train_2kshort data/train_6k data/train_half
do
    cat $train/text0 | uniq | sort > $train/text
    cat $train/utt2spk0 | uniq | sort > $train/utt2spk
    cat $train/wav.scp0 | uniq | sort > $train/wav.scp
    # create spk2utt for datasubdirectories
    cat $train/utt2spk | utils/utt2spk_to_spk2utt.pl > $train/spk2utt
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj $train
    steps/compute_cmvn_stats.sh $train
done

# create MFCC features and compute cmvn for train an testdata
for datdir in data/train data/dev data/test
do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj $datdir
    steps/compute_cmvn_stats.sh $datdir
done

if [ "$score_sclite" = true ]; then
    touch ./data/test/score_sclite
else
    rm ./data/test/score_sclite || true
fi

if [ $stage -le 2 ]; then

    # train mono
    echo "***** Start monophone training ***** "

    steps/train_mono.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
        data/train_2kshort data/lang_nosp exp/mono0a

    if $decode; then
        utils/mkgraph.sh data/lang_nosp exp/mono0a exp/mono0a/graph_nosp

        steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/mono0a/graph_nosp \
        data/test exp/mono0a/decode_nosp_test # local score could not be called, also score basic and sclite could not be called
    fi

fi

if [ $stage -le 3 ]; then
    # train tri1
    echo "***** Align monophones ***** "
    steps/align_si.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
        data/train_6k data/lang_nosp exp/mono0a exp/mono0a_ali

    echo "***** Start training delta based triphones ***** "

    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" \
        2000 10000 data/train_6k data/lang_nosp  exp/mono0a_ali exp/tri1

    if $decode; then
        echo "***** Decoding ***** "
        utils/mkgraph.sh data/lang_nosp exp/tri1 exp/tri1/graph_nosp

        steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri1/graph_nosp \
        data/test exp/tri1/decode_nosp_test
    fi
fi

if [ $stage -le 4 ]; then
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
fi

if [ $stage -le 5 ]; then
    # train tri3a
    echo "***** Align delta+delta based triphones ***** "

    steps/align_si.sh --nj $nj --cmd "$train_cmd" \
        data/train_half data/lang_nosp exp/tri2a exp/tri2a_ali

    echo "***** Train LDA-MLLT triphones ***** "
    steps/train_lda_mllt.sh --cmd "$train_cmd" \
        --splice-opts "--left-context=3 --right-context=3" \
        3500 20000 data/train_half data/lang_nosp exp/tri2a_ali exp/tri3a



    if $decode; then
        echo "Decoding"
        utils/mkgraph.sh data/lang_nosp exp/tri3a exp/tri3a/graph_nosp

        steps/decode.sh --nj $nj --cmd "$decode_cmd" exp/tri3a/graph_nosp \
        data/test exp/tri3a/decode_nosp_test

    fi

fi 

if [ $stage -le 6 ]; then
    # train tri4a
    echo "***** Align LDA-MLLT triphones ***** " #better with align_fmllr.sh?

    steps/align_si.sh --nj $nj --cmd "$train_cmd" \
        data/train data/lang_nosp exp/tri3a exp/tri3a_ali

    echo "***** Train SAT triphones ***** "
    steps/train_sat.sh --cmd "$train_cmd" 4200 40000 \
        data/train data/lang_nosp exp/tri3a_ali exp/tri4a

    if $decode; then
        echo "***** Decoding ***** "
        utils/mkgraph.sh data/lang_nosp exp/tri4a exp/tri4a/graph_nosp

        steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" \
            --acwt 0.067 \
            exp/tri4a/graph_nosp data/test exp/tri4a/decode_nosp_test

    fi
    # Make final alignements for further training in a neural net
    echo "***** Align SAT triphones ***** " 
    steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
        data/train data/lang_nosp exp/tri4a exp/tri4a_ali
fi

# run nnet3 chain neural net training
if [ $stage -le 7 ]; then 
    local/vm_run_chain.sh --test_online_decoding true
fi
