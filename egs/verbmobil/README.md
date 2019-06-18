# Verbmobil I+II

The Verbmobil (VM) corpus contains spontaneous dialogue recordings of people making appointments and general travel planning on the phone. 
The audio data used in this recipe amounts to over 46 hours of German dialogues in the training set.  
It consists of 24435 utterances in 962 dialogs spoken by 629 speakers. 
The provided lexicon contains 9036 German words.
Dataset definitions can be obtained from http://www.bas.uni-muenchen.de/forschung/Verbmobil/Verbmobil.html

The recipe is based on a version of the WSJ recipe. 
To start the standard speech recognition recipe you just have to a

The local/vm_run_chain_no_ivector.sh script creates the acoustic model withouth the use of i-vectors but instead uses MFCC40 features.  
To use it you have to adapt the run.sh file.

## Usage:

You have to specify the location of the audio files with the variables 
vm1 and vm2 which is the minimal configuration you need. 



## Results
|System     |WER    |
|:---|:---|
|tri3a|19.70%|
|tri4a| 16.42 %|
|chain| 9.41 %|

