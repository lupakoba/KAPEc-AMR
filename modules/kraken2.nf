#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process KRAKEN2 {

    tag "Taxonomic classification for sample ${sample_id}"

    // Contenedor
    container "${params.kraken2_container}"

    // Carpeta de salida
    publishDir "results/kraken2", mode: 'copy'

    // Recursos
    cpus params.kraken2_threads
    memory '16 GB'
    maxForks 1

    // ------------------------
    // Inputs
    // ------------------------
    input:
    tuple val(sample_id), path(reads), path(db_file)  // 3 inputs obligatorios

    // ------------------------
    // Outputs
    // ------------------------
    output:
    tuple val(sample_id), path("${sample_id}_kraken_report.txt")

    // ------------------------
    // Script de ejecución
    // ------------------------
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