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

function clean_text {
  cat $1 | sed 's/%hes//g' | sed -e 's/  */\ /g'
}

data=$1
lang=$2 # Note: may be graph directory not lang directory, but has the necessary stuff copied.
dir=$3

model=$dir/../final.mdl # assume model one level up from decoding dir.

sclite=$KALDI_ROOT/tools/sctk/bin/sclite
[ ! -f $sclite ] && echo "Cannot find scoring program at $sclite" && exit 1;
sclitdir=`dirname $sclite`
# TODO: check if sclite is installed, install in case it's not

for f in $data/text $lang/words.txt $dir/lat.1.gz; do
  [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1;
done

# transform data to fit expected format(trn) and clean from %hes
if [ ! -f $data/text_trn ]; then
  echo "create ref file"
  awk '{for(n=2;n<=NF;n++) if(n<NF){printf $n " "}else {print "(" $1 ")" }}' $data/text | \
  clean_text > $data/text_trn
fi

mkdir -p $dir/scoring/log


$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring/log/best_path.LMWT.log \
  lattice-best-path --lm-scale=LMWT --word-symbol-table=$lang/words.txt \
    "ark:gunzip -c $dir/lat.*.gz|" ark,t:$dir/scoring/LMWT.tra || exit 1;

for lmwt in `seq $min_lmwt $max_lmwt`; do
  utils/int2sym.pl -f 2- $lang/words.txt <$dir/scoring/$lmwt.tra | \
  cat - > $dir/scoring/$lmwt.txt || exit 1;
done


# remove hes from hyp ref
for lmwt in `seq $min_lmwt $max_lmwt`; do
#find utterances that are empty after cleaning
  clean_text $dir/scoring/$lmwt.txt | awk '{if(NF == 1){print $1}}' > $dir/scoring/empty
#remove empty utterances and reformat hypothesis files to trn format
  utils/filter_scp.pl --exclude $dir/scoring/empty $dir/scoring/$lmwt.txt | \
    clean_text | awk '{for(n=2;n<=NF;n++) if(n<NF){printf $n " "}else {print "(" $1 ")" }}' \
    > $dir/scoring/$lmwt.trn
done

# call sclite
$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring/log/score.LMWT.log \
  $sclite -r $data/text_trn -h $dir/scoring/LMWT.trn -i rm -o dtl -n wer_LMWT -O $dir/scoring || exit 1;

exit 0
