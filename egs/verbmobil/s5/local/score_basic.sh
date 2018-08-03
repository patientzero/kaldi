#!/bin/bash
# Copyright Johns Hopkins University (Author: Daniel Povey) 2012.  Apache 2.0.

# begin configuration section.
cmd=run.pl
min_lmwt=6
max_lmwt=12
#end configuration section.

[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 3 ]; then
  echo "Usage: local/score_basic.sh [--cmd (run.pl|queue.pl...)] <data-dir> <lang-dir|graph-dir> <decode-dir>"
  echo " Options:"
  echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
  echo "    --min_lmwt <int>                # minumum LM-weight for lattice rescoring "
  echo "    --max_lmwt <int>                # maximum LM-weight for lattice rescoring "
  exit 1;
fi

data=$1
lang=$2 # Note: may be graph directory not lang directory, but has the necessary stuff copied.
dir=$3

model=$dir/../final.mdl # assume model one level up from decoding dir.

hubscr=$KALDI_ROOT/tools/sctk/bin/hubscr.pl
[ ! -f $hubscr ] && echo "Cannot find scoring program at $hubscr" && exit 1;
hubdir=`dirname $hubscr`

for f in $data/text $lang/words.txt $dir/lat.1.gz; do
  [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1;
done

mkdir -p $dir/scoring/log

function clean_text {
  cat $1 | sed 's/%hes//g;s/<h"as>//g;s/<%>//g;s/<unk>//g' | sed -e 's/<"ahm>//g;s/<"ah>//g;s/<hm>//g' | sed -e 's/  */\ /g'
}

$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring/log/best_path.LMWT.log \
  lattice-best-path --lm-scale=LMWT --word-symbol-table=$lang/words.txt \
    "ark:gunzip -c $dir/lat.*.gz|" ark,t:$dir/scoring/LMWT.tra || exit 1;

for lmwt in `seq $min_lmwt $max_lmwt`; do
  utils/int2sym.pl -f 2- $lang/words.txt <$dir/scoring/$lmwt.tra | \
   cat - | clean_text > $dir/scoring/$lmwt.txt || exit 1;
done

clean_text $data/text >$dir/scoring/text.filt

$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring/log/score.LMWT.log \
  compute-wer --text --mode=present \
   ark:$dir/scoring/text.filt ark:$dir/scoring/LMWT.txt ">&" $dir/wer_LMWT || exit 1;

exit 0
