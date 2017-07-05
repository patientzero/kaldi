#!/bin/bash

. cmd.sh
. path.sh

set -e # exit on error
#has_fisher=true

#vm1=/export/VM1/
#vm2=/export/VM2/
vm1=/scratch/audio_data/VM1/
vm2=/scratch/audio_data/VM2/

#local/vm_dic_download.sh $vm1 $vm2

# Usage: local/vm_data_prep.sh 
local/vm_data_prep.sh $vm1 $vm2

# prepare vm dictionary
# before mapping lexicon
local/vm_prepare_dict.sh $vm1 $vm2
