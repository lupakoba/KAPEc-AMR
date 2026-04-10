#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process FASTQC_TRIMMED {

    tag "QC of trimmed reads for sample ${sample_id}"

    container 'biocontainers/fastqc:v0.11.9_cv8'

    publishDir "results/fastqc_trimmed", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "*.html", emit: fastqc_html
    path "*.zip",  emit: fastqc_zip

    script:
    """
    fastqc $reads
    """
}