#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process KRAKEN2 {

    tag "Taxonomic classification for sample ${sample_id}"

    container "${params.kraken2_container}"

    publishDir "results/kraken2", mode: 'copy'

    cpus params.kraken2_threads
    memory '16 GB'
    
    input:
    tuple val(sample_id), path(reads), path(db_file)  

    output:
    tuple val(sample_id), path("${sample_id}_kraken_report.txt")

    
    script:
    """
    kraken2 \
        --db ${db_file} \
        --paired ${reads[0]} ${reads[1]} \
        --report ${sample_id}_kraken_report.txt \
        --output /dev/null \
        --use-names \
        --threads ${task.cpus} 
    """
}