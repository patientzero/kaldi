#!/bin/python
import sys
import itertools as it
import os
import shutil
def create_subset_data_dir(srcdir, targetdir, subsetsize=1000, uttminlength=5, uttmaxlength=10):
    subsetsize=int(subsetsize)
    uttminlength=int(uttminlength) 
    uttmaxlength=int(uttmaxlength)
    with open(srcdir+'/wav.scp','r' ) as f:
        wavscp = map_text(f)
    with open(srcdir+'/utt2spk') as f:
        utt2spk = map_text(f)
    with open(srcdir+'/text') as f:
        text = map_text(f)
    
    filteredtext={k: v for k, v in text.iteritems() if len(v.split(' ')) >= uttminlength and len(v.split(' ')) <= uttmaxlength}
    print 'Max length of subset is ' + str(len(filteredtext))
    if len(filteredtext) < subsetsize:
        print "Not enough items in set, returning all filterd items" + str(len(filteredtext))
        target=take(len(filteredtext), filteredtext.iteritems())
    else: 
        target=take(subsetsize, filteredtext.iteritems())

    if os.path.exists(targetdir):
        shutil.rmtree(targetdir)
    os.mkdir(targetdir)
    filteredwav={}
    filteredutt2spk={}
    with open(targetdir+'/text', 'w') as f:
        for l in target:
            f.write(l[0] + ' ' + l[1] + '\n')
            filteredwav[l[0]]=wavscp.pop(l[0])
            filteredutt2spk[l[0]]=utt2spk.pop(l[0])
    with open(targetdir+'/wav.scp', 'w') as f:
        for k, v in filteredwav.iteritems():
            f.write(k + ' ' + v + '\n')   
    with open(targetdir+'/utt2spk', 'w') as f:
        for k, v in filteredutt2spk.iteritems():
            f.write(k + ' ' + v + '\n')
            

def map_text(file):
    mappedtext={}
    for line in file: 
        line.split()
        utt=line.replace('\n', '').partition(' ')
        mappedtext[utt[0]]=utt[2]
    return mappedtext 

def take(n, iterable):
    "Return first n items of the iterable as a list"
    return list(it.islice(iterable, n))


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print 'not enough arguments'
        print 'Arguments are: srcdir, targetdir, subsetsize=1000, uttminlength=5, uttmaxlength=10'
    elif len(sys.argv) == 3:
        create_subset_data_dir(sys.argv[1], sys.argv[2])
    elif len(sys.argv) == 4:
        create_subset_data_dir(sys.argv[1], sys.argv[2], sys.argv[3])
        print sys.argv
    elif len(sys.argv) == 5:
        create_subset_data_dir(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
        print sys.argv
    elif len(sys.argv) == 6:
        create_subset_data_dir(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
        print sys.argv
    else:
        print 'too many arguments' 