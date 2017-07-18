#!/bin/bash
#

if [ -f path.sh ]; then . path.sh; fi

silprob=0.5
lang_dir=data/lang_nosp/

arpa_lm=data/local/lm/3gram-mincount/lm_unpruned.gz
[ ! -f $arpa_lm ] && echo No such file $arpa_lm && exit 1;

gunzip -c "$arpa_lm" | \
    arpa2fst --disambig-symbol=#0 \
    --read-symbol-table=data/lang_nosp/words.txt - $lang_dir/G.fst


echo  "Checking how stochastic G is (the first of these numbers should be small):"
fstisstochastic $lang_dir/G.fst

## Check lexicon.
## just have a look and make sure it seems sane.
echo "First few lines of lexicon FST:"
fstprint   --isymbols=$lang_dir/phones.txt --osymbols=$lang_dir/words.txt $lang_dir/L.fst  | head

echo Performing further checks

# Checking that G.fst is determinizable.
fstdeterminize $lang_dir/G.fst /dev/null || echo Error determinizing G.

# Checking that L_disambig.fst is determinizable.
fstdeterminize $lang_dir/L_disambig.fst /dev/null || echo Error determinizing L.

# Checking that disambiguated lexicon times G is determinizable
# Note: we do this with fstdeterminizestar not fstdeterminize, as
# fstdeterminize was taking forever (presumbaly relates to a bug
# in this version of OpenFst that makes determinization slow for
# some case).
fsttablecompose $lang_dir/L_disambig.fst $lang_dir/G.fst | \
   fstdeterminizestar >/dev/null || echo Error

# Checking that LG is stochastic:
fsttablecompose $lang_dir/L_disambig.fst $lang_dir/G.fst | \
   fstisstochastic || echo LG is not stochastic


echo vm_format_data succeeded.
