#!/bin/bash

# Formatting the Uni Muenchen dictionary.

# To be run from one directory above this script.

. path.sh

#check existing directories
if [ $# !=  2 ]; then
  echo "Usage: vm_prepare_dict.sh /path/to/vm1 /path/to/vm2"
  echo "The arguments should be the top-levels vm1 and vm2 corpus directories."
  echo "The directories should include the dowloaded lex from uni-muenchen."
  exit 1;
fi 

dir=data/local/dict_nosp
mkdir -p $dir

vm1_dir=$1
vm2_dir=$2

# Audio data directory check
if [ ! -d $vm1_dir ] || [ ! -d $vm2_dir ]; then
  echo "Error: run.sh requires directory arguments"
  exit 1; 
fi

# Create lexikon for VM1 and VM2 train data
cat $vm2_dir/VM2_TRAIN.lex $vm1_dir/VM1_TRAIN.lex | sort | uniq > $dir/lexicon0.txt

# Remove Glottal Stop from Lex
sed 's/Q//g' $dir/lexicon0.txt > $dir/lexicon0q.txt


# Pre-processing (remove comments)
# grep -v '^#' $dir/lexicon0.txt | awk 'NF>0' | sort > $dir/lexicon1.txt || exit 1;
# Lexicon with remove glotal stop:
grep -v '^#' $dir/lexicon0q.txt | awk 'NF>0' | sort > $dir/lexicon1.txt || exit 1;

cat $dir/lexicon1.txt | awk '{ for(n=2;n<=NF;n++){ phones[$n] = 1; }} END{for (p in phones) print p;}' | \
    grep -v sil > $dir/nonsilence_phones.txt  || exit 1;

( echo sil; echo spn; echo nsn; echo lau ) > $dir/silence_phones.txt # silence, spoken noice, non spoken noise, laughter

echo sil > $dir/optional_silence.txt

# Add to the lexion the silences, noises etc.
# <"ahm> <%> <"ah> <h"as> <hm>
( echo '!sil sil'; echo '[vocalized-noise] spn'; echo '[noise] nsn'; \
    echo '[laughter] lau'; echo '<unk> spn' ) \
    | cat - $dir/lexicon1.txt  > $dir/lexicon2.txt || exit 1;

# No "extra questions" in the input to this setup, as we don't
# have stress or tone.
echo -n >$dir/extra_questions.txt

cp $dir/lexicon2.txt $dir/lexicon.txt #Final lexicon

echo "Prepared dictionary and phone-sets for Verbmobil"
