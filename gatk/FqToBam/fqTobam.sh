#!/bin/bash

SM_DIR=~/litt/projects/wes/upload/Cleandata/human
SMS=(`find $SM_DIR -mindepth 1 -maxdepth 1 -type d | sort`)
SUFFIX='.unmapped.bam'


echo "----------------"
echo "FqToBam starts at `date`"
for SM in ${SMS[@]}
do
    R1=`find $SM -name *R1.fq.gz`
    R2=`find $SM -name *R2.fq.gz`
    SM_NAME=`basename $SM`
    
    CMD="nohup java -Xmx8G -Xms2G -XX:ParallelGCThreads=3 \
        -Djava.io.tmpdir=`pwd`/tmp -jar $PICARD  FastqToSam \
        F1=$R1  \
		F2=$R2 \
        OUTPUT=${SM}/${SM_NAME}${SUFFIX} \
        READ_GROUP_NAME=${SM_NAME}_rg  \
        SAMPLE_NAME=${SM_NAME}   \
        LIBRARY_NAME=${SM_NAME}_lib  \
        PLATFORM=illumina &> ./log/${SM_NAME}_fqTobam.log & "
    echo $CMD
    eval $CMD
done
    
wait ; sleep 3
echo "FqToBam ends at `date`"
echo "----------------------"



