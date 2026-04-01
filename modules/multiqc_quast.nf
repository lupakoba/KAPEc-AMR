#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process MULTIQC_QUAST {

    tag "multiqc_quast"

    publishDir "${params.outdir}/multiqc/assembly", mode: 'copy'

    container 'quay.io/biocontainers/multiqc:1.33--pyhdfd78af_0'

    cpus 2
    memory '4 GB'

    input:
    path quast_dirs

    output:
    path "multiqc_report_quast.html"

    script:
    """
    set -euo pipefail

    multiqc . \\
        --outdir . \\
        --filename multiqc_report_quast.html \\
        --force
    """
}