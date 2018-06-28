#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: path/to/lexicon  path/to/text"
    echo "Expecting lex in the format: lexiconentry phones"
    echo "Expecting text in the format: utterance_id utterance"
fi
lexicon=''
text=''

. ./utils/parse_options.sh

cat $text | awk -v oov=0 -v lex=$lexicon -v nooov=0 'BEGIN{
    while((getline<lex) >0)
    {seen[$1]=1}}
    {for(n=2;n<=NF;n++){if(seen[$n]==1){nooov++}else{oov++}}}END{print "Percentage oov: " (oov/(oov+nooov))*100}'