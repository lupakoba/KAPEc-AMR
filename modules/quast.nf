#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process QUAST {

    tag "${sample_id}"

    publishDir "${params.outdir}/quast", mode: 'copy'

    container "staphb/quast:5.2.0"

    cpus 4
    memory '16 GB'

    input:
    tuple val(sample_id), path(fasta)

    output:
    tuple val(sample_id), path("quast_${sample_id}")

    script:
    """
    set -euo pipefail

    mkdir -p quast_${sample_id}

    quast.py \\
        ${fasta} \\
        -o quast_${sample_id} \\
        --threads ${task.cpus} \\
        --min-contig 200
    """
}