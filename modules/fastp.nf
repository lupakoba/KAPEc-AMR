#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process fastp_trim {

    tag "Trimming for sample ${sample_id}"

    container 'staphb/fastp:1.1.0'

    publishDir "results/fastp", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*.fastq.gz"), emit: trimmed_reads
    tuple val(sample_id), path("*.html"), emit: fastp_html
    tuple val(sample_id), path("*.json"), emit: fastp_json

    script:
    """
    fastp -i ${reads[0]} -I ${reads[1]} \
          -o ${sample_id}_trimmed_R1.fastq.gz \
          -O ${sample_id}_trimmed_R2.fastq.gz \
          -h ${sample_id}_fastp.html \
          -j ${sample_id}_fastp.json
    """
}