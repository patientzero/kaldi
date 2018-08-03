#!/bin/bash


# To be run from one directory above this script.

# This script takes no arguments.  It assumes you have already run
# vm_data_prep.sh
# It takes as input the files
# data/local/train/text
# data/local/dict/lexicon.txt

text=data/train/text
lexicon=data/local/dict_nosp/lexicon.txt

for f in "$text" "$lexicon"; do
  [ ! -f $x ] && echo "$0: No such file $f" && exit 1;
done

dir=data/local/lm
mkdir -p $dir
export LC_ALL=C # You'll get errors about things being not sorted, if you
# have a different locale.
export PATH=$PATH:`pwd`/../../../tools/kaldi_lm
( # First make sure the kaldi_lm toolkit is installed.
 cd ../../../tools || exit 1;
 if [ -d kaldi_lm ]; then
   echo Not installing the kaldi_lm toolkit since it is already there.
 else
   echo Downloading and installing the kaldi_lm tools
   if [ ! -f kaldi_lm.tar.gz ]; then
     wget http://www.danielpovey.com/files/kaldi/kaldi_lm.tar.gz || exit 1;
   fi
   tar -xvzf kaldi_lm.tar.gz || exit 1;
   cd kaldi_lm
   make || exit 1;
   echo Done making the kaldi_lm tools
 fi
) || exit 1;

# preprocessing, welche hesitation gibt es
# hier mapping, umgekehrt in lexikon aussrpachealternativen aehm, aehs etc. 
cleantext=$dir/text.no_oov 

# note: ignore 1st field of train.txt, it's the utterance-id.
# change all hesitations to a common hesitation symbol
cat $text | awk -v lex=$lexicon 'BEGIN{while((getline<lex) >0){ seen[$1]=1; } } 
  {for(n=2; n<=NF;n++) {  if (seen[$n]) { printf("%s ", $n); } else {printf("<unk> ");} } printf("\n");}' \
  | sed 's/<"ahm>/%hes/g;s/<"ah>/%hes/g;s/<hm>/%hes/g' > $cleantext || exit 1;

cat $cleantext | awk '{for(n=1;n<=NF;n++) print $n; }' | \
 sort | uniq -c | sort -nr > $dir/word.counts || exit 1;
 
# Get counts from acoustic training transcripts, and add  one-count
# for each word in the lexicon (but not silence, we don't want it
# in the LM-- we'll add it optionally later).

cat $cleantext | awk '{for(n=1;n<=NF;n++) print $n; }' | \
  cat - <(grep -w -v '!sil' $lexicon | awk '{print $1}') | \
  sort | uniq -c | sort -nr > $dir/unigram.counts || exit 1;
cat $dir/unigram.counts  | awk '{print $2}' | get_word_map.pl "<s>" "</s>" "<unk>" > $dir/word_map || exit 1;

cat $cleantext |  \
 awk -v wmap=$dir/word_map 'BEGIN{while((getline<wmap)>0)map[$1]=$2;}
  { for(n=1;n<=NF;n++) { printf map[$n]; if(n<NF){ printf " "; } else { print ""; }}}' | gzip -c >$dir/train.gz \
   || exit 1;

train_lm.sh --arpa --lmtype 3gram-mincount $dir || exit 1;

# LM is small enough that we don't need to prune it (only about 0.7M N-grams).
# Perplexity over 128254.000000 words is 90.446690

# note: output is
# data/local/lm/3gram-mincount/lm_unpruned.gz 
exit 0

# TODO: Baseline with SRILM


