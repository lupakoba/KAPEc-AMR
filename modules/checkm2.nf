#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process CHECKM2 {
    tag "${sample_id}"
    container "${params.checkm2_container}"
    
    cpus 8
    memory '16 GB'

    publishDir "${params.outdir}/checkm2", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta), path(db_file) // Ahora pasamos el archivo .dmnd directamente

    output:
    path("${sample_id}_checkm2"), emit: results

    script:
    """
    export HOME=\$PWD
    
    # IMPORTANTE: En v1.1.0, --database_path DEBE apuntar al archivo .dmnd
    checkm2 predict \
        --input ${fasta} \
        --database_path ${db_file} \
        --output-directory ${sample_id}_checkm2 \
        --threads ${task.cpus} \
        --force
    """
}


    
