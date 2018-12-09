#!/bin/bash

for i in 1 2 3 4
do
	read1=`sed -n $[i]p raw_fq.txt | cut -f1`
	SM=$(basename $(dirname $read1))
	mkdir $SM
	sed -n ${i}p raw_fq.txt > ${SM}/fq.txt
	cp rawFastq* $SM
	cd $SM
	sed -i "s/Test/${SM}/" rawFastqToCleanBam.json
	sed -i "s/read1.fq.gz/R1.fq.gz/" rawFastqToCleanBam.json
	nohup java -jar ~/bin/cromwell-34.jar run rawFastqToCleanBam.wdl -i rawFastqToCleanBam.json &> log &
	cd ..

done
