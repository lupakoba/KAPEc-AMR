#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process KRAKEN2 {

    tag "Kraken2 classification: ${sample_id}"

    container params.kraken2_docker

    publishDir "results/kraken2", mode: 'copy'

    cpus params.kraken2_threads
    maxForks 1

    input:
    tuple val(sample_id), path(reads), path(db_path)

    output:
    tuple val(sample_id),
          path("${sample_id}_kraken_report.txt"),
          emit: kraken_output

    script:
    """
    kraken2 \\
        --db ${db_path} \\
        --paired ${reads[0]} ${reads[1]} \\
        --report ${sample_id}_kraken_report.txt \\
        --output /dev/null \\
        --use-names \\
        --threads ${task.cpus} \\
        --memory-mapping
    """
}