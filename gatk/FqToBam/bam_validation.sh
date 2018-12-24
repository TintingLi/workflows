#!/bin/bash
#check whether the ubam files are validated for further analysis

BAMS=(`find ~/litt/projects/wes/upload/Cleandata/human -name *.bam`)
mkdir ./log
for i in ${BAMS[@]}
do
  gatk ValidateSamFile -I $i &> ./log/$(basename $i)_bam_validate.log &
done
