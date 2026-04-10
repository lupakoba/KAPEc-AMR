#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Valores por defecto 
params.mlst_container = params.mlst_container ?: "docker.io/staphb/mlst:2.19.0"

process MLST {

    tag "MLST typing for genome ${sample_id}"

    container "${params.mlst_container}"

    publishDir "${params.outdir}/mlst", mode: 'copy'

    cpus 2
    memory '4 GB'

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("${sample_id}_mlst.tsv")

    script:
    """
    mlst ${fasta} > ${sample_id}_mlst.tsv
    """
}