#!/bin/bash

for i in `cat unmapped_bam_5.txt`
do
	SM=$(basename $(dirname $i))
	mkdir ./$SM
	cp ubamTocleanBam* ./$SM
	cd $SM
	echo $i > unmapped_bam.txt
	sed -i "s/SAMPLE_NAME/$SM/" ubamTocleanBam_hg38.json
	nohup java -jar ~/litt/software/gatk/cromwell/cromwell-34.jar \
		run ubamTocleanBam.wdl -i ubamTocleanBam_hg38.json &> log &
	cd ..
done
