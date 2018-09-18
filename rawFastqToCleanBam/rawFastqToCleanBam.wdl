## This WDL pipeline implements data pre-processing from raw fastq to clean bam.
#Author: LTT
#Date: 201809

#Tips:
#1. This script takes one sample at a time, which can have multiple fq files.
#2. The Sequencing strategy should be pair-ended.
#3. All fq files should be supplied within a file, and the read1 and read2 files
#should be in the same line separated by tab. Read1 first.
#4. The alignment tool can be bowtie2 or bwa.

#OUTPUT:
#1. Fastqc of the raw fq data.
#2. Clean fq data generated by cutadapt.
#3. Fastqc of the clean fq data.
#4. clean bam file that are sorted by coordiante and markduplicated.


workflow rawFastqToCleanBam {
    String sample_name
    File raw_fq_list
    Array[Array[File]] raw_fqs = read_tsv(raw_fq_list)
    Int fq_num = length(raw_fqs)

    String cutadapter_para
    String bowtie2_para
    String bwa_para
    String sortbam_para
    String markdup_para

    String alignment_tool

    String discard_read1_suffix

    if (alignment_tool == 'bowtie2'){
        scatter (fq in raw_fqs) {
            Int num_fq = length(fq)
            if (num_fq != 2){
                call Error_message{
                    input:
                        message = 'fq number dose not equl to 2.'
                }
            }

            String fq_basename = basename(fq[0], discard_read1_suffix)
            String Read1 = basename(fq[0])
            String Read2 = basename(fq[1])

            call Fastqc as Fastqc_raw_data {
                input:
                    read1 = fq[0],
                    read2 = fq[1]
            }


            call CutAdapter {
                input:
                    parameter = cutadapter_para,
                    reads = fq,
                    read1_outname = fq_basename + 'R1_clean.fq.gz',
                    read2_outname = fq_basename + 'R2_clean_fq.gz'
            }

            call Fastqc as Fastqc_clean_data {
                input:
                    read1 = CutAdapter.read1,
                    read2 = CutAdapter.read2
            }

            call Bowtie2Alignment {
                input:
                    parameter = bowtie2_para,
                    sample_name = sample_name,
                    output_bam_basename = fq_basename + '.btw2',
                    read1 = CutAdapter.read1,
                    read2 = CutAdapter.read2
            }

            call SortBam {
                input:
                    parameter = sortbam_para,
                    input_bam = Bowtie2Alignment.output_bam,
                    output_bam_basename = fq_basename + '.aligned.sorted'
            }
        }

        call MarkDuplicates {
            input:
                parameter = markdup_para,
                output_bam_basename = sample_name + '.aligned.sorted.rmd',
                metrics_filename = sample_name + '_metrics',
                input_bam = SortBam.output_bam
        }
    }


    if (alignment_tool == 'bwa'){
        scatter (fq in raw_fqs) {
            Int num_fq2 = length(fq)
            if (num_fq2 != 2){
                call Error_message as Error_message2 {
                    input:
                        message = 'fq number dose not equl to 2.'
                }
            }

            String fq_basename2 = basename(fq[0], discard_read1_suffix)

            call Fastqc as fastqc_raw_data {
                input:
                    read1 = fq[0],
                    read2 = fq[1]
            }

            call CutAdapter as cutadapter {
            input:
                parameter = cutadapter_para,
                reads = fq,
                read1_outname = fq_basename2 + 'R1_clean.fq.gz',
                read2_outname = fq_basename2 + 'R2_clean_fq.gz'
            }

            call Fastqc as fastqc_clean_data {
                input:
                    read1 = cutadapter.read1,
                    read2 = cutadapter.read2
            }


            call BwaAlignment {
            input:
                parameter = bwa_para,
                sample_name = sample_name,
                output_bam_basename = fq_basename2 + '.bwa',
                read1 = cutadapter.read1,
                read2 = cutadapter.read2
            }

            call SortBam as sortbam {
                input:
                    parameter = sortbam_para,
                    input_bam = BwaAlignment.output_bam,
                    output_bam_basename = fq_basename2 + '.aligned.sorted'
            }
        }

        call MarkDuplicates as markduplicates {
            input:
                parameter = markdup_para,
                output_bam_basename = sample_name + '.aligned.sorted.rmd',
                metrics_filename = sample_name + '_metrics',
                input_bam = sortbam.output_bam
        }
    }
}


task Error_message {
    String message
    command {
        echo ${message}
        exit(1)
    }
}

task Fastqc {
    File read1
    File read2

    command {
        fastqc -o . -f fastq ${read1} ${read2}
    }
}


task CutAdapter{
    String parameter
    Array[File] reads
    String read1_outname
    String read2_outname

    command {
        cutadapt ${parameter} -o ${read1_outname} -p ${read2_outname} \
            ${sep=' ' reads} &> cutadapter.log
    }
    output {
        File read1 = "${read1_outname}"
        File read2 = "${read2_outname}"
    }

}


task Bowtie2Alignment {
    String parameter
    String sample_name
    File read1
    File read2
    String output_bam_basename

    command {
        bowtie2 ${parameter} --rg-id ncba --rg SM:${sample_name} \
            -1 ${read1} -2 ${read2} 2> bowtie2_${sample_name}.log | \
            samtools view -q 1 -b - -o ${output_bam_basename}.bam
    }
    output {
        File output_bam = "${output_bam_basename}.bam"
    }
}


task BwaAlignment {
    String parameter
    String sample_name
    File read1
    File read2
    String output_bam_basename

    command {
        bwa ${parameter} -R '@RG\tID:ncba\tLB:${sample_name}_lib\tSM:${sample_name}\tPL:illumina' \
            ${read1} ${read2} 2> ${sample_name}_bwa.log | \
            samtools view -q 1 -b - -o ${output_bam_basename}.bam
    }
    output {
        File output_bam = "${output_bam_basename}.bam"
    }
}


task SortBam {
    String parameter
    File input_bam
    String output_bam_basename

    command {
        samtools sort ${parameter} -o ${output_bam_basename}.bam ${input_bam}
    }
    output {
        File output_bam = "${output_bam_basename}.bam"
    }
}


task MarkDuplicates {
    String parameter
    String output_bam_basename
    String metrics_filename
    Array[File] input_bam

    command {
        gatk --java-options "${parameter}" MarkDuplicates \
            --INPUT ${sep = ' --INPUT ' input_bam} \
            --OUTPUT ${output_bam_basename}.bam \
            --METRICS_FILE ${metrics_filename} \
            --VALIDATION_STRINGENCY SILENT \
            --OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500 \
            --TMP_DIR ./tmp \
            --REMOVE_DUPLICATES true \
            --ASSUME_SORTED true \
    }

    output {
        File output_bam = "${output_bam_basename}.bam"
    }

}
